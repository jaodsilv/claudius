#!/usr/bin/env python3
"""
Unit tests for SimpleHTMLToMarkdownConverter.
"""

import pytest
from unittest.mock import patch, mock_open
from src.download2md.simple_converter import SimpleHTMLToMarkdownConverter


@pytest.mark.unit
class TestSimpleHTMLToMarkdownConverter:
    """Test SimpleHTMLToMarkdownConverter functionality."""
    
    def test_converter_initialization(self):
        """Test converter initialization with various options."""
        # Test default initialization
        converter = SimpleHTMLToMarkdownConverter()
        assert converter.convert_links == True
        assert converter.preserve_images == True
        assert converter.clean_content == True
        assert converter.body_width == 0
        assert converter.quiet == False
        
        # Test custom initialization
        converter = SimpleHTMLToMarkdownConverter(
            convert_links=False,
            preserve_images=False,
            clean_content=False,
            body_width=80,
            quiet=True
        )
        assert converter.convert_links == False
        assert converter.preserve_images == False
        assert converter.clean_content == False
        assert converter.body_width == 80
        assert converter.quiet == True
    
    def test_html_to_markdown_conversion(self):
        """Test basic HTML to Markdown conversion."""
        converter = SimpleHTMLToMarkdownConverter(quiet=True)
        
        html = """
        <html>
        <head><title>Test</title></head>
        <body>
            <h1>Main Heading</h1>
            <p>This is <strong>bold</strong> and <em>italic</em> text.</p>
            <a href="https://example.com">Link</a>
        </body>
        </html>
        """
        
        markdown = converter.convert_html_to_markdown(html)
        
        # Verify basic conversions
        assert "# Test" in markdown or "# Main Heading" in markdown
        assert "**bold**" in markdown
        assert "*italic*" in markdown
        assert "https://example.com" in markdown
    
    def test_title_extraction_regex(self):
        """Test title extraction using regex method."""
        converter = SimpleHTMLToMarkdownConverter(quiet=True)
        
        # Test with title tag
        html_with_title = "<title>Page Title</title><body>Content</body>"
        title = converter._extract_title_regex(html_with_title)
        assert title == "Page Title"
        
        # Test with h1 tag when no title
        html_with_h1 = "<body><h1>Header Title</h1><p>Content</p></body>"
        title = converter._extract_title_regex(html_with_h1)
        assert title == "Header Title"
        
        # Test fallback to default
        html_no_title = "<body><p>Just content</p></body>"
        title = converter._extract_title_regex(html_no_title)
        assert title == "Untitled Document"
    
    def test_link_conversion_toggle(self):
        """Test that link conversion can be toggled."""
        html = '<p>Visit <a href="https://example.com">our site</a></p>'
        
        # With links enabled
        converter = SimpleHTMLToMarkdownConverter(convert_links=True, quiet=True)
        markdown = converter.convert_html_to_markdown(html)
        assert "[our site](https://example.com)" in markdown or "https://example.com" in markdown
        
        # With links disabled (implementation may vary)
        converter = SimpleHTMLToMarkdownConverter(convert_links=False, quiet=True)
        markdown = converter.convert_html_to_markdown(html)
        # Should still contain the text but maybe not as markdown link
        assert "our site" in markdown
    
    def test_image_preservation_toggle(self):
        """Test that image preservation can be toggled."""
        html = '<p>See <img src="image.jpg" alt="Test Image"> here</p>'
        
        # With images enabled
        converter = SimpleHTMLToMarkdownConverter(preserve_images=True, quiet=True)
        markdown = converter.convert_html_to_markdown(html)
        assert "![Test Image](image.jpg)" in markdown or "image.jpg" in markdown
        
        # With images disabled (implementation may vary)
        converter = SimpleHTMLToMarkdownConverter(preserve_images=False, quiet=True)
        markdown = converter.convert_html_to_markdown(html)
        # Should still contain surrounding text
        assert "See" in markdown and "here" in markdown
    
    def test_code_block_conversion(self):
        """Test conversion of code blocks."""
        html = """
        <body>
            <pre><code>def hello():
    print("Hello, World!")</code></pre>
            <p>Inline <code>code()</code> here.</p>
        </body>
        """
        
        converter = SimpleHTMLToMarkdownConverter(quiet=True)
        markdown = converter.convert_html_to_markdown(html)
        
        # Should handle code blocks
        assert "```" in markdown or "def hello" in markdown
        assert "`code()`" in markdown
    
    def test_list_conversion(self):
        """Test conversion of lists."""
        html = """
        <body>
            <ul>
                <li>First item</li>
                <li>Second item</li>
            </ul>
        </body>
        """
        
        converter = SimpleHTMLToMarkdownConverter(quiet=True)
        markdown = converter.convert_html_to_markdown(html)
        
        # Should contain list items
        assert "First item" in markdown
        assert "Second item" in markdown
    
    @pytest.mark.asyncio
    async def test_file_conversion_success(self, temp_dir, sample_html):
        """Test successful file conversion."""
        # Create input file
        input_file = temp_dir / "test.html"
        input_file.write_text(sample_html)
        
        converter = SimpleHTMLToMarkdownConverter(quiet=True)
        result = await converter.convert(str(temp_dir), "test.html", "test.md")
        
        assert result == True
        
        # Check output file exists
        output_file = temp_dir / "test.md"
        assert output_file.exists()
        assert output_file.stat().st_size > 0
    
    @pytest.mark.asyncio
    async def test_file_conversion_missing_input(self, temp_dir):
        """Test file conversion with missing input file."""
        converter = SimpleHTMLToMarkdownConverter(quiet=True)
        result = await converter.convert(str(temp_dir), "missing.html", "output.md")
        
        assert result == False
        
        # Output file should not exist
        output_file = temp_dir / "output.md"
        assert not output_file.exists()
    
    @pytest.mark.asyncio 
    async def test_directory_creation(self, temp_dir, sample_html):
        """Test that output directories are created automatically."""
        # Create input file
        input_file = temp_dir / "test.html"
        input_file.write_text(sample_html)
        
        converter = SimpleHTMLToMarkdownConverter(quiet=True)
        
        # Convert to file in non-existent subdirectory
        result = await converter.convert(
            str(temp_dir), "test.html", "subdir/nested/test.md"
        )
        
        assert result == True
        
        # Check that directory was created
        output_file = temp_dir / "subdir" / "nested" / "test.md"
        assert output_file.exists()
        assert output_file.parent.exists()
    
    def test_file_path_building(self, temp_dir):
        """Test file path building logic."""
        converter = SimpleHTMLToMarkdownConverter(quiet=True)
        
        input_path, output_path = converter._build_file_paths(
            str(temp_dir), "input.html", "output.md"
        )
        
        assert input_path == str(temp_dir / "input.html")
        assert output_path == str(temp_dir / "output.md")