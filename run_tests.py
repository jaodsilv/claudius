#!/usr/bin/env python3
"""
Simple test runner for the project when pytest is not available.
"""

import sys
import traceback
from pathlib import Path

# Add project to Python path
sys.path.insert(0, str(Path(__file__).parent))

def test_imports():
    """Test that all modules can be imported without circular dependencies."""
    print("=== Testing Imports ===")
    
    try:
        from src.download2md.shared import ConversionItem, load_conversions_from_yaml
        print("✓ shared module imports successful")
    except Exception as e:
        print(f"✗ shared module import failed: {e}")
        return False
    
    try:
        from src.download2md.simple_converter import SimpleHTMLToMarkdownConverter
        print("✓ simple_converter imports successful")
    except Exception as e:
        print(f"✗ simple_converter import failed: {e}")
        return False
    
    try:
        from src.download2md.chunked_converter import ChunkedHTMLToMarkdownConverter
        print("✓ chunked_converter imports successful")
    except Exception as e:
        if "claude-code-sdk" in str(e):
            print("⚠ chunked_converter import skipped (missing claude-code-sdk)")
        else:
            print(f"✗ chunked_converter import failed: {e}")
            return False
    
    try:
        from src.download2md.converter import HTMLToMarkdownConverter
        print("✓ main converter imports successful")
    except Exception as e:
        if "claude-code-sdk" in str(e):
            print("⚠ main converter import skipped (missing claude-code-sdk)")
        else:
            print(f"✗ main converter import failed: {e}")
            return False
    
    return True

def test_backward_compatibility():
    """Test that backward compatibility is maintained."""
    print("\n=== Testing Backward Compatibility ===")
    
    try:
        # These should work for backward compatibility
        from src.download2md.converter import ConversionItem
        from src.download2md.converter import load_conversions_from_yaml
        print("✓ backward compatible imports successful")
    except Exception as e:
        print(f"✗ backward compatibility broken: {e}")
        return False
    
    return True

def test_basic_functionality():
    """Test basic functionality of the converters."""
    print("\n=== Testing Basic Functionality ===")
    
    try:
        from src.download2md.shared import ConversionItem
        from src.download2md.simple_converter import SimpleHTMLToMarkdownConverter
        
        # Test ConversionItem
        item = ConversionItem("test.html", "test.md")
        assert item.input_filename == "test.html"
        assert item.output_filename == "test.md"
        print("✓ ConversionItem functionality works")
        
        # Test SimpleHTMLToMarkdownConverter
        converter = SimpleHTMLToMarkdownConverter(quiet=True)
        html = '<h1>Test</h1><p>Hello <strong>world</strong>!</p>'
        markdown = converter.convert_html_to_markdown(html)
        assert len(markdown) > 0
        assert "Test" in markdown
        print("✓ Simple converter functionality works")
        
        return True
        
    except Exception as e:
        print(f"✗ basic functionality test failed: {e}")
        traceback.print_exc()
        return False

def main():
    """Run all tests."""
    print("Running basic test suite for HTML to Markdown converter\n")
    
    all_passed = True
    
    all_passed &= test_imports()
    all_passed &= test_backward_compatibility()
    all_passed &= test_basic_functionality()
    
    print("\n" + "="*50)
    if all_passed:
        print("🎉 All tests passed!")
        return 0
    else:
        print("❌ Some tests failed!")
        return 1

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)