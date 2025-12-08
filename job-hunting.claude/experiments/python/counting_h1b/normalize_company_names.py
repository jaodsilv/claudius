#!/usr/bin/env python3
"""
Normalize Company Names

This script reads a file containing company names (one per line) and outputs
a file containing only the unique normalized versions of those names.
"""

import argparse
from company_name_normalizer import normalize_company_name

def normalize_names(input_file, output_file):
    """
    Read company names from input file, normalize them, and write unique normalized names to output file.

    Args:
        input_file (str): Path to input file containing company names
        output_file (str): Path to output file for normalized names
    """
    try:
        # Read input file
        with open(input_file, 'r') as f:
            names = {line.strip() for line in f if line.strip()}

        # Debug: Print a few examples before and after normalization
        print("\nDebug: First 5 names before normalization:")
        for name in list(names)[:6]:
            print(f"Before: {name}")
            normalized = normalize_company_name(name)
            print(f"After:  {normalized}\n")

        normalized_names = {normalize_company_name(name) for name in names}

        # Sort the normalized names
        sorted_names = sorted(list(normalized_names))

        # Write to output file
        with open(output_file, 'w') as f:
            for name in sorted_names:
                f.write(f"{name}\n")

        print(f"Processed {len(names)} names")
        print(f"Found {len(normalized_names)} unique normalized names")
        print(f"Output written to {output_file}")

    except Exception as e:
        print(f"Error: {e}")
        exit(1)

def main():
    parser = argparse.ArgumentParser(description='Normalize company names from a file')
    parser.add_argument('input_file', help='Path to input file containing company names (one per line)')
    parser.add_argument('output_file', help='Path to output file for normalized names')

    args = parser.parse_args()
    normalize_names(args.input_file, args.output_file)

if __name__ == "__main__":
    main()
