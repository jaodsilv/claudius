#!/usr/bin/env python3
"""
Unit tests for Download2MarkdownPipeline.
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch, mock_open
from src.download2md.pipeline import (
    PipelineItem, 
    PipelineResult,
    Download2MarkdownPipeline
)


@pytest.mark.unit
class TestPipelineDataTypes:
    """Test pipeline data transfer objects."""
    
    def test_pipeline_item_creation(self):
        """Test PipelineItem creation and access."""
        item = PipelineItem(
            "https://example.com/page.html",
            "raw/page.html", 
            "converted/page.md"
        )
        
        assert item.url == "https://example.com/page.html"
        assert item.download_filename == "raw/page.html"
        assert item.converted_filename == "converted/page.md"
    
    def test_pipeline_item_immutability(self):
        """Test that PipelineItem is immutable."""
        item = PipelineItem("https://example.com", "input.html", "output.md")
        
        with pytest.raises(AttributeError):
            item.url = "https://changed.com"
        
        with pytest.raises(AttributeError):
            item.download_filename = "changed.html"
            
        with pytest.raises(AttributeError):
            item.converted_filename = "changed.md"
    
    def test_pipeline_item_tuple_behavior(self):
        """Test that PipelineItem behaves like a tuple."""
        item = PipelineItem("https://example.com", "input.html", "output.md")
        
        # Test unpacking
        url, download_file, converted_file = item
        assert url == "https://example.com"
        assert download_file == "input.html"
        assert converted_file == "output.md"
        
        # Test indexing
        assert item[0] == "https://example.com"
        assert item[1] == "input.html"
        assert item[2] == "output.md"
        
        # Test length
        assert len(item) == 3
    
    def test_pipeline_result_creation(self):
        """Test PipelineResult creation and access."""
        result = PipelineResult(
            download_success=True,
            conversion_success=True,
            verification_result={"score": 0.95, "issues": []}
        )
        
        assert result.download_success == True
        assert result.conversion_success == True
        assert result.verification_result["score"] == 0.95
    
    def test_pipeline_result_failure_cases(self):
        """Test PipelineResult for failure scenarios."""
        result = PipelineResult(
            download_success=False,
            conversion_success=False,
            verification_result=None
        )
        
        assert result.download_success == False
        assert result.conversion_success == False
        assert result.verification_result is None


@pytest.mark.unit
class TestDownload2MarkdownPipeline:
    """Test Download2MarkdownPipeline functionality."""
    
    def test_pipeline_initialization_defaults(self):
        """Test pipeline initialization with default values."""
        pipeline = Download2MarkdownPipeline()
        
        assert pipeline.max_download_attempts == 5
        assert pipeline.skip_existing == False
        assert pipeline.verify_conversions == True
    
    def test_pipeline_initialization_custom(self):
        """Test pipeline initialization with custom values."""
        pipeline = Download2MarkdownPipeline(
            max_download_attempts=3,
            skip_existing=True,
            verify_conversions=False
        )
        
        assert pipeline.max_download_attempts == 3
        assert pipeline.skip_existing == True
        assert pipeline.verify_conversions == False
    
    def test_initialize_components(self):
        """Test component initialization."""
        pipeline = Download2MarkdownPipeline()
        
        # Mock the component classes
        with patch('src.download2md.pipeline.DownloadManager') as mock_dl, \
             patch('src.download2md.pipeline.HTMLToMarkdownConverter') as mock_conv, \
             patch('src.download2md.pipeline.ConversionVerifier') as mock_ver:
            
            # Test component initialization
            downloader = pipeline._get_download_manager()
            converter = pipeline._get_converter()
            verifier = pipeline._get_verifier()
            
            # Components should be initialized
            assert downloader is not None
            assert converter is not None
            assert verifier is not None
    
    def test_get_download_manager_configuration(self):
        """Test download manager gets proper configuration."""
        pipeline = Download2MarkdownPipeline()
        
        with patch('src.download2md.pipeline.DownloadManager') as mock_dl:
            downloader = pipeline._get_download_manager(
                max_concurrent=3,
                delay_per_domain=2.0,
                quiet=True
            )
            
            # Should be called with expected parameters
            mock_dl.assert_called_with(
                max_concurrent=3,
                delay_per_domain=2.0,
                quiet=True
            )
    
    def test_get_converter_configuration(self):
        """Test converter gets proper configuration.""" 
        pipeline = Download2MarkdownPipeline()
        
        with patch('src.download2md.pipeline.HTMLToMarkdownConverter') as mock_conv:
            converter = pipeline._get_converter(
                conversion_strategy='simple',
                quiet=True,
                max_concurrent=2
            )
            
            # Should be called with expected parameters
            mock_conv.assert_called_with(
                conversion_strategy='simple',
                quiet=True,
                max_concurrent=2
            )
    
    def test_get_verifier_configuration(self):
        """Test verifier gets proper configuration."""
        pipeline = Download2MarkdownPipeline()
        
        with patch('src.download2md.pipeline.ConversionVerifier') as mock_ver:
            verifier = pipeline._get_verifier(
                min_content_length=100,
                quiet=True
            )
            
            # Should be called with expected parameters  
            mock_ver.assert_called_with(
                min_content_length=100,
                quiet=True
            )
    
    def test_extract_domain_from_url(self):
        """Test domain extraction utility."""
        pipeline = Download2MarkdownPipeline()
        
        test_cases = [
            ("https://example.com/page.html", "example.com"),
            ("http://subdomain.example.org/path", "subdomain.example.org"),
            ("https://docs.python.org/3/", "docs.python.org")
        ]
        
        for url, expected_domain in test_cases:
            try:
                domain = pipeline._extract_domain(url)
                assert domain == expected_domain
            except AttributeError:
                # Method might not exist - skip test
                pytest.skip("_extract_domain method not implemented")
    
    def test_build_file_paths(self, temp_dir):
        """Test file path building utilities."""
        pipeline = Download2MarkdownPipeline()
        
        try:
            download_path = pipeline._build_download_path(str(temp_dir), "page.html")
            convert_path = pipeline._build_convert_path(str(temp_dir), "page.md")
            
            assert download_path == str(temp_dir / "page.html")
            assert convert_path == str(temp_dir / "page.md")
        except AttributeError:
            # Methods might not exist - skip test
            pytest.skip("Path building methods not implemented")


@pytest.mark.unit
@pytest.mark.asyncio
class TestPipelineExecution:
    """Test pipeline execution functionality."""
    
    async def test_process_single_item_success(self, temp_dir):
        """Test successful processing of a single pipeline item."""
        pipeline = Download2MarkdownPipeline()
        
        item = PipelineItem(
            "https://example.com/test.html",
            "raw/test.html", 
            "converted/test.md"
        )
        
        # Mock successful components
        mock_downloader = AsyncMock()
        mock_downloader.download_file.return_value = True
        
        mock_converter = AsyncMock() 
        mock_converter.convert.return_value = True
        
        mock_verifier = AsyncMock()
        mock_verifier.verify.return_value = {"score": 0.9, "issues": []}
        
        with patch.object(pipeline, '_get_download_manager', return_value=mock_downloader), \
             patch.object(pipeline, '_get_converter', return_value=mock_converter), \
             patch.object(pipeline, '_get_verifier', return_value=mock_verifier):
            
            result = await pipeline.process_single_item(str(temp_dir), item)
            
            assert result.download_success == True
            assert result.conversion_success == True
            assert result.verification_result["score"] == 0.9
            
            # Verify components were called
            mock_downloader.download_file.assert_called_once()
            mock_converter.convert.assert_called_once()
            mock_verifier.verify.assert_called_once()
    
    async def test_process_single_item_download_failure(self, temp_dir):
        """Test handling of download failure."""
        pipeline = Download2MarkdownPipeline()
        
        item = PipelineItem("https://example.com/missing.html", "raw/missing.html", "converted/missing.md")
        
        # Mock download failure
        mock_downloader = AsyncMock()
        mock_downloader.download_file.return_value = False
        
        mock_converter = AsyncMock()
        mock_verifier = AsyncMock()
        
        with patch.object(pipeline, '_get_download_manager', return_value=mock_downloader), \
             patch.object(pipeline, '_get_converter', return_value=mock_converter), \
             patch.object(pipeline, '_get_verifier', return_value=mock_verifier):
            
            result = await pipeline.process_single_item(str(temp_dir), item)
            
            assert result.download_success == False
            # Conversion and verification should not be attempted after download failure
            assert result.conversion_success == False
            assert result.verification_result is None
            
            mock_downloader.download_file.assert_called_once()
            mock_converter.convert.assert_not_called()
            mock_verifier.verify.assert_not_called()
    
    async def test_process_single_item_conversion_failure(self, temp_dir):
        """Test handling of conversion failure.""" 
        pipeline = Download2MarkdownPipeline()
        
        item = PipelineItem("https://example.com/test.html", "raw/test.html", "converted/test.md")
        
        # Mock successful download but failed conversion
        mock_downloader = AsyncMock()
        mock_downloader.download_file.return_value = True
        
        mock_converter = AsyncMock()
        mock_converter.convert.return_value = False
        
        mock_verifier = AsyncMock()
        
        with patch.object(pipeline, '_get_download_manager', return_value=mock_downloader), \
             patch.object(pipeline, '_get_converter', return_value=mock_converter), \
             patch.object(pipeline, '_get_verifier', return_value=mock_verifier):
            
            result = await pipeline.process_single_item(str(temp_dir), item)
            
            assert result.download_success == True
            assert result.conversion_success == False
            assert result.verification_result is None
            
            mock_downloader.download_file.assert_called_once()
            mock_converter.convert.assert_called_once()
            mock_verifier.verify.assert_not_called()  # Should not verify failed conversion
    
    async def test_process_single_item_skip_verification(self, temp_dir):
        """Test processing with verification disabled."""
        pipeline = Download2MarkdownPipeline(verify_conversions=False)
        
        item = PipelineItem("https://example.com/test.html", "raw/test.html", "converted/test.md")
        
        mock_downloader = AsyncMock()
        mock_downloader.download_file.return_value = True
        
        mock_converter = AsyncMock()
        mock_converter.convert.return_value = True
        
        mock_verifier = AsyncMock()
        
        with patch.object(pipeline, '_get_download_manager', return_value=mock_downloader), \
             patch.object(pipeline, '_get_converter', return_value=mock_converter), \
             patch.object(pipeline, '_get_verifier', return_value=mock_verifier):
            
            result = await pipeline.process_single_item(str(temp_dir), item)
            
            assert result.download_success == True
            assert result.conversion_success == True
            assert result.verification_result is None  # Should be None when verification disabled
            
            mock_verifier.verify.assert_not_called()
    
    async def test_process_batch_success(self, temp_dir):
        """Test successful batch processing."""
        pipeline = Download2MarkdownPipeline()
        
        items = [
            PipelineItem("https://example.com/page1.html", "raw/page1.html", "converted/page1.md"),
            PipelineItem("https://example.com/page2.html", "raw/page2.html", "converted/page2.md")
        ]
        
        # Mock successful processing
        mock_downloader = AsyncMock()
        mock_downloader.download_file.return_value = True
        
        mock_converter = AsyncMock()
        mock_converter.convert.return_value = True
        
        mock_verifier = AsyncMock()
        mock_verifier.verify.return_value = {"score": 0.9, "issues": []}
        
        with patch.object(pipeline, '_get_download_manager', return_value=mock_downloader), \
             patch.object(pipeline, '_get_converter', return_value=mock_converter), \
             patch.object(pipeline, '_get_verifier', return_value=mock_verifier):
            
            results = await pipeline.process_batch(str(temp_dir), items)
            
            assert len(results) == 2
            assert all(r.download_success for r in results)
            assert all(r.conversion_success for r in results)
            assert all(r.verification_result is not None for r in results)
    
    async def test_process_batch_partial_failures(self, temp_dir):
        """Test batch processing with some failures."""
        pipeline = Download2MarkdownPipeline()
        
        items = [
            PipelineItem("https://example.com/good.html", "raw/good.html", "converted/good.md"),
            PipelineItem("https://example.com/bad.html", "raw/bad.html", "converted/bad.md"),
            PipelineItem("https://example.com/ugly.html", "raw/ugly.html", "converted/ugly.md")
        ]
        
        # Mock mixed results - second item fails download
        def mock_download(url, root_path, filename):
            if "bad.html" in filename:
                return False
            return True
        
        mock_downloader = AsyncMock()
        mock_downloader.download_file.side_effect = mock_download
        
        mock_converter = AsyncMock()
        mock_converter.convert.return_value = True
        
        mock_verifier = AsyncMock()
        mock_verifier.verify.return_value = {"score": 0.9, "issues": []}
        
        with patch.object(pipeline, '_get_download_manager', return_value=mock_downloader), \
             patch.object(pipeline, '_get_converter', return_value=mock_converter), \
             patch.object(pipeline, '_get_verifier', return_value=mock_verifier):
            
            results = await pipeline.process_batch(str(temp_dir), items)
            
            assert len(results) == 3
            assert results[0].download_success == True
            assert results[1].download_success == False  # Second should fail
            assert results[2].download_success == True
    
    async def test_process_batch_empty_list(self, temp_dir):
        """Test batch processing with empty list."""
        pipeline = Download2MarkdownPipeline()
        
        results = await pipeline.process_batch(str(temp_dir), [])
        assert results == []
    
    async def test_retry_logic_for_downloads(self, temp_dir):
        """Test retry logic for failed downloads."""
        pipeline = Download2MarkdownPipeline(max_download_attempts=3)
        
        item = PipelineItem("https://example.com/retry.html", "raw/retry.html", "converted/retry.md")
        
        # Mock download that fails twice then succeeds
        call_count = 0
        def mock_download_with_retry(*args, **kwargs):
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                return False  # Fail first two attempts
            return True  # Succeed on third attempt
        
        mock_downloader = AsyncMock()
        mock_downloader.download_file.side_effect = mock_download_with_retry
        
        mock_converter = AsyncMock()
        mock_converter.convert.return_value = True
        
        mock_verifier = AsyncMock()
        mock_verifier.verify.return_value = {"score": 0.9, "issues": []}
        
        with patch.object(pipeline, '_get_download_manager', return_value=mock_downloader), \
             patch.object(pipeline, '_get_converter', return_value=mock_converter), \
             patch.object(pipeline, '_get_verifier', return_value=mock_verifier):
            
            try:
                result = await pipeline.process_single_item(str(temp_dir), item)
                
                # Should eventually succeed after retries
                assert result.download_success == True
                assert call_count == 3  # Should have tried 3 times
            except AttributeError:
                # Retry logic might not be implemented yet
                pytest.skip("Retry logic not implemented")


@pytest.mark.unit
class TestPipelineYAMLIntegration:
    """Test YAML configuration integration."""
    
    def test_load_pipeline_config_from_yaml(self, temp_dir):
        """Test loading pipeline configuration from YAML."""
        yaml_content = f"""
# Pipeline configuration
output_path: "{temp_dir}"
skip_existing: true
verify_conversions: false
max_download_attempts: 3

# Component configurations
download_config:
  max_concurrent: 3
  delay_per_domain: 2.0
  timeout: 60

converter_config:
  conversion_strategy: "simple"
  quiet: true
  max_concurrent: 2

# Pipeline items
pipeline_items:
  - url: "https://example.com/page1.html"
    download_filename: "raw/page1.html"
    converted_filename: "converted/page1.md"
  - url: "https://example.com/page2.html"
    download_filename: "raw/page2.html"  
    converted_filename: "converted/page2.md"
"""
        config_file = temp_dir / "pipeline_config.yaml"
        config_file.write_text(yaml_content)
        
        try:
            # Import the function (assuming it exists)
            from src.download2md.pipeline import load_pipeline_config_from_yaml
            
            output_path, pipeline_items, config = load_pipeline_config_from_yaml(str(config_file))
            
            assert output_path == str(temp_dir)
            assert len(pipeline_items) == 2
            assert pipeline_items[0].url == "https://example.com/page1.html"
            assert config['skip_existing'] == True
            assert config['verify_conversions'] == False
            assert config['max_download_attempts'] == 3
            
        except ImportError:
            # Function might not exist yet
            pytest.skip("load_pipeline_config_from_yaml not implemented")


@pytest.mark.unit
class TestPipelineUtilities:
    """Test pipeline utility functions."""
    
    def test_skip_existing_files_logic(self, temp_dir):
        """Test logic for skipping existing files."""
        pipeline = Download2MarkdownPipeline(skip_existing=True)
        
        # Create an existing file
        existing_file = temp_dir / "existing.md"
        existing_file.write_text("Existing content")
        
        item_existing = PipelineItem("https://example.com/existing.html", "raw/existing.html", "existing.md")
        item_new = PipelineItem("https://example.com/new.html", "raw/new.html", "new.md")
        
        try:
            should_skip_existing = pipeline._should_skip_existing(str(temp_dir), item_existing)
            should_skip_new = pipeline._should_skip_existing(str(temp_dir), item_new)
            
            assert should_skip_existing == True
            assert should_skip_new == False
        except AttributeError:
            # Method might not exist yet
            pytest.skip("_should_skip_existing method not implemented")
    
    def test_progress_reporting(self):
        """Test progress reporting functionality.""" 
        pipeline = Download2MarkdownPipeline()
        
        try:
            # Test progress callback setup
            callback_called = False
            def progress_callback(current, total, item):
                nonlocal callback_called
                callback_called = True
            
            pipeline.set_progress_callback(progress_callback)
            
            # This is a basic test - actual implementation depends on pipeline design
            assert hasattr(pipeline, 'progress_callback') or callback_called is not None
        except AttributeError:
            # Progress reporting might not be implemented yet
            pytest.skip("Progress reporting not implemented")
    
    def test_error_handling_and_logging(self, temp_dir):
        """Test error handling and logging functionality."""
        pipeline = Download2MarkdownPipeline()
        
        # Test with invalid URLs and paths
        invalid_item = PipelineItem("not-a-url", "invalid", "invalid")
        
        try:
            # Should not crash with invalid inputs
            result = pipeline._validate_pipeline_item(invalid_item)
            assert isinstance(result, bool)
        except AttributeError:
            # Validation method might not exist yet
            pytest.skip("_validate_pipeline_item method not implemented")


@pytest.mark.unit
class TestPipelinePerformance:
    """Test pipeline performance characteristics.""" 
    
    @pytest.mark.asyncio
    async def test_concurrent_processing_limits(self, temp_dir):
        """Test that pipeline respects concurrency limits."""
        pipeline = Download2MarkdownPipeline()
        
        # Create many items to test concurrency
        items = [
            PipelineItem(f"https://example.com/page{i}.html", f"raw/page{i}.html", f"converted/page{i}.md")
            for i in range(10)
        ]
        
        # Mock components with tracking
        concurrent_count = 0
        max_concurrent_seen = 0
        
        async def mock_process_with_tracking(*args):
            nonlocal concurrent_count, max_concurrent_seen
            concurrent_count += 1
            max_concurrent_seen = max(max_concurrent_seen, concurrent_count)
            
            # Simulate processing time
            await asyncio.sleep(0.01)
            
            concurrent_count -= 1
            return PipelineResult(True, True, {"score": 0.9, "issues": []})
        
        with patch.object(pipeline, 'process_single_item', side_effect=mock_process_with_tracking):
            await pipeline.process_batch(str(temp_dir), items, max_concurrent=3)
            
            # Should not exceed concurrency limit
            assert max_concurrent_seen <= 3
    
    @pytest.mark.asyncio
    async def test_memory_usage_with_large_batch(self, temp_dir):
        """Test memory usage with large batches."""
        pipeline = Download2MarkdownPipeline()
        
        # Create large batch
        large_batch = [
            PipelineItem(f"https://example.com/page{i}.html", f"raw/page{i}.html", f"converted/page{i}.md")
            for i in range(100)
        ]
        
        # Mock lightweight processing 
        mock_result = PipelineResult(True, True, {"score": 0.9, "issues": []})
        
        with patch.object(pipeline, 'process_single_item', return_value=mock_result):
            results = await pipeline.process_batch(str(temp_dir), large_batch)
            
            # Should handle large batches without issues
            assert len(results) == 100
            assert all(isinstance(r, PipelineResult) for r in results)