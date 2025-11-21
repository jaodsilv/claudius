#!/usr/bin/env python3
"""
Integrated Download-to-Markdown Pipeline using Claude Code SDK.

This module provides a comprehensive OOP-based pipeline that integrates downloading,
HTML-to-Markdown conversion, and verification into a single workflow. It supports
both single-item processing and batch operations with YAML configuration.
"""

import asyncio
import glob
import os
import yaml
from collections import namedtuple
from typing import Dict, List, Optional, Tuple, Union
from urllib.parse import urlparse

from .downloader import DownloadManager, DownloadItem
from .converter import HTMLToMarkdownConverter, ConversionItem
from .verifier import ConversionVerifier, VerificationItem

# Data transfer objects for pipeline operations
PipelineItem = namedtuple('PipelineItem', ['url', 'download_filename', 'converted_filename'])
PipelineResult = namedtuple('PipelineResult', ['download_success', 'conversion_success', 'verification_result'])


class Download2MarkdownPipeline:
    """
    Integrated pipeline for downloading URLs and converting them to Markdown.
    
    This class orchestrates the entire process from downloading HTML content
    to converting it to Markdown and optionally verifying the conversion quality.
    """
    
    def __init__(self, 
                 max_download_attempts: int = 5,
                 skip_existing: bool = False,
                 verify_conversions: bool = True):
        """
        Initialize the pipeline with configuration options.
        
        Args:
            max_download_attempts: Maximum retry attempts for downloads
            skip_existing: Skip downloads if files already exist
            verify_conversions: Whether to verify conversion quality
        """
        self.max_download_attempts = max_download_attempts
        self.skip_existing = skip_existing
        self.verify_conversions = verify_conversions
        
        # Initialize component classes
        self.download_manager = DownloadManager(
            max_attempts=max_download_attempts,
            skip_existing=skip_existing
        )
        self.converter = HTMLToMarkdownConverter()
        self.verifier = ConversionVerifier() if verify_conversions else None
    
    def _resolve_filename(self, root_path: str, filename: str) -> str:
        """
        Resolve filename by checking for extension and finding matching files.
        
        Args:
            root_path: The base directory path
            filename: The filename to resolve
            
        Returns:
            The resolved filename (with extension if found)
        """
        # Check if filename already has an extension
        name, ext = os.path.splitext(filename)
        if ext:
            # Filename already has extension, return as-is
            return filename
        
        # No extension - search for files matching the base filename
        pattern = os.path.join(root_path, f"{filename}.*")
        matches = glob.glob(pattern)
        
        if matches:
            # Return just the filename part of the first match
            return os.path.basename(matches[0])
        
        # No matches found, return original filename
        return filename
    
    def _create_download_items(self, output_root: str, pipeline_items: List[PipelineItem]) -> List[DownloadItem]:
        """
        Convert PipelineItems to DownloadItems for the download manager.
        
        Args:
            output_root: Root directory for all operations
            pipeline_items: List of pipeline items to process
            
        Returns:
            List of DownloadItem objects for downloading
        """
        return [
            DownloadItem(url=item.url, filename=item.download_filename)
            for item in pipeline_items
        ]
    
    def _create_conversion_items(self, pipeline_items: List[PipelineItem]) -> List[ConversionItem]:
        """
        Convert PipelineItems to ConversionItems for the converter.
        
        Args:
            pipeline_items: List of pipeline items to process
            
        Returns:
            List of ConversionItem objects for conversion
        """
        return [
            ConversionItem(
                input_filename=item.download_filename,
                output_filename=item.converted_filename
            )
            for item in pipeline_items
        ]
    
    def _create_verification_items(self, pipeline_items: List[PipelineItem]) -> List[VerificationItem]:
        """
        Convert PipelineItems to VerificationItems for the verifier.
        
        Args:
            pipeline_items: List of pipeline items to process
            
        Returns:
            List of VerificationItem objects for verification
        """
        return [
            VerificationItem(
                original_filename=item.download_filename,
                converted_filename=item.converted_filename
            )
            for item in pipeline_items
        ]
    
    async def process_single(self, output_root: str, pipeline_item: PipelineItem) -> PipelineResult:
        """
        Process a single item through the entire pipeline.
        
        Args:
            output_root: Root directory for all operations
            pipeline_item: The item to process
            
        Returns:
            PipelineResult with success/failure status for each step
        """
        download_success = False
        conversion_success = False
        verification_result = None
        
        try:
            # Step 1: Download
            print(f"Downloading {pipeline_item.url} to {pipeline_item.download_filename}...")
            download_success = self.download_manager.download_single_file(
                output_root, pipeline_item.url, pipeline_item.download_filename
            )
            
            if not download_success:
                print(f"Download failed for {pipeline_item.url}")
                return PipelineResult(download_success, conversion_success, "Download failed")
            
            # Resolve filenames after download for subsequent steps
            resolved_download_filename = self._resolve_filename(output_root, pipeline_item.download_filename)
            resolved_converted_filename = self._resolve_filename(output_root, pipeline_item.converted_filename)
            
            # Step 2: Convert HTML to Markdown
            print(f"Converting {resolved_download_filename} to {resolved_converted_filename}...")
            conversion_success = await self.converter.convert(
                output_root, resolved_download_filename, resolved_converted_filename
            )
            
            if not conversion_success:
                print(f"Conversion failed for {resolved_download_filename}")
                return PipelineResult(download_success, conversion_success, "Conversion failed")
            
            # Step 3: Verify (optional)
            if self.verify_conversions and self.verifier:
                print(f"Verifying conversion quality...")
                # Re-resolve filenames to ensure we find the converted file
                final_download_filename = self._resolve_filename(output_root, resolved_download_filename)
                final_converted_filename = self._resolve_filename(output_root, resolved_converted_filename)
                
                verification_result = await self.verifier.verify(
                    output_root, final_download_filename, final_converted_filename
                )
                
                if verification_result is None:
                    print(f"Verification passed for {final_converted_filename}")
                else:
                    print(f"Verification failed: {verification_result}")
            
            print(f"Pipeline completed successfully for {pipeline_item.url}")
            return PipelineResult(download_success, conversion_success, verification_result)
            
        except Exception as e:
            error_msg = f"Pipeline error: {e}"
            print(error_msg)
            return PipelineResult(download_success, conversion_success, error_msg)
    
    async def process_batch(self, output_root: str, pipeline_items: List[PipelineItem]) -> List[PipelineResult]:
        """
        Process multiple items through the pipeline with optimized batch operations.
        
        Args:
            output_root: Root directory for all operations
            pipeline_items: List of items to process
            
        Returns:
            List of PipelineResult objects for each item
        """
        if not pipeline_items:
            return []
        
        results = []
        
        try:
            # Step 1: Batch download (domain-aware concurrent downloading)
            print(f"Starting batch download of {len(pipeline_items)} items...")
            download_items = self._create_download_items(output_root, pipeline_items)
            download_results = await self.download_manager.download_multi_domain(output_root, download_items)
            
            # Flatten download results to match pipeline_items order
            download_success_list = []
            for item in download_items:
                domain = urlparse(item.url).netloc
                domain_results = download_results.get(domain, [])
                # Find the result for this specific item
                item_index = [i for i, di in enumerate(download_items) if di.url == item.url and urlparse(di.url).netloc == domain]
                if item_index:
                    domain_item_index = len([di for di in download_items[:item_index[0]] if urlparse(di.url).netloc == domain])
                    if domain_item_index < len(domain_results):
                        download_success_list.append(domain_results[domain_item_index])
                    else:
                        download_success_list.append(False)
                else:
                    download_success_list.append(False)
            
            # Step 2: Batch conversion (sequential, as Claude SDK requires it)
            print(f"Starting batch conversion...")
            successful_downloads = [
                (pipeline_items[i], download_success_list[i])
                for i in range(len(pipeline_items))
                if download_success_list[i]
            ]
            
            conversion_results = {}
            for item, _ in successful_downloads:
                # Resolve filenames for conversion
                resolved_download_filename = self._resolve_filename(output_root, item.download_filename)
                resolved_converted_filename = self._resolve_filename(output_root, item.converted_filename)
                
                print(f"Converting {resolved_download_filename} to {resolved_converted_filename}...")
                success = await self.converter.convert(
                    output_root, resolved_download_filename, resolved_converted_filename
                )
                conversion_results[item] = success
            
            # Step 3: Batch verification (optional)
            verification_results = {}
            if self.verify_conversions and self.verifier:
                print(f"Starting batch verification...")
                successful_conversions = [
                    item for item, success in conversion_results.items() if success
                ]
                
                verification_items = self._create_verification_items(successful_conversions)
                if verification_items:
                    batch_verification_results = await self.verifier.verify_batch(output_root, verification_items)
                    
                    # Map verification results back to pipeline items
                    for item in successful_conversions:
                        # Use resolved filenames for key matching (verifier will resolve them internally too)
                        resolved_download = self._resolve_filename(output_root, item.download_filename)
                        resolved_converted = self._resolve_filename(output_root, item.converted_filename)
                        key = f"{resolved_download} -> {resolved_converted}"
                        verification_results[item] = batch_verification_results.get(key)
            
            # Compile final results
            for i, item in enumerate(pipeline_items):
                download_success = download_success_list[i] if i < len(download_success_list) else False
                conversion_success = conversion_results.get(item, False)
                verification_result = verification_results.get(item, None) if self.verify_conversions else None
                
                results.append(PipelineResult(download_success, conversion_success, verification_result))
            
            return results
            
        except Exception as e:
            print(f"Batch processing error: {e}")
            # Return partial results if we have them, otherwise return failure for all
            while len(results) < len(pipeline_items):
                results.append(PipelineResult(False, False, f"Batch error: {e}"))
            return results
    
    def load_from_yaml(self, yaml_file_path: str) -> Tuple[str, List[PipelineItem], Dict[str, any]]:
        """
        Load pipeline configuration from a YAML file.
        
        Args:
            yaml_file_path: Path to the YAML configuration file
            
        Returns:
            Tuple of (output_root, pipeline_items, config_options)
        """
        return load_pipeline_from_yaml(yaml_file_path)


def load_pipeline_from_yaml(yaml_file_path: str) -> Tuple[str, List[PipelineItem], Dict[str, any]]:
    """
    Load pipeline configuration from a YAML file.
    
    Expected YAML format:
    output_root: "./output"
    skip_existing: false  # optional, defaults to false
    verify_conversions: true  # optional, defaults to true
    max_download_attempts: 5  # optional, defaults to 5
    items:
      - url: "https://example.com/page1.html"
        download_filename: "raw/page1.html"
        converted_filename: "processed/page1.md"
      - url: "https://example.com/page2.html"
        download_filename: "raw/page2.html"
        converted_filename: "processed/page2.md"
    
    Args:
        yaml_file_path: Path to the YAML configuration file
        
    Returns:
        Tuple of (output_root, pipeline_items, config_options)
    """
    try:
        with open(yaml_file_path, 'r') as f:
            config = yaml.safe_load(f)
        
        if 'output_root' not in config:
            raise ValueError("YAML file must contain an 'output_root' key")
        if 'items' not in config:
            raise ValueError("YAML file must contain an 'items' key")
        
        yaml_dir = os.path.dirname(os.path.abspath(yaml_file_path))
        output_root = config.get('output_root', yaml_dir)
        
        # Make relative paths relative to the YAML file directory
        if not os.path.isabs(output_root):
            output_root = os.path.join(yaml_dir, output_root)
        
        # Extract configuration options
        config_options = {
            'skip_existing': config.get('skip_existing', False),
            'verify_conversions': config.get('verify_conversions', True),
            'max_download_attempts': config.get('max_download_attempts', 5)
        }
        
        # Parse pipeline items
        pipeline_items = []
        for item in config['items']:
            required_keys = ['url', 'download_filename', 'converted_filename']
            for key in required_keys:
                if key not in item:
                    raise ValueError(f"Each item must have '{key}' key")
            
            pipeline_items.append(PipelineItem(
                url=item['url'],
                download_filename=item['download_filename'],
                converted_filename=item['converted_filename']
            ))
        
        return output_root, pipeline_items, config_options
        
    except yaml.YAMLError as e:
        raise ValueError(f"Invalid YAML format: {e}")
    except FileNotFoundError:
        raise ValueError(f"YAML file not found: {yaml_file_path}")


async def main_async():
    """Async main function supporting both YAML and single item processing modes."""
    import sys
    
    # Check for different usage modes
    if len(sys.argv) == 2:
        # Mode 1: YAML file mode - python3 pipeline.py <yaml_file>
        yaml_file = sys.argv[1]
        
        try:
            output_root, pipeline_items, config_options = load_pipeline_from_yaml(yaml_file)
            print(f"Loaded {len(pipeline_items)} items from {yaml_file}")
            print(f"Output root: {output_root}")
            print(f"Configuration: {config_options}")
            
            # Create pipeline with configuration from YAML
            pipeline = Download2MarkdownPipeline(
                max_download_attempts=config_options['max_download_attempts'],
                skip_existing=config_options['skip_existing'],
                verify_conversions=config_options['verify_conversions']
            )
            
        except Exception as e:
            print(f"Error loading YAML file: {e}")
            sys.exit(1)
            
    elif len(sys.argv) == 5:
        # Mode 2: Single item mode - python3 pipeline.py <output_root> <url> <download_filename> <converted_filename>
        output_root, url, download_filename, converted_filename = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
        
        pipeline_items = [PipelineItem(
            url=url,
            download_filename=download_filename,
            converted_filename=converted_filename
        )]
        
        # Create pipeline with default configuration
        pipeline = Download2MarkdownPipeline()
        
    else:
        print("""Usage:
  Mode 1 (YAML file):  python3 pipeline.py <yaml_file>
  Mode 2 (Single item): python3 pipeline.py <output_root> <url> <download_filename> <converted_filename>

Examples:
  python3 pipeline.py pipeline_config.yaml
  python3 pipeline.py ./output https://example.com/page.html raw/page.html processed/page.md

YAML file format:
  output_root: './output'
  skip_existing: false  # optional, defaults to false
  verify_conversions: true  # optional, defaults to true
  max_download_attempts: 5  # optional, defaults to 5
  items:
    - url: 'https://example.com/page1.html'
      download_filename: 'raw/page1.html'
      converted_filename: 'processed/page1.md'
    - url: 'https://example.com/page2.html'
      download_filename: 'raw/page2.html'
      converted_filename: 'processed/page2.md'

Features:
  - Domain-aware concurrent downloading for efficiency
  - HTML to Markdown conversion using Claude Code SDK
  - Optional verification of conversion quality
  - Comprehensive error handling and progress reporting
  - Support for both single items and batch processing""")
        sys.exit(1)
    
    try:
        # Process the pipeline items
        if len(pipeline_items) == 1:
            # Single item processing
            result = await pipeline.process_single(output_root, pipeline_items[0])
            
            print(f"\nPipeline Results:")
            print(f"  Download: {'✓' if result.download_success else '✗'}")
            print(f"  Conversion: {'✓' if result.conversion_success else '✗'}")
            if pipeline.verify_conversions:
                verification_status = '✓' if result.verification_result is None else f'✗ ({result.verification_result})'
                print(f"  Verification: {verification_status}")
            
            if result.download_success and result.conversion_success and (not pipeline.verify_conversions or result.verification_result is None):
                print("Pipeline completed successfully!")
                sys.exit(0)
            else:
                print("Pipeline failed!")
                sys.exit(1)
        else:
            # Batch processing
            results = await pipeline.process_batch(output_root, pipeline_items)
            
            # Calculate statistics
            total_items = len(results)
            successful_downloads = sum(1 for r in results if r.download_success)
            successful_conversions = sum(1 for r in results if r.conversion_success)
            successful_verifications = sum(1 for r in results if not pipeline.verify_conversions or r.verification_result is None)
            
            print(f"\nBatch Pipeline Results:")
            print(f"  Total items: {total_items}")
            print(f"  Downloads: {successful_downloads}/{total_items}")
            print(f"  Conversions: {successful_conversions}/{total_items}")
            if pipeline.verify_conversions:
                print(f"  Verifications: {successful_verifications}/{total_items}")
            
            # Detailed results
            print(f"\nDetailed Results:")
            for i, (item, result) in enumerate(zip(pipeline_items, results)):
                status_parts = []
                status_parts.append('D' if result.download_success else 'd')
                status_parts.append('C' if result.conversion_success else 'c')
                if pipeline.verify_conversions:
                    status_parts.append('V' if result.verification_result is None else 'v')
                status = ''.join(status_parts)
                
                print(f"  [{status}] {item.url} -> {item.converted_filename}")
                if result.verification_result and result.verification_result != "Download failed" and result.verification_result != "Conversion failed":
                    print(f"      Verification: {result.verification_result}")
            
            print(f"\nLegend: D=Download, C=Conversion, V=Verification (uppercase=success, lowercase=failure)")
            
            if successful_downloads == total_items and successful_conversions == total_items and successful_verifications == total_items:
                print("All pipeline operations completed successfully!")
                sys.exit(0)
            else:
                print("Some pipeline operations failed!")
                sys.exit(1)
                
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main_async())
