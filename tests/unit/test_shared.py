#!/usr/bin/env python3
"""
Unit tests for shared components and utilities.
"""

import pytest
import tempfile
import yaml
from pathlib import Path
from src.download2md.shared import ConversionItem, load_conversions_from_yaml


@pytest.mark.unit
class TestConversionItem:
    """Test ConversionItem namedtuple."""
    
    def test_conversion_item_creation(self):
        """Test basic ConversionItem creation."""
        item = ConversionItem("input.html", "output.md")
        assert item.input_filename == "input.html"
        assert item.output_filename == "output.md"
    
    def test_conversion_item_named_parameters(self):
        """Test ConversionItem creation with named parameters."""
        item = ConversionItem(
            input_filename="test.html",
            output_filename="test.md"
        )
        assert item.input_filename == "test.html"
        assert item.output_filename == "test.md"
    
    def test_conversion_item_immutability(self):
        """Test that ConversionItem is immutable."""
        item = ConversionItem("input.html", "output.md")
        
        with pytest.raises(AttributeError):
            item.input_filename = "changed.html"
        
        with pytest.raises(AttributeError):
            item.output_filename = "changed.md"
    
    def test_conversion_item_tuple_behavior(self):
        """Test that ConversionItem behaves like a tuple."""
        item = ConversionItem("input.html", "output.md")
        
        # Test indexing
        assert item[0] == "input.html"
        assert item[1] == "output.md"
        
        # Test unpacking
        input_file, output_file = item
        assert input_file == "input.html"
        assert output_file == "output.md"
        
        # Test length
        assert len(item) == 2
    
    def test_conversion_item_equality(self):
        """Test ConversionItem equality comparison."""
        item1 = ConversionItem("input.html", "output.md")
        item2 = ConversionItem("input.html", "output.md")
        item3 = ConversionItem("different.html", "output.md")
        
        assert item1 == item2
        assert item1 != item3
        assert item2 != item3


@pytest.mark.unit
class TestLoadConversionsFromYaml:
    """Test YAML configuration loading functionality."""
    
    def test_load_basic_yaml_config(self, temp_dir):
        """Test loading a basic YAML configuration."""
        config_content = {
            'root_path': str(temp_dir),
            'conversions': [
                {'input_filename': 'test1.html', 'output_filename': 'test1.md'},
                {'input_filename': 'test2.html', 'output_filename': 'test2.md'}
            ]
        }
        
        config_file = temp_dir / "config.yaml"
        with open(config_file, 'w') as f:
            yaml.dump(config_content, f)
        
        root_path, conversions, config = load_conversions_from_yaml(str(config_file))
        
        assert root_path == str(temp_dir)
        assert len(conversions) == 2
        assert conversions[0].input_filename == 'test1.html'
        assert conversions[0].output_filename == 'test1.md'
        assert conversions[1].input_filename == 'test2.html'
        assert conversions[1].output_filename == 'test2.md'
    
    def test_load_yaml_with_config_options(self, temp_dir):
        """Test loading YAML with various configuration options."""
        config_content = {
            'root_path': str(temp_dir),
            'max_concurrent': 3,
            'conversion_strategy': 'chunked',
            'large_file_threshold_kb': 1000,
            'medium_file_threshold_kb': 200,
            'chunk_size_kb': 75,
            'chunk_overlap_kb': 10,
            'quiet': True,
            'conversions': [
                {'input_filename': 'test.html', 'output_filename': 'test.md'}
            ]
        }
        
        config_file = temp_dir / "config.yaml"
        with open(config_file, 'w') as f:
            yaml.dump(config_content, f)
        
        root_path, conversions, config = load_conversions_from_yaml(str(config_file))
        
        assert root_path == str(temp_dir)
        assert len(conversions) == 1
        assert config['max_concurrent'] == 3
        assert config['conversion_strategy'] == 'chunked'
        assert config['large_file_threshold_kb'] == 1000
        assert config['medium_file_threshold_kb'] == 200
        assert config['chunk_size_kb'] == 75
        assert config['chunk_overlap_kb'] == 10
        assert config['quiet'] == True
    
    def test_load_yaml_with_defaults(self, temp_dir):
        """Test that default values are applied when not specified."""
        config_content = {
            'root_path': str(temp_dir),
            'conversions': [
                {'input_filename': 'test.html', 'output_filename': 'test.md'}
            ]
        }
        
        config_file = temp_dir / "config.yaml"
        with open(config_file, 'w') as f:
            yaml.dump(config_content, f)
        
        root_path, conversions, config = load_conversions_from_yaml(str(config_file))
        
        # Check default values
        assert config['max_concurrent'] == 5
        assert config['conversion_strategy'] == 'auto'
        assert config['large_file_threshold_kb'] == 500
        assert config['medium_file_threshold_kb'] == 100
        assert config['chunk_size_kb'] == 50
        assert config['chunk_overlap_kb'] == 5
        assert config['quiet'] == False
    
    def test_load_yaml_relative_path(self, temp_dir):
        """Test loading YAML with relative root path."""
        # Create subdirectory
        subdir = temp_dir / "subdir"
        subdir.mkdir()
        
        config_content = {
            'root_path': './data',  # Relative path
            'conversions': [
                {'input_filename': 'test.html', 'output_filename': 'test.md'}
            ]
        }
        
        config_file = temp_dir / "config.yaml"
        with open(config_file, 'w') as f:
            yaml.dump(config_content, f)
        
        root_path, conversions, config = load_conversions_from_yaml(str(config_file))
        
        # Should resolve relative to YAML file directory
        expected_path = temp_dir / "data"
        assert root_path == str(expected_path)
    
    def test_load_yaml_missing_file(self):
        """Test error handling for missing YAML file."""
        with pytest.raises(ValueError, match="YAML file not found"):
            load_conversions_from_yaml("non_existent_file.yaml")
    
    def test_load_yaml_missing_root_path(self, temp_dir):
        """Test error handling for missing root_path."""
        config_content = {
            'conversions': [
                {'input_filename': 'test.html', 'output_filename': 'test.md'}
            ]
        }
        
        config_file = temp_dir / "config.yaml"
        with open(config_file, 'w') as f:
            yaml.dump(config_content, f)
        
        with pytest.raises(ValueError, match="YAML file must contain a 'root_path' key"):
            load_conversions_from_yaml(str(config_file))
    
    def test_load_yaml_missing_conversions(self, temp_dir):
        """Test error handling for missing conversions."""
        config_content = {
            'root_path': str(temp_dir)
        }
        
        config_file = temp_dir / "config.yaml"
        with open(config_file, 'w') as f:
            yaml.dump(config_content, f)
        
        with pytest.raises(ValueError, match="YAML file must contain a 'conversions' key"):
            load_conversions_from_yaml(str(config_file))
    
    def test_load_yaml_invalid_conversion_format(self, temp_dir):
        """Test error handling for invalid conversion format."""
        config_content = {
            'root_path': str(temp_dir),
            'conversions': [
                {'input_filename': 'test.html'}  # Missing output_filename
            ]
        }
        
        config_file = temp_dir / "config.yaml"
        with open(config_file, 'w') as f:
            yaml.dump(config_content, f)
        
        with pytest.raises(ValueError, match="must have 'input_filename' and 'output_filename' keys"):
            load_conversions_from_yaml(str(config_file))
    
    def test_load_yaml_invalid_yaml_format(self, temp_dir):
        """Test error handling for invalid YAML format."""
        config_file = temp_dir / "invalid.yaml"
        with open(config_file, 'w') as f:
            f.write("invalid: yaml: content: [\n")  # Malformed YAML
        
        with pytest.raises(ValueError, match="Invalid YAML format"):
            load_conversions_from_yaml(str(config_file))