#!/usr/bin/env python3
"""
Simple download utility for Claude Code scripts.

This module provides a class-based approach to download content from URLs and save to specified paths.
Supports single file downloads, multi-domain batch downloads, and YAML configuration.
"""

import asyncio
import concurrent.futures
import os
import time
import requests
import yaml
from collections import namedtuple, defaultdict
from urllib.parse import urlparse
from typing import Dict, List, Tuple, Optional

DownloadItem = namedtuple('DownloadItem', ['url', 'filename'])


def _infer_extension_from_url(url: str) -> str:
    """
    Infer file extension from URL path.
    
    Args:
        url: The URL to analyze
        
    Returns:
        File extension including the dot (e.g., '.html', '.pdf'), or empty string if none found
    """
    if not url or not isinstance(url, str):
        return ''
        
    try:
        parsed_url = urlparse(url.strip())
        path = parsed_url.path
        
        if not path or path == '/':
            return ''
        
        # Remove query parameters and fragments from path
        if '?' in path:
            path = path.split('?')[0]
        if '#' in path:
            path = path.split('#')[0]
            
        # Extract extension from the last path segment
        if path and path != '/':
            _, ext = os.path.splitext(path)
            # Only return valid extensions (2-5 characters)
            if ext and 1 < len(ext) <= 5 and ext.replace('.', '').isalnum():
                return ext.lower()
    except (ValueError, AttributeError, TypeError):
        # Handle URL parsing errors silently
        pass
    
    return ''


def _ensure_filename_has_extension(filename: str, url: str) -> str:
    """
    Ensure filename has an extension, inferring from URL if necessary.
    
    Args:
        filename: The original filename
        url: The URL to infer extension from if needed
        
    Returns:
        Filename with extension
    """
    if not filename or not isinstance(filename, str):
        return filename or ''
    
    try:
        # Check if filename already has an extension
        name, ext = os.path.splitext(filename.strip())
        
        if ext and len(ext) > 1:
            # Filename already has a valid extension
            return filename
        
        # Try to infer extension from URL
        if url:
            inferred_ext = _infer_extension_from_url(url)
            
            if inferred_ext:
                return filename + inferred_ext
    except (ValueError, AttributeError, TypeError):
        # Handle any unexpected errors in filename processing
        pass
    
    # No extension could be inferred, return original filename
    return filename


class FileDownloader:
    """Handles individual file download operations."""

    def __init__(self, skip_existing: bool = False):
        """
        Initialize FileDownloader.

        Args:
            skip_existing: If True, skip download if file already exists
        """
        self.skip_existing = skip_existing

    def download(self, output_path: str, url: str, filename: str) -> bool:
        """
        Download content from a URL and save it to the specified output path.

        Args:
            output_path: The directory where the file should be saved
            url: The absolute URL to download from
            filename: The filename or relative path where to write the output

        Returns:
            True if download was successful, False otherwise

        Raises:
            ValueError: If any of the parameters are invalid
            OSError: If there are file system related errors
            requests.RequestException: If there are network related errors
        """
        if not output_path:
            raise ValueError("output_path cannot be empty")
        if not url:
            raise ValueError("url cannot be empty")
        if not filename:
            raise ValueError("filename cannot be empty")

        # Ensure filename has an extension, inferring from URL if necessary
        enhanced_filename = _ensure_filename_has_extension(filename, url)
        
        # Log if extension was inferred
        if enhanced_filename != filename:
            print(f"Inferred extension from URL: {filename} -> {enhanced_filename}")

        # Create the full output file path
        full_output_path = os.path.join(output_path, enhanced_filename)

        # Skip if file exists and skip_existing is True
        if self.skip_existing and os.path.exists(full_output_path):
            print(f"Skipping {enhanced_filename} - file already exists")
            return True

        # Create output directory if it doesn't exist
        output_dir = os.path.dirname(full_output_path)
        if output_dir and not os.path.exists(output_dir):
            try:
                os.makedirs(output_dir, exist_ok=True)
            except OSError as e:
                print(f"Error creating directory {output_dir}: {e}")
                raise

        try:
            # Download the content
            print(f"Downloading {url}...")
            response = requests.get(url)
            response.raise_for_status()
            content = response.content

            # Write content to file
            with open(full_output_path, 'wb') as f:
                f.write(content)

            print(f"Successfully saved to {full_output_path}")
            return True

        except requests.RequestException as e:
            print(f"Error downloading from {url}: {e}")
            raise
        except OSError as e:
            print(f"Error writing to {full_output_path}: {e}")
            raise


def download(output_path: str, url: str, filename: str, skip_existing: bool = False) -> bool:
    """
    Download content from a URL and save it to the specified output path.

    Args:
        output_path: The directory where the file should be saved
        url: The absolute URL to download from
        filename: The filename or relative path where to write the output
        skip_existing: If True, skip download if file already exists

    Returns:
        True if download was successful, False otherwise

    Raises:
        ValueError: If any of the parameters are invalid
        OSError: If there are file system related errors
        requests.RequestException: If there are network related errors
    """
    if not output_path:
        raise ValueError("output_path cannot be empty")
    if not url:
        raise ValueError("url cannot be empty")
    if not filename:
        raise ValueError("filename cannot be empty")

    # Ensure filename has an extension, inferring from URL if necessary
    enhanced_filename = _ensure_filename_has_extension(filename, url)
    
    # Log if extension was inferred
    if enhanced_filename != filename:
        print(f"Inferred extension from URL: {filename} -> {enhanced_filename}")

    # Create the full output file path
    full_output_path = os.path.join(output_path, enhanced_filename)

    # Skip if file exists and skip_existing is True
    if skip_existing and os.path.exists(full_output_path):
        print(f"Skipping {enhanced_filename} - file already exists")
        return True

    # Create output directory if it doesn't exist
    output_dir = os.path.dirname(full_output_path)
    if output_dir and not os.path.exists(output_dir):
        try:
            os.makedirs(output_dir, exist_ok=True)
        except OSError as e:
            print(f"Error creating directory {output_dir}: {e}")
            raise

    try:
        # Download the content
        print(f"Downloading {url}...")
        response = requests.get(url)
        response.raise_for_status()
        content = response.content

        # Write content to file
        with open(full_output_path, 'wb') as f:
            f.write(content)

        print(f"Successfully saved to {full_output_path}")
        return True

    except requests.RequestException as e:
        print(f"Error downloading from {url}: {e}")
        raise
    except OSError as e:
        print(f"Error writing to {full_output_path}: {e}")
        raise


class DomainDownloader:
    """Handles downloads for a single domain with retry logic and exponential backoff."""

    def __init__(self, max_attempts: int = 5, skip_existing: bool = False):
        """
        Initialize DomainDownloader.

        Args:
            max_attempts: Maximum number of attempts per file (default: 5)
            skip_existing: If True, skip download if file already exists (default: False)
        """
        self.max_attempts = max_attempts
        self.file_downloader = FileDownloader(skip_existing=skip_existing)

    def download_domain(self, output_path: str, downloads: List[DownloadItem]) -> List[bool]:
        """
        Download multiple files from the same domain sequentially with exponential backoff retry logic.

        Args:
            output_path: The directory where files should be saved
            downloads: list of DownloadItem named tuples containing url and filename

        Returns:
            List of boolean values indicating success/failure for each download
        """
        attempts = {item.filename: 0 for item in downloads}
        urls = {item.filename: item.url for item in downloads}
        results = {item.filename: False for item in downloads}

        while attempts:
            for filename in list(attempts.keys()):
                attempts[filename] += 1
                url = urls[filename]

                try:
                    success = self.file_downloader.download(output_path, url, filename)
                    if success:
                        results[filename] = True
                        del attempts[filename]
                        del urls[filename]
                        continue
                except Exception as e:
                    print(f"Attempt {attempts[filename]} failed to download {url}: {e}")

                if attempts[filename] >= self.max_attempts:
                    print(f"Download failed after {self.max_attempts} attempts: {url}")
                    del attempts[filename]
                    del urls[filename]
                else:
                    # Exponential backoff: 3 * 2^(attempts-1) seconds
                    wait_time = 3 * (2 ** (attempts[filename] - 1))
                    time.sleep(wait_time)

        return [results[item.filename] for item in downloads]


def group_downloads_by_domain(downloads: list[DownloadItem]) -> dict[str, list[DownloadItem]]:
    """
    Group a list of DownloadItem objects by domain.

    Assumes the list is already sorted by domain of the URL.

    Args:
        downloads: list of DownloadItem named tuples containing url and filename

    Returns:
        Dictionary mapping domain names to lists of DownloadItem objects
    """
    groups = defaultdict(list)
    for item in downloads:
        domain = urlparse(item.url).netloc
        groups[domain].append(item)
    return groups


def download_single_domain(output_path: str, downloads: list[DownloadItem], max_attempts: int = 5, skip_existing: bool = False) -> list[bool]:
    """
    Download multiple files from the same domain sequentially with exponential backoff retry logic.

    Args:
        output_path: The directory where files should be saved
        downloads: list of DownloadItem named tuples containing url and filename
        max_attempts: Maximum number of attempts per file (default: 5)
        skip_existing: If True, skip download if file already exists (default: False)

    Returns:
        List of boolean values indicating success/failure for each download
    """
    attempts = {item.filename: 0 for item in downloads}
    urls = {item.filename: item.url for item in downloads}
    results = {item.filename: False for item in downloads}

    while attempts:
        for filename in list(attempts.keys()):
            attempts[filename] += 1
            url = urls[filename]

            try:
                success = download(output_path, url, filename, skip_existing)
                if success:
                    results[filename] = True
                    del attempts[filename]
                    del urls[filename]
                    continue
            except Exception as e:
                print(f"Attempt {attempts[filename]} failed to download {url}: {e}")

            if attempts[filename] >= max_attempts:
                print(f"Download failed after {max_attempts} attempts: {url}")
                del attempts[filename]
                del urls[filename]
            else:
                # Exponential backoff: 3 * 2^(attempts-1) seconds
                wait_time = 3 * (2 ** (attempts[filename] - 1))
                time.sleep(wait_time)

    return [results[item.filename] for item in downloads]

async def download_domain_async(output_path: str, domain: str, domain_downloads: list[DownloadItem], max_attempts: int = 5, skip_existing: bool = False) -> tuple[str, list[bool]]:
    """Download all files for a single domain asynchronously."""
    loop = asyncio.get_event_loop()
    with concurrent.futures.ThreadPoolExecutor() as executor:
        results = await loop.run_in_executor(
            executor,
            download_single_domain,
            output_path,
            domain_downloads,
            max_attempts,
            skip_existing
        )
    return domain, results

async def download_multi_domain(output_path: str, downloads: list[DownloadItem], max_attempts: int = 5, skip_existing: bool = False) -> dict[str, list[bool]]:
    """
    Download multiple files from multiple domains concurrently with exponential backoff retry logic.

    Args:
        output_path: The directory where files should be saved
        downloads: list of DownloadItem named tuples containing url and filename
        max_attempts: Maximum number of attempts per file (default: 5)
        skip_existing: If True, skip download if file already exists (default: False)

    Returns:
        Dictionary mapping domain names to lists of boolean values indicating success/failure for each download
    """
    # Group downloads by domain
    domain_groups = group_downloads_by_domain(downloads)

    # Create tasks for each domain
    tasks = [
        download_domain_async(output_path, domain, domain_downloads, max_attempts, skip_existing)
        for domain, domain_downloads in domain_groups.items()
    ]

    # Wait for all domains to complete
    domain_results = await asyncio.gather(*tasks)

    # Convert results to dictionary
    return dict(domain_results)


class DownloadManager:
    """Main orchestrator for all download operations."""

    def __init__(self, max_attempts: int = 5, skip_existing: bool = False):
        """
        Initialize DownloadManager.

        Args:
            max_attempts: Maximum number of attempts per file (default: 5)
            skip_existing: If True, skip download if file already exists (default: False)
        """
        self.max_attempts = max_attempts
        self.skip_existing = skip_existing
        self.file_downloader = FileDownloader(skip_existing=skip_existing)

    def download_single_file(self, output_path: str, url: str, filename: str) -> bool:
        """
        Download a single file.

        Args:
            output_path: The directory where the file should be saved
            url: The absolute URL to download from
            filename: The filename or relative path where to write the output

        Returns:
            True if download was successful, False otherwise
        """
        return self.file_downloader.download(output_path, url, filename)

    async def download_multi_domain(self, output_path: str, downloads: List[DownloadItem]) -> Dict[str, List[bool]]:
        """
        Download multiple files from multiple domains concurrently with exponential backoff retry logic.

        Args:
            output_path: The directory where files should be saved
            downloads: list of DownloadItem named tuples containing url and filename

        Returns:
            Dictionary mapping domain names to lists of boolean values indicating success/failure for each download
        """
        # Group downloads by domain
        domain_groups = self._group_downloads_by_domain(downloads)

        # Create tasks for each domain
        tasks = [
            self._download_domain_async(output_path, domain, domain_downloads)
            for domain, domain_downloads in domain_groups.items()
        ]

        # Wait for all domains to complete
        domain_results = await asyncio.gather(*tasks)

        # Convert results to dictionary
        return dict(domain_results)

    async def _download_domain_async(self, output_path: str, domain: str, domain_downloads: List[DownloadItem]) -> Tuple[str, List[bool]]:
        """Download all files for a single domain asynchronously."""
        loop = asyncio.get_event_loop()
        domain_downloader = DomainDownloader(max_attempts=self.max_attempts, skip_existing=self.skip_existing)

        with concurrent.futures.ThreadPoolExecutor() as executor:
            results = await loop.run_in_executor(
                executor,
                domain_downloader.download_domain,
                output_path,
                domain_downloads
            )
        return domain, results

    def _group_downloads_by_domain(self, downloads: List[DownloadItem]) -> Dict[str, List[DownloadItem]]:
        """
        Group a list of DownloadItem objects by domain.

        Args:
            downloads: list of DownloadItem named tuples containing url and filename

        Returns:
            Dictionary mapping domain names to lists of DownloadItem objects
        """
        groups = defaultdict(list)
        for item in downloads:
            domain = urlparse(item.url).netloc
            groups[domain].append(item)
        return groups

    def load_from_yaml(self, yaml_file_path: str) -> Tuple[str, List[DownloadItem], bool]:
        """
        Load download configuration from a YAML file.

        Args:
            yaml_file_path: Path to the YAML configuration file

        Returns:
            Tuple of (output_path, downloads_list, skip_existing)
        """
        return load_downloads_from_yaml(yaml_file_path)


def load_downloads_from_yaml(yaml_file_path: str) -> tuple[str, list[DownloadItem], bool]:
    """Load download configuration from a YAML file.

    Expected YAML format:
    output_path: "./downloads"
    skip_existing: false  # optional, defaults to false
    downloads:
      - url: "https://example.com/file1.txt"
        filename: "file1.txt"
      - url: "https://example.com/file2.txt"
        filename: "subdir/file2.txt"
    """
    try:
        with open(yaml_file_path, 'r') as f:
            config = yaml.safe_load(f)

        if 'output_path' not in config:
            raise ValueError("YAML file must contain an 'output_path' key")
        if 'downloads' not in config:
            raise ValueError("YAML file must contain a 'downloads' key")

        yaml_dir = os.path.dirname(os.path.abspath(yaml_file_path))
        output_path = config.get('output_path', yaml_dir)
        skip_existing = config.get('skip_existing', False)

        # Make relative paths relative to the YAML file directory
        if not os.path.isabs(output_path):
            output_path = os.path.join(yaml_dir, output_path)

        downloads = []
        for item in config['downloads']:
            if 'url' not in item or 'filename' not in item:
                raise ValueError("Each download item must have 'url' and 'filename' keys")
            downloads.append(DownloadItem(url=item['url'], filename=item['filename']))

        return output_path, downloads, skip_existing
    except yaml.YAMLError as e:
        raise ValueError(f"Invalid YAML format: {e}")
    except FileNotFoundError:
        raise ValueError(f"YAML file not found: {yaml_file_path}")

async def main_async():
    """Async main function that uses DownloadManager."""
    import sys

    # Check for different usage modes
    if len(sys.argv) == 2:
        # Mode 1: YAML file mode - python3 download.py <yaml_file>
        yaml_file = sys.argv[1]

        try:
            output_path, downloads, skip_existing = load_downloads_from_yaml(yaml_file)
            print(f"Loaded {len(downloads)} downloads from {yaml_file}")
            print(f"Output directory: {output_path}")
            print(f"Skip existing files: {skip_existing}")

            # Create DownloadManager with the configuration from YAML
            download_manager = DownloadManager(skip_existing=skip_existing)
        except Exception as e:
            print(f"Error loading YAML file: {e}")
            sys.exit(1)

    elif len(sys.argv) == 4:
        # Mode 2: Single URL mode - python3 download.py <output_path> <url> <filename>
        output_path, url, filename = sys.argv[1], sys.argv[2], sys.argv[3]
        downloads = [DownloadItem(url=url, filename=filename)]
        skip_existing = False

        # Create DownloadManager with default configuration
        download_manager = DownloadManager(skip_existing=skip_existing)

    else:
        print("""Usage:
  Mode 1 (YAML file):  python3 download.py <yaml_file>
  Mode 2 (Single URL): python3 download.py <output_path> <url> <filename>

Examples:
  python3 download.py downloads_config.yaml
  python3 download.py ./downloads https://example.com/file.txt document.txt

YAML file format:
  output_path: './downloads'
  skip_existing: false  # optional, defaults to false
  downloads:
    - url: 'https://example.com/file1.txt'
      filename: 'file1.txt'
    - url: 'https://example.com/file2.txt'
      filename: 'subdir/file2.txt'

Note: Uses DownloadManager class internally for robust
      downloading with retry logic and async capabilities.""")
        sys.exit(1)

    try:
        # Use DownloadManager for the download(s)
        results = await download_manager.download_multi_domain(output_path, downloads)

        # Check results and count successes/failures
        total_downloads = len(downloads)
        successful_downloads = 0

        for domain_results in results.values():
            successful_downloads += sum(domain_results)

        print(f"Download summary: {successful_downloads}/{total_downloads} files downloaded successfully")

        if successful_downloads == total_downloads:
            print("All downloads completed successfully!")
        elif successful_downloads > 0:
            print(f"Partial success: {total_downloads - successful_downloads} downloads failed")
            sys.exit(1)
        else:
            print("All downloads failed!")
            sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main_async())
