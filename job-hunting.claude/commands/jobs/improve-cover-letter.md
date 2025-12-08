---
description: improve a cover letter based on an evaluation result
allowed-tools: Read, TodoWrite, Write, LS, Grep, Glob, Edit, Skill
argument-hint: cover_letter_filepath: <cover_letter_filepath> job_description_filepath: <job_description_filepath>
---

# Improve Cover Letter

## Context

Arguments: $ARGUMENTS

Start by parsing the arguments and replacing the placeholders below.
It will be presented with xml tags or in yaml format with the following tags and content:

- output_filepath: This is the filepath to output the improvement to
- cover_letter_filepath: This is the filepath to the draft cover letter I want an improvement for
- job_description_filepath: This is the filepath to the job description of the position I'm applying to
- why_company_response_filepath: This is Optional and contains the response to the form field with the question "Why do you want to work for this company?"
- resume_filepath: This is the filepath to the resume of the candidate
- evaluation_result_filepath: This is the filepath to the evaluation result of the cover letter

Read the resume file.
Read the evaluation result file.
Read the job description file.
Read the cover letter file.
Read the why company response file.

## Skill Reference

Use the job hunting skill as a guide for improvements:

1. Consult `@job-hunting.claude/skills/job-hunting/SKILL.md` sections:
   1. "Cover Letter Excellence" for structure and best practices
   2. "Opening Paragraph", "Body Paragraphs", "Closing Paragraph" for specific guidance
   3. "Common Cover Letter Mistakes" for issues to fix

## Overview

You will be improving a cover letter based on evaluation feedback.

## Task

Your task is to rewrite and improve the original cover letter based on the evaluation feedback provided.
For each step of the evaluation, you should use the @tech-cover-letter-specialist agent to generate the output for that step.
The improved cover letter should address the specific weaknesses identified in the evaluation result while maintaining the strengths.

Here are the key steps to follow:

1. Carefully analyze the evaluation result to identify:
   - Specific criticisms or areas for improvement
   - Suggestions for better alignment with the job requirements
   - Missing elements that should be included
   - Strengths that should be preserved

2. Review the job description to understand:
   - Key requirements and qualifications
   - Company values and culture
   - Specific skills or experiences they're seeking

3. Examine the resume to identify:
   - Relevant experiences that could be highlighted
   - Specific achievements or metrics that could strengthen the cover letter
   - Skills that align with the job requirements

4. If provided, incorporate insights from the "Why this Company?" response to demonstrate genuine interest and research about the company.

Before writing your improved cover letter, use the scratchpad below to plan your approach:

<scratchpad>
Think through:
- What are the main issues identified in the evaluation?
- Which experiences from the resume should be emphasized?
- How can you better align the cover letter with the job requirements?
- What specific changes will you make to address each piece of feedback?
</scratchpad>

Write your improved cover letter that:

- Addresses all major concerns raised in the evaluation
- Better aligns with the job description requirements
- Incorporates relevant details from the resume
- Maintains an appropriate professional tone
- Includes specific examples and achievements where relevant
- Demonstrates clear understanding of the role and company

Your final response should contain only the improved cover letter body (from the opening paragraph through the closing paragraph,
excluding salutation and signature). Do not include explanations of what you changed -
just provide the improved cover letter text inside <improved_cover_letter> tags.
