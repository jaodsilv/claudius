#!/usr/bin/env python3
"""
Unit tests for HTMLToMarkdownConverter - the main intelligent converter class.
"""

import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock, patch, mock_open
from pathlib import Path
from src.download2md.converter import HTMLToMarkdownConverter
from src.download2md.shared import ConversionItem


@pytest.mark.unit
class TestHTMLToMarkdownConverter:
    """Test HTMLToMarkdownConverter functionality."""
    
    def test_converter_initialization_defaults(self):
        """Test converter initialization with default values."""
        converter = HTMLToMarkdownConverter()
        
        # Check default values
        assert converter.allowed_tools is None
        assert converter.max_turns == 10
        assert converter.max_concurrent == 5
        assert converter.quiet == False
        assert converter.conversion_strategy == 'auto'
        assert converter.large_file_threshold_kb == 500
        assert converter.medium_file_threshold_kb == 100
        assert converter.chunk_size_kb == 50
        assert converter.chunk_overlap_kb == 5
        
        # Check computed values
        assert converter.large_file_threshold_bytes == 500 * 1024
        assert converter.medium_file_threshold_bytes == 100 * 1024
    
    def test_converter_initialization_custom(self):
        """Test converter initialization with custom values."""
        converter = HTMLToMarkdownConverter(
            allowed_tools=['Read', 'Write'],
            max_turns=5,
            max_concurrent=3,
            quiet=True,
            conversion_strategy='simple',
            large_file_threshold_kb=1000,
            medium_file_threshold_kb=200,
            chunk_size_kb=75,
            chunk_overlap_kb=10
        )
        
        assert converter.allowed_tools == ['Read', 'Write']
        assert converter.max_turns == 5
        assert converter.max_concurrent == 3
        assert converter.quiet == True
        assert converter.conversion_strategy == 'simple'
        assert converter.large_file_threshold_kb == 1000
        assert converter.medium_file_threshold_kb == 200
        assert converter.chunk_size_kb == 75
        assert converter.chunk_overlap_kb == 10
        assert converter.large_file_threshold_bytes == 1000 * 1024
        assert converter.medium_file_threshold_bytes == 200 * 1024
    
    def test_method_selection_large_files(self):
        """Test method selection for large files (>500KB by default)."""
        converter = HTMLToMarkdownConverter()
        
        # Mock file size check
        with patch('os.path.exists', return_value=True), \
             patch('os.path.getsize', return_value=600 * 1024):  # 600KB
            
            method = converter._select_conversion_method('/tmp', 'large.html')
            assert method == 'simple'
    
    def test_method_selection_medium_files(self):
        """Test method selection for medium files (100-500KB by default)."""
        converter = HTMLToMarkdownConverter()
        
        # Mock file size check
        with patch('os.path.exists', return_value=True), \
             patch('os.path.getsize', return_value=200 * 1024):  # 200KB
            
            method = converter._select_conversion_method('/tmp', 'medium.html')
            # After our fix, medium files should use simple converter to avoid SDK pollution
            assert method == 'simple'
    
    def test_method_selection_small_files(self):
        """Test method selection for small files (<100KB by default)."""
        converter = HTMLToMarkdownConverter()
        
        # Mock file size check
        with patch('os.path.exists', return_value=True), \
             patch('os.path.getsize', return_value=50 * 1024):  # 50KB
            
            method = converter._select_conversion_method('/tmp', 'small.html')
            assert method == 'native'
    
    def test_method_selection_nonexistent_file(self):
        """Test method selection for nonexistent files."""
        converter = HTMLToMarkdownConverter()
        
        with patch('os.path.exists', return_value=False):
            method = converter._select_conversion_method('/tmp', 'missing.html')
            assert method == 'native'  # Default fallback
    
    def test_method_selection_forced_strategy(self):
        """Test that forced conversion strategy bypasses file size logic."""
        converter = HTMLToMarkdownConverter(conversion_strategy='simple')
        
        # Even for small files, should use simple when forced
        with patch('os.path.exists', return_value=True), \
             patch('os.path.getsize', return_value=10 * 1024):  # 10KB
            
            method = converter._select_conversion_method('/tmp', 'small.html')
            assert method == 'simple'
    
    def test_quiet_mode_suppresses_output(self, capsys):
        """Test that quiet mode suppresses print output."""
        converter = HTMLToMarkdownConverter(quiet=True)
        
        with patch('os.path.exists', return_value=True), \
             patch('os.path.getsize', return_value=200 * 1024):
            
            converter._select_conversion_method('/tmp', 'test.html')
            
        captured = capsys.readouterr()
        assert captured.out == ""
    
    def test_verbose_mode_shows_output(self, capsys):
        """Test that verbose mode shows method selection output."""
        converter = HTMLToMarkdownConverter(quiet=False)
        
        with patch('os.path.exists', return_value=True), \
             patch('os.path.getsize', return_value=200 * 1024):
            
            converter._select_conversion_method('/tmp', 'test.html')
            
        captured = capsys.readouterr()
        assert "[INFO]" in captured.out
        assert "200.0KB" in captured.out
        assert "simple converter" in captured.out


@pytest.mark.unit
@pytest.mark.asyncio
class TestHTMLToMarkdownConverterAsync:
    """Test async functionality of HTMLToMarkdownConverter."""
    
    async def test_convert_with_method_simple(self):
        """Test conversion using simple converter method."""
        converter = HTMLToMarkdownConverter()
        
        # Mock simple converter
        mock_simple = AsyncMock(return_value=True)
        with patch.object(converter, '_get_simple_converter') as mock_get:
            mock_converter = MagicMock()
            mock_converter.convert = mock_simple
            mock_get.return_value = mock_converter
            
            result = await converter._convert_with_method(
                'simple', '/tmp', 'input.html', 'output.md'
            )
            
            assert result == True
            mock_simple.assert_called_once_with('/tmp', 'input.html', 'output.md')
    
    async def test_convert_with_method_native(self):
        """Test conversion using native converter method."""
        converter = HTMLToMarkdownConverter()
        
        # Mock native converter
        mock_native = AsyncMock(return_value=True)
        with patch.object(converter, '_get_native_converter') as mock_get:
            mock_converter = MagicMock()
            mock_converter.convert = mock_native
            mock_get.return_value = mock_converter
            
            result = await converter._convert_with_method(
                'native', '/tmp', 'input.html', 'output.md'
            )
            
            assert result == True
            mock_native.assert_called_once_with('/tmp', 'input.html', 'output.md')
    
    async def test_convert_with_method_invalid_method(self):
        """Test error handling for invalid conversion method."""
        converter = HTMLToMarkdownConverter()
        
        with pytest.raises(ValueError, match="Unknown conversion method"):
            await converter._convert_with_method(
                'invalid', '/tmp', 'input.html', 'output.md'
            )
    
    async def test_convert_with_retry_success_first_try(self):
        """Test successful conversion on first attempt."""
        converter = HTMLToMarkdownConverter()
        
        with patch.object(converter, '_select_conversion_method', return_value='simple'), \
             patch.object(converter, '_convert_with_method', return_value=True) as mock_convert:
            
            result = await converter._convert_with_retry('/tmp', 'input.html', 'output.md')
            
            assert result == True
            mock_convert.assert_called_once_with('simple', '/tmp', 'input.html', 'output.md')
    
    async def test_convert_with_retry_fallback_success(self):
        """Test successful conversion after fallback to different method."""
        converter = HTMLToMarkdownConverter()
        
        with patch.object(converter, '_select_conversion_method', return_value='native'), \
             patch.object(converter, '_convert_with_method', side_effect=[False, True]) as mock_convert:
            
            result = await converter._convert_with_retry('/tmp', 'input.html', 'output.md')
            
            assert result == True
            # Should try native first, then fallback to chunked, then simple
            assert mock_convert.call_count == 2
            mock_convert.assert_any_call('native', '/tmp', 'input.html', 'output.md')
            mock_convert.assert_any_call('simple', '/tmp', 'input.html', 'output.md')
    
    async def test_convert_with_retry_all_methods_fail(self):
        """Test behavior when all conversion methods fail."""
        converter = HTMLToMarkdownConverter()
        
        with patch.object(converter, '_select_conversion_method', return_value='native'), \
             patch.object(converter, '_convert_with_method', return_value=False):
            
            result = await converter._convert_with_retry('/tmp', 'input.html', 'output.md')
            
            assert result == False
    
    async def test_convert_with_retry_exception_handling(self):
        """Test exception handling during conversion with retry."""
        converter = HTMLToMarkdownConverter()
        
        with patch.object(converter, '_select_conversion_method', return_value='native'), \
             patch.object(converter, '_convert_with_method', side_effect=[Exception("Test error"), True]) as mock_convert:
            
            result = await converter._convert_with_retry('/tmp', 'input.html', 'output.md')
            
            assert result == True
            # Should handle exception and try next method
            assert mock_convert.call_count == 2
    
    async def test_single_file_conversion(self):
        """Test converting a single file."""
        converter = HTMLToMarkdownConverter()
        
        with patch.object(converter, '_convert_with_retry', return_value=True) as mock_convert:
            result = await converter.convert('/tmp', 'input.html', 'output.md')
            
            assert result == True
            mock_convert.assert_called_once_with('/tmp', 'input.html', 'output.md')
    
    async def test_batch_conversion_success(self):
        """Test successful batch conversion of multiple files."""
        converter = HTMLToMarkdownConverter()
        conversions = [
            ConversionItem('file1.html', 'file1.md'),
            ConversionItem('file2.html', 'file2.md'),
            ConversionItem('file3.html', 'file3.md')
        ]
        
        with patch.object(converter, '_convert_with_retry', return_value=True):
            results = await converter.convert_batch('/tmp', conversions)
            
            assert len(results) == 3
            assert all(results)
    
    async def test_batch_conversion_partial_failure(self):
        """Test batch conversion with some files failing."""
        converter = HTMLToMarkdownConverter()
        conversions = [
            ConversionItem('file1.html', 'file1.md'),
            ConversionItem('file2.html', 'file2.md'),
            ConversionItem('file3.html', 'file3.md')
        ]
        
        # Second conversion fails
        with patch.object(converter, '_convert_with_retry', side_effect=[True, False, True]):
            results = await converter.convert_batch('/tmp', conversions)
            
            assert len(results) == 3
            assert results == [True, False, True]
    
    async def test_batch_conversion_with_concurrency_limit(self):
        """Test that batch conversion respects concurrency limits."""
        converter = HTMLToMarkdownConverter(max_concurrent=2)
        conversions = [ConversionItem(f'file{i}.html', f'file{i}.md') for i in range(5)]
        
        # Track concurrent executions
        concurrent_count = 0
        max_concurrent_seen = 0
        
        async def mock_convert_with_tracking(*args):
            nonlocal concurrent_count, max_concurrent_seen
            concurrent_count += 1
            max_concurrent_seen = max(max_concurrent_seen, concurrent_count)
            await asyncio.sleep(0.01)  # Simulate work
            concurrent_count -= 1
            return True
        
        with patch.object(converter, '_convert_with_retry', side_effect=mock_convert_with_tracking):
            results = await converter.convert_batch('/tmp', conversions)
            
            assert len(results) == 5
            assert all(results)
            assert max_concurrent_seen <= 2  # Should not exceed concurrency limit
    
    async def test_batch_conversion_empty_list(self):
        """Test batch conversion with empty conversion list."""
        converter = HTMLToMarkdownConverter()
        
        results = await converter.convert_batch('/tmp', [])
        assert results == []


@pytest.mark.unit
class TestConverterHelperMethods:
    """Test helper methods in HTMLToMarkdownConverter."""
    
    def test_get_simple_converter(self):
        """Test simple converter instantiation."""
        converter = HTMLToMarkdownConverter(quiet=True)
        
        simple_converter = converter._get_simple_converter()
        
        assert simple_converter is not None
        assert simple_converter.quiet == True
    
    def test_get_native_converter(self):
        """Test native converter instantiation."""
        converter = HTMLToMarkdownConverter(quiet=True, max_turns=5)
        
        native_converter = converter._get_native_converter()
        
        assert native_converter is not None
        assert native_converter.quiet == True
        assert native_converter.max_turns == 5


@pytest.mark.unit
class TestSDKPollutionPrevention:
    """Critical tests to ensure SDK pollution is prevented."""
    
    def test_no_claude_method_in_routing(self):
        """Test that 'claude' method is not available in routing logic."""
        converter = HTMLToMarkdownConverter()
        
        # Try to use 'claude' method directly - should raise error
        with pytest.raises(ValueError, match="Unknown conversion method: claude"):
            asyncio.run(converter._convert_with_method('claude', '/tmp', 'input.html', 'output.md'))
    
    def test_fallback_methods_exclude_claude(self):
        """Test that fallback logic doesn't include 'claude' method."""
        converter = HTMLToMarkdownConverter()
        
        # Check that the fallback methods dictionary doesn't contain 'claude'
        # This is an internal implementation detail, but critical for SDK pollution prevention
        with patch.object(converter, '_select_conversion_method', return_value='native'), \
             patch.object(converter, '_convert_with_method', return_value=False) as mock_convert:
            
            # This will try all fallback methods and we can verify none are 'claude'
            asyncio.run(converter._convert_with_retry('/tmp', 'input.html', 'output.md'))
            
            # Extract all methods that were tried
            methods_tried = [call[0][0] for call in mock_convert.call_args_list]
            
            # Ensure 'claude' was never tried as a fallback method
            assert 'claude' not in methods_tried
            
            # Should only try valid methods: native, chunked, simple
            valid_methods = {'native', 'simple'}  # chunked removed due to SDK pollution
            assert all(method in valid_methods for method in methods_tried)
    
    def test_medium_files_avoid_chunked_converter(self):
        """Test that medium files use simple converter to avoid SDK pollution from chunked."""
        converter = HTMLToMarkdownConverter()
        
        with patch('os.path.exists', return_value=True), \
             patch('os.path.getsize', return_value=200 * 1024):  # 200KB - medium file
            
            method = converter._select_conversion_method('/tmp', 'medium.html')
            
            # Critical: medium files should use 'simple' not 'chunked' to avoid SDK pollution
            assert method == 'simple'
            assert method != 'chunked'  # Explicitly verify chunked is avoided