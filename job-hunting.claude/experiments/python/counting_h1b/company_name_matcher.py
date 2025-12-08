"""
Company Name Matcher

This module provides functions to normalize and match company names with various formats and variations.
It handles common company naming inconsistencies like legal entity identifiers, punctuation, whitespace,
and "Doing Business As" (DBA) designations.

Usage:
    import company_name_matcher as cnm

    # Normalize a company name
    normalized = cnm.normalize_company_name("ACME Corp. LLC")

    # Calculate similarity between two company names
    similarity = cnm.calculate_similarity("ACME Corp.", "ACME Corporation")

    # Find similar companies in a TSV file
    similar_pairs = cnm.find_similar_companies("companies.tsv", threshold=85)

    # Get top companies by approvals
    top_companies = cnm.get_top_companies("companies.tsv", top_n=20, state_filter="CA")
"""

import pandas as pd
import re
import requests
from io import StringIO
from thefuzz import fuzz
from difflib import SequenceMatcher
from collections import defaultdict
from company_name_normalizer import normalize_company_name
import argparse
import os
import glob
from urllib.parse import urlparse


def calculate_similarity(name1: str, name2: str) -> float:
    """
    Calculate similarity between two company names.

    Args:
        name1 (str): First company name
        name2 (str): Second company name

    Returns:
        float: Similarity score between 0 and 1
    """
    # Normalize both names
    norm1 = normalize_company_name(name1)
    norm2 = normalize_company_name(name2)

    # Handle special cases
    if not norm1 or not norm2:
        return 0.0

    if norm1 == norm2:
        return 1.0

    # Define specific corporate families and their known subsidiaries
    amazon_pattern = r'^AMAZON\W'
    apple_pattern = r'^APPLE(?:\s+(?:PAYMENTS|INC))?$'

    # Check if the names match specific corporate family patterns
    if bool(re.match(amazon_pattern, norm1)) and "PRODUCE" not in norm1 and bool(re.match(amazon_pattern, norm2)) and "PRODUCE" not in norm2:
        return 1.0

    if bool(re.match(apple_pattern, norm1)) and bool(re.match(apple_pattern, norm2)):
        return 1.0

    # Calculate longest common substring
    matcher = SequenceMatcher(None, norm1, norm2)
    lcs = matcher.find_longest_match(0, len(norm1), 0, len(norm2))
    lcs_ratio = lcs.size / max(len(norm1), len(norm2))

   # Get tokens from both names and remove common business words
    tokens1 = set(norm1.split())
    tokens2 = set(norm2.split())

    COMMON_BUSINESS_WORDS = {
        'TECH', 'HLTH', 'SRVCS', 'SRVC', 'OF', 'SOLNS', 'SOLN', 'CONSULTING', 'WA', 'SEATTLE', 'USA', 'CTR', 'MANAGEMENT',
        'B', 'PS', 'D', 'A', 'THE', 'LABS', 'LAB', 'NW', 'CONSTRUCTION', 'COM', 'SCHOOL', 'INSTITUTE', 'RESEARCH', 'FOR',
        'US', 'S', 'ASSOCIATES', 'ENGINEERING', 'ARCHITECTURE', 'DEVELOPMENT', 'AMERICA', 'COMMUNITY', 'CAPITAL', 'AI',
        'INTL', 'MED', 'L', 'FOUNDATION', 'DESIGN', 'AI', 'SYS', 'GROUP',  'CAPITAL', 'CORP', 'GLOBAL', 'WORLD', 'AMERICAN',
        'ENTERPRISES', 'INDUSTRIES', 'ASSOCIATES', 'CARE', 'HIGH', 'NORTH', 'SOUTH', 'EAST', 'WEST', 'REGIONAL', 'PLAN'
    }

    # Get tokens from both names, excluding common words
    unique_words1 = {w for w in tokens1 if w not in COMMON_BUSINESS_WORDS}
    unique_words2 = {w for w in tokens2 if w not in COMMON_BUSINESS_WORDS}

    # If either name has no unique words after removing common words, return 0
    if not unique_words1 or not unique_words2:
        return 0

    # Calculate number of matching unique words
    matching_tokens = unique_words1.intersection(unique_words2)
    num_matching = len(matching_tokens)

    # If no unique words match, return 0
    if num_matching == 0:
        return 0

    # Require at least 2 matching unique words or a very long common substring
    if num_matching < 2 and lcs_ratio < 0.5:
        return 0.0

    # Calculate the ratio of matching unique words to total unique words
    min_unique_words = min(len(tokens1), len(tokens2))
    # Calculate word-based similarity
    unique_word_ratio = num_matching / min_unique_words

    # Combine scores
    similarity = 0.7 * unique_word_ratio + 0.3 * lcs_ratio

    return similarity

def one_name_contains_other(name1, name2):
    """
    Check if one name is contained within the other at word boundaries.
    This handles cases like abbreviated names or longer/shorter variants.

    Args:
        name1 (str): First normalized company name
        name2 (str): Second normalized company name

    Returns:
        bool: True if one name contains the other at word boundaries
    """
    if name1 == name2:
        return True

    # If one of the names is a single word, it cannot contain the other, e.g., "APPLE" cannot contain "APPLEXUS TECHNOLOGIES"
    if len(name1.split()) == 1 or len(name2.split()) == 1:
        return False

    # Check if one is a prefix of the other at word boundaries
    if len(name1) < len(name2):
        shorter, longer = name1, name2
    else:
        shorter, longer = name2, name1

    # Must be a substantial match (not just a couple of characters)
    if len(shorter) < 10:
        return False

    # Check if shorter is contained in longer at word boundaries
    if shorter + ' ' in longer + ' ':
        # The shorter name is a complete prefix of the longer name
        return True

    # Handle cases like "Amazon Com Services LLC" vs "Amazon.Com Services LLC"
    # by checking if the tokens are mostly contained
    tokens_shorter = set(shorter.split())
    tokens_longer = set(longer.split())

    # If most tokens from the shorter name are in the longer name
    if len(tokens_shorter.intersection(tokens_longer)) >= len(tokens_shorter) * 0.8:
        return True

    return False

def find_similar_companies(file_paths, threshold=85, company_column_index=2):
    """
    Find similar company names in a TSV file.

    Args:
        file_paths (str): Path to the TSV file containing company names
        threshold (int, optional): Minimum similarity score to consider companies as matches. Defaults to 85.
        company_column_index (int, optional): Index of the column containing company names. Defaults to 2.

    Returns:
        list: List of tuples (name1, name2, similarity) for companies with similarity >= threshold
    """
    # Read the TSV file
    df = pd.read_csv(file_paths, sep='\t')

    # Extract company names column
    company_column = df.columns[company_column_index]
    company_names = df[company_column].dropna().unique()

    # Store similar pairs
    similar_pairs = []

    # Compare each pair of companies
    for i, name1 in enumerate(company_names):
        for name2 in company_names[i+1:]:
            similarity = calculate_similarity(name1, name2)
            if similarity >= threshold:
                similar_pairs.append((name1, name2, similarity))

    # Sort by similarity score
    similar_pairs.sort(key=lambda x: x[2], reverse=True)

    return similar_pairs

def group_similar_companies(company_names, threshold=85):
    """
    Group similar company names together.

    Args:
        company_names (list): List of company names to group
        threshold (int, optional): Minimum similarity score to consider companies as matches. Defaults to 85.

    Returns:
        list: List of groups (lists) containing similar company names
    """
    # Initialize groups
    groups = []
    processed = set()

    for i, name1 in enumerate(company_names):
        if name1 in processed:
            continue

        # Create a new group with this company
        group = [name1]
        processed.add(name1)

        # Find similar companies
        for name2 in company_names[i+1:]:
            if name2 not in processed:
                similarity = calculate_similarity(name1, name2)
                if similarity >= threshold:
                    group.append(name2)
                    processed.add(name2)

        # Add the group to our groups list
        if len(group) > 1:  # Only add groups with more than one company
            groups.append(group)

    return groups

def load_data(sources, use_pandas=True):
    """
    Load data from file paths or URLs.

    Args:
        sources (str or list): Single file path/URL, folder path, or list of file paths/URLs
        use_pandas (bool, optional): Whether to use pandas for data loading. Defaults to True.

    Returns:
        pandas.DataFrame or list: Combined data from all sources
    """
    if isinstance(sources, str):
        sources = [sources]

    if use_pandas:
        dataframes = []

        def is_url(path):
            try:
                result = urlparse(path)
                return all([result.scheme, result.netloc])
            except:
                return False

        for source in sources:
            # Check if source is a URL
            if is_url(source):
                # Load from URL
                response = requests.get(source)
                response.raise_for_status()  # Raise exception for bad responses
                data = StringIO(response.text)
                df = pd.read_csv(data, sep='\t')
                dataframes.append(df)
                continue

            # Check if source is a directory
            if os.path.isdir(source):
                # Get all TSV files in the directory
                files = glob.glob(os.path.join(source, "*.tsv"))
                if not files:
                    print(f"Warning: No .tsv files found in directory: {source}")
                    continue
                sources.extend(files)
                continue

            # Handle local file paths
            # Try different encodings for local files
            encodings = ['utf-16', 'utf-8', 'latin1', 'cp1252', 'iso-8859-1']
            for encoding in encodings:
                try:
                    # First try to read just the first few lines to debug
                    with open(source, 'r', encoding=encoding) as f:
                        first_lines = [next(f) for _ in range(5)]
                    print(f"Successfully read file with encoding: {encoding}")
                    print("First few lines of the file:")
                    for line in first_lines:
                        print(line.strip())

                    # Now read the full file
                    df = pd.read_csv(source, sep='\t', encoding=encoding)
                    print(f"\nDataFrame columns: {df.columns.tolist()}")
                    print(f"DataFrame shape: {df.shape}")
                    break
                except UnicodeDecodeError:
                    print(f"Failed to read with encoding: {encoding}")
                    continue
                except Exception as e:
                    print(f"Error with encoding {encoding}: {str(e)}")
                    continue
            else:
                raise ValueError(f"Could not read file {source} with any of the attempted encodings: {encodings}")

            dataframes.append(df)

        # Combine all dataframes
        if len(dataframes) == 1:
            return dataframes[0]
        else:
            return pd.concat(dataframes, ignore_index=True)
    else:
        # Manual data loading without pandas
        data = []
        headers = None

        def is_url(path):
            try:
                result = urlparse(path)
                return all([result.scheme, result.netloc])
            except:
                return False

        for source in sources:
            # Check if source is a URL
            if is_url(source):
                # Load from URL
                response = requests.get(source)
                response.raise_for_status()
                content = response.text
                lines = content.split('\n')
            else:
                # Check if source is a directory
                if os.path.isdir(source):
                    files = glob.glob(os.path.join(source, "*.tsv"))
                    if not files:
                        print(f"Warning: No .tsv files found in directory: {source}")
                        continue
                    sources.extend(files)
                    continue

                # Handle local file paths
                encodings = ['utf-16', 'utf-8', 'latin1', 'cp1252', 'iso-8859-1']
                for encoding in encodings:
                    try:
                        with open(source, 'r', encoding=encoding) as f:
                            lines = f.readlines()
                        break
                    except UnicodeDecodeError:
                        continue
                    except Exception as e:
                        print(f"Error with encoding {encoding}: {str(e)}")
                        continue
                else:
                    raise ValueError(f"Could not read file {source} with any of the attempted encodings: {encodings}")

            # Process lines
            for line in lines:
                line = line.strip()
                if not line:
                    continue

                # Split by tab and handle potential encoding issues
                try:
                    fields = line.split('\t')
                except:
                    continue

                if headers is None:
                    headers = fields
                    continue

                if fields[0] == "Line by line":
                    continue

                if len(fields) != len(headers):
                    continue

                data.append(dict(zip(headers, fields)))

        return data

def extract_naics_codes(codes):
    """
    Extract the numeric part of NAICS codes from a series of codes.

    Args:
        codes (pandas.Series): Series containing NAICS codes

    Returns:
        list: Sorted list of unique numeric NAICS codes
    """
    return sorted(set(
        code.group(1) if (code := re.match(r"^(?:(\d\d(?:-\d\d)?) - .*)?$", str(c))) else None
        for c in codes.dropna()
        if code and code.group(1)  # Only include if there was a match and we got a group
    ))

def get_top_companies(sources, top_n=0, year_filter=None, state_filter=None,
                      similarity_threshold=85, employer_name_column='Employer (Petitioner) Name',
                      use_normalized_names=False, whitelist_file=None, use_pandas=True):
    """
    Get top companies by total approvals (Initial + Continuing), with grouped similar company names.

    Args:
        sources (str or list): Single file path/URL or list of file paths/URLs
        top_n (int, optional): Number of top companies to return. Use 0 for all companies.
        year_filter (int or list, optional): Filter by fiscal year(s). Defaults to None (all years).
        state_filter (str or list, optional): Filter by state(s). Defaults to None (all states).
        similarity_threshold (int, optional): Threshold for grouping similar companies. Defaults to 85.
        use_normalized_names (bool, optional): Whether to use normalized names throughout. Defaults to False.
        whitelist_file (str, optional): Path to file containing whitelisted company names. Defaults to None.
        use_pandas (bool, optional): Whether to use pandas for data processing. Defaults to True.

    Returns:
        pandas.DataFrame or list: Top companies with aggregated approval/denial counts
    """
    # Load data from sources
    data = load_data(sources, use_pandas=use_pandas)

    if use_pandas:
        df = data
        # Apply filters if provided
        if year_filter is not None:
            if isinstance(year_filter, (int, str)):
                year_filter = [int(year_filter)]
            df = df[df['Fiscal Year'].astype(int).isin(year_filter)]

        if state_filter is not None:
            if isinstance(state_filter, str):
                state_filter = [state_filter]
            df = df[df['Petitioner State'].isin(state_filter)]

        # If using normalized names, normalize the canonical names
        if use_normalized_names:
            df[employer_name_column] = df[employer_name_column].apply(normalize_company_name)

        # Extract company names and create a mapping
        company_names = df[employer_name_column].dropna().unique()

        # Group similar companies
        company_groups = []
        processed = set()

        for i, name1 in enumerate(company_names):
            if name1 in processed:
                continue

            # Create a new group with this company
            group = [name1]
            processed.add(name1)

            # Find similar companies
            for name2 in company_names[i+1:]:
                if name2 not in processed:
                    similarity = calculate_similarity(name1, name2)
                    if similarity >= similarity_threshold:
                        group.append(name2)
                        processed.add(name2)

            # Add the group to our groups list
            company_groups.append((name1, group))  # Use first name as canonical name

        # Create a mapping from each company name to its canonical name
        company_map = {}
        for canonical, group in company_groups:
            for name in group:
                company_map[name] = canonical

        # For companies not in any group, map to themselves
        for name in company_names:
            if name not in company_map:
                company_map[name] = name

        # Add canonical company name to dataframe
        df['Canonical Company'] = df[employer_name_column].map(company_map)

        # Convert numeric columns to integers
        numeric_columns = ['Initial Approval', 'Initial Denial', 'Continuing Approval', 'Continuing Denial']
        for col in numeric_columns:
            df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0).astype(int)

        # Aggregate data by canonical company name
        aggregated = df.groupby('Canonical Company').agg({
            'Initial Approval': 'sum',
            'Initial Denial': 'sum',
            'Continuing Approval': 'sum',
            'Continuing Denial': 'sum',
            'Industry (NAICS) Code': extract_naics_codes
        }).reset_index()

        # Calculate total approvals and denials and filter out companies with 0 total approvals
        aggregated['Total Approvals'] = aggregated['Initial Approval'] + aggregated['Continuing Approval']
        aggregated = aggregated[aggregated['Total Approvals'] > 0]
        aggregated['Total Denials'] = aggregated['Initial Denial'] + aggregated['Continuing Denial']

        # Calculate approval rate
        aggregated['total_cases'] = aggregated['Total Approvals'] + aggregated['Total Denials']
        aggregated['Approval Rate'] = (aggregated['Total Approvals'] / aggregated['total_cases'] * 100).round(1)

        # compute name lengths
        aggregated['name_len'] = aggregated['Canonical Company'].str.len()

        # Sort by total approvals
        result = aggregated.sort_values('Total Approvals', ascending=False)

        if top_n > 0:
            return result.head(top_n)
        else:
            return result
    else:
        # Manual processing without pandas
        # Apply filters
        if year_filter is not None:
            if isinstance(year_filter, (int, str)):
                year_filter = [int(year_filter)]
            data = [row for row in data if int(row.get('Fiscal Year', 0)) in year_filter]

        if state_filter is not None:
            if isinstance(state_filter, str):
                state_filter = [state_filter]
            data = [row for row in data if row.get('Petitioner State') in state_filter]

        # Group by company name
        company_data = {}
        for row in data:
            company_name = row.get(employer_name_column)
            if not company_name:
                continue

            if use_normalized_names:
                company_name = normalize_company_name(company_name)

            if company_name not in company_data:
                company_data[company_name] = {
                    'Initial Approval': 0,
                    'Initial Denial': 0,
                    'Continuing Approval': 0,
                    'Continuing Denial': 0,
                    'Industry (NAICS) Code': set()
                }

            # Sum up approvals and denials
            try:
                company_data[company_name]['Initial Approval'] += int(row.get('Initial Approval', 0).replace(",", ""))
                company_data[company_name]['Initial Denial'] += int(row.get('Initial Denial', 0).replace(",", ""))
                company_data[company_name]['Continuing Approval'] += int(row.get('Continuing Approval', 0).replace(",", ""))
                company_data[company_name]['Continuing Denial'] += int(row.get('Continuing Denial', 0).replace(",", ""))
            except:
                print(f'Failed for company {company_name}')
                raise

            # Process NAICS code
            naics_code = row.get('Industry (NAICS) Code')
            if naics_code:
                if match := re.match(r"^(?:(\d\d(?:-\d\d)?) - .*)?$", str(naics_code)):
                    if match.group(1):
                        company_data[company_name]['Industry (NAICS) Code'].add(match.group(1))

        # Convert to list of dictionaries
        result = []
        for company, stats in company_data.items():
            total_approvals = stats['Initial Approval'] + stats['Continuing Approval']
            if total_approvals > 0:
                total_denials = stats['Initial Denial'] + stats['Continuing Denial']
                total_cases = total_approvals + total_denials
                approval_rate = (total_approvals / total_cases * 100) if total_cases > 0 else 0

                result.append({
                    'Canonical Company': company,
                    'Initial Approval': stats['Initial Approval'],
                    'Initial Denial': stats['Initial Denial'],
                    'Continuing Approval': stats['Continuing Approval'],
                    'Continuing Denial': stats['Continuing Denial'],
                    'Total Approvals': total_approvals,
                    'Total Denials': total_denials,
                    'Approval Rate': round(approval_rate, 1),
                    'Industry (NAICS) Code': sorted(stats['Industry (NAICS) Code']),
                    'name_len': len(company)
                })

        # Sort by total approvals
        result.sort(key=lambda x: x['Total Approvals'], reverse=True)

        if top_n > 0:
            return result[:top_n]
        else:
            return result

def get_companies_by_distinct_names(sources, top_n=20, year_filter=None, state_filter=None, similarity_threshold=85, employer_name_column='Employer (Petitioner) Name'):
    """
    Get top companies by number of distinct name variations.

    Args:
        sources (str or list): Single file path/URL or list of file paths/URLs
        top_n (int, optional): Number of top companies to return. Defaults to 20.
        year_filter (int or list, optional): Filter by fiscal year(s). Defaults to None (all years).
        state_filter (str or list, optional): Filter by state(s). Defaults to None (all states).
        similarity_threshold (int, optional): Threshold for grouping similar companies. Defaults to 85.

    Returns:
        pandas.DataFrame: Top companies with their distinct name variations
    """
    # Load data from sources
    df = load_data(sources)

    # Apply filters if provided
    if year_filter is not None:
        if isinstance(year_filter, (int, str)):
            year_filter = [int(year_filter)]
        df = df[df['Fiscal Year'].astype(int).isin(year_filter)]

    if state_filter is not None:
        if isinstance(state_filter, str):
            state_filter = [state_filter]
        df = df[df['Petitioner State'].isin(state_filter)]

    # Extract company names and create a mapping
    company_names = df[employer_name_column].dropna().unique()

    # Group similar companies
    company_groups = []
    processed = set()

    for i, name1 in enumerate(company_names):
        if name1 in processed:
            continue

        # Create a new group with this company
        group = [name1]
        processed.add(name1)

        # Find similar companies
        for name2 in company_names[i+1:]:
            if name2 not in processed:
                similarity = calculate_similarity(name1, name2)
                if similarity >= similarity_threshold:
                    group.append(name2)
                    processed.add(name2)

        # Add the group to our groups list
        company_groups.append((name1, group))  # Use first name as canonical name

    # Create a mapping from each company name to its canonical name
    company_map = {}
    for canonical, group in company_groups:
        for name in group:
            company_map[name] = canonical

    # For companies not in any group, map to themselves
    for name in company_names:
        if name not in company_map:
            company_map[name] = name

    # Count distinct names per canonical company
    name_counts = defaultdict(list)
    for name, canonical in company_map.items():
        name_counts[canonical].append(name)

    # Convert to DataFrame
    result = pd.DataFrame([
        {
            'Canonical Company': canonical,
            'Distinct Names': len(names),
            'Name Variations': names
        }
        for canonical, names in name_counts.items()
    ])

    # Sort by number of distinct names and get top N
    result = result.sort_values('Distinct Names', ascending=False).head(top_n)

    return result

def test_examples():
    """Test company name matching with examples."""
    test_examples = [
        ("1UP HEALTH INC", "1UPHEALTH INC"),
        ("3 GIS LLC", "3-GIS LLC"),
        ("42 NORTH DENTAL CARE LLC", "42 NORTH DENTAL CARE PLLC"),
        ("84 51 LLC", "84.51 LLC"),
        ("A & B ENVIRONMENTAL SERVICES INC", "A and B ENVIRONMENTAL SERVICES INC"),
        ("A CARING DOCTOR MINNESOTA P A DBA BANFIELD PET HOSPITAL", "A CARING DOCTOR MINNESOTA PA DBA B")
    ]

    print("Test examples:")
    for name1, name2 in test_examples:
        similarity = calculate_similarity(name1, name2)
        print(f"Similarity: {similarity:.2f}%")
        print(f"  - {name1}")
        print(f"  - {name2}")
        print(f"  - Normalized: {normalize_company_name(name1)} | {normalize_company_name(name2)}")
        print()

def display_company_statistics(file_paths="d:/Downloads/Employer Information.2022-2024.WA.KingSnohomish.tsv", top_n=0, state=None,
                        year=None, multiline=False, employer_name_column='Employer (Petitioner) Name', output_file=None,
                        use_normalized_names=False, column_divider=' ', whitelist_file=None, use_pandas=True):
    """
    Display company statistics in a formatted table, showing approvals, denials, and NAICS codes.

    Args:
        file_paths (str): Path to the TSV file or directory containing company data
        top_n (int, optional): Number of top companies to display. Use 0 to show all companies.
        state (str, optional): Filter by state. Defaults to None (all states).
        year (int, optional): Filter by fiscal year. Defaults to None (all years).
        multiline (bool, optional): Whether to display each company's data on multiple lines. Defaults to False.
        employer_name_column (str, optional): Name of the column containing employer names. Defaults to 'Employer (Petitioner) Name'.
        output_file (str, optional): Path to output file. Defaults to None (print to stdout).
        use_normalized_names (bool, optional): Whether to use normalized company names. Defaults to False.
        column_divider (str, optional): Character to use as column divider. Defaults to ' '.
        whitelist_file (str, optional): Path to file containing whitelisted company names. Defaults to None.
        use_pandas (bool, optional): Whether to use pandas for data processing. Defaults to True.
    """
    top = get_top_companies(file_paths, top_n=top_n, year_filter=year, state_filter=state,
                           employer_name_column=employer_name_column, use_normalized_names=use_normalized_names,
                           whitelist_file=whitelist_file, use_pandas=use_pandas)

    # Create a context manager for output
    import sys
    from contextlib import contextmanager

    @contextmanager
    def get_output_handle():
        if output_file:
            with open(output_file, 'w') as f:
                yield f
        else:
            yield sys.stdout

    with get_output_handle() as out:
        if top_n == 0:
            print(f"All Companies by Total Approvals", file=out)
        else:
            print(f"Top {top_n} Companies by Total Approvals", file=out)
        if state:
            print(f"Filtered by State: {state}", file=out)
        if year:
            print(f"Filtered by Year: {year}", file=out)
        print("\n" + "-" * 100, file=out)

        max_chars_len = 0
        max_approvals = 0
        max_denials = 0
        max_approval_rate = 0
        min_approval_rate = 100

        # Format the output for better readability
        if use_pandas:
            pos_len = len(str(len(top))) if top_n == 0 else len(str(top_n))
            company_len = top['name_len'].max()
            data = top.to_dict('records')
        else:
            pos_len = len(str(len(top))) if top_n == 0 else len(str(top_n))
            company_len = max(row['name_len'] for row in top)
            data = top

        approvals_len = 9
        denials_len = 7
        rate_len = 6
        naics_len = 100  # Add space for NAICS codes
        line_len = pos_len+company_len+approvals_len+denials_len+rate_len+naics_len+8 # 5 for divisions + 2 for borders + 1 for percent sign
        line_division = "-" * line_len
        print(line_division, file=out)
        print(f"|{'Pos':>{pos_len}}|{'Company':<{company_len}}|{'Approvals':>{approvals_len}}|{'Denials':>{denials_len}}|{'Rate':>{rate_len + 1}}|{'NAICS Codes':<{naics_len}}|", file=out)
        print(line_division, file=out)

        for i, row in enumerate(data):
            if multiline:
                print(f"Company: {row['Canonical Company']}", file=out)
                print(f"  Total Approvals: {int(row['Total Approvals'])}", file=out)
                print(f"    - Initial: {int(row['Initial Approval'])}", file=out)
                print(f"    - Continuing: {int(row['Continuing Approval'])}", file=out)
                print(f"  Total Denials: {int(row['Total Denials'])}", file=out)
                print(f"    - Initial: {int(row['Initial Denial'])}", file=out)
                print(f"    - Continuing: {int(row['Continuing Denial'])}", file=out)
                print(f"  Approval Rate: {row['Approval Rate']:.1f}%", file=out)
                print(f"  NAICS Codes: {', '.join(f'\"{code}\"' for code in row['Industry (NAICS) Code'])}", file=out)
                print("-" * 100, file=out)
            else:
                naics_str = ', '.join(f'\"{code}\"' for code in row['Industry (NAICS) Code'])
                print(
                    f"|{i+1:>{pos_len}}"
                    f"{column_divider}{row['Canonical Company']:<{company_len}}"
                    f"{column_divider}{row['Total Approvals']:>{approvals_len}}"
                    f"{column_divider}{row['Total Denials']:>{denials_len}}"
                    f"{column_divider}{row['Approval Rate']:>{rate_len}.1f}%"
                    f"{column_divider}{naics_str:<{naics_len}}|",
                    file=out
                )

            max_chars_len = max(max_chars_len, len(row['Canonical Company']))
            max_approvals = max(max_approvals, int(row['Total Approvals']))
            max_denials = max(max_denials, int(row['Total Denials']))
            if row['Approval Rate'] != 100:
                max_approval_rate = max(max_approval_rate, row['Approval Rate'])
            if row['Approval Rate'] != 0:
                min_approval_rate = min(min_approval_rate, row['Approval Rate'])

        print(line_division, file=out)
        print(f"Max chars len: {max_chars_len}", file=out)
        print(f"Max approvals: {max_approvals}", file=out)
        print(f"Max denials: {max_denials}", file=out)
        print(f"Max approval rate: {max_approval_rate:.1f}%", file=out)
        print(f"Min approval rate: {min_approval_rate:.1f}%", file=out)
        print(line_division, file=out)
        print('', file=out)

def test_group_similar_companies():
    """
    Test the group_similar_companies function with various similarity cases.
    This test covers different types of string similarity:
    - Simple ratio: minor variations (typos, spacing)
    - Partial ratio: one name contained in another
    - Token sort ratio: same words in different order
    - Longest common substring: significant shared substring
    """
    test_companies = [
        # Group 1: Simple ratio matches (minor variations)
        "Acme Technology Inc",
        "ACME TECHNOLOGY INC",  # Same but different case
        "Acme Tecnology Inc",   # Typo

        # Group 2: Partial ratio matches (substring matches)
        "Global Software Solutions",
        "Global Software",      # Shorter version
        "The Global Software Solutions Company",  # Longer version

        # Group 3: Token sort ratio matches (word order differences)
        "Blue Ocean Consulting Group",
        "Consulting Group Blue Ocean",  # Same words, different order

        # Group 4: Longest common substring matches (significant overlap)
        "Northern California Healthcare Partners",
        "Northern California Medical Group",  # Shared prefix

        # Group 5: Strong case for longest common substring
        "International Digital Security Systems Associates",
        "Advanced Digital Security Systems LLC",  # "Digital Security Systems" is the common substring

        # Group 6: Mixed similarity types
        "Smith & Johnson Legal Services",
        "Smith and Johnson Legal",  # Ampersand vs "and" + substring

        # Group 7: Should not match with others
        "XYZ Industries Ltd",
        "ABC Financial Group",

        # Group 8: Apple, a common name with a huge company with the simplest one.
        "APPLE AMERICAN GROUP LLC",
        "APPLE AND HONEY LLC DBA HMH IRON D",
        "APPLE FREIGHT INC",
        "APPLE INC",
        "APPLE PAYMENTS SERVICES LLC",
        "APPLE PROCESSING LLC",
        "APPLEGREEN ELECTRIC US INC",
        "APPLEGREEN USA CENTRAL SERVICES LL",
        "APPLET SYSTEMS LLC",
        "APPLETON DENTAL CARE LLC",
        "APPLEXUS TECHNOLOGIES INC",
        "BERRY APPLEMAN AND LEIDEN LLP",
        "BIG APPLE OCCUPATIONAL SAFETY INC",
        "BIG APPLE SIGN CORPORATION DBA BIG",
        "BIG APPLE SIGN CORPORATION DBA BIG APPLE VISUAL GROUP",
        "GOOD APPLE PUBLISHING LLC",
        "PROJECT APPLECART LLC",
        "RED APPLE MANAGEMENT COMPANY LLC",
        "SANA GLOBAL INC D/B/A GREEN APPLE PHARMACY",
        "PINEAPPLE GAME DAVIS",
        "PINEAPPLE VENTURE LLC",

        # GROUP 9: AMAZON
        "AMAZON ADVERTISING LLC",
        "AMAZON CAPITAL SERVICES INC",
        "AMAZON COM CA INC",
        "AMAZON COM SERVICES LLC",
        "AMAZON DATA SERVICES INC",
        "AMAZON DEVELOPMENT CENTER U S INC",
        "AMAZON DEVELOPMENT CENTER US INC",
        "AMAZON PAYMENTS INC",
        "AMAZON PRODUCE NETWORK LLC",
        "AMAZON REGISTRY SERVICES INC",
        "AMAZON RETAIL LLC",
        "AMAZON STUDIOS LLC",
        "AMAZON WEB SERVICES INC",
        "AMAZON.COM SERVICES LLC"
    ]

    # Run the grouping with a threshold that should catch our similar names
    groups = group_similar_companies(test_companies, threshold=80)

    # Print results
    print("\nCompany Grouping Test Results:")
    print(f"Found {len(groups)} groups from {len(test_companies)} company names\n")

    for i, group in enumerate(groups, 1):
        print(f"Group {i}:")
        for company in group:
            print(f"  - {company}")
        print()

    # Print companies that weren't grouped
    all_grouped = set()
    for group in groups:
        all_grouped.update(group)

    not_grouped = set(test_companies) - all_grouped
    if not_grouped:
        print("Companies not in any group:")
        for company in not_grouped:
            print(f"  - {company}")
        print()

    # Print similarity scores between each pair in a group to show which metric caught them
    print("Similarity details for grouped companies:")
    for i, group in enumerate(groups, 1):
        print(f"Group {i} similarity scores:")
        for j, name1 in enumerate(group):
            for name2 in group[j+1:]:
                # Calculate individual metrics
                norm_name1 = normalize_company_name(name1)
                norm_name2 = normalize_company_name(name2)
                ratio = fuzz.ratio(norm_name1, norm_name2)
                partial_ratio = fuzz.partial_ratio(norm_name1, norm_name2)
                token_sort_ratio = fuzz.token_sort_ratio(norm_name1, norm_name2)
                matcher = SequenceMatcher(None, norm_name1, norm_name2)
                lcs_ratio = matcher.ratio() * 100
                max_ratio = max(ratio, partial_ratio, token_sort_ratio, lcs_ratio)

                # Highlight which metric is highest
                metrics = [
                    (ratio, "Simple Ratio"),
                    (partial_ratio, "Partial Ratio"),
                    (token_sort_ratio, "Token Sort Ratio"),
                    (lcs_ratio, "Longest Common Substring")
                ]

                # Find which metric caused the match
                max_metric = max(metrics, key=lambda x: x[0])
                match_type = max_metric[1]

                print(f"  {name1} <-> {name2}")
                print(f"    - Simple Ratio: {ratio:.1f}%")
                print(f"    - Partial Ratio: {partial_ratio:.1f}%")
                print(f"    - Token Sort Ratio: {token_sort_ratio:.1f}%")
                print(f"    - Longest Common Substring: {lcs_ratio:.1f}%")
                print(f"    - Match type: {match_type} ({max_ratio:.1f}%)\n")

    return groups

def test_companies_by_distinct_names(file_paths="d:/Downloads/Employer Information.2022-2024.WA.KingSnohomish.tsv", state=None, year=None):
    """Test the companies by distinct names functionality with the specified filters."""
    result = get_companies_by_distinct_names(file_paths, top_n=20, year_filter=year, state_filter=state)

    print(f"Top {len(result)} Companies by Number of Distinct Name Variations")
    if state:
        print(f"Filtered by State: {state}")
    if year:
        print(f"Filtered by Year: {year}")
    print("\n" + "-" * 100)

    for i, row in result.iterrows():
        print(f"\n{i+1}. {row['Canonical Company']}")
        print(f"   Number of distinct names: {row['Distinct Names']}")
        print("   Name variations:")
        for name in row['Name Variations']:
            print(f"   - {name}")
        print("-" * 100)

# If file_paths is a directory and file_pattern is provided, filter files
def get_matching_tsv_files(directory: str, pattern: str) -> list:
    """
    Get list of TSV files in directory matching the given pattern.

    Args:
        directory (str): Directory path to search
        pattern (str): Regex pattern to match filenames against

    Returns:
        list: List of matching file paths

    Raises:
        SystemExit: If no matching files are found
    """
    pattern = re.compile(pattern)
    files = [f for f in glob.glob(os.path.join(directory, "*.tsv"))
            if pattern.search(os.path.basename(f))]
    if not files:
        print(f"Warning: No files matching pattern '{pattern}' found in directory: {directory}")
        exit(1)
    return files

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Analyze H1B company data')
    parser.add_argument('--file_paths', type=str, default="d:/Downloads/Employer Information.2022-2024.WA.KingSnohomish.tsv",
                        help='Path to the TSV file or directory containing company data. If a directory is provided, all .tsv files will be processed.')
    parser.add_argument('--file_pattern', type=str, default=None,
                        help='Regex pattern to filter files when a directory is provided')
    parser.add_argument('--top_n', type=int, default=0,
                        help='Number of top companies to display. Use 0 to show all companies.')
    parser.add_argument('--employer_name_column', type=str, default='Employer (Petitioner) Name',
                        help='Name of the column containing employer names')
    parser.add_argument('--output_file', type=str, default=None,
                        help='Path to output file (default: print to stdout)')
    parser.add_argument('--normalized_names', action='store_true',
                        help='Use normalized company names throughout the entire process')
    parser.add_argument('--column_divider', type=str, default=' ',
                        help='Character to use as column divider (default: space)')
    parser.add_argument('--whitelist', type=str, default=None,
                        help='Path to file containing whitelisted company names (one per line)')
    parser.add_argument('--no_use_pandas', action='store_true', default=False,
                        help='Do not use pandas for data processing (default: False)')

    args = parser.parse_args()

    if os.path.isdir(args.file_paths) and args.file_pattern:
        args.file_paths = get_matching_tsv_files(args.file_paths, args.file_pattern)

    display_company_statistics(
        file_paths=args.file_paths,
        top_n=args.top_n,
        employer_name_column=args.employer_name_column,
        output_file=args.output_file,
        use_normalized_names=args.normalized_names,
        column_divider=args.column_divider,
        whitelist_file=args.whitelist,
        use_pandas = not args.no_use_pandas
    )
