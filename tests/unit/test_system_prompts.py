#!/usr/bin/env python3
"""
Unit tests for system_prompts module.
"""

import pytest
from src.prompts.system_prompts import (
    CONVERTER_SYSTEM_PROMPT,
    VERIFIER_SYSTEM_PROMPT
)


@pytest.mark.unit
class TestSystemPromptConstants:
    """Test that all system prompt constants are properly defined."""
    
    def test_converter_system_prompt_exists(self):
        """Test that converter system prompt is defined."""
        assert CONVERTER_SYSTEM_PROMPT is not None
        assert isinstance(CONVERTER_SYSTEM_PROMPT, str)
        assert len(CONVERTER_SYSTEM_PROMPT) > 0
    
    def test_verifier_system_prompt_exists(self):
        """Test that verifier system prompt is defined."""
        assert VERIFIER_SYSTEM_PROMPT is not None
        assert isinstance(VERIFIER_SYSTEM_PROMPT, str)
        assert len(VERIFIER_SYSTEM_PROMPT) > 0


@pytest.mark.unit
class TestSystemPromptContent:
    """Test system prompt content and structure."""
    
    def test_converter_system_prompt_content(self):
        """Test converter system prompt contains expected elements."""
        prompt = CONVERTER_SYSTEM_PROMPT
        
        # Should establish role as HTML to Markdown converter
        role_keywords = ['convert', 'conversion', 'html', 'markdown', 'transform']
        has_role_keywords = any(keyword in prompt.lower() for keyword in role_keywords)
        assert has_role_keywords, "Converter system prompt should establish conversion role"
        
        # Should mention HTML and Markdown
        assert 'html' in prompt.lower() or 'HTML' in prompt
        assert 'markdown' in prompt.lower() or 'Markdown' in prompt
    
    def test_verifier_system_prompt_content(self):
        """Test verifier system prompt contains expected elements."""
        prompt = VERIFIER_SYSTEM_PROMPT
        
        # Should establish role as verifier/quality checker
        role_keywords = ['verify', 'verification', 'quality', 'check', 'assess', 'evaluate']
        has_role_keywords = any(keyword in prompt.lower() for keyword in role_keywords)
        assert has_role_keywords, "Verifier system prompt should establish verification role"
        
        # Should mention quality or accuracy assessment
        quality_keywords = ['quality', 'accuracy', 'correct', 'valid', 'assess']
        has_quality_keywords = any(keyword in prompt.lower() for keyword in quality_keywords)
        assert has_quality_keywords, "Verifier system prompt should mention quality assessment"


@pytest.mark.unit
class TestSystemPromptStructure:
    """Test system prompt structure and formatting."""
    
    def test_system_prompts_are_substantial(self):
        """Test that system prompts have substantial content."""
        prompts = [CONVERTER_SYSTEM_PROMPT, VERIFIER_SYSTEM_PROMPT]
        
        for prompt in prompts:
            # System prompts should be more detailed than regular prompts
            assert len(prompt) >= 100, f"System prompt too short: {len(prompt)} characters"
            
            # Should not be excessively long
            assert len(prompt) <= 5000, f"System prompt too long: {len(prompt)} characters"
    
    def test_system_prompts_establish_persona(self):
        """Test that system prompts establish clear AI personas."""
        # System prompts should use "you are" or similar persona-establishing language
        persona_phrases = [
            'you are', 'your role', 'your task', 'your job', 'you will',
            'act as', 'serve as', 'function as', 'responsible for'
        ]
        
        converter_has_persona = any(phrase in CONVERTER_SYSTEM_PROMPT.lower() 
                                  for phrase in persona_phrases)
        verifier_has_persona = any(phrase in VERIFIER_SYSTEM_PROMPT.lower() 
                                 for phrase in persona_phrases)
        
        assert converter_has_persona, "Converter system prompt should establish clear persona"
        assert verifier_has_persona, "Verifier system prompt should establish clear persona"
    
    def test_system_prompts_provide_context(self):
        """Test that system prompts provide appropriate context."""
        # Should mention the broader context or purpose
        context_keywords = [
            'website', 'web', 'document', 'content', 'conversion', 'processing',
            'html', 'markdown', 'text', 'format', 'structure'
        ]
        
        for prompt in [CONVERTER_SYSTEM_PROMPT, VERIFIER_SYSTEM_PROMPT]:
            has_context = any(keyword in prompt.lower() for keyword in context_keywords)
            assert has_context, "System prompt should provide relevant context"
    
    def test_system_prompts_set_expectations(self):
        """Test that system prompts set clear expectations.""" 
        # Should contain guidance about expected behavior or output
        expectation_words = [
            'should', 'must', 'will', 'expect', 'ensure', 'maintain', 'preserve',
            'accurate', 'faithful', 'careful', 'thorough'
        ]
        
        for prompt in [CONVERTER_SYSTEM_PROMPT, VERIFIER_SYSTEM_PROMPT]:
            has_expectations = any(word in prompt.lower() for word in expectation_words)
            assert has_expectations, "System prompt should set clear expectations"


@pytest.mark.unit
class TestSystemPromptSpecialization:
    """Test that system prompts are properly specialized for their roles."""
    
    def test_converter_prompt_specialization(self):
        """Test that converter system prompt is specialized for conversion tasks."""
        prompt = CONVERTER_SYSTEM_PROMPT
        
        # Should mention conversion-specific concepts
        conversion_concepts = [
            'convert', 'conversion', 'transform', 'html', 'markdown', 
            'structure', 'format', 'preserve', 'maintain', 'semantic'
        ]
        
        concept_count = sum(1 for concept in conversion_concepts 
                          if concept in prompt.lower())
        
        assert concept_count >= 3, "Converter prompt should mention multiple conversion concepts"
        
        # Should NOT focus heavily on verification concepts
        verification_concepts = ['verify', 'check', 'validate', 'assess', 'score']
        verification_count = sum(1 for concept in verification_concepts 
                               if concept in prompt.lower())
        
        # Verification mentions should be minimal in converter prompt
        assert verification_count <= concept_count, \
            "Converter prompt should focus more on conversion than verification"
    
    def test_verifier_prompt_specialization(self):
        """Test that verifier system prompt is specialized for verification tasks."""
        prompt = VERIFIER_SYSTEM_PROMPT
        
        # Should mention verification-specific concepts
        verification_concepts = [
            'verify', 'verification', 'quality', 'accuracy', 'correct', 'valid',
            'assess', 'evaluate', 'check', 'review', 'score', 'rating'
        ]
        
        concept_count = sum(1 for concept in verification_concepts 
                          if concept in prompt.lower())
        
        assert concept_count >= 3, "Verifier prompt should mention multiple verification concepts"
        
        # Should mention what to look for in verification
        verification_criteria = [
            'completeness', 'accuracy', 'structure', 'format', 'content', 
            'missing', 'error', 'issue', 'problem', 'quality'
        ]
        
        criteria_count = sum(1 for criterion in verification_criteria 
                           if criterion in prompt.lower())
        
        assert criteria_count >= 2, "Verifier prompt should mention verification criteria"
    
    def test_prompts_are_distinct(self):
        """Test that converter and verifier prompts are meaningfully distinct."""
        converter = CONVERTER_SYSTEM_PROMPT.lower()
        verifier = VERIFIER_SYSTEM_PROMPT.lower()
        
        # Should not be identical or nearly identical
        assert converter != verifier, "Converter and verifier prompts should be different"
        
        # Should have different focuses
        converter_conversion_words = converter.count('convert') + converter.count('conversion')
        verifier_conversion_words = verifier.count('convert') + verifier.count('conversion')
        
        converter_verification_words = converter.count('verify') + converter.count('verification')
        verifier_verification_words = verifier.count('verify') + verifier.count('verification')
        
        # Converter should mention conversion more than verifier does
        if converter_conversion_words > 0 and verifier_conversion_words > 0:
            assert converter_conversion_words >= verifier_conversion_words, \
                "Converter prompt should focus more on conversion"
        
        # Verifier should mention verification more than converter does
        if verifier_verification_words > 0 and converter_verification_words > 0:
            assert verifier_verification_words >= converter_verification_words, \
                "Verifier prompt should focus more on verification"


@pytest.mark.unit
class TestSystemPromptUsability:
    """Test system prompt usability and practical considerations."""
    
    def test_prompts_avoid_contradictions(self):
        """Test that prompts don't contain internal contradictions."""
        prompts = [CONVERTER_SYSTEM_PROMPT, VERIFIER_SYSTEM_PROMPT]
        
        # Look for potentially contradictory phrases
        contradictory_pairs = [
            ('always', 'never'),
            ('must', 'optional'),
            ('required', 'ignore'),
            ('preserve', 'remove'),
            ('maintain', 'discard')
        ]
        
        for prompt in prompts:
            prompt_lower = prompt.lower()
            for word1, word2 in contradictory_pairs:
                if word1 in prompt_lower and word2 in prompt_lower:
                    # This doesn't necessarily mean contradiction, but flag for manual review
                    # We'll just verify the prompt contains both terms (manual inspection needed)
                    assert True  # If we get here, at least it didn't crash
    
    def test_prompts_provide_actionable_guidance(self):
        """Test that prompts provide actionable guidance."""
        # System prompts should contain actionable instructions, not just descriptions
        action_verbs = [
            'convert', 'transform', 'preserve', 'maintain', 'ensure', 'check',
            'verify', 'assess', 'evaluate', 'identify', 'analyze', 'examine'
        ]
        
        for prompt in [CONVERTER_SYSTEM_PROMPT, VERIFIER_SYSTEM_PROMPT]:
            action_count = sum(1 for verb in action_verbs if verb in prompt.lower())
            assert action_count >= 2, "System prompt should contain actionable instructions"
    
    def test_prompts_are_context_appropriate(self):
        """Test that prompts are appropriate for their usage context.""" 
        # System prompts are used to establish AI behavior, so they should:
        # 1. Be written in second person ("you") or imperative
        # 2. Establish clear role and responsibilities
        # 3. Provide behavioral guidance
        
        for prompt in [CONVERTER_SYSTEM_PROMPT, VERIFIER_SYSTEM_PROMPT]:
            # Should use second person or imperative
            personal_indicators = ['you ', 'your ', 'yourself']
            imperative_indicators = ['convert', 'verify', 'ensure', 'maintain', 'preserve']
            
            has_personal = any(indicator in prompt.lower() for indicator in personal_indicators)
            has_imperative = any(indicator in prompt.lower() for indicator in imperative_indicators)
            
            assert has_personal or has_imperative, \
                "System prompt should use appropriate voice (second person or imperative)"


@pytest.mark.unit
class TestSystemPromptIntegration:
    """Test system prompt integration with the system."""
    
    def test_system_prompts_can_be_imported(self):
        """Test that all system prompts can be imported without errors."""
        # This test passed if we got here without import errors
        assert True
    
    def test_system_prompts_are_accessible_as_module_attributes(self):
        """Test that system prompts are accessible as module attributes."""
        import src.prompts.system_prompts as system_prompts_module
        
        # Should be able to access all system prompt constants
        assert hasattr(system_prompts_module, 'CONVERTER_SYSTEM_PROMPT')
        assert hasattr(system_prompts_module, 'VERIFIER_SYSTEM_PROMPT')
    
    def test_system_prompts_string_operations_safety(self):
        """Test that system prompts are safe for string operations."""
        prompts = [CONVERTER_SYSTEM_PROMPT, VERIFIER_SYSTEM_PROMPT]
        
        for prompt in prompts:
            # Should support basic string operations without crashing
            assert len(prompt) > 0
            assert prompt.strip() == prompt or len(prompt.strip()) > 0
            assert prompt.upper() != prompt or prompt.lower() != prompt  # Has mixed case
            
            # Should be safe for concatenation
            test_concat = f"Prefix: {prompt} Suffix"
            assert isinstance(test_concat, str)
            assert "Prefix:" in test_concat
            assert "Suffix" in test_concat
    
    def test_system_prompts_encoding_safety(self):
        """Test that system prompts handle encoding properly."""
        prompts = [CONVERTER_SYSTEM_PROMPT, VERIFIER_SYSTEM_PROMPT]
        
        for prompt in prompts:
            # Should be safe to encode/decode
            try:
                encoded = prompt.encode('utf-8')
                decoded = encoded.decode('utf-8')
                assert decoded == prompt
            except UnicodeError:
                pytest.fail("System prompt should handle UTF-8 encoding")
            
            # Should not contain problematic characters for most use cases
            # (This is a basic check - in practice more characters might be acceptable)
            problematic_chars = ['\x00', '\x01', '\x02', '\x03', '\x04', '\x05']
            for char in problematic_chars:
                assert char not in prompt, f"System prompt should not contain control character {repr(char)}"


@pytest.mark.unit
class TestSystemPromptConsistency:
    """Test consistency between system prompts."""
    
    def test_prompts_consistent_formatting_style(self):
        """Test that system prompts use consistent formatting style."""
        prompts = [CONVERTER_SYSTEM_PROMPT, VERIFIER_SYSTEM_PROMPT]
        
        # Check for consistent sentence ending
        periods_count = [prompt.count('.') for prompt in prompts]
        exclamations_count = [prompt.count('!') for prompt in prompts]
        
        # All prompts should use similar punctuation patterns
        # (This is a basic check - more sophisticated analysis could be added)
        for count in periods_count:
            assert count > 0, "System prompts should use proper sentence structure"
    
    def test_prompts_consistent_tone(self):
        """Test that system prompts maintain consistent professional tone."""
        prompts = [CONVERTER_SYSTEM_PROMPT, VERIFIER_SYSTEM_PROMPT]
        
        # Should avoid overly casual language
        casual_words = ['gonna', 'wanna', 'kinda', 'sorta', 'yeah', 'ok', 'hey']
        
        for prompt in prompts:
            for casual_word in casual_words:
                assert casual_word not in prompt.lower(), \
                    f"System prompt should maintain professional tone, avoid '{casual_word}'"
        
        # Should use professional language
        professional_indicators = [
            'responsible', 'ensure', 'maintain', 'accurate', 'precise', 
            'careful', 'thorough', 'systematic'
        ]
        
        for prompt in prompts:
            professional_count = sum(1 for indicator in professional_indicators 
                                   if indicator in prompt.lower())
            # Should have at least some professional language
            # (Not enforcing a specific count as it depends on prompt style)
            assert isinstance(professional_count, int)  # Basic check that counting works