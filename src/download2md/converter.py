#!/usr/bin/env python3
"""
HTML to Markdown conversion utility using Claude Code SDK.

This module provides functionality to convert HTML files to Markdown format
using Claude's advanced content processing capabilities.
"""

import asyncio
import glob
import os
import yaml
from typing import List, Optional, Tuple
from collections import namedtuple
from claude_code_sdk import ClaudeSDKClient, ClaudeCodeOptions
from prompts.system_prompts import CONVERTER_SYSTEM_PROMPT
from prompts.prompts import CONVERTER_PLANNING_PROMPT, CONVERTER_EXECUTION_PROMPT

ConversionItem = namedtuple('ConversionItem', ['input_filename', 'output_filename'])


class HTMLToMarkdownConverter:
    """
    A class for converting HTML files to Markdown format using Claude Code SDK.
    """

    def __init__(self,
                 system_prompt: str = CONVERTER_SYSTEM_PROMPT,
                 allowed_tools: Optional[List[str]] = None,
                 max_turns: int = 2):
        """
        Initialize the converter with configuration options.

        Args:
            system_prompt: The system prompt to use for Claude
            allowed_tools: List of tools Claude can use during conversion
            max_turns: Maximum number of conversation turns
        """
        self.system_prompt = system_prompt
        self.allowed_tools = allowed_tools or ["Read", "Write", "Edit", "LS", "TodoWrite", "Grep", "Glob"]
        self.max_turns = max_turns

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

    def _build_file_paths(self, root_path: str, input_filename: str, output_filename: str) -> tuple[str, str]:
        """
        Build full file paths for input and output files.

        Args:
            root_path: The base directory path
            input_filename: The input HTML filename
            output_filename: The output Markdown filename

        Returns:
            Tuple of (input_path, output_path)
        """
        # Resolve filenames to handle missing extensions
        resolved_input = self._resolve_filename(root_path, input_filename)
        resolved_output = self._resolve_filename(root_path, output_filename)

        input_path = os.path.join(root_path, resolved_input)
        output_path = os.path.join(root_path, resolved_output)
        return input_path, output_path

    def _create_prompts(self, input_path: str, output_path: str) -> tuple[str, str]:
        """
        Create planning and execution prompts for the conversion.

        Args:
            input_path: Full path to input file
            output_path: Full path to output file

        Returns:
            Tuple of (planning_prompt, execution_prompt)
        """
        planning_prompt = CONVERTER_PLANNING_PROMPT.format(
            input_path=input_path,
            output_path=output_path
        )

        execution_prompt = CONVERTER_EXECUTION_PROMPT.format(
            output_path=output_path
        )

        return planning_prompt, execution_prompt

    async def _execute_claude_conversion(self, planning_prompt: str, execution_prompt: str) -> None:
        """
        Execute the conversion using Claude Code SDK.

        Args:
            planning_prompt: The planning prompt for Claude
            execution_prompt: The execution prompt for Claude
        """
        async with ClaudeSDKClient(
            options=ClaudeCodeOptions(
                system_prompt=self.system_prompt,
                allowed_tools=self.allowed_tools,
                max_turns=self.max_turns
            )
        ) as client:
            # Step 1: Planning
            await client.query(planning_prompt)

            async for _ in client.receive_response():
                pass  # Let the planning phase complete

            # Step 2: Execution
            await client.query(execution_prompt)

            async for _ in client.receive_response():
                pass  # Let the execution phase complete

    def _verify_conversion_success(self, output_path: str) -> bool:
        """
        Verify that the conversion was successful.

        Args:
            output_path: Path to the output file

        Returns:
            True if conversion was successful, False otherwise
        """
        return os.path.exists(output_path) and os.path.getsize(output_path) > 0

    async def convert(self, root_path: str, input_filename: str, output_filename: str) -> bool:
        """
        Convert an HTML file to Markdown format.

        Args:
            root_path: The base directory path
            input_filename: The input HTML filename
            output_filename: The output Markdown filename

        Returns:
            True if conversion was successful, False otherwise
        """
        try:
            # Build file paths
            input_path, output_path = self._build_file_paths(root_path, input_filename, output_filename)

            # Create prompts
            planning_prompt, execution_prompt = self._create_prompts(input_path, output_path)

            # Execute conversion
            await self._execute_claude_conversion(planning_prompt, execution_prompt)

            # Verify success
            if self._verify_conversion_success(output_path):
                print(f"Successfully converted {input_path} to {output_path}")
                return True
            else:
                print("Error: Conversion failed - output file not created or is empty")
                return False

        except Exception as e:
            print(f"Error during conversion: {e}")
            return False

    async def convert_file(self, root_path: str, conversion_item: ConversionItem) -> bool:
        """
        Convert an HTML file to Markdown format using a ConversionItem.

        Args:
            root_path: The base directory path
            conversion_item: ConversionItem namedtuple containing input_filename and output_filename

        Returns:
            True if conversion was successful, False otherwise
        """
        return await self.convert(root_path, conversion_item.input_filename, conversion_item.output_filename)

    async def convert_batch(self, root_path: str, conversions: List[ConversionItem]) -> List[bool]:
        """
        Convert multiple HTML files to Markdown format sequentially.

        Args:
            root_path: The base directory path
            conversions: List of ConversionItem namedtuples

        Returns:
            List of boolean values indicating success/failure for each conversion
        """
        results = []
        for conversion_item in conversions:
            success = await self.convert_file(root_path, conversion_item)
            results.append(success)
        return results

    def load_from_yaml(self, yaml_file_path: str) -> Tuple[str, List[ConversionItem]]:
        """
        Load conversion configuration from a YAML file.

        Args:
            yaml_file_path: Path to the YAML configuration file

        Returns:
            Tuple of (root_path, conversions_list)
        """
        return load_conversions_from_yaml(yaml_file_path)


async def html_to_md(root_path: str, input_filename: str, output_filename: str) -> bool:
    """
    Convert an HTML file to Markdown format using Claude Code SDK.

    This is a convenience function that maintains backward compatibility.

    Args:
        root_path: The base directory path
        input_filename: The input HTML filename
        output_filename: The output Markdown filename

    Returns:
        True if conversion was successful, False otherwise
    """
    converter = HTMLToMarkdownConverter()
    return await converter.convert(root_path, input_filename, output_filename)


async def convert_file(root_path: str, conversion_item: ConversionItem) -> bool:
    """
    Convert an HTML file to Markdown format using a ConversionItem.

    Args:
        root_path: The base directory path
        conversion_item: ConversionItem namedtuple containing input_filename and output_filename

    Returns:
        True if conversion was successful, False otherwise
    """
    converter = HTMLToMarkdownConverter()
    return await converter.convert_file(root_path, conversion_item)


async def convert_batch(root_path: str, conversions: List[ConversionItem]) -> List[bool]:
    """
    Convert multiple HTML files to Markdown format sequentially.

    Args:
        root_path: The base directory path
        conversions: List of ConversionItem namedtuples

    Returns:
        List of boolean values indicating success/failure for each conversion
    """
    converter = HTMLToMarkdownConverter()
    return await converter.convert_batch(root_path, conversions)


def load_conversions_from_yaml(yaml_file_path: str) -> Tuple[str, List[ConversionItem]]:
    """Load conversion configuration from a YAML file.

    Expected YAML format:
    root_path: "./docs"
    conversions:
      - input_filename: "page1.html"
        output_filename: "page1.md"
      - input_filename: "subdir/page2.html"
        output_filename: "subdir/page2.md"
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

        # Make relative paths relative to the YAML file directory
        if not os.path.isabs(root_path):
            root_path = os.path.join(yaml_dir, root_path)

        conversions = []
        for item in config['conversions']:
            if 'input_filename' not in item or 'output_filename' not in item:
                raise ValueError("Each conversion item must have 'input_filename' and 'output_filename' keys")
            conversions.append(ConversionItem(input_filename=item['input_filename'], output_filename=item['output_filename']))

        return root_path, conversions
    except yaml.YAMLError as e:
        raise ValueError(f"Invalid YAML format: {e}")
    except FileNotFoundError:
        raise ValueError(f"YAML file not found: {yaml_file_path}")


if __name__ == "__main__":
    import sys

    # Check for different usage modes
    if len(sys.argv) == 2:
        # Mode 1: YAML file mode - python3 converter.py <yaml_file>
        yaml_file = sys.argv[1]

        try:
            root_path, conversions = load_conversions_from_yaml(yaml_file)
            print(f"Loaded {len(conversions)} conversions from {yaml_file}")
            print(f"Root directory: {root_path}")

            # Create converter and run batch conversion
            converter = HTMLToMarkdownConverter()
            results = asyncio.run(converter.convert_batch(root_path, conversions))

            # Check results and count successes/failures
            total_conversions = len(conversions)
            successful_conversions = sum(results)

            print(f"Conversion summary: {successful_conversions}/{total_conversions} files converted successfully")

            if successful_conversions == total_conversions:
                print("All conversions completed successfully!")
            elif successful_conversions > 0:
                print(f"Partial success: {total_conversions - successful_conversions} conversions failed")
                sys.exit(1)
            else:
                print("All conversions failed!")
                sys.exit(1)

        except Exception as e:
            print(f"Error loading YAML file: {e}")
            sys.exit(1)

    elif len(sys.argv) == 4:
        # Mode 2: Single file mode - python3 converter.py <root_path> <input_filename> <output_filename>
        root_path, input_filename, output_filename = sys.argv[1], sys.argv[2], sys.argv[3]

        try:
            success = asyncio.run(html_to_md(root_path, input_filename, output_filename))
            if success:
                print("Conversion completed successfully!")
            else:
                print("Conversion failed!")
                sys.exit(1)
        except Exception as e:
            print(f"Error: {e}")
            sys.exit(1)

    else:
        print("""Usage:
  Mode 1 (YAML file):  python3 converter.py <yaml_file>
  Mode 2 (Single file): python3 converter.py <root_path> <input_filename> <output_filename>

Examples:
  python3 converter.py conversions_config.yaml
  python3 converter.py ./docs page.html page.md

YAML file format:
  root_path: './docs'
  conversions:
    - input_filename: 'page1.html'
      output_filename: 'page1.md'
    - input_filename: 'subdir/page2.html'
      output_filename: 'subdir/page2.md'""")
        sys.exit(1)
