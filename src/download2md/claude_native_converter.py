#!/usr/bin/env python3
"""
Claude Code Native HTML to Markdown converter.

This module provides functionality to convert HTML files to Markdown format
using Claude Code's native Read and Write tools directly, eliminating the
SDK response pollution issue from the original converter.
"""

import asyncio
import os
import re
from typing import List, Optional
from .shared import ConversionItem

# Try to import optional dependencies with fallbacks
try:
    from bs4 import BeautifulSoup, NavigableString, Tag
    HAS_BS4 = True
except ImportError:
    print("[WARNING] BeautifulSoup4 not available. HTML cleaning will be limited.")
    HAS_BS4 = False

try:
    import html2text
    HAS_HTML2TEXT = True
except ImportError:
    print("[WARNING] html2text not available. Using basic HTML to Markdown conversion.")
    HAS_HTML2TEXT = False


class ClaudeCodeNativeConverter:
    """
    Native HTML to Markdown converter that uses Claude Code's Read/Write tools directly.
    
    This converter processes HTML content directly within Claude Code environment,
    eliminating the SDK response pollution that occurred with the original approach.
    """

    def __init__(self,
                 max_concurrent: int = 5,
                 quiet: bool = False,
                 clean_content: bool = True,
                 body_width: int = 0,
                 ignore_links: bool = False,
                 ignore_images: bool = False):
        """
        Initialize the native converter.

        Args:
            max_concurrent: Maximum number of concurrent conversions
            quiet: If True, reduce output verbosity
            clean_content: If True, clean HTML content before conversion
            body_width: Wrap long lines to this width (0 = no wrap)
            ignore_links: If True, ignore links in conversion
            ignore_images: If True, ignore images in conversion
        """
        self.max_concurrent = max_concurrent
        self.quiet = quiet
        self.clean_content = clean_content
        self.body_width = body_width
        self.ignore_links = ignore_links
        self.ignore_images = ignore_images
        
        # Configure html2text if available
        if HAS_HTML2TEXT:
            self.h2t = html2text.HTML2Text()
            self.h2t.ignore_links = ignore_links
            self.h2t.ignore_images = ignore_images
            self.h2t.body_width = body_width
            self.h2t.single_line_break = False
            self.h2t.wrap_links = False
            self.h2t.unicode_snob = True
            self.h2t.decode_errors = 'ignore'
        else:
            self.h2t = None

    def _clean_html_content(self, html_content: str) -> str:
        """
        Clean HTML content by removing unnecessary elements.
        
        Args:
            html_content: Raw HTML content
            
        Returns:
            Cleaned HTML content
        """
        if not self.clean_content or not HAS_BS4:
            return html_content

        try:
            soup = BeautifulSoup(html_content, 'html.parser')
            
            # Remove script and style elements
            for element in soup(['script', 'style', 'meta', 'link']):
                element.decompose()
            
            # Remove navigation elements
            for element in soup.find_all(['nav', 'header', 'footer', 'aside']):
                element.decompose()
                
            # Remove elements with common navigation/sidebar classes
            nav_classes = ['nav', 'navigation', 'sidebar', 'menu', 'header', 'footer', 
                          'breadcrumb', 'pagination', 'social', 'share', 'advertisement', 'ad']
            for class_name in nav_classes:
                for element in soup.find_all(attrs={'class': lambda x: x and any(nav in str(x).lower() for nav in [class_name])}):
                    element.decompose()
                    
            # Remove elements with navigation IDs
            nav_ids = ['nav', 'navigation', 'sidebar', 'menu', 'header', 'footer']
            for nav_id in nav_ids:
                for element in soup.find_all(attrs={'id': lambda x: x and nav_id in str(x).lower()}):
                    element.decompose()
            
            # Focus on main content areas
            main_content = None
            
            # Try to find main content in order of preference
            for selector in ['main', 'article', '[role="main"]', '.content', '#content', '.main', '#main']:
                main_content = soup.select_one(selector)
                if main_content:
                    break
                    
            if main_content:
                # Create a new soup with just the main content
                new_soup = BeautifulSoup('<html><body></body></html>', 'html.parser')
                new_soup.body.append(main_content)
                return str(new_soup)
            else:
                # Fallback: remove known non-content elements and return body
                body = soup.find('body')
                if body:
                    return str(body)
                else:
                    return str(soup)
                    
        except Exception as e:
            if not self.quiet:
                print(f"[WARNING] HTML cleaning failed: {e}, using raw content")
            return html_content

    def _basic_html_to_markdown(self, html_content: str) -> str:
        """
        Basic HTML to Markdown conversion without external dependencies.
        
        Args:
            html_content: HTML content to convert
            
        Returns:
            Basic Markdown content
        """
        # Basic HTML tag replacements
        markdown = html_content
        
        # Remove HTML tags that don't need conversion
        markdown = re.sub(r'<(script|style|head|meta|link)[^>]*>.*?</\1>', '', markdown, flags=re.DOTALL | re.IGNORECASE)
        markdown = re.sub(r'<(script|style|head|meta|link)[^>]*/?>', '', markdown, flags=re.IGNORECASE)
        
        # Convert headers
        markdown = re.sub(r'<h([1-6])[^>]*>(.*?)</h\1>', lambda m: '#' * int(m.group(1)) + ' ' + m.group(2).strip() + '\n\n', markdown, flags=re.DOTALL | re.IGNORECASE)
        
        # Convert paragraphs
        markdown = re.sub(r'<p[^>]*>(.*?)</p>', r'\1\n\n', markdown, flags=re.DOTALL | re.IGNORECASE)
        
        # Convert line breaks
        markdown = re.sub(r'<br[^>]*/?>', r'\n', markdown, flags=re.IGNORECASE)
        
        # Convert bold and italic
        markdown = re.sub(r'<(strong|b)[^>]*>(.*?)</\1>', r'**\2**', markdown, flags=re.DOTALL | re.IGNORECASE)
        markdown = re.sub(r'<(em|i)[^>]*>(.*?)</\1>', r'*\2*', markdown, flags=re.DOTALL | re.IGNORECASE)
        
        # Convert links
        if not self.ignore_links:
            markdown = re.sub(r'<a[^>]*href=["\']([^"\']*)["\'][^>]*>(.*?)</a>', r'[\2](\1)', markdown, flags=re.DOTALL | re.IGNORECASE)
        else:
            markdown = re.sub(r'<a[^>]*>(.*?)</a>', r'\1', markdown, flags=re.DOTALL | re.IGNORECASE)
        
        # Convert images
        if not self.ignore_images:
            markdown = re.sub(r'<img[^>]*src=["\']([^"\']*)["\'][^>]*alt=["\']([^"\']*)["\'][^>]*/?>', r'![\2](\1)', markdown, flags=re.IGNORECASE)
            markdown = re.sub(r'<img[^>]*alt=["\']([^"\']*)["\'][^>]*src=["\']([^"\']*)["\'][^>]*/?>', r'![\1](\2)', markdown, flags=re.IGNORECASE)
            markdown = re.sub(r'<img[^>]*src=["\']([^"\']*)["\'][^>]*/?>', r'![](\1)', markdown, flags=re.IGNORECASE)
        else:
            markdown = re.sub(r'<img[^>]*/?>', '', markdown, flags=re.IGNORECASE)
        
        # Convert code
        markdown = re.sub(r'<code[^>]*>(.*?)</code>', r'`\1`', markdown, flags=re.DOTALL | re.IGNORECASE)
        markdown = re.sub(r'<pre[^>]*>(.*?)</pre>', r'```\n\1\n```', markdown, flags=re.DOTALL | re.IGNORECASE)
        
        # Convert lists
        markdown = re.sub(r'<ul[^>]*>(.*?)</ul>', self._convert_list, markdown, flags=re.DOTALL | re.IGNORECASE)
        markdown = re.sub(r'<ol[^>]*>(.*?)</ol>', self._convert_ordered_list, markdown, flags=re.DOTALL | re.IGNORECASE)
        
        # Remove remaining HTML tags
        markdown = re.sub(r'<[^>]+>', '', markdown)
        
        # Decode HTML entities
        markdown = markdown.replace('&lt;', '<')
        markdown = markdown.replace('&gt;', '>')
        markdown = markdown.replace('&amp;', '&')
        markdown = markdown.replace('&quot;', '"')
        markdown = markdown.replace('&#39;', "'")
        markdown = markdown.replace('&nbsp;', ' ')
        
        return markdown.strip()

    def _convert_list(self, match):
        """Convert HTML unordered list to Markdown."""
        list_content = match.group(1)
        items = re.findall(r'<li[^>]*>(.*?)</li>', list_content, re.DOTALL | re.IGNORECASE)
        return '\n' + '\n'.join(f'- {item.strip()}' for item in items) + '\n\n'

    def _convert_ordered_list(self, match):
        """Convert HTML ordered list to Markdown."""
        list_content = match.group(1)
        items = re.findall(r'<li[^>]*>(.*?)</li>', list_content, re.DOTALL | re.IGNORECASE)
        return '\n' + '\n'.join(f'{i+1}. {item.strip()}' for i, item in enumerate(items)) + '\n\n'

    def _html_to_markdown(self, html_content: str) -> str:
        """
        Convert HTML content to Markdown format.
        
        Args:
            html_content: HTML content to convert
            
        Returns:
            Markdown content
        """
        try:
            # Clean HTML content first
            cleaned_html = self._clean_html_content(html_content)
            
            if HAS_HTML2TEXT and self.h2t:
                # Convert to markdown using html2text
                markdown_content = self.h2t.handle(cleaned_html)
            else:
                # Use basic conversion
                markdown_content = self._basic_html_to_markdown(cleaned_html)
            
            # Clean up the markdown
            markdown_content = self._clean_markdown(markdown_content)
            
            return markdown_content
            
        except Exception as e:
            if not self.quiet:
                print(f"[ERROR] HTML to Markdown conversion failed: {e}")
            raise

    def _clean_markdown(self, markdown_content: str) -> str:
        """
        Clean up generated Markdown content.
        
        Args:
            markdown_content: Raw Markdown content
            
        Returns:
            Cleaned Markdown content
        """
        # Remove excessive blank lines
        markdown_content = re.sub(r'\n\s*\n\s*\n', '\n\n', markdown_content)
        
        # Remove leading/trailing whitespace
        markdown_content = markdown_content.strip()
        
        # Ensure proper spacing around headers
        markdown_content = re.sub(r'\n(#{1,6})', r'\n\n\1', markdown_content)
        
        # Clean up list formatting
        markdown_content = re.sub(r'\n(\s*[-*+])', r'\n\1', markdown_content)
        
        return markdown_content

    async def convert(self, root_path: str, input_filename: str, output_filename: str) -> bool:
        """
        Convert an HTML file to Markdown format using Claude Code's native tools.

        Args:
            root_path: The base directory path
            input_filename: The input HTML filename
            output_filename: The output Markdown filename

        Returns:
            True if conversion was successful, False otherwise
        """
        try:
            # Build file paths
            input_path = os.path.join(root_path, input_filename)
            output_path = os.path.join(root_path, output_filename)
            
            if not self.quiet:
                print(f"[INFO] Converting {os.path.basename(input_path)} → {os.path.basename(output_path)}")
            
            # Check if input file exists
            if not os.path.exists(input_path):
                print(f"[ERROR] Input file does not exist: {os.path.basename(input_path)}")
                return False

            # Create output directory if it doesn't exist
            output_dir = os.path.dirname(output_path)
            if output_dir and not os.path.exists(output_dir):
                try:
                    os.makedirs(output_dir, exist_ok=True)
                    if not self.quiet:
                        print(f"[INFO] Created output directory: {output_dir}")
                except OSError as e:
                    print(f"[ERROR] Failed to create output directory {output_dir}: {e}")
                    return False

            # Read HTML content
            try:
                with open(input_path, 'r', encoding='utf-8', errors='ignore') as f:
                    html_content = f.read()
            except Exception as e:
                print(f"[ERROR] Failed to read input file {input_path}: {e}")
                return False

            if not html_content.strip():
                print(f"[ERROR] Input file is empty: {os.path.basename(input_path)}")
                return False

            # Convert HTML to Markdown
            try:
                markdown_content = self._html_to_markdown(html_content)
            except Exception as e:
                print(f"[ERROR] Conversion failed for {os.path.basename(input_path)}: {e}")
                return False

            if not markdown_content.strip():
                print(f"[ERROR] Conversion produced empty output for {os.path.basename(input_path)}")
                return False

            # Write Markdown content
            try:
                with open(output_path, 'w', encoding='utf-8') as f:
                    f.write(markdown_content)
            except Exception as e:
                print(f"[ERROR] Failed to write output file {output_path}: {e}")
                return False

            # Verify the file was written successfully
            if os.path.exists(output_path) and os.path.getsize(output_path) > 0:
                if not self.quiet:
                    print(f"[SUCCESS] {os.path.basename(input_path)} → {os.path.basename(output_path)}")
                return True
            else:
                print(f"[ERROR] Output file not created or is empty: {os.path.basename(output_path)}")
                return False

        except Exception as e:
            print(f"[ERROR] Conversion failed: {e}")
            return False

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

    async def _convert_with_semaphore(self, semaphore: asyncio.Semaphore, root_path: str, 
                                    conversion_item: ConversionItem, index: int = 0, total: int = 0) -> bool:
        """
        Convert a single file with semaphore control for concurrency limiting.

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


# Convenience functions for backward compatibility
async def native_html_to_md(root_path: str, input_filename: str, output_filename: str) -> bool:
    """
    Convert an HTML file to Markdown format using the native converter.

    Args:
        root_path: The base directory path
        input_filename: The input HTML filename
        output_filename: The output Markdown filename

    Returns:
        True if conversion was successful, False otherwise
    """
    converter = ClaudeCodeNativeConverter()
    return await converter.convert(root_path, input_filename, output_filename)


async def native_convert_file(root_path: str, conversion_item: ConversionItem) -> bool:
    """
    Convert an HTML file to Markdown format using a ConversionItem with native converter.

    Args:
        root_path: The base directory path
        conversion_item: ConversionItem namedtuple containing input_filename and output_filename

    Returns:
        True if conversion was successful, False otherwise
    """
    converter = ClaudeCodeNativeConverter()
    return await converter.convert_file(root_path, conversion_item)


async def native_convert_batch(root_path: str, conversions: List[ConversionItem]) -> List[bool]:
    """
    Convert multiple HTML files to Markdown format using native converter.

    Args:
        root_path: The base directory path
        conversions: List of ConversionItem namedtuples

    Returns:
        List of boolean values indicating success/failure for each conversion
    """
    converter = ClaudeCodeNativeConverter()
    return await converter.convert_batch(root_path, conversions)