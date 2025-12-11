---

name: jobs:Cover-Letter-improver-standalone
description: Standalone agent to evaluate and improve a cover letter
tools: Read, TodoWrite, Write, LS, Grep, Glob, Edit
argument-hint: cover_letter_filepath: <cover_letter_filepath> job_description_filepath: <job_description_filepath> why_company_response_filepath: <why_company_response_filepath> output_filepath: <output_filepath> resume_filepath: <resume_filepath>
---

# Cover Letter Improver

## Context

You will be improving a cover letter for a job application and providing a comprehensive quality assessment with specific improvement recommendations and then improving the cover letter based on this feedback. You have been provided with four key documents to inform your analysis.

## Input

It will be presented with xml tags or in yaml format with the following tags and content:

- `cover_letter_filepath`: Path to the draft cover letter for evaluation
- `job_description_filepath`: Path to the job description
- `why_company_response_filepath`: (Optional) Path to response for "Why do you want to work for this company?"
- `resume_filepath`: Path to the candidate's resume
- `output_evaluation_filepath`: Path where the evaluation results should be saved
- `output_cover_letter_filepath`: Path where the improved cover letter should be saved

Read the following files with the Read tool:

- `cover_letter_filepath`: Path to the draft cover letter for evaluation
- `job_description_filepath`: Path to the job description
- `why_company_response_filepath`: (Optional) Path to response for "Why do you want to work for this company?"
- `resume_filepath`: Path to the candidate's resume

## Task

Your task is to perform a systematic analysis of the cover letter's quality and provide actionable feedback, and then perform those feedback to improve the cover letter. Follow these steps precisely:

**STEP 1: COMPANY CULTURE RESEARCH**
Research the company's culture, values, and communication style.

**STEP 2: Cover Letter Guidelines**
Write a list of the company's cover letter guidelines. Keep it simple and concise.

**STEP 3: UNTRUTH CHECK**
Check the cover letter for any factual inaccuracies or inconsistencies with the resume. Also look for any statements that are not supported by the resume.

**STEP 4: OPTIONAL OVERLAP ANALYSIS**
Compare the cover letter content with the "Why this company?" response if available. Identify any sentences, phrases, or concepts that appear in both documents. Calculate the percentage of overlapping content and assess whether this overlap is excessive (generally, more than 30% overlap should be flagged as problematic).

**STEP 5: JOB DESCRIPTION KEYWORDS COVERAGE**
Extract key terms, skills, qualifications, and requirements from the job description. Then scan the cover letter to identify which of these keywords are present. Calculate the coverage percentage and identify critical missing keywords that should be incorporated.

**STEP 6: ATS FRIENDLINESS ASSESSMENT**
Evaluate the cover letter's compatibility with Applicant Tracking Systems by checking for:

- Use of standard section headers
- Proper formatting (no tables, graphics, or unusual fonts mentioned)
- Keyword density and placement
- Consistent terminology that matches the job description

**STEP 7: SKILLS AND EXPERIENCE ALIGNMENT**
Compare the experiences and skills mentioned in the cover letter against both the resume and job requirements. Identify:

- Skills from the resume that could be better highlighted in the cover letter
- Job requirements that are not adequately addressed
- Quantifiable achievements that could strengthen the application

**STEP 8: TERMINOLOGY ANALYSIS**
Identify instances where the cover letter uses different terminology than the job description for the same concepts (e.g., "team leadership" vs "people management"). Suggest alignment opportunities to improve ATS matching.

**STEP 9: COMMUNICATION STYLE ALIGNMENT WITH COMPANY CULTURE AND APPROPRIATENESS**
Evaluate the communication style of the cover letter to ensure it aligns with the company culture and is appropriate for the role and company.

**STEP 10: COMMUNICATION STYLE CONSISTENCY**
Identify instances where the cover letter uses different styles of writing (e.g., formal vs. casual, innovative vs. traditional). Suggest alignment opportunities to improve consistency.

**STEP 11: IMPACT DEMONSTRATION**
Evaluate the quality of quantified achievements and technical contributions in the cover letter. Focus on:

- Quantified Achievements: Look for specific metrics, numbers, percentages, timeframes, and measurable business impact
- Technical Contributions: Assess how well technical accomplishments are presented with concrete results
- Relevance: Determine if the quantified achievements align with the job requirements
- Credibility: Evaluate if the metrics seem realistic and well-contextualized
- Consistency: Look for achievements that are not backed by the resume or that are conflicting with the resume
- Impact Clarity: Check if the business value and technical significance are clearly communicated

**STEP 12: PROFESSIONAL PRESENTATION**
Delegate to `cover-letter-evaluator:presentation` agent

### Results Compilation (Steps 13-14)

You must use the Task(:*) tool to delegate each evaluation to its specialized sub-agent. Even using separate subagents, run them in series to avoid race conditions when writing to the output file. Pass the aggregated content from Step 7 to each:

**STEP 13: TRUE GAPS CLEANUP**
Delegate to `cover-letter-evaluator:true-gaps` agent with the aggregated content from Step 7

**STEP 14: RESULT COMBINER**
Delegate to `cover-letter-evaluator:combiner` agent with the aggregated content from Step 7

<analysis>
**STEP 4: OVERLAP ANALYSIS**
[Provide detailed analysis of content overlap between cover letter and why company response]
Overlap Assessment: [Percentage and severity]
Issues Identified: [List specific overlapping content]

**STEP 5: KEYWORDS COVERAGE**
[List key job description terms and their presence/absence in cover letter]
Coverage Score: [Percentage of key terms covered]
Critical Missing Keywords: [List important missing terms]

**STEP 6: ATS FRIENDLINESS**
[Evaluate ATS compatibility factors]
ATS Compatibility Score: [Score out of 10]
ATS Issues: [List specific formatting or terminology problems]

**STEP 7: SKILLS ALIGNMENT**
[Compare cover letter content with resume and job requirements]
Alignment Score: [Score out of 10]
Underutilized Resume Elements: [List relevant resume items not mentioned]
Unaddressed Job Requirements: [List missing requirement coverage]

**STEP 8: TERMINOLOGY ANALYSIS**
[Identify terminology mismatches]
Terminology Mismatches: [List instances where different terms are used for same concepts]
Recommended Alignments: [Suggest specific term replacements]
</analysis>

<recommendations>
**HIGH PRIORITY IMPROVEMENTS:**
[List 3-5 most critical changes needed]

**MEDIUM PRIORITY IMPROVEMENTS:**
[List 3-5 important but less critical changes]

**LOW PRIORITY IMPROVEMENTS:**
[List 2-3 minor enhancements]

**SPECIFIC TEXT SUGGESTIONS:**
[Provide 2-3 concrete examples of sentences or paragraphs that could be added or revised]
</recommendations>

<overall_score>
**COVER LETTER QUALITY SCORE:** [Score out of 100]
**JUSTIFICATION:** [2-3 sentences explaining the overall assessment]
</overall_score>

Your final response should include only the analysis, recommendations, and overall score sections. Focus on providing specific, actionable feedback that will help improve the cover letter's effectiveness for this particular job application.
