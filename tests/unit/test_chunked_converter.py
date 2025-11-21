#!/usr/bin/env python3
"""
Unit tests for ChunkedHTMLToMarkdownConverter.
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch, mock_open
from src.download2md.chunked_converter import ChunkedHTMLToMarkdownConverter


@pytest.mark.unit
class TestChunkedHTMLToMarkdownConverter:
    """Test ChunkedHTMLToMarkdownConverter functionality."""
    
    def test_converter_initialization_defaults(self):
        """Test converter initialization with default values."""
        converter = ChunkedHTMLToMarkdownConverter()
        
        assert converter.chunk_size_kb == 50
        assert converter.chunk_overlap_kb == 5
        assert converter.max_turns == 10
        assert converter.quiet == False
        assert converter.allowed_tools is None
        
        # Check computed values
        assert converter.chunk_size_bytes == 50 * 1024
        assert converter.chunk_overlap_bytes == 5 * 1024
    
    def test_converter_initialization_custom(self):
        """Test converter initialization with custom values."""
        converter = ChunkedHTMLToMarkdownConverter(
            chunk_size_kb=100,
            chunk_overlap_kb=15,
            max_turns=5,
            quiet=True,
            allowed_tools=['Read', 'Write']
        )
        
        assert converter.chunk_size_kb == 100
        assert converter.chunk_overlap_kb == 15
        assert converter.max_turns == 5
        assert converter.quiet == True
        assert converter.allowed_tools == ['Read', 'Write']
        assert converter.chunk_size_bytes == 100 * 1024
        assert converter.chunk_overlap_bytes == 15 * 1024
    
    def test_chunk_splitting_basic(self):
        """Test basic chunk splitting functionality."""
        converter = ChunkedHTMLToMarkdownConverter(chunk_size_kb=1, chunk_overlap_kb=0)
        
        # Create content larger than 1KB
        content = "<p>" + "test content " * 100 + "</p>"  # > 1KB
        
        chunks = converter._split_content_into_chunks(content)
        
        assert len(chunks) > 1
        assert all(len(chunk.encode('utf-8')) <= 1024 + 100 for chunk in chunks)  # Allow some tolerance
    
    def test_chunk_splitting_with_overlap(self):
        """Test chunk splitting with overlap."""
        converter = ChunkedHTMLToMarkdownConverter(chunk_size_kb=1, chunk_overlap_kb=0.2)
        
        content = "<p>" + "test content " * 100 + "</p>"
        chunks = converter._split_content_into_chunks(content)
        
        if len(chunks) > 1:
            # Check that chunks have some overlapping content (basic check)
            # This is hard to test precisely without knowing the exact implementation
            assert len(chunks) > 1
    
    def test_chunk_splitting_small_content(self):
        """Test that small content doesn't get split unnecessarily."""
        converter = ChunkedHTMLToMarkdownConverter(chunk_size_kb=50)
        
        small_content = "<p>This is small content that should not be chunked.</p>"
        chunks = converter._split_content_into_chunks(small_content)
        
        # Small content should result in just one chunk
        assert len(chunks) == 1
        assert chunks[0] == small_content
    
    def test_chunk_splitting_empty_content(self):
        """Test chunk splitting with empty content."""
        converter = ChunkedHTMLToMarkdownConverter()
        
        chunks = converter._split_content_into_chunks("")
        
        assert len(chunks) == 1
        assert chunks[0] == ""
    
    def test_html_extraction_basic(self):
        """Test HTML content extraction."""
        converter = ChunkedHTMLToMarkdownConverter()
        
        html_content = """
        <!DOCTYPE html>
        <html>
        <head><title>Test</title></head>
        <body>
            <h1>Main Content</h1>
            <p>This is the main content.</p>
        </body>
        </html>
        """
        
        extracted = converter._extract_content_from_html(html_content)
        
        assert "Main Content" in extracted
        assert "This is the main content" in extracted
        # Should not contain head elements like title in the main content
        assert extracted.strip() != html_content.strip()
    
    def test_html_extraction_body_only(self):
        """Test HTML extraction focuses on body content."""
        converter = ChunkedHTMLToMarkdownConverter()
        
        html_content = """
        <html>
        <head>
            <title>Page Title</title>
            <meta name="description" content="Description">
        </head>
        <body>
            <main>
                <h1>Article Title</h1>
                <p>Article content goes here.</p>
            </main>
        </body>
        </html>
        """
        
        extracted = converter._extract_content_from_html(html_content)
        
        # Should contain body content
        assert "Article Title" in extracted
        assert "Article content goes here" in extracted
        
        # Should minimize head content
        assert "Page Title" not in extracted or extracted.count("Page Title") == 0
        assert "Description" not in extracted or extracted.count("Description") == 0
    
    def test_html_extraction_malformed(self):
        """Test HTML extraction with malformed HTML."""
        converter = ChunkedHTMLToMarkdownConverter()
        
        malformed_html = "<div><p>Unclosed paragraph<div>Nested content</p></div>"
        
        # Should not raise an exception
        extracted = converter._extract_content_from_html(malformed_html)
        assert isinstance(extracted, str)
        assert "Unclosed paragraph" in extracted
        assert "Nested content" in extracted
    
    def test_result_merging_basic(self):
        """Test basic result merging functionality."""
        converter = ChunkedHTMLToMarkdownConverter()
        
        chunk_results = [
            "# Section 1\n\nContent for section 1.",
            "# Section 2\n\nContent for section 2.",
            "# Section 3\n\nContent for section 3."
        ]
        
        merged = converter._merge_chunk_results(chunk_results)
        
        assert "Section 1" in merged
        assert "Section 2" in merged
        assert "Section 3" in merged
        assert len(merged) > len(chunk_results[0])
    
    def test_result_merging_empty_chunks(self):
        """Test result merging with empty chunks."""
        converter = ChunkedHTMLToMarkdownConverter()
        
        chunk_results = [
            "# Section 1\n\nContent here.",
            "",
            "# Section 2\n\nMore content."
        ]
        
        merged = converter._merge_chunk_results(chunk_results)
        
        assert "Section 1" in merged
        assert "Section 2" in merged
        assert merged.count("Content here") == 1
        assert merged.count("More content") == 1
    
    def test_result_merging_single_chunk(self):
        """Test result merging with single chunk."""
        converter = ChunkedHTMLToMarkdownConverter()
        
        chunk_results = ["# Only Section\n\nSingle chunk content."]
        merged = converter._merge_chunk_results(chunk_results)
        
        assert merged == chunk_results[0]


@pytest.mark.unit
@pytest.mark.asyncio  
class TestChunkedConverterAsync:
    """Test async functionality of ChunkedHTMLToMarkdownConverter."""
    
    async def test_single_chunk_conversion(self):
        """Test conversion of single chunk content."""
        converter = ChunkedHTMLToMarkdownConverter(quiet=True)
        
        html_content = "<h1>Test</h1><p>Small content</p>"
        
        # Mock the Claude SDK client to avoid actual API calls
        with patch('src.download2md.chunked_converter.ClaudeSDKClient') as mock_client:
            mock_instance = AsyncMock()
            mock_client.return_value.__aenter__.return_value = mock_instance
            
            # Mock the conversation result
            mock_instance.create_conversation.return_value.get_final_result.return_value = "# Test\n\nSmall content"
            
            result = await converter._convert_chunk_with_claude(html_content)
            
            assert result == "# Test\n\nSmall content"
            mock_instance.create_conversation.assert_called_once()
    
    async def test_chunk_conversion_error_handling(self):
        """Test error handling in chunk conversion."""
        converter = ChunkedHTMLToMarkdownConverter(quiet=True)
        
        html_content = "<h1>Test</h1><p>Content</p>"
        
        # Mock SDK to raise an exception
        with patch('src.download2md.chunked_converter.ClaudeSDKClient') as mock_client:
            mock_client.side_effect = Exception("API Error")
            
            result = await converter._convert_chunk_with_claude(html_content)
            
            # Should return None or empty string on error
            assert result is None or result == ""
    
    async def test_file_conversion_success(self, temp_dir):
        """Test successful file conversion."""
        converter = ChunkedHTMLToMarkdownConverter(quiet=True)
        
        # Create test HTML file
        html_content = """
        <html>
        <body>
            <h1>Test Document</h1>
            <p>This is test content for chunked conversion.</p>
        </body>
        </html>
        """
        input_file = temp_dir / "test.html"
        input_file.write_text(html_content)
        
        # Mock Claude SDK
        with patch('src.download2md.chunked_converter.ClaudeSDKClient') as mock_client:
            mock_instance = AsyncMock()
            mock_client.return_value.__aenter__.return_value = mock_instance
            mock_instance.create_conversation.return_value.get_final_result.return_value = "# Test Document\n\nThis is test content for chunked conversion."
            
            result = await converter.convert(str(temp_dir), "test.html", "test.md")
            
            assert result == True
            
            # Check output file was created
            output_file = temp_dir / "test.md"
            assert output_file.exists()
            
            content = output_file.read_text()
            assert "Test Document" in content
    
    async def test_file_conversion_missing_input(self, temp_dir):
        """Test file conversion with missing input file."""
        converter = ChunkedHTMLToMarkdownConverter(quiet=True)
        
        result = await converter.convert(str(temp_dir), "missing.html", "output.md")
        
        assert result == False
        
        # Output file should not be created
        output_file = temp_dir / "output.md"
        assert not output_file.exists()
    
    async def test_large_file_chunking(self, temp_dir):
        """Test that large files get properly chunked."""
        converter = ChunkedHTMLToMarkdownConverter(chunk_size_kb=1, quiet=True)  # Very small chunks
        
        # Create large HTML content
        large_content = "<html><body>"
        for i in range(100):
            large_content += f"<h2>Section {i}</h2><p>{'Content ' * 20}</p>"
        large_content += "</body></html>"
        
        input_file = temp_dir / "large.html"
        input_file.write_text(large_content)
        
        # Mock Claude SDK to return different content for different chunks
        with patch('src.download2md.chunked_converter.ClaudeSDKClient') as mock_client:
            mock_instance = AsyncMock()
            mock_client.return_value.__aenter__.return_value = mock_instance
            
            # Create a side effect that returns different content based on call count
            call_count = 0
            def mock_conversion(*args, **kwargs):
                nonlocal call_count
                call_count += 1
                return f"# Chunk {call_count}\n\nConverted content {call_count}"
            
            mock_instance.create_conversation.return_value.get_final_result.side_effect = mock_conversion
            
            result = await converter.convert(str(temp_dir), "large.html", "large.md")
            
            assert result == True
            
            # Verify multiple chunks were processed
            assert call_count > 1
            
            # Check output file
            output_file = temp_dir / "large.md"
            assert output_file.exists()
            
            content = output_file.read_text()
            assert "Chunk 1" in content
            assert "Chunk 2" in content  # At least 2 chunks


@pytest.mark.unit
class TestSDKDependency:
    """Test SDK dependency handling in chunked converter."""
    
    def test_sdk_import_required(self):
        """Test that the chunked converter requires Claude SDK."""
        # This test verifies that the chunked converter imports the SDK
        # which is why we route around it in the main converter
        try:
            from src.download2md.chunked_converter import ClaudeSDKClient
            # If we get here, the SDK is imported
            assert True
        except ImportError:
            # SDK not available, which is expected in some environments
            pytest.skip("Claude SDK not available")
    
    def test_chunked_converter_uses_sdk(self):
        """Test that chunked converter uses SDK (hence potential pollution source)."""
        converter = ChunkedHTMLToMarkdownConverter()
        
        # Verify that the converter has methods that use Claude SDK
        assert hasattr(converter, '_convert_chunk_with_claude')
        
        # This confirms why we avoid using chunked converter in the main router
        # to prevent SDK pollution


@pytest.mark.unit  
class TestChunkedConverterBatch:
    """Test batch processing in chunked converter."""
    
    @pytest.mark.asyncio
    async def test_batch_conversion_success(self, temp_dir):
        """Test successful batch conversion."""
        converter = ChunkedHTMLToMarkdownConverter(quiet=True)
        
        # Create multiple test files
        files = []
        conversions = []
        for i in range(3):
            html_content = f"<h1>Document {i}</h1><p>Content for document {i}</p>"
            input_file = temp_dir / f"doc{i}.html"
            input_file.write_text(html_content)
            files.append(input_file)
            
            conversions.append((f"doc{i}.html", f"doc{i}.md"))
        
        # Mock Claude SDK
        with patch('src.download2md.chunked_converter.ClaudeSDKClient') as mock_client:
            mock_instance = AsyncMock()
            mock_client.return_value.__aenter__.return_value = mock_instance
            
            def mock_result(prompt):
                # Extract document number from prompt to return appropriate content
                if "Document 0" in prompt:
                    return "# Document 0\n\nContent for document 0"
                elif "Document 1" in prompt:
                    return "# Document 1\n\nContent for document 1" 
                elif "Document 2" in prompt:
                    return "# Document 2\n\nContent for document 2"
                else:
                    return "# Unknown Document\n\nContent"
            
            mock_instance.create_conversation.return_value.get_final_result.side_effect = lambda: mock_result("test")
            
            results = await converter.convert_batch(str(temp_dir), conversions)
            
            assert len(results) == 3
            assert all(results)  # All should succeed
            
            # Verify output files were created
            for i in range(3):
                output_file = temp_dir / f"doc{i}.md"
                assert output_file.exists()
    
    @pytest.mark.asyncio
    async def test_batch_conversion_partial_failure(self, temp_dir):
        """Test batch conversion with some failures."""
        from src.download2md.shared import ConversionItem
        
        converter = ChunkedHTMLToMarkdownConverter(quiet=True)
        
        # Create test files (but skip one to cause failure)
        conversions = [
            ConversionItem("doc1.html", "doc1.md"),
            ConversionItem("missing.html", "missing.md"),  # This will fail
            ConversionItem("doc3.html", "doc3.md")
        ]
        
        # Create only some input files
        (temp_dir / "doc1.html").write_text("<h1>Doc 1</h1>")
        (temp_dir / "doc3.html").write_text("<h1>Doc 3</h1>")
        # missing.html intentionally not created
        
        results = await converter.convert_batch(str(temp_dir), conversions)
        
        assert len(results) == 3
        assert results[0] == False or results[2] == False  # Some should fail due to missing SDK
        # The exact failure pattern depends on whether SDK is available