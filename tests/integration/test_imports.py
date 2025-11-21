#!/usr/bin/env python3
"""
Test for import resolution and circular dependency issues.
"""

import pytest
import importlib
import sys
from pathlib import Path


@pytest.mark.import_test
class TestImports:
    """Test that all modules can be imported without circular dependency errors."""
    
    def test_import_converter_module(self):
        """Test that converter module can be imported."""
        try:
            import src.download2md.converter
            assert src.download2md.converter is not None
        except ImportError as e:
            pytest.fail(f"Failed to import converter module: {e}")
    
    def test_import_simple_converter_module(self):
        """Test that simple_converter module can be imported."""
        try:
            import src.download2md.simple_converter
            assert src.download2md.simple_converter is not None
        except ImportError as e:
            pytest.fail(f"Failed to import simple_converter module: {e}")
    
    def test_import_chunked_converter_module(self):
        """Test that chunked_converter module can be imported."""
        try:
            import src.download2md.chunked_converter
            assert src.download2md.chunked_converter is not None
        except ImportError as e:
            # chunked_converter requires claude_code_sdk, so we allow ImportError for missing SDK
            if "claude-code-sdk" in str(e) or "claude_code_sdk" in str(e):
                pytest.skip(f"Skipping due to missing claude-code-sdk: {e}")
            else:
                pytest.fail(f"Failed to import chunked_converter module: {e}")
    
    def test_no_circular_imports(self):
        """Test that importing all modules together doesn't cause circular import errors."""
        # Clear any previously imported modules
        modules_to_clear = [
            'src.download2md.converter',
            'src.download2md.simple_converter', 
            'src.download2md.chunked_converter'
        ]
        
        for module in modules_to_clear:
            if module in sys.modules:
                del sys.modules[module]
        
        try:
            # Import all modules in different orders to check for circular dependencies
            import src.download2md.converter
            import src.download2md.simple_converter
            
            # Try importing in reverse order after clearing
            for module in modules_to_clear:
                if module in sys.modules:
                    del sys.modules[module]
            
            import src.download2md.simple_converter
            import src.download2md.converter
            
        except ImportError as e:
            if "claude-code-sdk" in str(e) or "claude_code_sdk" in str(e):
                pytest.skip(f"Skipping due to missing claude-code-sdk: {e}")
            else:
                pytest.fail(f"Circular import detected: {e}")
    
    def test_conversion_item_accessibility(self):
        """Test that ConversionItem is accessible from appropriate modules."""
        try:
            from src.download2md.shared import ConversionItem
            assert ConversionItem is not None
            
            # Test that we can create a ConversionItem
            item = ConversionItem(input_filename="test.html", output_filename="test.md")
            assert item.input_filename == "test.html"
            assert item.output_filename == "test.md"
            
        except ImportError as e:
            pytest.fail(f"Failed to import ConversionItem: {e}")
    
    def test_load_conversions_from_yaml_accessibility(self):
        """Test that load_conversions_from_yaml is accessible."""
        try:
            from src.download2md.shared import load_conversions_from_yaml
            assert load_conversions_from_yaml is not None
            
        except ImportError as e:
            pytest.fail(f"Failed to import load_conversions_from_yaml: {e}")
    
    def test_module_independence(self):
        """Test that modules can be imported independently."""
        modules = [
            'src.download2md.converter',
            'src.download2md.simple_converter'
        ]
        
        for module_name in modules:
            # Clear module cache
            if module_name in sys.modules:
                del sys.modules[module_name]
            
            try:
                module = importlib.import_module(module_name)
                assert module is not None
                
                # Clear it again for next iteration
                if module_name in sys.modules:
                    del sys.modules[module_name]
                    
            except ImportError as e:
                if "claude-code-sdk" in str(e):
                    continue  # Skip modules that require Claude SDK
                pytest.fail(f"Module {module_name} cannot be imported independently: {e}")


@pytest.mark.import_test  
class TestSharedComponents:
    """Test shared components that might cause circular imports."""
    
    def test_conversion_item_namedtuple(self):
        """Test ConversionItem namedtuple functionality."""
        from src.download2md.shared import ConversionItem
        
        # Test creation
        item = ConversionItem("input.html", "output.md")
        assert item.input_filename == "input.html"
        assert item.output_filename == "output.md"
        
        # Test named access
        item2 = ConversionItem(input_filename="test.html", output_filename="test.md")
        assert item2.input_filename == "test.html"
        assert item2.output_filename == "test.md"
        
        # Test immutability
        with pytest.raises(AttributeError):
            item.input_filename = "changed.html"
    
    def test_yaml_loading_function_exists(self):
        """Test that YAML loading function exists and is callable."""
        from src.download2md.shared import load_conversions_from_yaml
        
        assert callable(load_conversions_from_yaml)
        
        # Test with non-existent file to check error handling
        with pytest.raises((ValueError, FileNotFoundError)):
            load_conversions_from_yaml("non_existent_file.yaml")