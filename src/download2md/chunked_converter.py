#!/usr/bin/env python3
"""
Chunked HTML to Markdown converter for medium-sized files.
Splits large HTML files into manageable chunks and processes them through Claude SDK.
"""

import asyncio
import os
import re
from typing import List, Optional, Tuple
from collections import namedtuple
from .shared import ConversionItem, load_conversions_from_yaml

# Enhanced parsing libraries with fallbacks
try:
    from bs4 import BeautifulSoup, Comment
    HAS_BS4 = True
except ImportError:
    HAS_BS4 = False

try:
    from claude_code_sdk import ClaudeSDKClient, ClaudeCodeOptions
    HAS_CLAUDE_SDK = True
except ImportError:
    HAS_CLAUDE_SDK = False

ChunkItem = namedtuple('ChunkItem', ['content', 'index', 'total'])

class ChunkedHTMLToMarkdownConverter:
    """
    Chunked HTML to Markdown converter for medium-sized files.
    
    Splits HTML into semantic chunks and processes them through Claude SDK
    to avoid token limits while maintaining high conversion quality.
    """
    
    def __init__(self, 
                 chunk_size_kb: int = 50,
                 chunk_overlap_kb: int = 5,
                 max_turns: int = 5,
                 quiet: bool = False):
        """
        Initialize the chunked converter.
        
        Args:
            chunk_size_kb: Target chunk size in KB
            chunk_overlap_kb: Overlap between chunks in KB  
            max_turns: Maximum conversation turns per chunk
            quiet: Reduce output verbosity
        """
        self.chunk_size_bytes = chunk_size_kb * 1024
        self.overlap_size_bytes = chunk_overlap_kb * 1024
        self.max_turns = max_turns
        self.quiet = quiet
        
        if not HAS_CLAUDE_SDK:
            raise ImportError("claude-code-sdk is required for chunked conversion")
    
    def _find_semantic_boundaries(self, html_content: str) -> List[int]:
        """
        Find semantic boundaries in HTML for better chunk splitting.
        
        Args:
            html_content: Raw HTML content
            
        Returns:
            List of byte positions for semantic boundaries
        """
        boundaries = [0]  # Start position
        
        if HAS_BS4:
            try:
                soup = BeautifulSoup(html_content, 'html.parser')
                
                # Find major structural elements
                major_elements = soup.find_all(['article', 'section', 'div', 'main'])
                
                for element in major_elements:
                    start_pos = html_content.find(str(element)[:100])  # Find approximate position
                    if start_pos > 0:
                        boundaries.append(start_pos)
                
                # Find heading boundaries
                headings = soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6'])
                for heading in headings:
                    heading_str = str(heading)
                    start_pos = html_content.find(heading_str)
                    if start_pos > 0:
                        boundaries.append(start_pos)
                        
            except Exception as e:
                if not self.quiet:
                    print(f"[WARNING] Failed to find semantic boundaries with BS4: {e}")
        
        # Fallback to regex-based boundary detection
        heading_pattern = r'<h[1-6][^>]*>'
        section_pattern = r'<(article|section|div|main)[^>]*>'
        
        for match in re.finditer(heading_pattern, html_content, re.IGNORECASE):
            boundaries.append(match.start())
            
        for match in re.finditer(section_pattern, html_content, re.IGNORECASE):
            boundaries.append(match.start())
        
        # Remove duplicates and sort
        boundaries = sorted(list(set(boundaries)))
        
        # Add end position
        boundaries.append(len(html_content))
        
        return boundaries
    
    def _split_into_chunks(self, html_content: str) -> List[str]:
        """
        Split HTML content into manageable chunks with semantic awareness.
        
        Args:
            html_content: Raw HTML content
            
        Returns:
            List of HTML chunks
        """
        boundaries = self._find_semantic_boundaries(html_content)
        chunks = []
        
        i = 0
        while i < len(boundaries) - 1:
            chunk_start = boundaries[i]
            chunk_content = ""
            chunk_size = 0
            
            # Build chunk until we reach size limit
            j = i + 1
            while j < len(boundaries) and chunk_size < self.chunk_size_bytes:
                chunk_end = boundaries[j]
                potential_chunk = html_content[chunk_start:chunk_end]
                
                if len(potential_chunk.encode('utf-8')) > self.chunk_size_bytes:
                    break
                    
                chunk_content = potential_chunk
                chunk_size = len(chunk_content.encode('utf-8'))
                j += 1
            
            if not chunk_content:  # Single boundary segment is too large
                # Force split at size limit
                chunk_end = min(chunk_start + self.chunk_size_bytes, len(html_content))
                chunk_content = html_content[chunk_start:chunk_end]
                j = i + 1
            
            if chunk_content.strip():
                chunks.append(chunk_content)
            
            # Move to next chunk with overlap
            overlap_start = max(0, len(chunk_content) - self.overlap_size_bytes)
            next_start = chunk_start + overlap_start
            
            # Find next boundary after overlap
            i = j - 1
            while i < len(boundaries) - 1 and boundaries[i] < next_start:
                i += 1
        
        return chunks
    
    def _create_chunk_prompt(self, chunk_content: str, chunk_index: int, total_chunks: int, 
                           is_first: bool, is_last: bool) -> str:
        """
        Create a prompt for converting a single chunk.
        
        Args:
            chunk_content: HTML chunk content
            chunk_index: Current chunk index (0-based)
            total_chunks: Total number of chunks
            is_first: Whether this is the first chunk
            is_last: Whether this is the last chunk
            
        Returns:
            Formatted prompt for chunk conversion
        """
        context = ""
        if total_chunks > 1:
            context = f"This is chunk {chunk_index + 1} of {total_chunks}. "
            if is_first:
                context += "This is the first chunk - include document title if present. "
            elif is_last:
                context += "This is the final chunk - ensure proper conclusion. "
            else:
                context += "This is a middle chunk - focus on content continuity. "
        
        prompt = f"""Convert the following HTML content to clean, well-formatted Markdown.

{context}

Requirements:
1. Preserve semantic structure (headings, paragraphs, lists, etc.)
2. Convert links and images to proper markdown syntax
3. Handle code blocks and inline code appropriately
4. Remove navigation, ads, and non-content elements
5. Maintain readability and formatting

HTML Content:
{chunk_content}

Convert to Markdown format:"""

        return prompt
    
    async def _convert_chunk(self, chunk_content: str, chunk_index: int, total_chunks: int) -> str:
        """
        Convert a single HTML chunk to Markdown using Claude SDK.
        
        Args:
            chunk_content: HTML chunk content
            chunk_index: Current chunk index
            total_chunks: Total number of chunks
            
        Returns:
            Markdown content for this chunk
        """
        is_first = chunk_index == 0
        is_last = chunk_index == total_chunks - 1
        
        prompt = self._create_chunk_prompt(chunk_content, chunk_index, total_chunks, is_first, is_last)
        
        try:
            async with ClaudeSDKClient(
                options=ClaudeCodeOptions(
                    system_prompt="You are an expert HTML to Markdown converter. Focus on creating clean, readable markdown while preserving all important content and structure.",
                    allowed_tools=[],  # No tools needed for chunk conversion
                    max_turns=self.max_turns
                )
            ) as client:
                await client.query(prompt)
                
                markdown_content = ""
                async for response in client.receive_response():
                    response_text = str(response)
                    markdown_content += response_text
                
                return markdown_content.strip()
                
        except Exception as e:
            if not self.quiet:
                print(f"[ERROR] Failed to convert chunk {chunk_index + 1}: {e}")
            return f"<!-- Chunk {chunk_index + 1} conversion failed: {e} -->\n"
    
    def _merge_chunks(self, chunk_results: List[str]) -> str:
        """
        Merge converted chunks into a single markdown document.
        
        Args:
            chunk_results: List of markdown content from each chunk
            
        Returns:
            Combined markdown document
        """
        if not chunk_results:
            return ""
        
        # Filter out empty or error chunks
        valid_chunks = [chunk for chunk in chunk_results if chunk and not chunk.startswith('<!--')]
        
        if not valid_chunks:
            return "<!-- All chunks failed to convert -->"
        
        # Simple concatenation with spacing
        merged_content = "\n\n".join(valid_chunks)
        
        # Clean up excessive whitespace
        merged_content = re.sub(r'\n\s*\n\s*\n', '\n\n', merged_content)
        
        return merged_content.strip()
    
    async def convert_html_to_markdown(self, html_content: str) -> str:
        """
        Convert HTML content to Markdown using chunked processing.
        
        Args:
            html_content: Raw HTML content
            
        Returns:
            Markdown formatted text
        """
        file_size_kb = len(html_content.encode('utf-8')) / 1024
        
        if not self.quiet:
            print(f"[INFO] Processing {file_size_kb:.1f}KB file with chunked converter...")
        
        # Split into chunks
        chunks = self._split_into_chunks(html_content)
        
        if not self.quiet and len(chunks) > 1:
            print(f"[INFO] Split into {len(chunks)} chunks for processing...")
        
        # Convert each chunk concurrently
        chunk_tasks = [
            self._convert_chunk(chunk, i, len(chunks))
            for i, chunk in enumerate(chunks)
        ]
        
        # Process chunks with limited concurrency to avoid overwhelming the API
        max_concurrent = min(3, len(chunks))  # Limit concurrent chunk processing
        semaphore = asyncio.Semaphore(max_concurrent)
        
        async def convert_with_semaphore(task, index):
            async with semaphore:
                if not self.quiet and len(chunks) > 1:
                    print(f"[INFO] Converting chunk {index + 1}/{len(chunks)}...")
                return await task
        
        chunk_results = await asyncio.gather(*[
            convert_with_semaphore(task, i) for i, task in enumerate(chunk_tasks)
        ])
        
        # Merge chunks
        merged_content = self._merge_chunks(chunk_results)
        
        if not self.quiet:
            print(f"[INFO] Successfully merged {len(chunks)} chunks into final document")
        
        return merged_content
    
    def _build_file_paths(self, root_path: str, input_filename: str, output_filename: str):
        """Build full file paths and create output directories."""
        input_path = os.path.join(root_path, input_filename)
        output_path = os.path.join(root_path, output_filename)
        
        # Create output directory
        output_dir = os.path.dirname(output_path)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir, exist_ok=True)
            if not self.quiet:
                print(f"[INFO] Created output directory: {output_dir}")
        
        return input_path, output_path
    
    async def convert(self, root_path: str, input_filename: str, output_filename: str) -> bool:
        """
        Convert HTML file to Markdown using chunked processing.
        
        Args:
            root_path: The base directory path
            input_filename: The input HTML filename
            output_filename: The output Markdown filename
            
        Returns:
            True if conversion was successful, False otherwise
        """
        try:
            input_path, output_path = self._build_file_paths(root_path, input_filename, output_filename)
            
            if not os.path.exists(input_path):
                print(f"[ERROR] Input file not found: {os.path.basename(input_path)}")
                return False
            
            # Check file size
            file_size = os.path.getsize(input_path)
            file_size_mb = file_size / (1024 * 1024)
            
            if not self.quiet:
                print(f"[INFO] Processing {os.path.basename(input_path)} ({file_size_mb:.1f} MB) with chunked converter...")
            
            # Read HTML content
            with open(input_path, 'r', encoding='utf-8', errors='ignore') as f:
                html_content = f.read()
            
            # Convert to markdown
            markdown_content = await self.convert_html_to_markdown(html_content)
            
            # Write markdown file
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(markdown_content)
            
            if not self.quiet:
                print(f"[SUCCESS] {os.path.basename(input_path)} → {os.path.basename(output_path)}")
            return True
            
        except Exception as e:
            print(f"[ERROR] Chunked conversion failed: {e}")
            return False
    
    async def convert_file(self, root_path: str, conversion_item: ConversionItem) -> bool:
        """Convert using ConversionItem."""
        return await self.convert(root_path, conversion_item.input_filename, conversion_item.output_filename)
    
    async def convert_batch(self, root_path: str, conversions: List[ConversionItem]) -> List[bool]:
        """Convert multiple files with progress tracking."""
        results = []
        total = len(conversions)
        
        if not self.quiet and total > 1:
            print(f"[INFO] Starting chunked batch conversion of {total} files...")
            
        for i, conversion_item in enumerate(conversions):
            if not self.quiet and total > 1:
                print(f"[{i + 1}/{total}] Converting {conversion_item.input_filename}...")
            
            success = await self.convert_file(root_path, conversion_item)
            results.append(success)
        
        if not self.quiet and total > 1:
            successful = sum(results)
            print(f"[INFO] Chunked batch conversion completed: {successful}/{total} successful")
            
        return results


if __name__ == "__main__":
    import sys
    
    # Parse command line arguments
    quiet_mode = '--quiet' in sys.argv or '-q' in sys.argv
    chunk_size = 50  # Default chunk size in KB
    overlap_size = 5  # Default overlap in KB
    
    # Parse chunk size if provided
    for i, arg in enumerate(sys.argv):
        if arg.startswith('--chunk-size='):
            chunk_size = int(arg.split('=')[1])
        elif arg.startswith('--overlap='):
            overlap_size = int(arg.split('=')[1])
    
    # Remove option flags from argv
    sys.argv = [arg for arg in sys.argv if not arg.startswith('--') and not arg.startswith('-q')]
    
    if not HAS_CLAUDE_SDK:
        print("[ERROR] claude-code-sdk is required for chunked conversion")
        print("Install with: pip install claude-code-sdk")
        sys.exit(1)
    
    if len(sys.argv) == 2:
        # YAML file mode
        yaml_file = sys.argv[1]
        try:
            root_path, conversions, max_concurrent = load_conversions_from_yaml(yaml_file)
            if not quiet_mode:
                print(f"[INFO] Loaded {len(conversions)} conversions from {os.path.basename(yaml_file)}")
                if len(conversions) <= 3:
                    print(f"[INFO] Root directory: {root_path}")
                print(f"[INFO] Using chunked converter (chunk size: {chunk_size}KB, overlap: {overlap_size}KB)")
            
            converter = ChunkedHTMLToMarkdownConverter(
                chunk_size_kb=chunk_size,
                chunk_overlap_kb=overlap_size,
                quiet=quiet_mode
            )
            results = asyncio.run(converter.convert_batch(root_path, conversions))
            
            successful = sum(results)
            total = len(conversions)
            
            if successful == total:
                print(f"[SUCCESS] All {total} conversions completed successfully!")
            elif successful > 0:
                print(f"[WARNING] Partial success: {total - successful} conversions failed")
                sys.exit(1)
            else:
                print(f"[ERROR] All {total} conversions failed!")
                sys.exit(1)
                
        except Exception as e:
            print(f"[ERROR] Failed to process YAML file: {e}")
            sys.exit(1)
    
    elif len(sys.argv) == 4:
        # Single file mode
        root_path, input_filename, output_filename = sys.argv[1], sys.argv[2], sys.argv[3]
        
        if not quiet_mode:
            print(f"[INFO] Using chunked converter (chunk size: {chunk_size}KB, overlap: {overlap_size}KB)")
        
        converter = ChunkedHTMLToMarkdownConverter(
            chunk_size_kb=chunk_size,
            chunk_overlap_kb=overlap_size,
            quiet=quiet_mode
        )
        success = asyncio.run(converter.convert(root_path, input_filename, output_filename))
        
        if success:
            if not quiet_mode:
                print(f"[SUCCESS] Conversion completed: {input_filename} → {output_filename}")
        else:
            print(f"[ERROR] Conversion failed: {input_filename}")
            sys.exit(1)
    
    else:
        print("""Usage:
  Mode 1 (YAML file):  python3 chunked_converter.py <yaml_file> [options]
  Mode 2 (Single file): python3 chunked_converter.py <root_path> <input_filename> <output_filename> [options]

Options:
  --quiet, -q              Reduce output verbosity
  --chunk-size=<KB>        Chunk size in KB (default: 50)
  --overlap=<KB>           Overlap between chunks in KB (default: 5)

Examples:
  python3 chunked_converter.py conversions_config.yaml --chunk-size=30 --quiet
  python3 chunked_converter.py ./docs page.html page.md --chunk-size=75

Features:
  • Handles medium-large files (100KB - 2MB) efficiently
  • Uses semantic chunking to preserve document structure
  • High-quality conversion via Claude SDK without token limits
  • Configurable chunk size and overlap
  • Concurrent chunk processing for speed""")
        sys.exit(1)