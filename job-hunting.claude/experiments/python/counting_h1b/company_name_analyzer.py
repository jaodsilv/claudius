"""
Company Name Analyzer

This module provides functions to analyze company names and extract patterns,
common words, and other metrics that can be used to improve company name matching.
"""

from collections import defaultdict, Counter
import re
from typing import Dict, List, Set
from company_name_normalizer import normalize_company_name

def analyze_company_name_patterns(file_path: str, min_word_freq: int = 5, min_acronym_length: int = 2) -> Dict:
    """
    Analyze company names to extract patterns, common words, and acronyms.
    First normalizes all names and eliminates duplicates before computing metrics.

    Args:
        file_path (str): Path to file containing company names (one per line)
        min_word_freq (int): Minimum frequency for a word to be considered common
        min_acronym_length (int): Minimum length for an acronym to be considered

    Returns:
        dict: Dictionary containing various metrics and patterns
    """
    # Read company names
    with open(file_path, 'r', encoding='utf-16') as f:
        raw_names = [line.strip() for line in f if line.strip()]

    # Normalize all names and create a mapping from normalized to original names
    normalized_to_original = {}
    for name in raw_names:
        norm_name = normalize_company_name(name)
        if norm_name:  # Only include non-empty normalized names
            if norm_name not in normalized_to_original:
                normalized_to_original[norm_name] = []
            normalized_to_original[norm_name].append(name)

    # Get unique normalized names
    company_names = list(normalized_to_original.keys())

    # Initialize metrics
    metrics = {
        'total_raw_names': len(raw_names),
        'total_unique_normalized_names': len(company_names),
        'word_frequencies': defaultdict(int),
        'prefix_frequencies': defaultdict(int),
        'suffix_frequencies': defaultdict(int),
        'acronyms': defaultdict(int),
        'common_phrases': defaultdict(int),
        'word_lengths': defaultdict(int),
        'name_lengths': defaultdict(int),
        'unique_words': set(),
        'word_positions': defaultdict(lambda: defaultdict(int)),
        'name_variations': normalized_to_original  # Store the mapping of normalized to original names
    }

    # Analyze each unique normalized name
    for norm_name in company_names:
        # Count name length
        metrics['name_lengths'][len(norm_name)] += 1

        # Split into words
        words = norm_name.split()

        # Count word frequencies and positions
        for i, word in enumerate(words):
            metrics['word_frequencies'][word] += 1
            metrics['word_lengths'][len(word)] += 1
            metrics['word_positions'][word][i] += 1
            metrics['unique_words'].add(word)

        # Count prefixes and suffixes
        if words:
            metrics['prefix_frequencies'][words[0]] += 1
            metrics['suffix_frequencies'][words[-1]] += 1

        # Look for acronyms (all caps words)
        for word in words:
            if word.isupper() and len(word) >= min_acronym_length:
                metrics['acronyms'][word] += 1

        # Look for common phrases (2-3 word combinations)
        for i in range(len(words) - 1):
            phrase = ' '.join(words[i:i+2])
            metrics['common_phrases'][phrase] += 1
            if i < len(words) - 2:
                phrase = ' '.join(words[i:i+3])
                metrics['common_phrases'][phrase] += 1

    # Filter and sort results
    metrics['common_words'] = {
        word: freq for word, freq in metrics['word_frequencies'].items()
        if freq >= min_word_freq
    }
    metrics['common_prefixes'] = {
        prefix: freq for prefix, freq in metrics['prefix_frequencies'].items()
        if freq >= min_word_freq
    }
    metrics['common_suffixes'] = {
        suffix: freq for suffix, freq in metrics['suffix_frequencies'].items()
        if freq >= min_word_freq
    }
    metrics['common_phrases'] = {
        phrase: freq for phrase, freq in metrics['common_phrases'].items()
        if freq >= min_word_freq
    }

    # Sort all metrics by frequency
    for key in ['common_words', 'common_prefixes', 'common_suffixes',
                'acronyms', 'common_phrases']:
        metrics[key] = dict(sorted(metrics[key].items(), key=lambda x: x[1], reverse=True))

    # Calculate word position statistics
    metrics['word_position_stats'] = {}
    for word, positions in metrics['word_positions'].items():
        if metrics['word_frequencies'][word] >= min_word_freq:
            total = sum(positions.values())
            avg_pos = sum(pos * count for pos, count in positions.items()) / total
            metrics['word_position_stats'][word] = {
                'frequency': metrics['word_frequencies'][word],
                'average_position': avg_pos,
                'position_distribution': dict(positions)
            }

    return metrics

def print_company_name_analysis(metrics: Dict):
    """
    Print the results of company name analysis in a readable format.

    Args:
        metrics (dict): Dictionary containing analysis metrics
    """
    print(f"\nTotal number of raw company names: {metrics['total_raw_names']}")
    print(f"Total number of unique normalized names: {metrics['total_unique_normalized_names']}")
    print(f"Total number of unique words: {len(metrics['unique_words'])}")

    print("\nMost common words:")
    for word, freq in list(metrics['common_words'].items())[:20]:
        print(f"  {word}: {freq}")

    print("\nMost common prefixes:")
    for prefix, freq in list(metrics['common_prefixes'].items())[:20]:
        print(f"  {prefix}: {freq}")

    print("\nMost common suffixes:")
    for suffix, freq in list(metrics['common_suffixes'].items())[:20]:
        print(f"  {suffix}: {freq}")

    print("\nMost common acronyms:")
    for acronym, freq in list(metrics['acronyms'].items())[:20]:
        print(f"  {acronym}: {freq}")

    print("\nMost common phrases (2-3 words):")
    for phrase, freq in list(metrics['common_phrases'].items())[:20]:
        print(f"  {phrase}: {freq}")

    print("\nWord length distribution:")
    for length, freq in sorted(metrics['word_lengths'].items()):
        print(f"  {length} letters: {freq}")

    print("\nName length distribution:")
    for length, freq in sorted(metrics['name_lengths'].items()):
        print(f"  {length} characters: {freq}")

    print("\nWord position statistics (for common words):")
    for word, stats in list(metrics['word_position_stats'].items())[:20]:
        print(f"\n  {word}:")
        print(f"    Frequency: {stats['frequency']}")
        print(f"    Average position: {stats['average_position']:.2f}")
        print("    Position distribution:")
        for pos, count in sorted(stats['position_distribution'].items()):
            print(f"      Position {pos}: {count}")

    # Print examples of name variations
    print("\nExamples of name variations (normalized -> original):")
    variations = list(metrics['name_variations'].items())
    for norm_name, originals in variations[:5]:  # Show first 5 examples
        print(f"\n  Normalized: {norm_name}")
        print("  Originals:")
        for original in originals:
            print(f"    - {original}")

def save_analysis_results(metrics: Dict, output_file: str):
    """
    Save analysis results to a file in a structured format.

    Args:
        metrics (dict): Dictionary containing analysis metrics
        output_file (str): Path to output file
    """
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("Company Name Analysis Results\n")
        f.write("============================\n\n")

        f.write(f"Total number of raw company names: {metrics['total_raw_names']}\n")
        f.write(f"Total number of unique normalized names: {metrics['total_unique_normalized_names']}\n")
        f.write(f"Total number of unique words: {len(metrics['unique_words'])}\n\n")

        f.write("Most Common Words\n")
        f.write("----------------\n")
        for word, freq in metrics['common_words'].items():
            f.write(f"{word}: {freq}\n")

        f.write("\nMost Common Prefixes\n")
        f.write("-------------------\n")
        for prefix, freq in metrics['common_prefixes'].items():
            f.write(f"{prefix}: {freq}\n")

        f.write("\nMost Common Suffixes\n")
        f.write("-------------------\n")
        for suffix, freq in metrics['common_suffixes'].items():
            f.write(f"{suffix}: {freq}\n")

        f.write("\nMost Common Acronyms\n")
        f.write("-------------------\n")
        for acronym, freq in metrics['acronyms'].items():
            f.write(f"{acronym}: {freq}\n")

        f.write("\nMost Common Phrases\n")
        f.write("------------------\n")
        for phrase, freq in metrics['common_phrases'].items():
            f.write(f"{phrase}: {freq}\n")

        f.write("\nWord Position Statistics\n")
        f.write("----------------------\n")
        for word, stats in metrics['word_position_stats'].items():
            f.write(f"\n{word}:\n")
            f.write(f"  Frequency: {stats['frequency']}\n")
            f.write(f"  Average position: {stats['average_position']:.2f}\n")
            f.write("  Position distribution:\n")
            for pos, count in sorted(stats['position_distribution'].items()):
                f.write(f"    Position {pos}: {count}\n")

        f.write("\nName Variations\n")
        f.write("--------------\n")
        for norm_name, originals in list(metrics['name_variations'].items())[:20]:  # Save first 20 examples
            f.write(f"\nNormalized: {norm_name}\n")
            f.write("Originals:\n")
            for original in originals:
                f.write(f"  - {original}\n")

def main():
    """Main function to run the analysis."""

    print("abc".__hash__())
    print(["a", "b", "c"].__hash__())


    # import sys

    # if len(sys.argv) != 3:
    #     print("Usage: python company_name_analyzer.py <input_file> <output_file>")
    #     sys.exit(1)

    # input_file = sys.argv[1]
    # output_file = sys.argv[2]

    # print(f"Analyzing company names from {input_file}...")
    # metrics = analyze_company_name_patterns(input_file)

    # print("\nAnalysis complete. Printing results...")
    # print_company_name_analysis(metrics)

    # print(f"\nSaving results to {output_file}...")
    # save_analysis_results(metrics, output_file)
    # print("Done!")

if __name__ == "__main__":
    main()
