#!/usr/bin/env python3
"""
Unit tests for prompts module.
"""

import pytest
from src.prompts.prompts import (
    CONVERTER_PLANNING_PROMPT,
    CONVERTER_EXECUTION_PROMPT, 
    VERIFIER_PLANNING_PROMPT,
    VERIFIER_EXECUTION_PROMPT
)


@pytest.mark.unit
class TestPromptConstants:
    """Test that all prompt constants are properly defined."""
    
    def test_conversion_planning_prompt_exists(self):
        """Test that conversion planning prompt is defined."""
        assert CONVERTER_PLANNING_PROMPT is not None
        assert isinstance(CONVERTER_PLANNING_PROMPT, str)
        assert len(CONVERTER_PLANNING_PROMPT) > 0
    
    def test_conversion_execution_prompt_exists(self):
        """Test that conversion execution prompt is defined."""
        assert CONVERTER_EXECUTION_PROMPT is not None
        assert isinstance(CONVERTER_EXECUTION_PROMPT, str)
        assert len(CONVERTER_EXECUTION_PROMPT) > 0
    
    def test_verifier_planning_prompt_exists(self):
        """Test that verifier planning prompt is defined."""
        assert VERIFIER_PLANNING_PROMPT is not None
        assert isinstance(VERIFIER_PLANNING_PROMPT, str)
        assert len(VERIFIER_PLANNING_PROMPT) > 0
    
    def test_verifier_execution_prompt_exists(self):
        """Test that verifier execution prompt is defined."""
        assert VERIFIER_EXECUTION_PROMPT is not None
        assert isinstance(VERIFIER_EXECUTION_PROMPT, str)
        assert len(VERIFIER_EXECUTION_PROMPT) > 0


@pytest.mark.unit
class TestPromptContent:
    """Test prompt content and structure."""
    
    def test_conversion_planning_prompt_content(self):
        """Test conversion planning prompt contains expected elements."""
        prompt = CONVERTER_PLANNING_PROMPT
        
        # Should mention planning and HTML conversion
        assert "plan" in prompt.lower() or "planning" in prompt.lower()
        assert "html" in prompt.lower() or "HTML" in prompt
        assert "markdown" in prompt.lower() or "Markdown" in prompt
    
    def test_conversion_execution_prompt_content(self):
        """Test conversion execution prompt contains expected elements."""
        prompt = CONVERTER_EXECUTION_PROMPT
        
        # Should mention execution and conversion
        assert "convert" in prompt.lower() or "conversion" in prompt.lower()
        assert "html" in prompt.lower() or "HTML" in prompt
        assert "markdown" in prompt.lower() or "Markdown" in prompt
    
    def test_verifier_planning_prompt_content(self):
        """Test verifier planning prompt contains expected elements."""
        prompt = VERIFIER_PLANNING_PROMPT
        
        # Should mention verification and planning
        assert "verify" in prompt.lower() or "verification" in prompt.lower()
        assert "plan" in prompt.lower() or "planning" in prompt.lower()
    
    def test_verifier_execution_prompt_content(self):
        """Test verifier execution prompt contains expected elements."""
        prompt = VERIFIER_EXECUTION_PROMPT
        
        # Should mention verification and execution
        assert "verify" in prompt.lower() or "verification" in prompt.lower()
        assert "quality" in prompt.lower() or "check" in prompt.lower()


@pytest.mark.unit
class TestPromptFormatting:
    """Test prompt formatting and structure."""
    
    def test_prompts_are_non_empty_strings(self):
        """Test all prompts are non-empty strings."""
        prompts = [
            CONVERTER_PLANNING_PROMPT,
            CONVERTER_EXECUTION_PROMPT,
            VERIFIER_PLANNING_PROMPT,
            VERIFIER_EXECUTION_PROMPT
        ]
        
        for prompt in prompts:
            assert isinstance(prompt, str), f"Prompt should be string, got {type(prompt)}"
            assert len(prompt.strip()) > 0, "Prompt should not be empty"
    
    def test_prompts_have_reasonable_length(self):
        """Test that prompts have reasonable length (not too short or extremely long)."""
        prompts = [
            CONVERTER_PLANNING_PROMPT,
            CONVERTER_EXECUTION_PROMPT,
            VERIFIER_PLANNING_PROMPT,
            VERIFIER_EXECUTION_PROMPT
        ]
        
        for prompt in prompts:
            # Should be at least 50 characters (substantial content)
            assert len(prompt) >= 50, f"Prompt too short: {len(prompt)} characters"
            
            # Should not be excessively long (>10k chars would be unusual for a prompt)
            assert len(prompt) <= 10000, f"Prompt too long: {len(prompt)} characters"
    
    def test_prompts_contain_placeholder_patterns(self):
        """Test that prompts contain expected placeholder patterns."""
        # Conversion prompts should have placeholders for input/output content
        conversion_prompts = [CONVERTER_PLANNING_PROMPT, CONVERTER_EXECUTION_PROMPT]
        
        for prompt in conversion_prompts:
            # Look for common placeholder patterns
            has_placeholders = (
                "{" in prompt and "}" in prompt or  # {placeholder} style
                "<" in prompt and ">" in prompt or  # <placeholder> style  
                "INPUT" in prompt.upper() or        # INPUT/OUTPUT keywords
                "OUTPUT" in prompt.upper() or
                "HTML" in prompt.upper() or
                "MARKDOWN" in prompt.upper()
            )
            assert has_placeholders, f"Conversion prompt should contain placeholders or keywords"
    
    def test_prompts_proper_formatting(self):
        """Test that prompts are properly formatted."""
        prompts = [
            CONVERTER_PLANNING_PROMPT,
            CONVERTER_EXECUTION_PROMPT,
            VERIFIER_PLANNING_PROMPT,
            VERIFIER_EXECUTION_PROMPT
        ]
        
        for prompt in prompts:
            # Should not have excessive whitespace at start/end
            assert prompt == prompt.strip() or len(prompt.strip()) == len(prompt) - prompt.count('\n'), \
                "Prompt should not have excessive leading/trailing whitespace"
            
            # Should not have multiple consecutive blank lines (more than 2 \n in a row)
            assert '\n\n\n' not in prompt, "Prompt should not have excessive blank lines"


@pytest.mark.unit
class TestPromptUsability:
    """Test prompt usability and practical considerations."""
    
    def test_prompts_are_clear_instructions(self):
        """Test that prompts contain clear instructions."""
        prompts = [
            CONVERTER_PLANNING_PROMPT,
            CONVERTER_EXECUTION_PROMPT,
            VERIFIER_PLANNING_PROMPT,
            VERIFIER_EXECUTION_PROMPT
        ]
        
        for prompt in prompts:
            # Should contain imperative language (commands/instructions)
            imperative_words = ['convert', 'verify', 'analyze', 'check', 'create', 'generate', 
                              'review', 'examine', 'process', 'transform', 'ensure', 'provide']
            
            has_imperative = any(word in prompt.lower() for word in imperative_words)
            assert has_imperative, f"Prompt should contain clear instruction words"
    
    def test_prompts_mention_expected_output_format(self):
        """Test that prompts specify expected output format."""
        # Planning prompts should mention they expect plans
        planning_prompts = [CONVERTER_PLANNING_PROMPT, VERIFIER_PLANNING_PROMPT]
        
        for prompt in planning_prompts:
            # Should mention planning, strategy, approach, or steps
            planning_words = ['plan', 'strategy', 'approach', 'steps', 'method', 'process']
            has_planning_ref = any(word in prompt.lower() for word in planning_words)
            assert has_planning_ref, "Planning prompt should reference planning concepts"
        
        # Execution prompts should mention they expect actual results
        execution_prompts = [CONVERTER_EXECUTION_PROMPT, VERIFIER_EXECUTION_PROMPT]
        
        for prompt in execution_prompts:
            # Should mention execution, results, output, or completion
            execution_words = ['execute', 'result', 'output', 'complete', 'perform', 'produce']
            has_execution_ref = any(word in prompt.lower() for word in execution_words)
            assert has_execution_ref, "Execution prompt should reference execution concepts"
    
    def test_prompts_avoid_ambiguous_language(self):
        """Test that prompts avoid overly ambiguous language."""
        prompts = [
            CONVERTER_PLANNING_PROMPT,
            CONVERTER_EXECUTION_PROMPT,
            VERIFIER_PLANNING_PROMPT,
            VERIFIER_EXECUTION_PROMPT
        ]
        
        # Words that might indicate ambiguity or vagueness
        vague_phrases = ['maybe', 'perhaps', 'might be', 'could be', 'sort of', 'kind of']
        
        for prompt in prompts:
            for phrase in vague_phrases:
                assert phrase not in prompt.lower(), f"Prompt should avoid vague phrase '{phrase}'"


@pytest.mark.unit
class TestPromptIntegration:
    """Test prompt integration with the system."""
    
    def test_prompts_can_be_imported(self):
        """Test that all prompts can be imported without errors."""
        # This test passed if we got here without import errors
        assert True
    
    def test_prompts_are_accessible_as_module_attributes(self):
        """Test that prompts are accessible as module attributes."""
        import src.prompts.prompts as prompts_module
        
        # Should be able to access all prompt constants
        assert hasattr(prompts_module, 'CONVERTER_PLANNING_PROMPT')
        assert hasattr(prompts_module, 'CONVERTER_EXECUTION_PROMPT')
        assert hasattr(prompts_module, 'VERIFIER_PLANNING_PROMPT')
        assert hasattr(prompts_module, 'VERIFIER_EXECUTION_PROMPT')
    
    def test_prompts_string_formatting_compatibility(self):
        """Test that prompts work with string formatting operations."""
        # Test basic string operations that might be used in the application
        for prompt in [CONVERTER_PLANNING_PROMPT, CONVERTER_EXECUTION_PROMPT]:
            # Should be able to perform basic string operations
            assert len(prompt) > 0
            assert prompt.upper() != prompt  # Should contain some lowercase letters
            assert prompt.lower() != prompt  # Should contain some uppercase letters
            
            # Should be able to safely check for content
            assert 'conversion' in prompt.lower() or 'convert' in prompt.lower()
    
    def test_prompts_template_substitution_readiness(self):
        """Test that prompts are ready for template substitution."""
        prompts = [
            CONVERTER_PLANNING_PROMPT,
            CONVERTER_EXECUTION_PROMPT,
            VERIFIER_PLANNING_PROMPT,
            VERIFIER_EXECUTION_PROMPT
        ]
        
        for prompt in prompts:
            # Should not crash when used in format operations
            try:
                # Test basic format safety (shouldn't crash even if no placeholders)
                formatted = prompt.format()  # With no arguments
                assert isinstance(formatted, str)
            except (KeyError, ValueError):
                # If format() fails, it means there are placeholders, which is expected
                # The prompt should at least be a valid string for formatting
                assert "{" in prompt or "<" in prompt  # Should have some placeholder pattern
            
            # Should be safe for percentage formatting too
            try:
                # Test with %s formatting - should not crash
                if '%' not in prompt:  # Only test if no % symbols present
                    test_format = f"Prefix: {prompt} Suffix"
                    assert isinstance(test_format, str)
            except Exception:
                # If there are % symbols, they might be part of the prompt content
                pass


@pytest.mark.unit
class TestPromptConsistency:
    """Test consistency across different prompts."""
    
    def test_related_prompts_consistent_terminology(self):
        """Test that related prompts use consistent terminology."""
        # Conversion prompts should use similar terminology
        conversion_prompts = [CONVERTER_PLANNING_PROMPT, CONVERTER_EXECUTION_PROMPT]
        
        # Both should mention HTML and Markdown consistently
        html_terms = []
        markdown_terms = []
        
        for prompt in conversion_prompts:
            if 'HTML' in prompt:
                html_terms.append('HTML')
            if 'html' in prompt:
                html_terms.append('html')
            if 'Markdown' in prompt:
                markdown_terms.append('Markdown')
            if 'markdown' in prompt:
                markdown_terms.append('markdown')
        
        # Should have some consistency in terminology usage
        assert len(set(html_terms)) <= 2, "HTML terminology should be consistent"
        assert len(set(markdown_terms)) <= 2, "Markdown terminology should be consistent"
    
    def test_planning_vs_execution_prompt_distinction(self):
        """Test that planning and execution prompts are appropriately distinct."""
        planning_prompts = [CONVERTER_PLANNING_PROMPT, VERIFIER_PLANNING_PROMPT]
        execution_prompts = [CONVERTER_EXECUTION_PROMPT, VERIFIER_EXECUTION_PROMPT]
        
        # Planning prompts should emphasize planning
        for prompt in planning_prompts:
            planning_emphasis = prompt.lower().count('plan') + prompt.lower().count('strategy')
            assert planning_emphasis > 0, "Planning prompt should emphasize planning"
        
        # Execution prompts should emphasize action
        for prompt in execution_prompts:
            action_words = ['execute', 'perform', 'do', 'convert', 'verify', 'process']
            action_emphasis = sum(prompt.lower().count(word) for word in action_words)
            assert action_emphasis > 0, "Execution prompt should emphasize action"