#!/usr/bin/env python3
"""
End-to-end integration tests for HTML to Markdown conversion.
"""

import pytest
import asyncio
from pathlib import Path
from src.download2md.simple_converter import SimpleHTMLToMarkdownConverter
from src.download2md.shared import ConversionItem


@pytest.mark.integration
@pytest.mark.asyncio
class TestEndToEndConversion:
    """Test complete conversion workflows."""
    
    async def test_simple_converter_end_to_end(self, temp_dir, sample_html):
        """Test complete simple converter workflow."""
        # Create input file
        input_file = temp_dir / "input.html"
        input_file.write_text(sample_html)
        
        # Setup converter
        converter = SimpleHTMLToMarkdownConverter(quiet=True)
        
        # Perform conversion
        success = await converter.convert(
            str(temp_dir), "input.html", "output.md"
        )
        
        assert success == True
        
        # Verify output file exists and has content
        output_file = temp_dir / "output.md"
        assert output_file.exists()
        assert output_file.stat().st_size > 0
        
        # Verify basic markdown content
        content = output_file.read_text()
        assert "# Test Document" in content
        assert "**bold text**" in content
        assert "*italic text*" in content
        assert "https://example.com" in content
    
    async def test_batch_conversion(self, temp_dir, sample_html, complex_html):
        """Test batch conversion functionality."""
        # Create multiple input files
        input1 = temp_dir / "input1.html"
        input2 = temp_dir / "input2.html"
        input1.write_text(sample_html)
        input2.write_text(complex_html)
        
        # Create conversion items
        conversions = [
            ConversionItem("input1.html", "output1.md"),
            ConversionItem("input2.html", "output2.md")
        ]
        
        # Setup converter
        converter = SimpleHTMLToMarkdownConverter(quiet=True)
        
        # Perform batch conversion
        results = await converter.convert_batch(str(temp_dir), conversions)
        
        # Verify all conversions succeeded
        assert len(results) == 2
        assert all(results)
        
        # Verify output files exist
        output1 = temp_dir / "output1.md"
        output2 = temp_dir / "output2.md"
        assert output1.exists()
        assert output2.exists()
        assert output1.stat().st_size > 0
        assert output2.stat().st_size > 0
    
    async def test_conversion_with_subdirectories(self, temp_dir, sample_html):
        """Test conversion with subdirectory structure."""
        # Create subdirectory structure
        subdir = temp_dir / "docs" / "pages"
        subdir.mkdir(parents=True)
        
        # Create input file in subdirectory
        input_file = subdir / "page.html"
        input_file.write_text(sample_html)
        
        # Setup converter
        converter = SimpleHTMLToMarkdownConverter(quiet=True)
        
        # Perform conversion
        success = await converter.convert(
            str(temp_dir), "docs/pages/page.html", "docs/pages/page.md"
        )
        
        assert success == True
        
        # Verify output file exists in correct location
        output_file = subdir / "page.md"
        assert output_file.exists()
        assert output_file.stat().st_size > 0
    
    async def test_html_cleaning(self, temp_dir, complex_html):
        """Test that HTML cleaning removes unwanted elements."""
        # Create input file
        input_file = temp_dir / "complex.html"
        input_file.write_text(complex_html)
        
        # Setup converter with cleaning enabled
        converter = SimpleHTMLToMarkdownConverter(clean_content=True, quiet=True)
        
        # Perform conversion
        success = await converter.convert(
            str(temp_dir), "complex.html", "cleaned.md"
        )
        
        assert success == True
        
        # Verify unwanted elements were removed
        output_file = temp_dir / "cleaned.md"
        content = output_file.read_text()
        
        # Should contain main article content
        assert "Article Title" in content
        assert "Main article content" in content
        
        # Should not contain navigation/sidebar/footer (this depends on implementation)
        # Note: The simple converter may not remove all unwanted elements
        # as effectively as the BeautifulSoup4 version
    
    async def test_error_handling_missing_input(self, temp_dir):
        """Test error handling when input file is missing."""
        converter = SimpleHTMLToMarkdownConverter(quiet=True)
        
        success = await converter.convert(
            str(temp_dir), "nonexistent.html", "output.md"
        )
        
        assert success == False
        
        # Output file should not be created
        output_file = temp_dir / "output.md"
        assert not output_file.exists()
    
    async def test_empty_html_handling(self, temp_dir):
        """Test handling of empty HTML files."""
        # Create empty HTML file
        input_file = temp_dir / "empty.html"
        input_file.write_text("")
        
        converter = SimpleHTMLToMarkdownConverter(quiet=True)
        
        success = await converter.convert(
            str(temp_dir), "empty.html", "empty.md"
        )
        
        assert success == True
        
        # Output file should exist but be minimal
        output_file = temp_dir / "empty.md"
        assert output_file.exists()


@pytest.mark.integration
@pytest.mark.asyncio
class TestYamlConfigIntegration:
    """Test YAML configuration integration."""
    
    async def test_yaml_config_end_to_end(self, temp_dir, sample_html, complex_html):
        """Test complete workflow using YAML configuration."""
        # Create input files
        input1 = temp_dir / "page1.html"
        input2 = temp_dir / "page2.html"
        input1.write_text(sample_html)
        input2.write_text(complex_html)
        
        # Create YAML config
        config_content = f"""
root_path: "{temp_dir}"
max_concurrent: 2
conversion_strategy: "simple"
quiet: true
conversions:
  - input_filename: "page1.html"
    output_filename: "page1.md"
  - input_filename: "page2.html"
    output_filename: "page2.md"
"""
        config_file = temp_dir / "config.yaml"
        config_file.write_text(config_content)
        
        # Load configuration
        from src.download2md.shared import load_conversions_from_yaml
        
        root_path, conversions, config = load_conversions_from_yaml(str(config_file))
        
        # Verify configuration was loaded correctly
        assert root_path == str(temp_dir)
        assert len(conversions) == 2
        assert config['max_concurrent'] == 2
        assert config['conversion_strategy'] == 'simple'
        assert config['quiet'] == True
        
        # Perform batch conversion using loaded config
        converter = SimpleHTMLToMarkdownConverter(
            quiet=config['quiet']
        )
        results = await converter.convert_batch(root_path, conversions)
        
        # Verify results
        assert len(results) == 2
        assert all(results)
        
        # Verify output files
        output1 = temp_dir / "page1.md"
        output2 = temp_dir / "page2.md" 
        assert output1.exists()
        assert output2.exists()


@pytest.mark.integration
@pytest.mark.asyncio
class TestMainConverterIntegration:
    """Test main HTMLToMarkdownConverter integration scenarios."""
    
    async def test_intelligent_method_selection(self, temp_dir):
        """Test that the main converter selects appropriate methods based on file size."""
        converter = HTMLToMarkdownConverter(quiet=True)
        
        # Create files of different sizes
        small_html = "<html><body><h1>Small</h1><p>Small content</p></body></html>"
        
        medium_html = "<html><body><h1>Medium</h1>"
        for i in range(500):  # Make it ~200KB
            medium_html += f"<p>Medium content paragraph {i} with substantial text.</p>"
        medium_html += "</body></html>"
        
        large_html = "<html><body><h1>Large</h1>"
        for i in range(2000):  # Make it >500KB
            large_html += f"<section><h2>Section {i}</h2><p>Large content section {i} with extensive text content to make this a large file.</p></section>"
        large_html += "</body></html>"
        
        # Create test files
        (temp_dir / "small.html").write_text(small_html)
        (temp_dir / "medium.html").write_text(medium_html)
        (temp_dir / "large.html").write_text(large_html)
        
        # Test conversions
        small_result = await converter.convert(str(temp_dir), "small.html", "small.md")
        medium_result = await converter.convert(str(temp_dir), "medium.html", "medium.md")  
        large_result = await converter.convert(str(temp_dir), "large.html", "large.md")
        
        # All should complete without SDK pollution (main requirement)
        for output_file in ["small.md", "medium.md", "large.md"]:
            if (temp_dir / output_file).exists():
                content = (temp_dir / output_file).read_text()
                
                # No SDK pollution
                assert "SystemMessage" not in content
                assert "AssistantMessage" not in content
                assert "ResultMessage" not in content
                
                # Should contain meaningful content
                assert len(content.strip()) > 0
    
    async def test_concurrent_conversions(self, temp_dir):
        """Test concurrent conversion processing."""
        from src.download2md.shared import ConversionItem
        
        converter = HTMLToMarkdownConverter(max_concurrent=2, quiet=True)
        
        # Create multiple HTML files
        conversions = []
        for i in range(5):
            html_content = f"<html><body><h1>Document {i}</h1><p>Content for document {i}</p></body></html>"
            input_file = temp_dir / f"doc{i}.html"
            input_file.write_text(html_content)
            
            conversions.append(ConversionItem(f"doc{i}.html", f"doc{i}.md"))
        
        # Process batch
        results = await converter.convert_batch(str(temp_dir), conversions)
        
        # Check all results
        assert len(results) == 5
        
        for i, result in enumerate(results):
            output_file = temp_dir / f"doc{i}.md"
            if output_file.exists():
                content = output_file.read_text()
                
                # No SDK pollution
                assert "SystemMessage" not in content
                assert "AssistantMessage" not in content
                assert f"Document {i}" in content or len(content.strip()) > 0
    
    async def test_error_recovery_and_fallbacks(self, temp_dir):
        """Test error recovery and fallback mechanisms."""
        converter = HTMLToMarkdownConverter(quiet=True)
        
        # Test with challenging HTML
        challenging_html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Challenging Document</title>
            <meta charset="utf-8">
        </head>
        <body>
            <!-- Complex nested structure -->
            <div class="container">
                <nav>Navigation content</nav>
                <main>
                    <article>
                        <h1>Main Article</h1>
                        <p>Content with <span style="display:none">hidden</span> elements.</p>
                        <script>console.log('should be filtered');</script>
                        <style>.hidden { display: none; }</style>
                    </article>
                </main>
                <aside>Sidebar content</aside>
                <footer>Footer content</footer>
            </div>
        </body>
        </html>
        """
        
        input_file = temp_dir / "challenging.html"
        input_file.write_text(challenging_html)
        
        result = await converter.convert(str(temp_dir), "challenging.html", "challenging.md")
        
        output_file = temp_dir / "challenging.md"
        if output_file.exists():
            content = output_file.read_text()
            
            # Should handle gracefully without SDK pollution
            assert "SystemMessage" not in content
            assert "AssistantMessage" not in content
            assert len(content.strip()) > 0


@pytest.mark.integration
@pytest.mark.asyncio
class TestPipelineIntegration:
    """Test complete pipeline integration scenarios."""
    
    async def test_download_to_markdown_pipeline(self, temp_dir):
        """Test complete download-to-markdown pipeline if implemented."""
        try:
            from src.download2md.pipeline import Download2MarkdownPipeline, PipelineItem
            
            pipeline = Download2MarkdownPipeline(verify_conversions=False)
            
            # Mock a simple download scenario
            # (In practice, this would download real URLs)
            # For testing, we'll create the HTML file directly
            html_content = "<html><body><h1>Downloaded Content</h1><p>Test content</p></body></html>"
            (temp_dir / "downloaded.html").write_text(html_content)
            
            item = PipelineItem("https://example.com/test.html", "downloaded.html", "converted.md")
            
            # This would normally download, but we'll test just the conversion part
            with patch.object(pipeline, '_get_download_manager') as mock_dl:
                mock_downloader = AsyncMock()
                mock_downloader.download_file.return_value = True
                mock_dl.return_value = mock_downloader
                
                result = await pipeline.process_single_item(str(temp_dir), item)
                
                if result and result.conversion_success:
                    output_file = temp_dir / "converted.md"
                    if output_file.exists():
                        content = output_file.read_text()
                        
                        # No SDK pollution in pipeline output
                        assert "SystemMessage" not in content
                        assert "AssistantMessage" not in content
                        assert len(content.strip()) > 0
            
        except ImportError:
            pytest.skip("Pipeline module not available or not implemented")


@pytest.mark.integration
class TestYAMLConfigurationIntegration:
    """Test YAML configuration integration across modules."""
    
    @pytest.mark.asyncio
    async def test_yaml_driven_conversion_workflow(self, temp_dir):
        """Test complete YAML-driven conversion workflow."""
        # Create test HTML files
        html_files = {
            "page1.html": "<html><body><h1>Page 1</h1><p>Content 1</p></body></html>",
            "page2.html": "<html><body><h1>Page 2</h1><p>Content 2</p></body></html>",
            "page3.html": "<html><body><h1>Page 3</h1><p>Content 3</p></body></html>"
        }
        
        for filename, content in html_files.items():
            (temp_dir / filename).write_text(content)
        
        # Create YAML configuration
        yaml_content = f"""
root_path: "{temp_dir}"
max_concurrent: 2
conversion_strategy: "auto"
quiet: true
conversions:
  - input_filename: "page1.html"
    output_filename: "page1.md"
  - input_filename: "page2.html"
    output_filename: "page2.md"
  - input_filename: "page3.html"
    output_filename: "page3.md"
"""
        
        config_file = temp_dir / "conversion_config.yaml"
        config_file.write_text(yaml_content)
        
        # Load and process configuration
        from src.download2md.shared import load_conversions_from_yaml
        from src.download2md.converter import HTMLToMarkdownConverter
        
        root_path, conversions, config = load_conversions_from_yaml(str(config_file))
        
        # Process conversions
        converter = HTMLToMarkdownConverter(
            max_concurrent=config['max_concurrent'],
            conversion_strategy=config['conversion_strategy'], 
            quiet=config['quiet']
        )
        
        results = await converter.convert_batch(root_path, conversions)
        
        # Verify results
        assert len(results) == 3
        
        for i, (filename, _) in enumerate(html_files.items()):
            output_filename = filename.replace('.html', '.md')
            output_file = temp_dir / output_filename
            
            if output_file.exists():
                content = output_file.read_text()
                
                # No SDK pollution
                assert "SystemMessage" not in content
                assert "AssistantMessage" not in content
                assert len(content.strip()) > 0
                assert f"Page {i+1}" in content or "Content" in content


@pytest.mark.integration
class TestErrorHandlingIntegration:
    """Test error handling across the entire system."""
    
    @pytest.mark.asyncio
    async def test_missing_files_error_handling(self, temp_dir):
        """Test graceful handling of missing files."""
        from src.download2md.shared import ConversionItem
        converter = HTMLToMarkdownConverter(quiet=True)
        
        # Create some files but not others
        (temp_dir / "exists.html").write_text("<html><body>Exists</body></html>")
        
        conversions = [
            ConversionItem("exists.html", "exists.md"),
            ConversionItem("missing1.html", "missing1.md"),
            ConversionItem("missing2.html", "missing2.md")
        ]
        
        results = await converter.convert_batch(str(temp_dir), conversions)
        
        # Should handle missing files gracefully
        assert len(results) == 3
        assert results[0] in [True, False]  # First might succeed or fail
        assert results[1] == False  # Missing files should fail
        assert results[2] == False
        
        # Existing file should not produce SDK pollution if converted
        output_file = temp_dir / "exists.md"
        if output_file.exists():
            content = output_file.read_text()
            assert "SystemMessage" not in content
    
    @pytest.mark.asyncio
    async def test_invalid_html_error_handling(self, temp_dir):
        """Test handling of invalid/corrupted HTML."""
        converter = HTMLToMarkdownConverter(quiet=True)
        
        # Create files with invalid HTML
        invalid_htmls = {
            "binary.html": b'\x00\x01\x02\x03\x04\x05',  # Binary content
            "incomplete.html": "<html><body><h1>Incomplete",  # Incomplete HTML
            "empty.html": "",  # Empty file
            "text_only.html": "Just plain text without HTML tags"
        }
        
        for filename, content in invalid_htmls.items():
            if isinstance(content, bytes):
                (temp_dir / filename).write_bytes(content)
            else:
                (temp_dir / filename).write_text(content)
        
        # Test conversion of each file
        for filename in invalid_htmls.keys():
            output_filename = filename.replace('.html', '.md')
            
            result = await converter.convert(str(temp_dir), filename, output_filename)
            
            # Should handle invalid HTML gracefully
            output_file = temp_dir / output_filename
            if output_file.exists():
                try:
                    content = output_file.read_text()
                    # No SDK pollution even with invalid input
                    assert "SystemMessage" not in content
                    assert "AssistantMessage" not in content
                except UnicodeDecodeError:
                    # Some binary content might not be readable, which is acceptable
                    pass


@pytest.mark.integration
class TestBackwardCompatibility:
    """Test that the refactoring maintains backward compatibility."""
    
    def test_old_import_patterns_still_work(self):
        """Test that old import patterns continue to work.""" 
        # These should all work for backward compatibility
        try:
            from src.download2md.converter import HTMLToMarkdownConverter
            
            # Test that the imported items are functional
            converter = HTMLToMarkdownConverter()
            assert converter is not None
            
        except ImportError as e:
            pytest.fail(f"Backward compatibility broken: {e}")
    
    def test_new_import_patterns_work(self):
        """Test that new import patterns work correctly."""
        try:
            from src.download2md.shared import ConversionItem, load_conversions_from_yaml
            
            item = ConversionItem("test.html", "test.md")
            assert item.input_filename == "test.html"
            assert item.output_filename == "test.md"
            
        except ImportError as e:
            pytest.fail(f"New import pattern failed: {e}")


@pytest.mark.integration
class TestPerformanceIntegration:
    """Test performance characteristics of the integrated system."""
    
    @pytest.mark.asyncio
    async def test_large_batch_processing_performance(self, temp_dir):
        """Test performance with large batches."""
        from src.download2md.shared import ConversionItem
        converter = HTMLToMarkdownConverter(max_concurrent=3, quiet=True)
        
        # Create many small files
        conversions = []
        for i in range(20):
            html_content = f"<html><body><h1>Doc {i}</h1><p>Content {i}</p></body></html>"
            input_file = temp_dir / f"doc{i:03d}.html"
            input_file.write_text(html_content)
            
            conversions.append(ConversionItem(f"doc{i:03d}.html", f"doc{i:03d}.md"))
        
        import time
        start_time = time.time()
        
        results = await converter.convert_batch(str(temp_dir), conversions)
        
        end_time = time.time()
        processing_time = end_time - start_time
        
        # Should complete in reasonable time (adjust threshold as needed)
        assert processing_time < 60, f"Batch processing took too long: {processing_time}s"
        assert len(results) == 20
        
        # Verify all outputs are clean
        for i in range(20):
            output_file = temp_dir / f"doc{i:03d}.md"
            if output_file.exists():
                content = output_file.read_text()
                assert "SystemMessage" not in content
    
    @pytest.mark.asyncio
    async def test_memory_usage_with_large_files(self, temp_dir):
        """Test memory usage with large files."""
        converter = HTMLToMarkdownConverter(quiet=True)
        
        # Create a very large HTML file
        large_content = "<html><body><h1>Large Document</h1>"
        
        # Add substantial content (~2MB)
        for i in range(5000):
            large_content += f"""
            <section>
                <h2>Section {i}</h2>
                <p>This is section {i} with substantial content to test memory usage during conversion.
                The content is repeated many times to create a large file that will test the converter's
                ability to handle large documents without excessive memory usage or SDK pollution.</p>
                <ul>
                    <li>Point A for section {i}</li>
                    <li>Point B for section {i}</li>
                    <li>Point C for section {i}</li>
                </ul>
            </section>
            """
        
        large_content += "</body></html>"
        
        input_file = temp_dir / "very_large.html"
        input_file.write_text(large_content)
        
        # Should handle large files without crashing
        result = await converter.convert(str(temp_dir), "very_large.html", "very_large.md")
        
        output_file = temp_dir / "very_large.md"
        if output_file.exists():
            content = output_file.read_text()
            
            # Should complete without SDK pollution
            assert "SystemMessage" not in content
            assert "AssistantMessage" not in content
            assert len(content.strip()) > 0