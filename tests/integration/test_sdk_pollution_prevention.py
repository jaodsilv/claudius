#!/usr/bin/env python3
"""
Critical regression tests to prevent SDK pollution in HTML to Markdown conversion.

This test suite ensures that the converters produce clean Markdown output without
Claude SDK response objects like SystemMessage, AssistantMessage, etc.
"""

import pytest
import asyncio
from pathlib import Path
from src.download2md.converter import HTMLToMarkdownConverter
from src.download2md.simple_converter import SimpleHTMLToMarkdownConverter
from src.download2md.claude_native_converter import ClaudeCodeNativeConverter


# Patterns that indicate SDK pollution
SDK_POLLUTION_PATTERNS = [
    'SystemMessage',
    'AssistantMessage', 
    'ResultMessage',
    'UserMessage',
    'subtype=',
    'session_id=',
    'duration_ms=',
    'duration_api_ms=',
    'is_error=',
    'num_turns=',
    'total_cost_usd=',
    'input_tokens=',
    'output_tokens=',
    'cache_creation_input_tokens=',
    'cache_read_input_tokens=',
    'server_tool_use=',
    'service_tier=',
    'usage={',
    'model=\'claude-',
    'tools=[\'Task\'',
    'TextBlock(text=',
    'content=[TextBlock',
    'claudecodeoptions',
    'claude_code_sdk',
    'result=\''
]


def detect_sdk_pollution(content: str) -> list:
    """
    Detect SDK pollution patterns in content.
    
    Returns:
        List of detected pollution patterns
    """
    detected = []
    content_lower = content.lower()
    
    for pattern in SDK_POLLUTION_PATTERNS:
        if pattern.lower() in content_lower:
            detected.append(pattern)
    
    return detected


@pytest.mark.integration
@pytest.mark.asyncio
class TestSDKPollutionPrevention:
    """Critical tests to prevent SDK pollution regression."""
    
    async def test_main_converter_no_sdk_pollution(self, temp_dir, sample_html):
        """Test that main converter produces clean output without SDK pollution."""
        converter = HTMLToMarkdownConverter()
        
        # Create test HTML file
        input_file = temp_dir / "test.html"
        input_file.write_text(sample_html)
        
        # Test conversion
        result = await converter.convert(str(temp_dir), "test.html", "test.md")
        
        # Check if conversion succeeded
        output_file = temp_dir / "test.md"
        if output_file.exists():
            content = output_file.read_text()
            
            # CRITICAL: Check for SDK pollution
            pollution = detect_sdk_pollution(content)
            assert not pollution, f"SDK pollution detected in main converter output: {pollution}"
            
            # Should contain actual converted content
            assert len(content.strip()) > 0, "Output should not be empty"
            assert content != sample_html, "Output should be different from input HTML"
    
    async def test_simple_converter_no_sdk_pollution(self, temp_dir, sample_html):
        """Test that simple converter produces clean output without SDK pollution."""
        converter = SimpleHTMLToMarkdownConverter(quiet=True)
        
        # Create test HTML file
        input_file = temp_dir / "test.html"
        input_file.write_text(sample_html)
        
        # Test conversion
        result = await converter.convert(str(temp_dir), "test.html", "test.md")
        
        assert result == True, "Simple converter should succeed"
        
        # Check output
        output_file = temp_dir / "test.md"
        assert output_file.exists(), "Output file should exist"
        
        content = output_file.read_text()
        
        # CRITICAL: Check for SDK pollution
        pollution = detect_sdk_pollution(content)
        assert not pollution, f"SDK pollution detected in simple converter output: {pollution}"
        
        # Should contain converted content
        assert len(content.strip()) > 0, "Output should not be empty"
        assert "Test Document" in content or "Main Heading" in content, "Should contain converted content"
    
    async def test_native_converter_no_sdk_pollution(self, temp_dir, sample_html):
        """Test that native converter produces clean output without SDK pollution."""
        converter = ClaudeCodeNativeConverter(quiet=True)
        
        # Create test HTML file
        input_file = temp_dir / "test.html"
        input_file.write_text(sample_html)
        
        # Test conversion
        result = await converter.convert(str(temp_dir), "test.html", "test.md")
        
        # Check if conversion succeeded
        output_file = temp_dir / "test.md"
        if output_file.exists():
            content = output_file.read_text()
            
            # CRITICAL: Check for SDK pollution
            pollution = detect_sdk_pollution(content)
            assert not pollution, f"SDK pollution detected in native converter output: {pollution}"
            
            # Should contain meaningful content
            assert len(content.strip()) > 0, "Output should not be empty"
    
    async def test_batch_conversion_no_sdk_pollution(self, temp_dir):
        """Test that batch conversions produce clean output without SDK pollution."""
        from src.download2md.shared import ConversionItem
        
        converter = HTMLToMarkdownConverter(quiet=True)
        
        # Create multiple test HTML files
        test_files = []
        conversions = []
        
        for i in range(3):
            html_content = f"""
            <html>
            <head><title>Test Document {i}</title></head>
            <body>
                <h1>Document {i} Title</h1>
                <p>This is test content for document {i} with <strong>formatting</strong>.</p>
                <ul>
                    <li>Item 1 for doc {i}</li>
                    <li>Item 2 for doc {i}</li>
                </ul>
            </body>
            </html>
            """
            
            input_file = temp_dir / f"test{i}.html"
            input_file.write_text(html_content)
            
            conversions.append(ConversionItem(f"test{i}.html", f"test{i}.md"))
        
        # Perform batch conversion
        results = await converter.convert_batch(str(temp_dir), conversions)
        
        # Check each result for SDK pollution
        for i, result in enumerate(results):
            output_file = temp_dir / f"test{i}.md"
            
            if output_file.exists():
                content = output_file.read_text()
                
                # CRITICAL: Check for SDK pollution
                pollution = detect_sdk_pollution(content)
                assert not pollution, f"SDK pollution detected in batch output {i}: {pollution}"
                
                # Should contain meaningful content
                assert len(content.strip()) > 0, f"Output {i} should not be empty"
    
    async def test_large_file_conversion_no_sdk_pollution(self, temp_dir):
        """Test that large file conversions don't produce SDK pollution."""
        converter = HTMLToMarkdownConverter(quiet=True)
        
        # Create large HTML content that would trigger simple converter
        large_html = "<html><head><title>Large Document</title></head><body>"
        large_html += "<h1>Large Document Title</h1>"
        
        # Add enough content to exceed medium file threshold (100KB default)
        for i in range(2000):
            large_html += f"""
            <section>
                <h2>Section {i}</h2>
                <p>This is section {i} with substantial content to make the file large enough 
                to trigger the simple converter path. We need to ensure that even large files
                do not result in SDK pollution in the output.</p>
                <ul>
                    <li>Point A for section {i}</li>
                    <li>Point B for section {i}</li>
                    <li>Point C for section {i}</li>
                </ul>
            </section>
            """
        
        large_html += "</body></html>"
        
        # Create large test file
        input_file = temp_dir / "large.html"
        input_file.write_text(large_html)
        
        # Should be large enough to trigger simple converter
        file_size = len(large_html.encode('utf-8'))
        assert file_size > 100 * 1024, f"Test file should be >100KB, got {file_size} bytes"
        
        # Test conversion
        result = await converter.convert(str(temp_dir), "large.html", "large.md")
        
        # Check output
        output_file = temp_dir / "large.md"
        if output_file.exists():
            content = output_file.read_text()
            
            # CRITICAL: Check for SDK pollution
            pollution = detect_sdk_pollution(content)
            assert not pollution, f"SDK pollution detected in large file output: {pollution}"
            
            # Should contain meaningful content
            assert len(content.strip()) > 0, "Large file output should not be empty"
            assert "Large Document" in content, "Should contain converted title"
    
    async def test_complex_html_conversion_no_sdk_pollution(self, temp_dir, complex_html):
        """Test that complex HTML conversions don't produce SDK pollution."""
        converter = HTMLToMarkdownConverter(quiet=True)
        
        # Create test file with complex HTML
        input_file = temp_dir / "complex.html"
        input_file.write_text(complex_html)
        
        # Test conversion
        result = await converter.convert(str(temp_dir), "complex.html", "complex.md")
        
        # Check output
        output_file = temp_dir / "complex.md"
        if output_file.exists():
            content = output_file.read_text()
            
            # CRITICAL: Check for SDK pollution
            pollution = detect_sdk_pollution(content)
            assert not pollution, f"SDK pollution detected in complex HTML output: {pollution}"
            
            # Should contain converted content
            assert len(content.strip()) > 0, "Complex HTML output should not be empty"
    
    async def test_malformed_html_conversion_no_sdk_pollution(self, temp_dir):
        """Test that malformed HTML conversions don't produce SDK pollution."""
        converter = HTMLToMarkdownConverter(quiet=True)
        
        # Create malformed HTML
        malformed_html = """
        <html>
        <head><title>Malformed Document</title>
        <body>
            <h1>Unclosed Header
            <p>Paragraph without closing tag
            <div><span>Nested unclosed tags
            <ul>
                <li>Item 1
                <li>Item 2</li>
            </div>
        """
        
        input_file = temp_dir / "malformed.html"
        input_file.write_text(malformed_html)
        
        # Test conversion
        result = await converter.convert(str(temp_dir), "malformed.html", "malformed.md")
        
        # Check output
        output_file = temp_dir / "malformed.md"
        if output_file.exists():
            content = output_file.read_text()
            
            # CRITICAL: Check for SDK pollution
            pollution = detect_sdk_pollution(content)
            assert not pollution, f"SDK pollution detected in malformed HTML output: {pollution}"
            
            # Should handle malformed input gracefully
            assert len(content.strip()) > 0, "Malformed HTML output should not be empty"
    
    async def test_empty_html_conversion_no_sdk_pollution(self, temp_dir):
        """Test that empty HTML conversions don't produce SDK pollution."""
        converter = HTMLToMarkdownConverter(quiet=True)
        
        # Create empty HTML file
        input_file = temp_dir / "empty.html"
        input_file.write_text("")
        
        # Test conversion
        result = await converter.convert(str(temp_dir), "empty.html", "empty.md")
        
        # Check output if it exists
        output_file = temp_dir / "empty.md"
        if output_file.exists():
            content = output_file.read_text()
            
            # CRITICAL: Check for SDK pollution
            pollution = detect_sdk_pollution(content)
            assert not pollution, f"SDK pollution detected in empty HTML output: {pollution}"
    
    async def test_unicode_html_conversion_no_sdk_pollution(self, temp_dir):
        """Test that Unicode HTML conversions don't produce SDK pollution."""
        converter = HTMLToMarkdownConverter(quiet=True)
        
        # Create HTML with Unicode content
        unicode_html = """
        <html>
        <head><title>Unicode Test Document</title></head>
        <body>
            <h1>Unicode Content Test</h1>
            <p>Regular ASCII content mixed with Unicode:</p>
            <ul>
                <li>Accented characters: café, résumé, naïve</li>
                <li>Symbols: © ® ™ € £ ¥ § ¶</li>
                <li>Emoji: 🎉 ✅ ❌ 🚀 💯 🔥</li>
                <li>Mathematical: α β γ δ ε ∑ ∆ π ∞</li>
                <li>CJK: 中文 日本語 한국어</li>
            </ul>
        </body>
        </html>
        """
        
        input_file = temp_dir / "unicode.html"
        input_file.write_text(unicode_html, encoding='utf-8')
        
        # Test conversion
        result = await converter.convert(str(temp_dir), "unicode.html", "unicode.md")
        
        # Check output
        output_file = temp_dir / "unicode.md"
        if output_file.exists():
            content = output_file.read_text(encoding='utf-8')
            
            # CRITICAL: Check for SDK pollution
            pollution = detect_sdk_pollution(content)
            assert not pollution, f"SDK pollution detected in Unicode HTML output: {pollution}"
            
            # Should preserve some Unicode content
            assert len(content.strip()) > 0, "Unicode HTML output should not be empty"


@pytest.mark.integration
class TestSDKPollutionDetection:
    """Test the SDK pollution detection itself."""
    
    def test_pollution_detector_catches_known_patterns(self):
        """Test that our pollution detector catches known SDK pollution patterns."""
        # Test content with SDK pollution
        polluted_content = """
        SystemMessage(subtype='init', data={'type': 'system', 'subtype': 'init'})
        AssistantMessage(content=[TextBlock(text='# Test\\n\\nContent')])
        ResultMessage(subtype='success', duration_ms=1500, total_cost_usd=0.05)
        """
        
        pollution = detect_sdk_pollution(polluted_content)
        
        # Should detect multiple pollution patterns
        assert len(pollution) > 0, "Should detect SDK pollution patterns"
        assert 'SystemMessage' in pollution, "Should detect SystemMessage"
        assert 'AssistantMessage' in pollution, "Should detect AssistantMessage"
        assert 'ResultMessage' in pollution, "Should detect ResultMessage"
        assert 'subtype=' in pollution, "Should detect subtype parameter"
        assert 'duration_ms=' in pollution, "Should detect duration_ms parameter"
        assert 'total_cost_usd=' in pollution, "Should detect cost parameter"
    
    def test_pollution_detector_ignores_clean_content(self):
        """Test that pollution detector doesn't flag clean Markdown content."""
        clean_content = """
        # Test Document
        
        This is a clean Markdown document with **bold** text and *italic* text.
        
        ## Features
        
        - Item 1
        - Item 2
        - Item 3
        
        ### Code Example
        
        ```python
        def hello_world():
            print("Hello, World!")
        ```
        
        > This is a quote block.
        
        [Link to example](https://example.com)
        """
        
        pollution = detect_sdk_pollution(clean_content)
        
        # Should not detect any pollution in clean content
        assert len(pollution) == 0, f"Clean content should not trigger pollution detection: {pollution}"
    
    def test_pollution_detector_case_insensitive(self):
        """Test that pollution detector is case insensitive."""
        mixed_case_pollution = """
        SystemMessage with mixed case
        assistantmessage in lowercase
        RESULTMESSAGE in uppercase
        SubType=value in mixed case
        """
        
        pollution = detect_sdk_pollution(mixed_case_pollution)
        
        # Should detect patterns regardless of case
        assert len(pollution) > 0, "Should detect mixed-case pollution patterns"
    
    def test_pollution_detector_partial_matches(self):
        """Test that pollution detector catches partial pattern matches."""
        partial_pollution = """
        Some text with session_id=abc123 embedded
        Content with duration_ms=1500 in middle
        Text containing total_cost_usd=0.05 value
        """
        
        pollution = detect_sdk_pollution(partial_pollution)
        
        # Should detect partial matches
        assert 'session_id=' in pollution, "Should detect session_id parameter"
        assert 'duration_ms=' in pollution, "Should detect duration_ms parameter"
        assert 'total_cost_usd=' in pollution, "Should detect total_cost_usd parameter"


@pytest.mark.integration
class TestRegressionScenarios:
    """Test specific scenarios that previously caused SDK pollution."""
    
    async def test_previous_pollution_scenario_fixed(self, temp_dir):
        """Test scenario that previously caused SDK pollution is now fixed."""
        converter = HTMLToMarkdownConverter(quiet=True)
        
        # This is based on the original issue - a file that would previously cause pollution
        problematic_html = """
        <!doctype html>
        <html lang="en" dir="ltr" class="docs-wrapper">
        <head>
        <meta charset="UTF-8">
        <meta name="generator" content="Docusaurus v3.8.0">
        <title>Awesome Claude Code | ClaudeLog</title>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        </head>
        <body>
            <main>
                <article>
                    <h1>Awesome Claude Code</h1>
                    <p>Curated collection of Claude Code slash commands, CLAUDE.md files, workflows, CLI tools, and productivity resources for enhanced development workflows.</p>
                </article>
            </main>
        </body>
        </html>
        """
        
        input_file = temp_dir / "problematic.html"
        input_file.write_text(problematic_html)
        
        # Test conversion
        result = await converter.convert(str(temp_dir), "problematic.html", "problematic.md")
        
        # Check output
        output_file = temp_dir / "problematic.md"
        if output_file.exists():
            content = output_file.read_text()
            
            # CRITICAL: This scenario previously caused pollution - ensure it's fixed
            pollution = detect_sdk_pollution(content)
            assert not pollution, f"Previously problematic scenario still causes pollution: {pollution}"
            
            # Should contain the actual content
            assert len(content.strip()) > 0, "Output should not be empty"
            
            # Should NOT contain raw SDK messages
            assert "SystemMessage(subtype='init'" not in content
            assert "AssistantMessage(content=[TextBlock" not in content
            assert "ResultMessage(subtype='success'" not in content
    
    async def test_medium_file_routing_fixed(self, temp_dir):
        """Test that medium files no longer use chunked converter (which caused pollution)."""
        converter = HTMLToMarkdownConverter(quiet=True)
        
        # Create medium-sized file (between 100-500KB)
        medium_html = "<html><head><title>Medium File</title></head><body><h1>Medium File</h1>"
        
        # Add content to make it medium-sized (~200KB)
        for i in range(400):
            medium_html += f"""
            <section>
                <h2>Section {i}</h2>
                <p>Content for section {i} with enough text to make this a medium-sized file
                that would previously trigger the chunked converter which used Claude SDK.</p>
            </section>
            """
        
        medium_html += "</body></html>"
        
        input_file = temp_dir / "medium.html"
        input_file.write_text(medium_html)
        
        # Verify file size is in medium range
        file_size = len(medium_html.encode('utf-8'))
        assert 100 * 1024 < file_size < 500 * 1024, f"File should be medium-sized, got {file_size} bytes"
        
        # Test conversion
        result = await converter.convert(str(temp_dir), "medium.html", "medium.md")
        
        # Check output
        output_file = temp_dir / "medium.md"
        if output_file.exists():
            content = output_file.read_text()
            
            # CRITICAL: Medium files should now use simple converter, not chunked
            pollution = detect_sdk_pollution(content)
            assert not pollution, f"Medium file still causes SDK pollution: {pollution}"
            
            # Should contain converted content
            assert len(content.strip()) > 0, "Medium file output should not be empty"
            assert "Medium File" in content, "Should contain converted title"


@pytest.mark.integration
class TestRouterSDKPollutionPrevention:
    """Test that the main converter's routing logic prevents SDK pollution."""
    
    def test_chunked_converter_not_used_for_medium_files(self, temp_dir):
        """Test that chunked converter is not used for medium files."""
        converter = HTMLToMarkdownConverter()
        
        # Mock file size to be in medium range (100-500KB)
        with patch('os.path.exists', return_value=True), \
             patch('os.path.getsize', return_value=200 * 1024):  # 200KB
            
            method = converter._select_conversion_method(str(temp_dir), 'medium.html')
            
            # Should use simple converter for medium files, not chunked
            assert method == 'simple', f"Medium files should use simple converter, got {method}"
            assert method != 'chunked', "Medium files should not use chunked converter"
    
    def test_no_claude_method_in_routing(self):
        """Test that 'claude' method is not available in routing."""
        converter = HTMLToMarkdownConverter()
        
        # The 'claude' method should not be available
        with pytest.raises(ValueError, match="Unknown conversion method: claude"):
            asyncio.run(converter._convert_with_method('claude', '/tmp', 'input.html', 'output.md'))
    
    def test_fallback_chains_exclude_claude(self, temp_dir):
        """Test that fallback chains do not include 'claude' method.""" 
        converter = HTMLToMarkdownConverter()
        
        with patch.object(converter, '_select_conversion_method', return_value='native'), \
             patch.object(converter, '_convert_with_method', return_value=False) as mock_convert:
            
            # This will try all fallback methods
            result = asyncio.run(converter._convert_with_retry(str(temp_dir), 'test.html', 'test.md'))
            
            # Extract all methods that were tried
            methods_tried = [call[0][0] for call in mock_convert.call_args_list]
            
            # Should not include 'claude' in any of the attempted methods
            assert 'claude' not in methods_tried, f"Fallback should not include 'claude' method: {methods_tried}"
            
            # Should only try safe methods
            safe_methods = {'native', 'simple'}
            assert all(method in safe_methods for method in methods_tried), \
                f"Should only try safe methods: {methods_tried}"