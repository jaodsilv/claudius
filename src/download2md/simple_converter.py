#!/usr/bin/env python3
"""
Enhanced HTML to Markdown converter that handles large files efficiently.
Uses BeautifulSoup4 and html2text for high-quality conversion without token limits.
"""

import asyncio
import os
import re
from html import unescape
from typing import List, Optional
from .shared import ConversionItem, load_conversions_from_yaml

# Enhanced parsing libraries with fallbacks
try:
    from bs4 import BeautifulSoup, Comment
    HAS_BS4 = True
except ImportError:
    HAS_BS4 = False
    print("[WARNING] BeautifulSoup4 not installed. Using basic HTML parsing. Install with: pip install beautifulsoup4")

try:
    import html2text
    HAS_HTML2TEXT = True
except ImportError:
    HAS_HTML2TEXT = False
    print("[WARNING] html2text not installed. Using basic conversion. Install with: pip install html2text")

class SimpleHTMLToMarkdownConverter:
    """
    Enhanced HTML to Markdown converter that handles large files efficiently.
    Uses BeautifulSoup4 and html2text for high-quality conversion without token limits.
    """
    
    def __init__(self, 
                 convert_links: bool = True,
                 preserve_images: bool = True, 
                 clean_content: bool = True,
                 body_width: int = 0,
                 quiet: bool = False):
        """
        Initialize the enhanced converter.
        
        Args:
            convert_links: Whether to preserve hyperlinks
            preserve_images: Whether to include image references
            clean_content: Whether to remove navigation/ads/etc
            body_width: Text width for wrapping (0 = no wrap)
            quiet: Reduce output verbosity
        """
        self.convert_links = convert_links
        self.preserve_images = preserve_images
        self.clean_content = clean_content
        self.body_width = body_width
        self.quiet = quiet
        
        # Initialize html2text if available
        if HAS_HTML2TEXT:
            self.html2text_handler = html2text.HTML2Text()
            self.html2text_handler.ignore_links = not convert_links
            self.html2text_handler.ignore_images = not preserve_images
            self.html2text_handler.body_width = body_width
            self.html2text_handler.ignore_emphasis = False
    
    def _clean_html_content(self, soup: BeautifulSoup) -> BeautifulSoup:
        """
        Clean HTML content by removing unwanted elements.
        
        Args:
            soup: BeautifulSoup parsed HTML
            
        Returns:
            Cleaned BeautifulSoup object
        """
        if not self.clean_content:
            return soup
            
        # Remove common unwanted elements
        unwanted_tags = [
            'script', 'style', 'nav', 'header', 'footer', 
            'aside', 'advertisement', 'ads', 'sidebar'
        ]
        
        for tag_name in unwanted_tags:
            for element in soup.find_all(tag_name):
                element.decompose()
        
        # Remove elements with common unwanted classes/ids
        unwanted_selectors = [
            '[class*="nav"]', '[class*="menu"]', '[class*="sidebar"]',
            '[class*="advertisement"]', '[class*="ads"]', '[class*="footer"]',
            '[class*="header"]', '[id*="nav"]', '[id*="menu"]',
            '[id*="sidebar"]', '[id*="footer"]', '[id*="header"]'
        ]
        
        for selector in unwanted_selectors:
            for element in soup.select(selector):
                element.decompose()
        
        # Remove comments
        for comment in soup.find_all(string=lambda text: isinstance(text, Comment)):
            comment.extract()
            
        return soup
    
    def _extract_title_bs4(self, soup: BeautifulSoup) -> str:
        """
        Extract title using BeautifulSoup.
        
        Args:
            soup: BeautifulSoup parsed HTML
            
        Returns:
            Document title
        """
        # Try title tag first
        title_tag = soup.find('title')
        if title_tag and title_tag.get_text(strip=True):
            return title_tag.get_text(strip=True)
        
        # Try first h1 tag
        h1_tag = soup.find('h1')
        if h1_tag and h1_tag.get_text(strip=True):
            return h1_tag.get_text(strip=True)
        
        # Try og:title meta tag
        og_title = soup.find('meta', property='og:title')
        if og_title and og_title.get('content'):
            return og_title['content'].strip()
            
        return "Untitled Document"
    
    def _extract_title_regex(self, html_content: str) -> str:
        """
        Fallback title extraction using regex (original method).
        
        Args:
            html_content: Raw HTML content
            
        Returns:
            Document title
        """
        title_match = re.search(r'<title[^>]*>(.*?)</title>', html_content, re.IGNORECASE | re.DOTALL)
        if title_match:
            return unescape(title_match.group(1).strip())
        
        h1_match = re.search(r'<h1[^>]*>(.*?)</h1>', html_content, re.IGNORECASE | re.DOTALL)
        if h1_match:
            return unescape(re.sub(r'<[^>]+>', '', h1_match.group(1)).strip())
        
        return "Untitled Document"
    
    def _find_main_content(self, soup: BeautifulSoup) -> Optional[BeautifulSoup]:
        """
        Attempt to find the main content area of the page.
        
        Args:
            soup: BeautifulSoup parsed HTML
            
        Returns:
            BeautifulSoup object containing main content, or None
        """
        # Common selectors for main content
        main_selectors = [
            'main', 'article', '[role="main"]',
            '.content', '.main-content', '.post-content',
            '.article-content', '.entry-content', '#content',
            '#main', '#main-content'
        ]
        
        for selector in main_selectors:
            main_element = soup.select_one(selector)
            if main_element:
                return main_element
        
        # If no main content found, try to find the largest content block
        content_candidates = soup.find_all(['div', 'section'], recursive=True)
        if content_candidates:
            # Find the element with the most text content
            best_candidate = max(content_candidates, 
                               key=lambda el: len(el.get_text(strip=True)))
            if len(best_candidate.get_text(strip=True)) > 100:
                return best_candidate
        
        return None
    
    def convert_html_to_markdown_bs4(self, html_content: str) -> str:
        """
        Convert HTML to Markdown using BeautifulSoup4 and html2text.
        
        Args:
            html_content: Raw HTML content
            
        Returns:
            Markdown formatted text
        """
        try:
            soup = BeautifulSoup(html_content, 'html.parser')
            soup = self._clean_html_content(soup)
            
            # Extract title
            title = self._extract_title_bs4(soup)
            
            # Find main content area if cleaning is enabled
            if self.clean_content:
                main_content = self._find_main_content(soup)
                if main_content:
                    soup = main_content
            
            # Convert to markdown using html2text if available
            if HAS_HTML2TEXT:
                markdown_content = self.html2text_handler.handle(str(soup))
                
                # Add title if not already present in content
                if title and not markdown_content.startswith('# '):
                    markdown_content = f"# {title}\n\n{markdown_content}"
                    
                return markdown_content.strip()
            else:
                # Fallback to basic conversion
                return self._convert_html_to_markdown_basic(str(soup), title)
                
        except Exception as e:
            if not self.quiet:
                print(f"[WARNING] BeautifulSoup conversion failed: {e}. Falling back to regex.")
            return self.convert_html_to_markdown_regex(html_content)
    
    def _convert_html_to_markdown_basic(self, html_content: str, title: str = None) -> str:
        """
        Basic HTML to Markdown conversion without html2text.
        
        Args:
            html_content: HTML content string
            title: Document title
            
        Returns:
            Basic markdown conversion
        """
        # Simple tag replacements
        html_content = re.sub(r'<br\s*/?>', '\n', html_content, flags=re.IGNORECASE)
        html_content = re.sub(r'<hr\s*/?>', '\n---\n', html_content, flags=re.IGNORECASE)
        
        # Headers
        for i in range(1, 7):
            html_content = re.sub(f'<h{i}[^>]*>(.*?)</h{i}>', 
                                f'\n{"#" * i} \\1\n', 
                                html_content, flags=re.IGNORECASE | re.DOTALL)
        
        # Bold and italic
        html_content = re.sub(r'<(strong|b)[^>]*>(.*?)</\1>', r'**\2**', html_content, flags=re.IGNORECASE | re.DOTALL)
        html_content = re.sub(r'<(em|i)[^>]*>(.*?)</\1>', r'*\2*', html_content, flags=re.IGNORECASE | re.DOTALL)
        
        # Links
        if self.convert_links:
            html_content = re.sub(r'<a[^>]*href=["\']([^"\']+)["\'][^>]*>(.*?)</a>', 
                                r'[\2](\1)', html_content, flags=re.IGNORECASE | re.DOTALL)
        
        # Images
        if self.preserve_images:
            html_content = re.sub(r'<img[^>]*src=["\']([^"\']+)["\'][^>]*alt=["\']([^"\']*)["\'][^>]*/?>', 
                                r'![\2](\1)', html_content, flags=re.IGNORECASE)
            html_content = re.sub(r'<img[^>]*alt=["\']([^"\']*)["\'][^>]*src=["\']([^"\']+)["\'][^>]*/?>', 
                                r'![\1](\2)', html_content, flags=re.IGNORECASE)
            html_content = re.sub(r'<img[^>]*src=["\']([^"\']+)["\'][^>]*/?>', 
                                r'![](\1)', html_content, flags=re.IGNORECASE)
        
        # Code blocks
        html_content = re.sub(r'<pre[^>]*>(.*?)</pre>', r'```\n\1\n```', html_content, flags=re.IGNORECASE | re.DOTALL)
        html_content = re.sub(r'<code[^>]*>(.*?)</code>', r'`\1`', html_content, flags=re.IGNORECASE | re.DOTALL)
        
        # Paragraphs
        html_content = re.sub(r'<p[^>]*>(.*?)</p>', r'\n\1\n', html_content, flags=re.IGNORECASE | re.DOTALL)
        
        # Remove remaining HTML tags
        html_content = re.sub(r'<[^>]+>', '', html_content)
        
        # Clean up whitespace
        html_content = re.sub(r'\n\s*\n\s*\n', '\n\n', html_content)
        html_content = unescape(html_content)
        
        # Add title
        if title and not html_content.strip().startswith('# '):
            html_content = f"# {title}\n\n{html_content}"
            
        return html_content.strip()
    
    def convert_html_to_markdown_regex(self, html_content: str) -> str:
        """
        Fallback regex-based conversion (original method enhanced).
        
        Args:
            html_content: Raw HTML content
            
        Returns:
            Markdown formatted text
        """
        title = self._extract_title_regex(html_content)
        return self._convert_html_to_markdown_basic(html_content, title)
    
    def convert_html_to_markdown(self, html_content: str) -> str:
        """
        Convert HTML content to Markdown format using the best available method.
        
        Args:
            html_content: Raw HTML content
            
        Returns:
            Markdown formatted text
        """
        if HAS_BS4:
            return self.convert_html_to_markdown_bs4(html_content)
        else:
            return self.convert_html_to_markdown_regex(html_content)
    
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
        """Convert HTML file to Markdown."""
        try:
            input_path, output_path = self._build_file_paths(root_path, input_filename, output_filename)
            
            if not os.path.exists(input_path):
                print(f"[ERROR] Input file not found: {os.path.basename(input_path)}")
                return False
            
            # Check file size for progress indication
            file_size = os.path.getsize(input_path)
            if not self.quiet:
                size_mb = file_size / (1024 * 1024)
                print(f"[INFO] Processing {os.path.basename(input_path)} ({size_mb:.1f} MB)...")
            
            # Read HTML content
            with open(input_path, 'r', encoding='utf-8', errors='ignore') as f:
                html_content = f.read()
            
            # Convert to markdown
            markdown_content = self.convert_html_to_markdown(html_content)
            
            # Write markdown file
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(markdown_content)
            
            if not self.quiet:
                print(f"[SUCCESS] {os.path.basename(input_path)} → {os.path.basename(output_path)}")
            return True
            
        except Exception as e:
            print(f"[ERROR] Conversion failed: {e}")
            return False
    
    async def convert_file(self, root_path: str, conversion_item: ConversionItem) -> bool:
        """Convert using ConversionItem."""
        return await self.convert(root_path, conversion_item.input_filename, conversion_item.output_filename)
    
    async def convert_batch(self, root_path: str, conversions: List[ConversionItem]) -> List[bool]:
        """Convert multiple files with progress tracking."""
        results = []
        total = len(conversions)
        
        if not self.quiet and total > 1:
            print(f"[INFO] Starting batch conversion of {total} files...")
            
        for i, conversion_item in enumerate(conversions):
            if not self.quiet and total > 1:
                print(f"[{i + 1}/{total}] Converting {conversion_item.input_filename}...")
            
            success = await self.convert_file(root_path, conversion_item)
            results.append(success)
        
        if not self.quiet and total > 1:
            successful = sum(results)
            print(f"[INFO] Batch conversion completed: {successful}/{total} successful")
            
        return results

if __name__ == "__main__":
    import sys
    
    # Parse command line arguments for converter options
    quiet_mode = '--quiet' in sys.argv or '-q' in sys.argv
    clean_content = '--clean' in sys.argv or not ('--no-clean' in sys.argv)
    
    # Remove option flags from argv
    sys.argv = [arg for arg in sys.argv if not arg.startswith('--') and not arg.startswith('-q')]
    
    if len(sys.argv) == 2:
        # YAML file mode
        yaml_file = sys.argv[1]
        try:
            root_path, conversions, max_concurrent = load_conversions_from_yaml(yaml_file)
            if not quiet_mode:
                print(f"[INFO] Loaded {len(conversions)} conversions from {os.path.basename(yaml_file)}")
                if len(conversions) <= 3:
                    print(f"[INFO] Root directory: {root_path}")
                print(f"[INFO] Using enhanced simple converter (handles files of any size)")
            
            converter = SimpleHTMLToMarkdownConverter(
                clean_content=clean_content,
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
            print(f"[INFO] Using enhanced simple converter (handles files of any size)")
        
        converter = SimpleHTMLToMarkdownConverter(
            clean_content=clean_content,
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
  Mode 1 (YAML file):  python3 simple_converter.py <yaml_file> [options]
  Mode 2 (Single file): python3 simple_converter.py <root_path> <input_filename> <output_filename> [options]

Options:
  --quiet, -q          Reduce output verbosity
  --clean              Remove navigation/ads/etc (default)
  --no-clean           Keep all content

Examples:
  python3 simple_converter.py conversions_config.yaml --quiet
  python3 simple_converter.py ./docs page.html page.md --clean

Features:
  • Handles files of any size (no token limits)
  • Uses BeautifulSoup4 + html2text for high-quality conversion
  • Automatic content cleaning (removes nav, ads, etc)
  • Preserves links, images, tables, and code blocks
  • Fallback to regex parsing if libraries unavailable""")
        sys.exit(1)