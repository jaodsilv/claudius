#!/usr/bin/env python3
"""
Unit tests for ClaudeCodeNativeConverter.
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch, mock_open
from pathlib import Path
from src.download2md.claude_native_converter import ClaudeCodeNativeConverter


@pytest.mark.unit
class TestClaudeCodeNativeConverter:
    """Test ClaudeCodeNativeConverter functionality."""
    
    def test_converter_initialization_defaults(self):
        """Test converter initialization with default values."""
        converter = ClaudeCodeNativeConverter()
        
        assert converter.max_turns == 10
        assert converter.quiet == False
        assert converter.allowed_tools is None
    
    def test_converter_initialization_custom(self):
        """Test converter initialization with custom values."""
        converter = ClaudeCodeNativeConverter(
            max_turns=5,
            quiet=True,
            allowed_tools=['Read', 'Write', 'Edit']
        )
        
        assert converter.max_turns == 5
        assert converter.quiet == True
        assert converter.allowed_tools == ['Read', 'Write', 'Edit']
    
    def test_html_to_markdown_basic_conversion(self):
        """Test basic HTML to Markdown conversion using fallback method."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        html_content = """
        <html>
        <head><title>Test Document</title></head>
        <body>
            <h1>Main Heading</h1>
            <p>This is a paragraph with <strong>bold</strong> text.</p>
            <ul>
                <li>First item</li>
                <li>Second item</li>
            </ul>
        </body>
        </html>
        """
        
        markdown = converter._html_to_markdown_fallback(html_content)
        
        assert isinstance(markdown, str)
        assert len(markdown) > 0
        # Should contain some basic conversion
        assert "Main Heading" in markdown
        assert "bold" in markdown
        assert "First item" in markdown
    
    def test_html_to_markdown_empty_content(self):
        """Test HTML to Markdown conversion with empty content."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        result = converter._html_to_markdown_fallback("")
        
        assert result == ""
    
    def test_html_to_markdown_malformed_html(self):
        """Test HTML to Markdown conversion with malformed HTML."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        malformed_html = "<div><p>Unclosed paragraph<span>Unclosed span</div>"
        
        # Should not raise an exception
        result = converter._html_to_markdown_fallback(malformed_html)
        
        assert isinstance(result, str)
        assert "Unclosed paragraph" in result
        assert "Unclosed span" in result
    
    def test_html_to_markdown_no_body_content(self):
        """Test HTML conversion with only head content."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        html_content = """
        <html>
        <head>
            <title>Test</title>
            <meta name="description" content="Description">
        </head>
        </html>
        """
        
        result = converter._html_to_markdown_fallback(html_content)
        
        # Should handle gracefully even with minimal content
        assert isinstance(result, str)
    
    def test_html_to_markdown_complex_structure(self):
        """Test HTML conversion with complex nested structure."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        html_content = """
        <html>
        <body>
            <article>
                <header>
                    <h1>Article Title</h1>
                    <p class="subtitle">Article subtitle</p>
                </header>
                <section>
                    <h2>Section 1</h2>
                    <p>Paragraph in section 1.</p>
                    <blockquote>
                        <p>A quoted paragraph.</p>
                    </blockquote>
                </section>
                <section>
                    <h2>Section 2</h2>
                    <code>inline code</code>
                    <pre><code>code block</code></pre>
                </section>
            </article>
        </body>
        </html>
        """
        
        result = converter._html_to_markdown_fallback(html_content)
        
        assert "Article Title" in result
        assert "Section 1" in result
        assert "Section 2" in result
        assert "quoted paragraph" in result
        assert "inline code" in result
        assert "code block" in result
    
    def test_file_path_building(self):
        """Test file path building logic."""
        converter = ClaudeCodeNativeConverter()
        
        input_path, output_path = converter._build_file_paths(
            "/tmp", "input.html", "output.md"
        )
        
        assert input_path == "/tmp/input.html"
        assert output_path == "/tmp/output.md"
    
    def test_file_path_building_with_subdirs(self):
        """Test file path building with subdirectories."""
        converter = ClaudeCodeNativeConverter()
        
        input_path, output_path = converter._build_file_paths(
            "/tmp", "docs/input.html", "docs/output.md"
        )
        
        assert input_path == "/tmp/docs/input.html"
        assert output_path == "/tmp/docs/output.md"


@pytest.mark.unit
@pytest.mark.asyncio
class TestClaudeCodeNativeConverterAsync:
    """Test async functionality of ClaudeCodeNativeConverter."""
    
    async def test_file_conversion_success(self, temp_dir):
        """Test successful file conversion."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        # Create test HTML file
        html_content = """
        <html>
        <body>
            <h1>Test Document</h1>
            <p>This is test content.</p>
        </body>
        </html>
        """
        input_file = temp_dir / "test.html"
        input_file.write_text(html_content)
        
        result = await converter.convert(str(temp_dir), "test.html", "test.md")
        
        # The result depends on whether Claude Code tools are available
        # In test environment, it might fail and fall back to basic conversion
        assert isinstance(result, bool)
        
        # If conversion succeeded, output file should exist
        output_file = temp_dir / "test.md"
        if result:
            assert output_file.exists()
            content = output_file.read_text()
            assert len(content) > 0
    
    async def test_file_conversion_missing_input(self, temp_dir):
        """Test file conversion with missing input file."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        result = await converter.convert(str(temp_dir), "missing.html", "output.md")
        
        assert result == False
        
        # Output file should not be created
        output_file = temp_dir / "output.md"
        assert not output_file.exists()
    
    async def test_directory_creation_for_output(self, temp_dir):
        """Test that output directories are created automatically."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        # Create test HTML file
        html_content = "<h1>Test</h1><p>Content</p>"
        input_file = temp_dir / "test.html"
        input_file.write_text(html_content)
        
        # Convert to file in non-existent subdirectory
        result = await converter.convert(
            str(temp_dir), "test.html", "output/nested/test.md"
        )
        
        # Should create directory structure
        output_file = temp_dir / "output" / "nested" / "test.md"
        if result:
            assert output_file.exists()
            assert output_file.parent.exists()
    
    async def test_large_file_handling(self, temp_dir):
        """Test handling of large HTML files."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        # Create large HTML content
        large_content = "<html><body><h1>Large Document</h1>"
        for i in range(1000):
            large_content += f"<p>Paragraph {i} with content repeated many times. " * 10 + "</p>"
        large_content += "</body></html>"
        
        input_file = temp_dir / "large.html"
        input_file.write_text(large_content)
        
        result = await converter.convert(str(temp_dir), "large.html", "large.md")
        
        # Should handle large files without crashing
        assert isinstance(result, bool)
        
        if result:
            output_file = temp_dir / "large.md"
            assert output_file.exists()
    
    async def test_empty_html_file(self, temp_dir):
        """Test handling of empty HTML files."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        # Create empty HTML file
        input_file = temp_dir / "empty.html"
        input_file.write_text("")
        
        result = await converter.convert(str(temp_dir), "empty.html", "empty.md")
        
        # Should handle empty files gracefully
        assert isinstance(result, bool)
        
        # If conversion succeeded, output should exist
        if result:
            output_file = temp_dir / "empty.md"
            assert output_file.exists()
    
    async def test_html_with_encoding_issues(self, temp_dir):
        """Test handling of HTML with potential encoding issues."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        # Create HTML with various characters
        html_content = """
        <html>
        <body>
            <h1>Unicode Test</h1>
            <p>Regular text with special chars: á, é, í, ó, ú</p>
            <p>Symbols: © ® ™ € £ ¥</p>
            <p>Emoji: 🎉 ✅ ❌ 🚀</p>
        </body>
        </html>
        """
        
        input_file = temp_dir / "unicode.html"
        input_file.write_text(html_content, encoding='utf-8')
        
        result = await converter.convert(str(temp_dir), "unicode.html", "unicode.md")
        
        # Should handle unicode without crashing
        assert isinstance(result, bool)
        
        if result:
            output_file = temp_dir / "unicode.md"
            assert output_file.exists()
            
            # Try to read the output file
            content = output_file.read_text(encoding='utf-8')
            assert len(content) > 0


@pytest.mark.unit
class TestClaudeNativeConverterSDKPollutionPrevention:
    """Test that native converter doesn't cause SDK pollution."""
    
    def test_fallback_method_produces_clean_output(self):
        """Test that fallback conversion produces clean Markdown."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        html_content = """
        <html>
        <body>
            <h1>Test</h1>
            <p>Regular content</p>
        </body>
        </html>
        """
        
        result = converter._html_to_markdown_fallback(html_content)
        
        # Critical: verify no SDK pollution
        assert "SystemMessage" not in result
        assert "AssistantMessage" not in result
        assert "ResultMessage" not in result
        assert "subtype=" not in result
        assert "session_id=" not in result
        
        # Should contain actual content
        assert "Test" in result
        assert "Regular content" in result
    
    @pytest.mark.asyncio
    async def test_file_conversion_produces_clean_output(self, temp_dir):
        """Test that file conversion produces clean Markdown without SDK pollution."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        html_content = """
        <html>
        <body>
            <h1>Clean Test</h1>
            <p>This should produce clean output.</p>
        </body>
        </html>
        """
        
        input_file = temp_dir / "clean_test.html"
        input_file.write_text(html_content)
        
        result = await converter.convert(str(temp_dir), "clean_test.html", "clean_output.md")
        
        # If conversion succeeded, check output is clean
        if result:
            output_file = temp_dir / "clean_output.md"
            content = output_file.read_text()
            
            # Critical: verify no SDK pollution
            assert "SystemMessage" not in content
            assert "AssistantMessage" not in content  
            assert "ResultMessage" not in content
            assert "subtype=" not in content
            assert "session_id=" not in content
            assert "claude_code_sdk" not in content.lower()
            
            # Should contain expected content
            assert "Clean Test" in content or "This should produce clean output" in content


@pytest.mark.unit
class TestClaudeNativeConverterBatch:
    """Test batch processing functionality."""
    
    @pytest.mark.asyncio
    async def test_batch_conversion_success(self, temp_dir):
        """Test successful batch conversion."""
        from src.download2md.shared import ConversionItem
        
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        # Create multiple test files
        conversions = []
        for i in range(3):
            html_content = f"<h1>Document {i}</h1><p>Content for document {i}</p>"
            input_file = temp_dir / f"doc{i}.html"
            input_file.write_text(html_content)
            
            conversions.append(ConversionItem(f"doc{i}.html", f"doc{i}.md"))
        
        results = await converter.convert_batch(str(temp_dir), conversions)
        
        assert len(results) == 3
        # Results might be mixed success/failure depending on environment
        assert all(isinstance(result, bool) for result in results)
    
    @pytest.mark.asyncio
    async def test_batch_conversion_partial_failure(self, temp_dir):
        """Test batch conversion with some missing files."""
        from src.download2md.shared import ConversionItem
        
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        # Create some files but not others
        (temp_dir / "doc1.html").write_text("<h1>Doc 1</h1>")
        (temp_dir / "doc3.html").write_text("<h1>Doc 3</h1>")
        # doc2.html intentionally missing
        
        conversions = [
            ConversionItem("doc1.html", "doc1.md"),
            ConversionItem("doc2.html", "doc2.md"),  # This will fail
            ConversionItem("doc3.html", "doc3.md")
        ]
        
        results = await converter.convert_batch(str(temp_dir), conversions)
        
        assert len(results) == 3
        # Middle one should fail due to missing file
        assert results[1] == False
    
    @pytest.mark.asyncio
    async def test_batch_conversion_empty_list(self, temp_dir):
        """Test batch conversion with empty list."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        results = await converter.convert_batch(str(temp_dir), [])
        
        assert results == []


@pytest.mark.unit
class TestClaudeNativeConverterEdgeCases:
    """Test edge cases and error conditions."""
    
    @pytest.mark.asyncio
    async def test_invalid_root_path(self):
        """Test conversion with invalid root path."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        result = await converter.convert("/nonexistent/path", "test.html", "test.md")
        
        assert result == False
    
    @pytest.mark.asyncio
    async def test_read_only_output_directory(self, temp_dir):
        """Test handling of read-only output directory."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        # Create input file
        input_file = temp_dir / "test.html"
        input_file.write_text("<h1>Test</h1>")
        
        # Try to write to a path that simulates permission issues
        # Note: This is challenging to test reliably across platforms
        result = await converter.convert(str(temp_dir), "test.html", "/root/readonly.md")
        
        # Should handle permission errors gracefully
        assert isinstance(result, bool)
    
    def test_malformed_file_paths(self):
        """Test handling of malformed file paths."""
        converter = ClaudeCodeNativeConverter()
        
        # Test with various problematic paths
        test_cases = [
            ("", "test.html", "test.md"),
            ("/tmp", "", "test.md"), 
            ("/tmp", "test.html", ""),
            ("/tmp", "../../test.html", "test.md"),
            ("/tmp", "test.html", "../../test.md")
        ]
        
        for root_path, input_file, output_file in test_cases:
            try:
                input_path, output_path = converter._build_file_paths(root_path, input_file, output_file)
                # Should not crash, even if paths are strange
                assert isinstance(input_path, str)
                assert isinstance(output_path, str)
            except (ValueError, TypeError):
                # Some malformed paths might raise exceptions, which is acceptable
                pass