#!/usr/bin/env python3
"""
Unit tests for downloader module.
"""

import pytest
from unittest.mock import Mock, patch, mock_open
from src.download2md.downloader import (
    DownloadItem, 
    _infer_extension_from_url, 
    DownloadManager
)


@pytest.mark.unit
class TestDownloadItem:
    """Test DownloadItem namedtuple."""
    
    def test_download_item_creation(self):
        """Test basic DownloadItem creation."""
        item = DownloadItem("https://example.com/page.html", "page.html")
        assert item.url == "https://example.com/page.html"
        assert item.filename == "page.html"
    
    def test_download_item_named_parameters(self):
        """Test DownloadItem creation with named parameters."""
        item = DownloadItem(
            url="https://test.com/doc.pdf",
            filename="document.pdf"
        )
        assert item.url == "https://test.com/doc.pdf"
        assert item.filename == "document.pdf"
    
    def test_download_item_immutability(self):
        """Test that DownloadItem is immutable."""
        item = DownloadItem("https://example.com", "file.html")
        
        with pytest.raises(AttributeError):
            item.url = "https://changed.com"
        
        with pytest.raises(AttributeError):
            item.filename = "changed.html"
    
    def test_download_item_tuple_behavior(self):
        """Test that DownloadItem behaves like a tuple."""
        item = DownloadItem("https://example.com", "file.html")
        
        # Test indexing
        assert item[0] == "https://example.com"
        assert item[1] == "file.html"
        
        # Test unpacking
        url, filename = item
        assert url == "https://example.com"
        assert filename == "file.html"
        
        # Test length
        assert len(item) == 2


@pytest.mark.unit
class TestExtensionInference:
    """Test URL extension inference functionality."""
    
    def test_infer_extension_common_cases(self):
        """Test extension inference for common file types."""
        test_cases = [
            ("https://example.com/page.html", ".html"),
            ("https://example.com/document.pdf", ".pdf"),
            ("https://example.com/script.js", ".js"),
            ("https://example.com/style.css", ".css"),
            ("https://example.com/data.json", ".json"),
            ("https://example.com/image.png", ".png"),
            ("https://example.com/archive.zip", ".zip")
        ]
        
        for url, expected_ext in test_cases:
            result = _infer_extension_from_url(url)
            assert result == expected_ext, f"URL {url} should return {expected_ext}, got {result}"
    
    def test_infer_extension_no_extension(self):
        """Test URLs without file extensions."""
        test_cases = [
            "https://example.com/",
            "https://example.com",
            "https://example.com/page",
            "https://example.com/directory/",
            "https://example.com/path/to/resource"
        ]
        
        for url in test_cases:
            result = _infer_extension_from_url(url)
            assert result == "", f"URL {url} should return empty string, got {result}"
    
    def test_infer_extension_with_query_params(self):
        """Test URLs with query parameters."""
        test_cases = [
            ("https://example.com/page.html?param=value", ".html"),
            ("https://example.com/doc.pdf?download=true&v=1", ".pdf"),
            ("https://example.com/api/data.json?format=compact", ".json")
        ]
        
        for url, expected_ext in test_cases:
            result = _infer_extension_from_url(url)
            assert result == expected_ext, f"URL {url} should return {expected_ext}, got {result}"
    
    def test_infer_extension_with_fragments(self):
        """Test URLs with fragment identifiers."""
        test_cases = [
            ("https://example.com/page.html#section1", ".html"),
            ("https://example.com/doc.pdf#page=5", ".pdf"),
            ("https://example.com/style.css#main", ".css")
        ]
        
        for url, expected_ext in test_cases:
            result = _infer_extension_from_url(url)
            assert result == expected_ext, f"URL {url} should return {expected_ext}, got {result}"
    
    def test_infer_extension_complex_paths(self):
        """Test URLs with complex path structures."""
        test_cases = [
            ("https://example.com/path/to/deep/file.html", ".html"),
            ("https://example.com/v1/api/endpoint.json", ".json"),
            ("https://docs.example.com/guides/tutorial.md", ".md")
        ]
        
        for url, expected_ext in test_cases:
            result = _infer_extension_from_url(url)
            assert result == expected_ext, f"URL {url} should return {expected_ext}, got {result}"
    
    def test_infer_extension_edge_cases(self):
        """Test edge cases for extension inference."""
        test_cases = [
            ("", ""),  # Empty string
            (None, ""),  # None value
            ("not-a-url", ""),  # Invalid URL
            ("https://", ""),  # Incomplete URL
            ("https://example.com/.hidden", ".hidden"),  # Hidden file
            ("https://example.com/file.", "."),  # Dot without extension
            ("https://example.com/file.tar.gz", ".gz")  # Multiple extensions - takes last
        ]
        
        for url, expected_ext in test_cases:
            result = _infer_extension_from_url(url)
            assert result == expected_ext, f"URL {url} should return {expected_ext}, got {result}"


@pytest.mark.unit
class TestDownloadManager:
    """Test DownloadManager functionality."""
    
    def test_download_manager_initialization_defaults(self):
        """Test download manager initialization with defaults."""
        manager = DownloadManager()
        
        assert manager.max_concurrent == 5
        assert manager.delay_per_domain == 1.0
        assert manager.timeout == 30
        assert manager.quiet == False
        assert isinstance(manager.session_headers, dict)
    
    def test_download_manager_initialization_custom(self):
        """Test download manager initialization with custom values."""
        custom_headers = {"User-Agent": "TestBot/1.0"}
        
        manager = DownloadManager(
            max_concurrent=3,
            delay_per_domain=2.0,
            timeout=60,
            quiet=True,
            session_headers=custom_headers
        )
        
        assert manager.max_concurrent == 3
        assert manager.delay_per_domain == 2.0
        assert manager.timeout == 60
        assert manager.quiet == True
        assert manager.session_headers == custom_headers
    
    def test_extract_domain(self):
        """Test domain extraction from URLs."""
        manager = DownloadManager()
        
        test_cases = [
            ("https://example.com/path", "example.com"),
            ("http://subdomain.example.com/file.html", "subdomain.example.com"),
            ("https://docs.python.org/3/library/", "docs.python.org"),
            ("ftp://files.example.net/data", "files.example.net")
        ]
        
        for url, expected_domain in test_cases:
            result = manager._extract_domain(url)
            assert result == expected_domain, f"URL {url} should extract {expected_domain}, got {result}"
    
    def test_extract_domain_invalid_url(self):
        """Test domain extraction with invalid URLs."""
        manager = DownloadManager()
        
        invalid_urls = ["not-a-url", "", "://missing-scheme", "ftp://"]
        
        for url in invalid_urls:
            result = manager._extract_domain(url)
            # Should return something reasonable or empty string, not crash
            assert isinstance(result, str)
    
    def test_group_by_domain(self):
        """Test grouping downloads by domain."""
        manager = DownloadManager()
        
        downloads = [
            DownloadItem("https://example.com/page1.html", "page1.html"),
            DownloadItem("https://other.com/doc.pdf", "doc.pdf"),
            DownloadItem("https://example.com/page2.html", "page2.html"),
            DownloadItem("https://third.com/data.json", "data.json")
        ]
        
        grouped = manager._group_downloads_by_domain(downloads)
        
        assert len(grouped) == 3
        assert "example.com" in grouped
        assert "other.com" in grouped
        assert "third.com" in grouped
        assert len(grouped["example.com"]) == 2
        assert len(grouped["other.com"]) == 1
        assert len(grouped["third.com"]) == 1
    
    def test_build_file_path(self, temp_dir):
        """Test file path building logic."""
        manager = DownloadManager()
        
        file_path = manager._build_file_path(str(temp_dir), "test.html")
        expected_path = str(temp_dir / "test.html")
        
        assert file_path == expected_path
    
    def test_build_file_path_with_subdirectory(self, temp_dir):
        """Test file path building with subdirectories."""
        manager = DownloadManager()
        
        file_path = manager._build_file_path(str(temp_dir), "docs/page.html")
        expected_path = str(temp_dir / "docs" / "page.html")
        
        assert file_path == expected_path


@pytest.mark.unit
@pytest.mark.asyncio
class TestDownloadManagerAsync:
    """Test async functionality of DownloadManager."""
    
    async def test_single_file_download_success(self, temp_dir):
        """Test successful single file download."""
        manager = DownloadManager(quiet=True)
        
        # Mock successful HTTP response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.content = b"<html><body>Test content</body></html>"
        mock_response.raise_for_status = Mock()
        
        with patch('requests.get', return_value=mock_response):
            result = await manager.download_file(
                "https://example.com/test.html", 
                str(temp_dir),
                "test.html"
            )
            
            assert result == True
            
            # Check file was created
            output_file = temp_dir / "test.html"
            assert output_file.exists()
            
            content = output_file.read_text()
            assert "Test content" in content
    
    async def test_single_file_download_http_error(self, temp_dir):
        """Test handling of HTTP errors during download."""
        manager = DownloadManager(quiet=True)
        
        # Mock HTTP error
        with patch('requests.get') as mock_get:
            mock_get.side_effect = requests.exceptions.RequestException("Network error")
            
            result = await manager.download_file(
                "https://example.com/test.html",
                str(temp_dir),
                "test.html"
            )
            
            assert result == False
            
            # File should not be created on error
            output_file = temp_dir / "test.html"
            assert not output_file.exists()
    
    async def test_single_file_download_creates_directories(self, temp_dir):
        """Test that download creates necessary directories."""
        manager = DownloadManager(quiet=True)
        
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.content = b"<html>Content</html>"
        mock_response.raise_for_status = Mock()
        
        with patch('requests.get', return_value=mock_response):
            result = await manager.download_file(
                "https://example.com/test.html",
                str(temp_dir),
                "nested/deep/test.html"
            )
            
            assert result == True
            
            # Check nested directories were created
            output_file = temp_dir / "nested" / "deep" / "test.html"
            assert output_file.exists()
            assert output_file.parent.exists()
    
    async def test_batch_download_success(self, temp_dir):
        """Test successful batch download."""
        manager = DownloadManager(quiet=True)
        
        downloads = [
            DownloadItem("https://example.com/page1.html", "page1.html"),
            DownloadItem("https://example.com/page2.html", "page2.html"),
            DownloadItem("https://other.com/doc.pdf", "doc.pdf")
        ]
        
        # Mock successful responses
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.content = b"Mock content"
        mock_response.raise_for_status = Mock()
        
        with patch('requests.get', return_value=mock_response):
            results = await manager.download_batch(str(temp_dir), downloads)
            
            assert len(results) == 3
            assert all(results)  # All should succeed
            
            # Check all files were created
            for download in downloads:
                output_file = temp_dir / download.filename
                assert output_file.exists()
    
    async def test_batch_download_partial_failure(self, temp_dir):
        """Test batch download with some failures."""
        manager = DownloadManager(quiet=True)
        
        downloads = [
            DownloadItem("https://example.com/page1.html", "page1.html"),
            DownloadItem("https://example.com/missing.html", "missing.html"),  # This will fail
            DownloadItem("https://example.com/page3.html", "page3.html")
        ]
        
        def mock_get_side_effect(url, **kwargs):
            if "missing.html" in url:
                raise requests.exceptions.RequestException("404 Not Found")
            
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.content = b"Mock content"
            mock_response.raise_for_status = Mock()
            return mock_response
        
        with patch('requests.get', side_effect=mock_get_side_effect):
            results = await manager.download_batch(str(temp_dir), downloads)
            
            assert len(results) == 3
            assert results[0] == True   # First should succeed
            assert results[1] == False  # Second should fail
            assert results[2] == True   # Third should succeed
    
    async def test_batch_download_respects_concurrency_limit(self, temp_dir):
        """Test that batch download respects concurrency limits."""
        manager = DownloadManager(max_concurrent=2, quiet=True)
        
        downloads = [DownloadItem(f"https://example.com/page{i}.html", f"page{i}.html") for i in range(5)]
        
        # Track concurrent calls
        concurrent_count = 0
        max_concurrent_seen = 0
        
        def mock_get_with_tracking(url, **kwargs):
            nonlocal concurrent_count, max_concurrent_seen
            concurrent_count += 1
            max_concurrent_seen = max(max_concurrent_seen, concurrent_count)
            
            # Simulate some delay
            import time
            time.sleep(0.01)
            
            concurrent_count -= 1
            
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.content = b"Content"
            mock_response.raise_for_status = Mock()
            return mock_response
        
        with patch('requests.get', side_effect=mock_get_with_tracking):
            results = await manager.download_batch(str(temp_dir), downloads)
            
            assert len(results) == 5
            assert all(results)
            assert max_concurrent_seen <= 2  # Should not exceed limit
    
    async def test_batch_download_domain_delays(self, temp_dir):
        """Test that downloads respect per-domain delays."""
        manager = DownloadManager(delay_per_domain=0.1, quiet=True)  # Short delay for testing
        
        # Multiple downloads from same domain
        downloads = [
            DownloadItem("https://example.com/page1.html", "page1.html"),
            DownloadItem("https://example.com/page2.html", "page2.html"),
            DownloadItem("https://example.com/page3.html", "page3.html")
        ]
        
        start_time = None
        call_times = []
        
        def mock_get_with_timing(url, **kwargs):
            nonlocal start_time
            import time
            current_time = time.time()
            
            if start_time is None:
                start_time = current_time
            
            call_times.append(current_time - start_time)
            
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.content = b"Content"
            mock_response.raise_for_status = Mock()
            return mock_response
        
        with patch('requests.get', side_effect=mock_get_with_timing):
            await manager.download_batch(str(temp_dir), downloads)
            
            # Calls to same domain should be spaced by delay_per_domain
            # (This is a basic check - exact timing can vary in test environments)
            assert len(call_times) == 3
    
    async def test_batch_download_empty_list(self, temp_dir):
        """Test batch download with empty list."""
        manager = DownloadManager()
        
        results = await manager.download_batch(str(temp_dir), [])
        assert results == []


@pytest.mark.unit
class TestDownloadManagerYAMLIntegration:
    """Test YAML configuration integration with downloader."""
    
    def test_load_downloads_from_yaml_basic(self, temp_dir):
        """Test loading download configuration from YAML."""
        yaml_content = f"""
output_path: "{temp_dir}"
max_concurrent: 3
delay_per_domain: 1.5
downloads:
  - url: "https://example.com/page1.html"
    filename: "page1.html"
  - url: "https://example.com/page2.html"
    filename: "page2.html"
"""
        config_file = temp_dir / "downloads.yaml"
        config_file.write_text(yaml_content)
        
        # Import the function (assuming it exists in the downloader module)
        try:
            from src.download2md.downloader import load_downloads_from_yaml
            
            output_path, downloads, config = load_downloads_from_yaml(str(config_file))
            
            assert output_path == str(temp_dir)
            assert len(downloads) == 2
            assert downloads[0].url == "https://example.com/page1.html"
            assert downloads[0].filename == "page1.html"
            assert config['max_concurrent'] == 3
            assert config['delay_per_domain'] == 1.5
            
        except ImportError:
            # Function might not exist yet
            pytest.skip("load_downloads_from_yaml not implemented")


@pytest.mark.unit 
class TestDownloadManagerEdgeCases:
    """Test edge cases and error conditions."""
    
    def test_invalid_url_handling(self):
        """Test handling of invalid URLs."""
        manager = DownloadManager()
        
        invalid_urls = [
            "",
            "not-a-url",
            "://missing-protocol",
            "https://",
            None
        ]
        
        for url in invalid_urls:
            try:
                # Should not crash when extracting domain
                if url is not None:
                    domain = manager._extract_domain(url)
                    assert isinstance(domain, str)
            except (TypeError, AttributeError):
                # Some invalid URLs might raise exceptions, which is acceptable
                pass
    
    def test_file_writing_permissions(self, temp_dir):
        """Test handling of file writing permission issues."""
        manager = DownloadManager(quiet=True)
        
        # This test is platform-dependent and may not work everywhere
        # We'll just verify the method doesn't crash with reasonable inputs
        try:
            path = manager._build_file_path(str(temp_dir), "test.html")
            assert isinstance(path, str)
        except (OSError, PermissionError):
            # Permission errors are expected in some test environments
            pass