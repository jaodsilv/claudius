#!/usr/bin/env python3
"""
Shared components for HTML to Markdown conversion.

This module contains shared types and utility functions used across
the conversion modules to avoid circular import dependencies.
"""

import os
import yaml
from typing import List, Tuple
from collections import namedtuple

# Shared type for conversion items
ConversionItem = namedtuple('ConversionItem', ['input_filename', 'output_filename'])


def load_conversions_from_yaml(yaml_file_path: str) -> Tuple[str, List[ConversionItem], dict]:
    """Load conversion configuration from a YAML file.

    Expected YAML format:
    root_path: "./docs"
    max_concurrent: 3  # Optional, defaults to 5
    conversion_strategy: "auto"  # auto, simple, chunked, native
    large_file_threshold_kb: 500  # Files above this use simple converter
    medium_file_threshold_kb: 100  # Files above this use chunked converter  
    chunk_size_kb: 50  # Chunk size for chunked converter
    chunk_overlap_kb: 5  # Overlap for chunked converter
    conversions:
      - input_filename: "page1.html"
        output_filename: "page1.md"
      - input_filename: "subdir/page2.html"
        output_filename: "subdir/page2.md"
    
    Returns:
        Tuple of (root_path, conversions_list, config_dict)
    """
    try:
        with open(yaml_file_path, 'r') as f:
            config = yaml.safe_load(f)

        if 'root_path' not in config:
            raise ValueError("YAML file must contain a 'root_path' key")
        if 'conversions' not in config:
            raise ValueError("YAML file must contain a 'conversions' key")

        yaml_dir = os.path.dirname(os.path.abspath(yaml_file_path))
        root_path = config.get('root_path', yaml_dir)
        
        # Extract configuration parameters
        converter_config = {
            'max_concurrent': config.get('max_concurrent', 5),
            'conversion_strategy': config.get('conversion_strategy', 'auto'),
            'large_file_threshold_kb': config.get('large_file_threshold_kb', 500),
            'medium_file_threshold_kb': config.get('medium_file_threshold_kb', 100),
            'chunk_size_kb': config.get('chunk_size_kb', 50),
            'chunk_overlap_kb': config.get('chunk_overlap_kb', 5),
            'quiet': config.get('quiet', False)
        }

        # Make relative paths relative to the YAML file directory
        if not os.path.isabs(root_path):
            root_path = os.path.join(yaml_dir, root_path)

        conversions = []
        for item in config['conversions']:
            if 'input_filename' not in item or 'output_filename' not in item:
                raise ValueError("Each conversion item must have 'input_filename' and 'output_filename' keys")
            conversions.append(ConversionItem(input_filename=item['input_filename'], output_filename=item['output_filename']))

        return root_path, conversions, converter_config
    except yaml.YAMLError as e:
        raise ValueError(f"Invalid YAML format: {e}")
    except FileNotFoundError:
        raise ValueError(f"YAML file not found: {yaml_file_path}")