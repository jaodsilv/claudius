#!/usr/bin/env python3
"""
HTML to Markdown conversion utility using Claude Code SDK.

This module provides functionality to convert HTML files to Markdown format
using Claude's advanced content processing capabilities.
"""

import asyncio
import glob
import os
from typing import List, Optional, Tuple
from .shared import ConversionItem, load_conversions_from_yaml

# Re-export for backward compatibility
__all__ = ['HTMLToMarkdownConverter', 'ConversionItem', 'load_conversions_from_yaml', 
           'html_to_md', 'convert_file', 'convert_batch']
from .simple_converter import SimpleHTMLToMarkdownConverter
from .chunked_converter import ChunkedHTMLToMarkdownConverter
from .claude_native_converter import ClaudeCodeNativeConverter


class HTMLToMarkdownConverter:
    """
    Intelligent HTML to Markdown converter with automatic method selection.
    
    Automatically chooses the best conversion method based on file size and requirements:
    - Simple converter for large files (>500KB) - no token limits
    - Chunked converter for medium files (100KB-500KB) - high quality with chunking
    - Claude converter for small files (<100KB) - maximum quality
    """

    def __init__(self,
                 allowed_tools: Optional[List[str]] = None,
                 max_turns: int = 10,
                 max_concurrent: int = 5,
                 quiet: bool = False,
                 conversion_strategy: str = 'auto',
                 large_file_threshold_kb: int = 500,
                 medium_file_threshold_kb: int = 100,
                 chunk_size_kb: int = 50,
                 chunk_overlap_kb: int = 5):
        """
        Initialize the intelligent converter with configuration options.

        Args:
            allowed_tools: List of tools Claude can use during conversion
            max_turns: Maximum number of conversation turns
            max_concurrent: Maximum number of concurrent conversions
            quiet: If True, reduce output verbosity
            conversion_strategy: 'auto', 'simple', 'chunked', or 'native'
            large_file_threshold_kb: Files above this size use simple converter
            medium_file_threshold_kb: Files above this size use chunked converter
            chunk_size_kb: Chunk size for chunked converter
            chunk_overlap_kb: Overlap size for chunked converter
        """
        self.allowed_tools = allowed_tools or ["Read", "Write", "Edit", "LS", "TodoWrite", "Grep", "Glob"]
        self.max_turns = max_turns
        self.max_concurrent = max_concurrent
        self.quiet = quiet
        self.conversion_strategy = conversion_strategy
        self.large_file_threshold_bytes = large_file_threshold_kb * 1024
        self.medium_file_threshold_bytes = medium_file_threshold_kb * 1024
        self.chunk_size_kb = chunk_size_kb
        self.chunk_overlap_kb = chunk_overlap_kb
        
        # Initialize sub-converters lazily
        self._simple_converter = None
        self._chunked_converter = None
        self._native_converter = None
    
    def _get_simple_converter(self) -> SimpleHTMLToMarkdownConverter:
        """Get or create simple converter instance."""
        if self._simple_converter is None:
            self._simple_converter = SimpleHTMLToMarkdownConverter(
                clean_content=True,
                quiet=self.quiet
            )
        return self._simple_converter
    
    def _get_chunked_converter(self) -> ChunkedHTMLToMarkdownConverter:
        """Get or create chunked converter instance."""
        if self._chunked_converter is None:
            try:
                self._chunked_converter = ChunkedHTMLToMarkdownConverter(
                    chunk_size_kb=self.chunk_size_kb,
                    chunk_overlap_kb=self.chunk_overlap_kb,
                    max_turns=self.max_turns,
                    quiet=self.quiet
                )
            except ImportError as e:
                if not self.quiet:
                    print(f"[WARNING] Chunked converter unavailable: {e}")
                return None
        return self._chunked_converter
    
    def _get_native_converter(self) -> ClaudeCodeNativeConverter:
        """Get or create native converter instance."""
        if self._native_converter is None:
            self._native_converter = ClaudeCodeNativeConverter(
                max_concurrent=self.max_concurrent,
                quiet=self.quiet
            )
        return self._native_converter
    
    def _determine_conversion_method(self, file_size_bytes: int, input_path: str) -> str:
        """
        Determine the best conversion method based on file size and strategy.
        
        Args:
            file_size_bytes: Size of the input file in bytes
            input_path: Path to input file (for error reporting)
            
        Returns:
            Conversion method: 'simple', 'chunked', or 'native'
        """
        if self.conversion_strategy != 'auto':
            return self.conversion_strategy
        
        file_size_kb = file_size_bytes / 1024
        
        if file_size_bytes > self.large_file_threshold_bytes:
            if not self.quiet:
                print(f"[INFO] Large file ({file_size_kb:.1f}KB) - using simple converter")
            return 'simple'
        elif file_size_bytes > self.medium_file_threshold_bytes:
            # Use simple converter for medium files to avoid Claude SDK pollution
            # (chunked converter uses Claude SDK which causes pollution)
            if not self.quiet:
                print(f"[INFO] Medium file ({file_size_kb:.1f}KB) - using simple converter")
            return 'simple'
        else:
            if not self.quiet:
                print(f"[INFO] Small file ({file_size_kb:.1f}KB) - using native converter")
            return 'native'
    
    async def _convert_with_method(self, method: str, root_path: str, input_filename: str, output_filename: str) -> bool:
        """
        Convert file using the specified method.
        
        Args:
            method: Conversion method ('simple', 'chunked', or 'native')
            root_path: The base directory path
            input_filename: The input HTML filename
            output_filename: The output Markdown filename
            
        Returns:
            True if conversion was successful, False otherwise
        """
        if method == 'simple':
            converter = self._get_simple_converter()
            return await converter.convert(root_path, input_filename, output_filename)
        
        elif method == 'chunked':
            converter = self._get_chunked_converter()
            if converter is None:
                if not self.quiet:
                    print(f"[WARNING] Chunked converter unavailable, falling back to native converter")
                converter = self._get_native_converter()
            return await converter.convert(root_path, input_filename, output_filename)
        
        elif method == 'native':
            converter = self._get_native_converter()
            return await converter.convert(root_path, input_filename, output_filename)
        
        else:
            raise ValueError(f"Unknown conversion method: {method}")
    
    
    

    def _resolve_filename(self, root_path: str, filename: str) -> str:
        """
        Resolve filename by checking for extension and finding matching files.

        Args:
            root_path: The base directory path
            filename: The filename to resolve

        Returns:
            The resolved filename (with extension if found)
        """
        # Check if filename already has an extension
        name, ext = os.path.splitext(filename)
        if ext:
            # Filename already has extension, return as-is
            return filename

        # No extension - search for files matching the base filename
        pattern = os.path.join(root_path, f"{filename}.*")
        matches = glob.glob(pattern)

        if matches:
            # Return just the filename part of the first match
            return os.path.basename(matches[0])

        # No matches found, return original filename
        return filename

    def _build_file_paths(self, root_path: str, input_filename: str, output_filename: str) -> tuple[str, str]:
        """
        Build full file paths for input and output files.

        Args:
            root_path: The base directory path
            input_filename: The input HTML filename
            output_filename: The output Markdown filename

        Returns:
            Tuple of (input_path, output_path)
        """
        # Resolve filenames to handle missing extensions
        resolved_input = self._resolve_filename(root_path, input_filename)
        resolved_output = self._resolve_filename(root_path, output_filename)

        input_path = os.path.join(root_path, resolved_input)
        output_path = os.path.join(root_path, resolved_output)
        
        # Create output directory if it doesn't exist
        output_dir = os.path.dirname(output_path)
        if output_dir and not os.path.exists(output_dir):
            try:
                os.makedirs(output_dir, exist_ok=True)
                if not self.quiet:
                    print(f"[INFO] Created output directory: {output_dir}")
            except OSError as e:
                raise ValueError(f"Failed to create output directory {output_dir}: {e}")
        
        return input_path, output_path



    def _verify_conversion_success(self, output_path: str) -> bool:
        """
        Verify that the conversion was successful.

        Args:
            output_path: Path to the output file

        Returns:
            True if conversion was successful, False otherwise
        """
        return os.path.exists(output_path) and os.path.getsize(output_path) > 0

    async def convert(self, root_path: str, input_filename: str, output_filename: str) -> bool:
        """
        Convert an HTML file to Markdown format using intelligent method selection.

        Args:
            root_path: The base directory path
            input_filename: The input HTML filename
            output_filename: The output Markdown filename

        Returns:
            True if conversion was successful, False otherwise
        """
        try:
            # Build file paths
            input_path, output_path = self._build_file_paths(root_path, input_filename, output_filename)
            
            # Check if input file exists
            if not os.path.exists(input_path):
                print(f"[ERROR] Input file does not exist: {os.path.basename(input_path)}")
                return False

            # Determine file size and conversion method
            file_size = os.path.getsize(input_path)
            conversion_method = self._determine_conversion_method(file_size, input_path)
            
            # Perform conversion with fallback logic
            success = await self._convert_with_retry(conversion_method, root_path, input_filename, output_filename)
            
            return success

        except Exception as e:
            print(f"[ERROR] Conversion failed: {e}")
            return False
    
    async def _convert_with_retry(self, initial_method: str, root_path: str, input_filename: str, output_filename: str) -> bool:
        """
        Attempt conversion with fallback to simpler methods if needed.
        
        Args:
            initial_method: Initial conversion method to try
            root_path: The base directory path
            input_filename: The input HTML filename
            output_filename: The output Markdown filename
            
        Returns:
            True if conversion was successful, False otherwise
        """
        # Define fallback order: native -> chunked -> simple
        fallback_methods = {
            'native': ['chunked', 'simple'],
            'chunked': ['simple'],
            'simple': []
        }
        
        methods_to_try = [initial_method] + fallback_methods.get(initial_method, [])
        
        for method in methods_to_try:
            try:
                if not self.quiet and method != initial_method:
                    print(f"[INFO] Trying fallback method: {method}")
                
                success = await self._convert_with_method(method, root_path, input_filename, output_filename)
                
                if success:
                    return True
                elif method != initial_method:
                    if not self.quiet:
                        print(f"[WARNING] {method} conversion failed, trying next method...")
                        
            except Exception as e:
                if not self.quiet:
                    error_type = "token limit" if "token" in str(e).lower() or "size" in str(e).lower() else "conversion"
                    print(f"[WARNING] {method} {error_type} error: {e}")
                
        
        print(f"[ERROR] All conversion methods failed for {input_filename}")
        return False

    async def _convert_with_semaphore(self, semaphore: asyncio.Semaphore, root_path: str, conversion_item: ConversionItem, index: int = 0, total: int = 0) -> bool:
        """
        Convert a single file with semaphore control.
        
        Args:
            semaphore: Asyncio semaphore for limiting concurrency
            root_path: The base directory path
            conversion_item: ConversionItem namedtuple
            index: Current file index (for progress display)
            total: Total number of files (for progress display)
            
        Returns:
            True if conversion was successful, False otherwise
        """
        async with semaphore:
            if not self.quiet and total > 1:
                print(f"[{index + 1}/{total}] Converting {conversion_item.input_filename}...")
            return await self.convert_file(root_path, conversion_item)

    async def convert_file(self, root_path: str, conversion_item: ConversionItem) -> bool:
        """
        Convert an HTML file to Markdown format using a ConversionItem.

        Args:
            root_path: The base directory path
            conversion_item: ConversionItem namedtuple containing input_filename and output_filename

        Returns:
            True if conversion was successful, False otherwise
        """
        return await self.convert(root_path, conversion_item.input_filename, conversion_item.output_filename)

    async def convert_batch(self, root_path: str, conversions: List[ConversionItem]) -> List[bool]:
        """
        Convert multiple HTML files to Markdown format using concurrent processing.

        Args:
            root_path: The base directory path
            conversions: List of ConversionItem namedtuples

        Returns:
            List of boolean values indicating success/failure for each conversion
        """
        if not conversions:
            return []
        
        # Create semaphore to limit concurrent operations
        semaphore = asyncio.Semaphore(self.max_concurrent)
        
        # Create tasks for concurrent conversion
        tasks = [
            self._convert_with_semaphore(semaphore, root_path, conversion_item, i, len(conversions))
            for i, conversion_item in enumerate(conversions)
        ]
        
        # Execute all conversions concurrently
        results = await asyncio.gather(*tasks)
        
        if not self.quiet and len(conversions) > 1:
            successful = sum(results)
            print(f"[INFO] Batch conversion completed: {successful}/{len(conversions)} successful")
        
        return results

    def load_from_yaml(self, yaml_file_path: str) -> Tuple[str, List[ConversionItem], int]:
        """
        Load conversion configuration from a YAML file.

        Args:
            yaml_file_path: Path to the YAML configuration file

        Returns:
            Tuple of (root_path, conversions_list, max_concurrent)
        """
        return load_conversions_from_yaml(yaml_file_path)


async def html_to_md(root_path: str, input_filename: str, output_filename: str) -> bool:
    """
    Convert an HTML file to Markdown format using Claude Code SDK.

    This is a convenience function that maintains backward compatibility.

    Args:
        root_path: The base directory path
        input_filename: The input HTML filename
        output_filename: The output Markdown filename

    Returns:
        True if conversion was successful, False otherwise
    """
    converter = HTMLToMarkdownConverter()
    return await converter.convert(root_path, input_filename, output_filename)


async def convert_file(root_path: str, conversion_item: ConversionItem) -> bool:
    """
    Convert an HTML file to Markdown format using a ConversionItem.

    Args:
        root_path: The base directory path
        conversion_item: ConversionItem namedtuple containing input_filename and output_filename

    Returns:
        True if conversion was successful, False otherwise
    """
    converter = HTMLToMarkdownConverter()
    return await converter.convert_file(root_path, conversion_item)


async def convert_batch(root_path: str, conversions: List[ConversionItem]) -> List[bool]:
    """
    Convert multiple HTML files to Markdown format sequentially.

    Args:
        root_path: The base directory path
        conversions: List of ConversionItem namedtuples

    Returns:
        List of boolean values indicating success/failure for each conversion
    """
    converter = HTMLToMarkdownConverter()
    return await converter.convert_batch(root_path, conversions)




if __name__ == "__main__":
    import sys

    # Check for different usage modes
    if len(sys.argv) == 2:
        # Mode 1: YAML file mode - python3 converter.py <yaml_file>
        yaml_file = sys.argv[1]

        try:
            root_path, conversions, config = load_conversions_from_yaml(yaml_file)
            
            if not config.get('quiet', False):
                print(f"[INFO] Loaded {len(conversions)} conversions from {os.path.basename(yaml_file)}")
                if len(conversions) <= 3:  # Show details only for small batches
                    print(f"[INFO] Root directory: {root_path}")
                print(f"[INFO] Strategy: {config['conversion_strategy']}, Thresholds: {config['medium_file_threshold_kb']}KB/{config['large_file_threshold_kb']}KB")

            # Create intelligent converter with configuration
            converter = HTMLToMarkdownConverter(
                max_concurrent=config['max_concurrent'],
                quiet=config['quiet'],
                conversion_strategy=config['conversion_strategy'],
                large_file_threshold_kb=config['large_file_threshold_kb'],
                medium_file_threshold_kb=config['medium_file_threshold_kb'],
                chunk_size_kb=config['chunk_size_kb'],
                chunk_overlap_kb=config['chunk_overlap_kb']
            )
            results = asyncio.run(converter.convert_batch(root_path, conversions))

            # Check results and count successes/failures
            successful_conversions = sum(results)

            if successful_conversions == len(conversions):
                print(f"[SUCCESS] All {len(conversions)} conversions completed successfully!")
            elif successful_conversions > 0:
                print(f"[WARNING] Partial success: {len(conversions) - successful_conversions} conversions failed")
                sys.exit(1)
            else:
                print(f"[ERROR] All {len(conversions)} conversions failed!")
                sys.exit(1)

        except Exception as e:
            print(f"[ERROR] Failed to load YAML file: {e}")
            sys.exit(1)

    elif len(sys.argv) == 4:
        # Mode 2: Single file mode - python3 converter.py <root_path> <input_filename> <output_filename>
        root_path, input_filename, output_filename = sys.argv[1], sys.argv[2], sys.argv[3]

        try:
            success = asyncio.run(html_to_md(root_path, input_filename, output_filename))
            if success:
                print(f"[SUCCESS] Conversion completed: {input_filename} → {output_filename}")
            else:
                print(f"[ERROR] Conversion failed: {input_filename}")
                sys.exit(1)
        except Exception as e:
            print(f"[ERROR] {e}")
            sys.exit(1)

    else:
        print("""Usage:
  Mode 1 (YAML file):  python3 converter.py <yaml_file>
  Mode 2 (Single file): python3 converter.py <root_path> <input_filename> <output_filename>

Examples:
  python3 converter.py conversions_config.yaml
  python3 converter.py ./docs page.html page.md

YAML file format:
  root_path: './docs'
  max_concurrent: 3                      # Optional: concurrent limit (default: 5)
  conversions:
    - input_filename: 'page1.html'
      output_filename: 'page1.md'
    - input_filename: 'subdir/page2.html'
      output_filename: 'subdir/page2.md'""")
        sys.exit(1)
