#!/usr/bin/env python3
"""
File conversion verification utility using Claude Code SDK.

This module provides functionality to verify the quality and correctness
of file conversions using Claude's advanced content processing capabilities.
"""

import asyncio
import os
import yaml
from collections import namedtuple
from typing import List, Optional, Dict
from claude_code_sdk import ClaudeSDKClient, ClaudeCodeOptions
from ..prompts.system_prompts import VERIFIER_SYSTEM_PROMPT
from ..prompts.prompts import VERIFIER_PLANNING_PROMPT, VERIFIER_EXECUTION_PROMPT

VerificationItem = namedtuple('VerificationItem', ['original_filename', 'converted_filename'])


class ConversionVerifier:
    """
    A class for verifying file conversions using Claude Code SDK.
    """
    
    # Format mapping for file extensions
    FORMAT_MAP = {
        '.html': 'HTML',
        '.htm': 'HTML',
        '.md': 'Markdown',
        '.txt': 'Plain Text',
        '.json': 'JSON',
        '.xml': 'XML'
    }
    
    def __init__(self, 
                 system_prompt: str = VERIFIER_SYSTEM_PROMPT,
                 allowed_tools: Optional[List[str]] = None,
                 max_turns: int = 2,
                 max_concurrent: int = 5):
        """
        Initialize the verifier with configuration options.
        
        Args:
            system_prompt: The system prompt to use for Claude
            allowed_tools: List of tools Claude can use during verification
            max_turns: Maximum number of conversation turns
            max_concurrent: Maximum number of concurrent verifications
        """
        self.system_prompt = system_prompt
        self.allowed_tools = allowed_tools or ["Read", "Write", "LS", "Bash", "TodoWrite", "Grep", "Glob", "Edit"]
        self.max_turns = max_turns
        self.max_concurrent = max_concurrent
    
    def _resolve_filename(self, root_path: str, filename: str) -> str:
        """
        Resolve filename with flexible extension matching.
        
        If the exact filename exists, returns it as-is.
        If the exact filename doesn't exist and has no extension,
        searches for files with the same base name and known extensions.
        
        Args:
            root_path: The base directory path
            filename: The filename to resolve
            
        Returns:
            Resolved filename (may be the same as input)
        """
        # Try exact filename first
        full_path = os.path.join(root_path, filename)
        if os.path.exists(full_path):
            return filename
        
        # If filename has extension, don't try flexible matching
        if os.path.splitext(filename)[1]:
            return filename
        
        # Try flexible matching for extensionless filenames
        try:
            if os.path.exists(root_path):
                for file in os.listdir(root_path):
                    file_base = os.path.splitext(file)[0]
                    file_ext = os.path.splitext(file)[1].lower()
                    
                    # Check if base name matches and extension is known
                    if file_base == filename and file_ext in self.FORMAT_MAP:
                        return file
        except (OSError, PermissionError):
            pass  # Return original filename if directory can't be read
        
        return filename
    
    def _build_file_paths(self, root_path: str, original_filename: str, converted_filename: str) -> tuple[str, str]:
        """
        Build full file paths for original and converted files.
        Uses flexible filename resolution to handle missing extensions.
        
        Args:
            root_path: The base directory path
            original_filename: The original file filename
            converted_filename: The converted file filename
            
        Returns:
            Tuple of (original_path, converted_path)
        """
        # Resolve filenames with flexible matching
        resolved_original = self._resolve_filename(root_path, original_filename)
        resolved_converted = self._resolve_filename(root_path, converted_filename)
        
        original_path = os.path.join(root_path, resolved_original)
        converted_path = os.path.join(root_path, resolved_converted)
        return original_path, converted_path
    
    def _determine_file_formats(self, original_filename: str, converted_filename: str) -> tuple[str, str]:
        """
        Determine file formats based on extensions.
        
        Args:
            original_filename: The original file filename
            converted_filename: The converted file filename
            
        Returns:
            Tuple of (original_format, converted_format)
        """
        original_ext = os.path.splitext(original_filename)[1].lower()
        converted_ext = os.path.splitext(converted_filename)[1].lower()
        
        original_format = self.FORMAT_MAP.get(original_ext, 'Unknown')
        converted_format = self.FORMAT_MAP.get(converted_ext, 'Unknown')
        
        return original_format, converted_format
    
    def _create_prompts(self, original_format: str, converted_format: str, 
                       original_path: str, converted_path: str) -> tuple[str, str]:
        """
        Create planning and execution prompts for verification.
        
        Args:
            original_format: Format of the original file
            converted_format: Format of the converted file
            original_path: Full path to original file
            converted_path: Full path to converted file
            
        Returns:
            Tuple of (planning_prompt, execution_prompt)
        """
        planning_prompt = VERIFIER_PLANNING_PROMPT.format(
            original_format=original_format,
            converted_format=converted_format,
            original_path=original_path,
            converted_path=converted_path
        )
        
        execution_prompt = VERIFIER_EXECUTION_PROMPT.format(
            original_format=original_format,
            converted_format=converted_format,
            original_path=original_path,
            converted_path=converted_path
        )
        
        return planning_prompt, execution_prompt
    
    async def _execute_claude_verification(self, planning_prompt: str, execution_prompt: str) -> str:
        """
        Execute the verification using Claude Code SDK.
        
        Args:
            planning_prompt: The planning prompt for Claude
            execution_prompt: The execution prompt for Claude
            
        Returns:
            The verification result from Claude
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
            
            verification_result = ""
            async for message in client.receive_response():
                if hasattr(message, 'content'):
                    for block in message.content:
                        if hasattr(block, 'text'):
                            verification_result += block.text
        
        return verification_result
    
    def _parse_verification_result(self, result: str) -> str | None:
        """
        Parse the verification result from Claude.
        
        Args:
            result: The raw result from Claude
            
        Returns:
            None if verification passed, error message if failed
        """
        if not result.strip():
            return "Error: Claude returned empty verification result"
        
        # Check if verification passed
        if result.strip() == "PASS":
            return None  # Conversion is correct
        else:
            return result.strip()  # Return error message
    
    async def verify(self, root_path: str, original_filename: str, converted_filename: str) -> str | None:
        """
        Verify the conversion quality between original and converted files.
        
        Args:
            root_path: The base directory path
            original_filename: The original file filename
            converted_filename: The converted file filename
            
        Returns:
            None if conversion is correct, error message if incorrect
        """
        try:
            # Build file paths with flexible filename resolution
            original_path, converted_path = self._build_file_paths(root_path, original_filename, converted_filename)
            
            # Validate that files exist
            if not os.path.exists(original_path):
                return f"Error: Original file not found: {original_path}"
            
            if not os.path.exists(converted_path):
                return f"Error: Converted file not found: {converted_path}"
            
            # Extract actual filenames for format determination (in case they were resolved)
            actual_original_filename = os.path.basename(original_path)
            actual_converted_filename = os.path.basename(converted_path)
            
            # Determine file formats using actual resolved filenames
            original_format, converted_format = self._determine_file_formats(actual_original_filename, actual_converted_filename)
            
            # Create prompts
            planning_prompt, execution_prompt = self._create_prompts(
                original_format, converted_format, original_path, converted_path
            )
            
            # Execute verification
            verification_result = await self._execute_claude_verification(planning_prompt, execution_prompt)
            
            # Parse and return result
            return self._parse_verification_result(verification_result)
            
        except Exception as e:
            return f"Error during verification: {e}"
    
    async def _verify_with_semaphore(self, semaphore: asyncio.Semaphore, root_path: str, verification: VerificationItem) -> tuple[str, str | None]:
        """
        Verify a single file pair with semaphore control.
        
        Args:
            semaphore: Asyncio semaphore for limiting concurrency
            root_path: The base directory path
            verification: VerificationItem namedtuple
            
        Returns:
            Tuple of (key, verification_result)
        """
        async with semaphore:
            result = await self.verify(root_path, verification.original_filename, verification.converted_filename)
            key = f"{verification.original_filename} -> {verification.converted_filename}"
            return key, result
    
    async def verify_batch(self, root_path: str, verifications: List[VerificationItem]) -> Dict[str, str | None]:
        """
        Verify multiple file pairs and return results mapping using concurrent processing.
        
        Args:
            root_path: The base directory path
            verifications: List of VerificationItem named tuples
            
        Returns:
            Dictionary mapping filenames to verification results (None if passed, error message if failed)
        """
        if not verifications:
            return {}
        
        # Create semaphore to limit concurrent operations
        semaphore = asyncio.Semaphore(self.max_concurrent)
        
        # Create tasks for concurrent verification
        tasks = [
            self._verify_with_semaphore(semaphore, root_path, verification)
            for verification in verifications
        ]
        
        # Execute all verifications concurrently
        results_list = await asyncio.gather(*tasks)
        
        # Convert list of tuples back to dictionary
        return dict(results_list)


def load_verifications_from_yaml(yaml_file_path: str) -> tuple[str, list[VerificationItem], int]:
    """Load verification configuration from a YAML file.

    Expected YAML format:
    root_path: "./conversions"
    max_concurrent: 3  # Optional, defaults to 5
    verifications:
      - original_filename: "page1.html"
        converted_filename: "page1.md"
      - original_filename: "page2"  # Flexible: finds page2.html or page2.md etc.
        converted_filename: "page2.md"
    
    Note: Flexible filename matching:
    - If exact filename exists, it's used as-is
    - If filename has no extension and doesn't exist, searches for files with same base name
    - Matches files with known extensions (.html, .md, .txt, .json, .xml)
    - For same base name, first match found is used
    
    Returns:
        Tuple of (root_path, verifications_list, max_concurrent)
    """
    try:
        with open(yaml_file_path, 'r') as f:
            config = yaml.safe_load(f)

        if 'root_path' not in config:
            raise ValueError("YAML file must contain a 'root_path' key")
        if 'verifications' not in config:
            raise ValueError("YAML file must contain a 'verifications' key")

        yaml_dir = os.path.dirname(os.path.abspath(yaml_file_path))
        root_path = config.get('root_path', yaml_dir)
        max_concurrent = config.get('max_concurrent', 5)

        # Make relative paths relative to the YAML file directory
        if not os.path.isabs(root_path):
            root_path = os.path.join(yaml_dir, root_path)

        verifications = []
        for item in config['verifications']:
            if 'original_filename' not in item or 'converted_filename' not in item:
                raise ValueError("Each verification item must have 'original_filename' and 'converted_filename' keys")
            verifications.append(VerificationItem(
                original_filename=item['original_filename'], 
                converted_filename=item['converted_filename']
            ))

        return root_path, verifications, max_concurrent
    except yaml.YAMLError as e:
        raise ValueError(f"Invalid YAML format: {e}")
    except FileNotFoundError:
        raise ValueError(f"YAML file not found: {yaml_file_path}")


async def verify_batch_from_list(root_path: str, verifications: List[VerificationItem]) -> Dict[str, str | None]:
    """
    Verify multiple file pairs and return results mapping using ConversionVerifier class.
    
    This is a convenience function that maintains backward compatibility.
    
    Args:
        root_path: The base directory path
        verifications: List of VerificationItem named tuples
        
    Returns:
        Dictionary mapping filenames to verification results (None if passed, error message if failed)
    """
    verifier = ConversionVerifier()
    return await verifier.verify_batch(root_path, verifications)


async def verify_conversion(root_path: str, original_filename: str, converted_filename: str) -> str | None:
    """
    Verify the conversion quality between original and converted files using Claude Code SDK.
    
    This is a convenience function that maintains backward compatibility.
    
    Args:
        root_path: The base directory path
        original_filename: The original file filename
        converted_filename: The converted file filename
        
    Returns:
        None if conversion is correct, error message if incorrect
    """
    verifier = ConversionVerifier()
    return await verifier.verify(root_path, original_filename, converted_filename)


async def main_async():
    """Async main function that supports both YAML and single file verification modes."""
    import sys

    # Check for different usage modes
    if len(sys.argv) == 2:
        # Mode 1: YAML file mode - python3 verifier.py <yaml_file>
        yaml_file = sys.argv[1]

        try:
            root_path, verifications, max_concurrent = load_verifications_from_yaml(yaml_file)
            print(f"Loaded {len(verifications)} verifications from {yaml_file}")
            print(f"Root directory: {root_path}")
            print(f"Max concurrent: {max_concurrent}")
            
            # Create ConversionVerifier and run batch verification
            verifier = ConversionVerifier(max_concurrent=max_concurrent)
        except Exception as e:
            print(f"Error loading YAML file: {e}")
            sys.exit(1)

    elif len(sys.argv) == 4:
        # Mode 2: Single file mode - python3 verifier.py <root_path> <original_filename> <converted_filename>
        root_path, original_filename, converted_filename = sys.argv[1], sys.argv[2], sys.argv[3]
        verifications = [VerificationItem(original_filename=original_filename, converted_filename=converted_filename)]
        
        # Create ConversionVerifier
        verifier = ConversionVerifier()

    else:
        print("""Usage:
  Mode 1 (YAML file):  python3 -m src.download2md.verifier <yaml_file>
  Mode 2 (Single file): python3 -m src.download2md.verifier <root_path> <original_filename> <converted_filename>

Examples:
  python3 -m src.download2md.verifier verifications_config.yaml
  python3 -m src.download2md.verifier ./docs page.html page.md
  python3 -m src.download2md.verifier ./docs page1 page1.md  # Flexible: finds page1.html

YAML file format:
  root_path: './conversions'
  max_concurrent: 3                      # Optional: concurrent limit (default: 5)
  verifications:
    - original_filename: 'page1.html'    # Exact filename
      converted_filename: 'page1.md'     # Exact filename
    - original_filename: 'page2'         # Flexible: finds page2.html/md/etc
      converted_filename: 'page2.md'     # Exact filename

Flexible filename matching:
  - If exact filename exists, it's used as-is
  - If filename has no extension and doesn't exist, searches for files with same base name
  - Matches files with known extensions (.html, .md, .txt, .json, .xml)
  - For same base name, first match found is used

Note: Uses ConversionVerifier class internally for robust
      verification with Claude Code SDK capabilities.""")
        sys.exit(1)

    try:
        # Use ConversionVerifier for the verification(s)
        results = await verifier.verify_batch(root_path, verifications)

        # Check results and count successes/failures
        total_verifications = len(verifications)
        passed_verifications = 0

        for key, result in results.items():
            if result is None:
                print(f"PASSED: {key}")
                passed_verifications += 1
            else:
                print(f"FAILED: {key} - {result}")

        print(f"Verification summary: {passed_verifications}/{total_verifications} verifications passed")

        if passed_verifications == total_verifications:
            print("All verifications passed successfully!")
        elif passed_verifications > 0:
            print(f"Partial success: {total_verifications - passed_verifications} verifications failed")
            sys.exit(1)
        else:
            print("All verifications failed!")
            sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main_async())
