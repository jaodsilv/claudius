import unittest
from .company_name_normalizer import (
    normalize_company_name,
    remove_dba,
    remove_entity_types,
    standardize_abbreviations,
    handle_special_cases,
    normalize_punctuation,
    handle_big_corporations,
    handle_amazon_cases,
    remove_common_words
)

class TestRemoveDBA(unittest.TestCase):
    def test_dba_removal(self):
        test_cases = [
            # DBA cases
            ("1 HOTEL KAUAI LLC DBA 1 HOTEL HANALEI BAY", "1 HOTEL KAUAI LLC"),
            ("BEXCO ENTERPRISE INC DBA MILLION D", "BEXCO ENTERPRISE INC"),
            ("COMPANY NAME DBA OTHER NAME", "COMPANY NAME"),
            ("COMPANY NAME DOING BUSINESS AS OTHER NAME", "COMPANY NAME"),
            ("COMPANY NAME D/B/A OTHER NAME", "COMPANY NAME"),
            # FKA cases
            ("COMPANY NAME FKA OLD NAME", "COMPANY NAME"),
            ("COMPANY NAME FORMERLY KNOWN AS OLD NAME", "COMPANY NAME"),
            ("COMPANY NAME F/K/A OLD NAME", "COMPANY NAME"),
            ("COMPANY NAME FKA OLD NAME", "COMPANY NAME"),
            # Mixed cases
            ("COMPANY NAME DBA CURRENT NAME FKA OLD NAME", "COMPANY NAME"),
            ("COMPANY NAME FKA OLD NAME DBA CURRENT NAME", "COMPANY NAME"),
        ]
        for input_name, expected in test_cases:
            with self.subTest(input_name=input_name):
                self.assertEqual(remove_dba(input_name), expected)

class TestRemoveEntityTypes(unittest.TestCase):
    def test_entity_type_removal(self):
        test_cases = [
            ("AAA GLOBAL TECHNOLOGIES LLC", "AAA GLOBAL TECHNOLOGIES"),
            ("MICROSOFT CORPORATION", "MICROSOFT CORPORATION"),  # Abbreviation handled by standardize_abbreviations
            ("GOOGLE INC", "GOOGLE"),
            ("COMPANY LIMITED", "COMPANY LIMITED"), # Abbreviation handled by standardize_abbreviations
            ("INTERNATIONAL COMPANY", "INTERNATIONAL COMPANY"),  # Abbreviation handled by standardize_abbreviations
        ]
        for input_name, expected in test_cases:
            with self.subTest(input_name=input_name):
                self.assertEqual(remove_entity_types(input_name), expected)

class TestStandardizeAbbreviations(unittest.TestCase):
    def test_abbreviation_standardization(self):
        test_cases = [
            ("INTERNATIONAL COMPANY", "INTERNATIONAL CO"),
            ("COMPANY INTERNATIONAL", "COMPANY INTL"),
            ("TECHNOLOGY SOLUTIONS", "TECHNOLOGY SOLNS"),
            ("SOLUTIONS TECHNOLOGY", "SOLUTIONS TECH"),
            ("SOFTWARE SYSTEMS", "SOFTWARE SYS"),
            ("SYSTEMS SOFTWARE", "SYSTEMS SOFT"),
            ("MEDICAL SERVICES", "MEDICAL SVCS"),
            ("SERVICES MEDICAL", "SERVICES MED"),
            ("NORTHWEST REGION", "NORTHWEST REGION"),
            ("REGION NORTHWEST", "REGION NW"),
            ("CORPORATION NAME", "CORPORATION NAME"),
            ("NAME CORPORATION", "NAME CORP"),
            ("LIMITED COMPANY", "LIMITED CO"),
            ("COMPANY LIMITED", "COMPANY LTD"),
            ("COMPANY NAME", "COMPANY NAME"),
            ("NAME COMPANY", "NAME CO"),
        ]
        for input_name, expected in test_cases:
            with self.subTest(input_name=input_name):
                self.assertEqual(standardize_abbreviations(input_name), expected)

class TestHandleSpecialCases(unittest.TestCase):
    def test_special_cases(self):
        test_cases = [
            ("FACEBOOK TECHNOLOGIES", "META"),
            ("ALPHABET INC", "GOOGLE"),
            ("OTHER COMPANY", "OTHER COMPANY"),  # Should remain unchanged
        ]
        for input_name, expected in test_cases:
            with self.subTest(input_name=input_name):
                self.assertEqual(handle_special_cases(input_name), expected)

class TestNormalizePunctuation(unittest.TestCase):
    def test_punctuation_normalization(self):
        test_cases = [
            ("COMPANY, INC.", "COMPANY INC"),
            ("COMPANY & CO.", "COMPANY CO"),
            ("COMPANY+LTD", "COMPANY LTD"),
            ("COMPANY.COM", "COMPANY COM"),
            ("COMPANY-NAME", "COMPANY NAME"),
        ]
        for input_name, expected in test_cases:
            with self.subTest(input_name=input_name):
                self.assertEqual(normalize_punctuation(input_name), expected)

class TestHandleBigCorporations(unittest.TestCase):
    def test_big_corporations(self):
        test_cases = [
            ("MICROSOFT CORPORATION", "MICROSOFT"),
            ("GOOGLE INC", "GOOGLE"),
            ("OTHER COMPANY", "OTHER COMPANY"),  # Should remain unchanged
        ]
        for input_name, expected in test_cases:
            with self.subTest(input_name=input_name):
                self.assertEqual(handle_big_corporations(input_name), expected)

class TestHandleAmazonCases(unittest.TestCase):
    def test_amazon_cases(self):
        test_cases = [
            ("AMAZON WEB SERVICES", "AMAZON WEB SERVICES"),
            ("AMAZON PRODUCE", "AMAZON PRODUCE"),
            ("AMAZON RETAIL", "AMAZON"),
            ("OTHER COMPANY", "OTHER COMPANY"),  # Should remain unchanged
        ]
        for input_name, expected in test_cases:
            with self.subTest(input_name=input_name):
                self.assertEqual(handle_amazon_cases(input_name), expected)

class TestNormalizeCompanyName(unittest.TestCase):
    def test_full_normalization(self):
        test_cases = [
            ("1 HOTEL KAUAI LLC DBA 1 HOTEL HANALEI BAY", "1 HOTEL KAUAI"),
            ("MICROSOFT CORPORATION", "MICROSOFT"),
            ("FACEBOOK TECHNOLOGIES", "META"),
            ("AMAZON WEB SERVICES", "AMAZON WEB SERVICES"),
            ("COMPANY, INC. & CO.", "COMPANY CO"),
            ("INTERNATIONAL TECHNOLOGY SOLUTIONS LLC", "INTERNATIONAL TECH SOLNS"),
        ]
        for input_name, expected in test_cases:
            with self.subTest(input_name=input_name):
                self.assertEqual(normalize_company_name(input_name), expected)

class TestRemoveCommonWords(unittest.TestCase):
    def test_remove_common_words(self):
        test_cases = [
            ("GRAND CONSTRUCTION AND DEVELOPMENT GROUP", "GRAND CONSTRUCTION DEVELOPMENT GROUP"),
            ("BANK OF AMERICA", "BANK AMERICA"),
            ("THE BOSTON CONSULTING GROUP", "BOSTON CONSULTING GROUP"),
            ("PARTNERS FOR PROGRESS", "PARTNERS PROGRESS"),
            ("DOCTORS IN TRAINING", "DOCTORS TRAINING"),
            ("AT&T CORPORATION", "AT&T CORPORATION"),  # Should not change AT&T
            ("AT T CORPORATION", "AT T CORPORATION"),  # Should not change AT T
            ("THE COMPANY NAME", "COMPANY NAME"),
            ("SCHOOL OF THE ARTS", "SCHOOL ARTS"),
            ("PARTNERS IN HEALTH AND WELLNESS", "PARTNERS HEALTH WELLNESS"),
            ("SOLUTIONS FOR THE FUTURE", "SOLUTIONS FUTURE"),
            ("INSTITUTE OF THE AMERICAS", "INSTITUTE AMERICAS"),
        ]
        for input_name, expected in test_cases:
            with self.subTest(input_name=input_name):
                self.assertEqual(remove_common_words(input_name), expected)

    def test_multiple_common_words(self):
        test_cases = [
            ("BANK OF THE WEST", "BANK WEST"),
            ("COLLEGE OF THE HOLY AND CROSS", "COLLEGE HOLY CROSS"),
            ("PARTNERS IN AND FOR HEALTH", "PARTNERS HEALTH"),
            ("THE SCHOOL OF THE ARTS AND SCIENCES", "SCHOOL ARTS SCIENCES"),
        ]
        for input_name, expected in test_cases:
            with self.subTest(input_name=input_name):
                self.assertEqual(remove_common_words(input_name), expected)

    def test_edge_cases(self):
        test_cases = [
            ("", ""),  # Empty string
            ("THE", "THE"),  # Single common word
            ("AND OF THE", "AND THE"),  # Only common words
            ("NORMAL", "NORMAL"),  # No common words
            ("AND NORMAL AND", "AND NORMAL AND"),  # Common words at edges
            ("THE    OF    AND", "AND"),  # Multiple spaces
        ]
        for input_name, expected in test_cases:
            with self.subTest(input_name=input_name):
                self.assertEqual(remove_common_words(input_name), expected)

if __name__ == '__main__':
    unittest.main()
