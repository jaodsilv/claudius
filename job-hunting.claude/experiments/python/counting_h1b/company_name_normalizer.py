"""
Company Name Normalizer

This module provides functions to normalize company names by removing entity types,
punctuation, and standardizing formats.
"""

import re
from typing import Dict, List, Set

def remove_dba(name: str) -> str:
    """Remove DBA (Doing Business As) and FKA (Formerly Known As) variations from company name."""
    patterns = [
        # DBA variations
        r' D\W?B\W?A\W?( .*)?$',
        r' DOING BUSINESS AS .*$',
        r' D/B/A .*$',
        r' DBA .*$',
        # FKA variations
        r' PREVIOUSLY N.*$',
        r' P\W?K\W?A\W?( .*)?$',
        r' F\W?K\W?A\W?( .*)?$',
        r' FORMERLY KNOWN AS .*$',
        r' F/K/A .*$',
        r' FKA .*$'
    ]
    for pattern in patterns:
        name = re.sub(pattern, '', name)
    return name

def remove_entity_types(name: str) -> str:
    """Remove common entity type identifiers from company name."""
    patterns = [
        (r' ?P\W*L\W*L\W*C\W*($| )', lambda m: m.group(1) if m.group(1) else ''),
        (r' ?L\W*L\W*C\W*($| )', lambda m: m.group(1) if m.group(1) else ''),
        (r' ?L\W*L\W*P\W*($| )', lambda m: m.group(1) if m.group(1) else ''),
        (r' ?L\W*P\W*($| )', lambda m: m.group(1) if m.group(1) else ''),
        (r' ?P\W*[ACS]\W*($| )', lambda m: m.group(1) if m.group(1) else ''),
        (r' ?INC\W*( |$)', lambda m: m.group(1) if m.group(1) else ''),
        (r' ?CORP\W*( |$)', lambda m: m.group(1) if m.group(1) else ''),
        (r' ?LTD\W*( |$)', lambda m: m.group(1) if m.group(1) else ''),
    ]
    for pattern, replacement in patterns:
        name = re.sub(pattern, replacement, name)
    return name

def standardize_abbreviations(name: str) -> str:
    """Convert common words to their standardized abbreviations."""
    replacements = [
        (r' CORPORATION\W?( |$)', lambda m: ' CORP' + m.group(1)),
        (r' CORPORAT\W?( |$)', lambda m: ' CORP' + m.group(1)),
        (r' LIMITED\W?( |$)', lambda m: ' LTD' + m.group(1)),
        (r' COMPANY\W?( |$)', lambda m: ' CO' + m.group(1)),
        (r' INTERNATIONAL\W?( |$)', lambda m: ' INTL' + m.group(1)),
        (r' SERVICE(S?)\W?( |$)', lambda m: ' SVC' + m.group(1) + m.group(2)),
        (r' SERVIC(S?)\W?( |$)', lambda m: ' SVC' + m.group(1) + m.group(2)),
        (r' SERVI(S?)\W?( |$)', lambda m: ' SVC' + m.group(1) + m.group(2)),
        (r' SERV(S?)\W?( |$)', lambda m: ' SVC' + m.group(1) + m.group(2)),
        (r' HEALTH\W?( |$)', lambda m: ' HLTH' + m.group(1)),
        (r' TECHNOLOG(?:IES|Y)?\W?( |$)', lambda m: ' TECH' + m.group(1)),
        (r' SOLUTION(S?)\W?( |$)', lambda m: ' SOLN' + m.group(1) + m.group(2)),
        (r' SYSTEMS?\W?( |$)', lambda m: ' SYS' + m.group(1)),
        (r' SOFTWARE\W?( |$)', lambda m: ' SOFT' + m.group(1)),
        (r' INCORPORATED?\W?( |$)', lambda m: ' INC' + m.group(1)),
        (r' COMPUTERS?\W?( |$)', lambda m: ' COMP' + m.group(1)),
        (r' NORTHWEST\W?( |$)', lambda m: ' NW' + m.group(1)),
        (r' SOUTHWEST\W?( |$)', lambda m: ' SW' + m.group(1)),
        (r' NORTHEAST\W?( |$)', lambda m: ' NE' + m.group(1)),
        (r' SOUTHEAST\W?( |$)', lambda m: ' SE' + m.group(1)),
        (r' EASTERN\W?( |$)', lambda m: ' EAST' + m.group(1)),
        (r' WESTERN\W?( |$)', lambda m: ' WEST' + m.group(1)),
        (r' MIDWEST\W?( |$)', lambda m: ' MW' + m.group(1)),
        (r' MIDDLE\W?( |$)', lambda m: ' MID' + m.group(1)),
        (r' WASHINGTON\W?( |$)', lambda m: ' WA' + m.group(1)),
        (r' COOPERATIVE\W?( |$)', lambda m: ' COOP' + m.group(1)),
        (r' (?:MEDICAL|MEDICINE|MEDICINAL)\W?( |$)', lambda m: ' MED' + m.group(1)),
        (r' LABORATOR(?:Y|IES)\W?( |$)', lambda m: ' LAB' + m.group(1)),
        (r' CENT(?:ER)?(S?)\W?( |$)', lambda m: ' CTR' + m.group(1) + m.group(2)),
        (r' SAINTS?\W?( |$)', lambda m: ' ST' + m.group(1)),
        (r' CHURCH(?:ES)?\W?( |$)', lambda m: ' CH' + m.group(1)),
        (r' PRODUCE\W?( |$)', lambda m: ' PROD' + m.group(1)),
        (r' PRODUCTION(S?)\W?( |$)', lambda m: ' PROD' + m.group(1) + m.group(2))
    ]
    for pattern, replacement in replacements:
        name = re.sub(pattern, replacement, name)
    return name

def handle_special_cases(name: str) -> str:
    """Handle special cases like Facebook -> Meta, Alphabet -> Google."""
    special_cases = [
        (r'^FACEBOOK\W.*$', 'META'),
        (r'^ALPHABET\W.*$', 'GOOGLE')
    ]
    for pattern, replacement in special_cases:
        if re.match(pattern, name):
            return replacement
    return name

def normalize_punctuation(name: str) -> str:
    """Normalize punctuation and spacing in company name."""
    # Replace common separators with spaces
    name = re.sub(r'[&+,%-]', ' ', name)

    # Handle dots between words
    name = re.sub(r'(\w)\.(\w{2})', lambda m: m.group(1) + ' ' + m.group(2), name)
    name = re.sub(r'(\w{2})\.(\w)', lambda m: m.group(1) + ' ' + m.group(2), name)
    name = re.sub(r'(\w)\.(\w)', lambda m: m.group(1) + m.group(2), name)

    # Remove remaining punctuation
    name = re.sub(r'[^\w ]', '', name)

    # Normalize spaces
    name = re.sub(r'\s+', ' ', name)
    return name.strip()

def handle_big_corporations(name: str) -> str:
    """Handle special cases for big corporations."""
    big_corp_first_names = ['MICROSOFT', 'GOOGLE', 'META', 'CISCO', 'ORACLE', 'IBM',
                           'INTEL', 'NVIDIA', 'AMD', 'QUALCOMM', 'NINTENDO', 'SONY',
                           'APPLE PAYMENTS', 'PROVIDENCE']

    if any(bool(re.match(f"^{corp}\\W", name)) for corp in big_corp_first_names):
        return re.sub(r"^(\w+)\W.*", lambda m: m.group(1), name)
    return name

def handle_amazon_cases(name: str) -> str:
    """Handle special cases for Amazon companies."""
    if name.startswith('AMAZON') and 'PRODUCE' not in name:
        if 'WEB SERVICE' in name or 'WEB SVC' in name:
            return 'AMAZON WEB SERVICES'
        else:
            return 'AMAZON'
    return name

def remove_common_words(name: str) -> str:
    """Remove common words like conjunctions that don't add value."""
    # We should not AT from AT&T
    if name.startswith("AT T"):
        return name

    patterns = [
        r' AND ',
        r' OF ',
        r' THE ',
        r' FOR ',
        r' IN ',
        r' AT ',
    ]


    for pattern in patterns:
        name = name.replace(pattern, ' ')
    # Clean up any double spaces created
    return re.sub(r'\s+', ' ', re.sub(r'THE ', '', name)).strip()

def normalize_company_name(name: str) -> str:
    """
    Normalize company name by removing entity types, punctuation, and standardizing formats.

    Args:
        name (str): Company name to normalize

    Returns:
        str: Normalized company name
    """
    if not name:
        return ""

    # Convert to uppercase
    name = name.upper()

    # Apply transformations in order
    name = normalize_punctuation(name)  # First normalize punctuation so D/B/A becomes DBA
    name = remove_dba(name)  # Then remove DBA and variants
    name = handle_special_cases(name)
    name = remove_common_words(name)
    name = standardize_abbreviations(name)
    name = remove_entity_types(name)
    name = handle_big_corporations(name)
    name = handle_amazon_cases(name)

    # Final cleanup
    name = re.sub(r'\s+', ' ', name)
    return name.strip()
