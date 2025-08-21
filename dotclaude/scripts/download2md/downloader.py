#!/usr/bin/env python3
"""
Simple download utility for Claude Code scripts.

This module provides a function to download content from a URL and save it to a specified path.
"""

import asyncio
import concurrent.futures
import os
import time
import requests
import yaml
from collections import namedtuple, defaultdict
from urllib.parse import urlparse

DownloadItem = namedtuple('DownloadItem', ['url', 'filename'])

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

    # Create the full output file path
    full_output_path = os.path.join(output_path, filename)

    # Skip if file exists and skip_existing is True
    if skip_existing and os.path.exists(full_output_path):
        print(f"Skipping {filename} - file already exists")
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

        output_path = config['output_path']
        skip_existing = config.get('skip_existing', False)

        # Make relative paths relative to the YAML file directory
        if not os.path.isabs(output_path):
            yaml_dir = os.path.dirname(os.path.abspath(yaml_file_path))
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
    """Async main function that uses download_multi_domain."""
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
        except Exception as e:
            print(f"Error loading YAML file: {e}")
            sys.exit(1)

    elif len(sys.argv) == 4:
        # Mode 2: Single URL mode - python3 download.py <output_path> <url> <filename>
        output_path, url, filename = sys.argv[1], sys.argv[2], sys.argv[3]
        downloads = [DownloadItem(url=url, filename=filename)]
        skip_existing = False

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

Note: Uses multi-domain download function internally for robust
      downloading with retry logic and async capabilities.""")
        sys.exit(1)

    try:
        # Use download_multi_domain for the download(s)
        results = await download_multi_domain(output_path, downloads, skip_existing=skip_existing)

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
