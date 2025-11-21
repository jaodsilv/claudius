---
description: Generate a cover letter for a YCombinator company
allowed-tools: Read, TodoWrite, Write, LS, Grep, Glob, Edit
argument-hint: resume_filepath: <resume_filepath> input_filepath: <input_filepath> output_filepath: <output_filepath>
---

# YCombinator Cover Letter

## Context

Arguments: $ARGUMENTS

Start by parsing the arguments and replacing the placeholders below.
You should find the following arguments:

- resume_filepath: to replace {{RESUME_FILEPATH}}
- input_filepath: to replace {{INPUT_FILEPATH}}
- output_filepath: to replace {{OUTPUT_FILEPATH}}

second you should make sure you are using the output-style: ycombinator-cover-letter

## Tools

- <resume_filepath>Use the Read tool to read @{{RESUME_FILEPATH}}</resume_filepath>
- <input_filepath>Use the Read tool to read @{{INPUT_FILEPATH}}</input_filepath>
- <output_filepath>Use the Write tool to write @{{OUTPUT_FILEPATH}}</output_filepath>

## Task

Your task is to write tailored cover letter-like responses that effectively match candidate qualifications with job requirements
while maint

## Process

Your analytical thinking process and intermediate steps should include the following XML tag blocks in your thinking output,
not in your main output with some required only on first interaction:

### 1. Read Stage

1. Read the two input files:
   1. Using a new subagent, parse the information from the job description present in the file {{INPUT_FILEPATH}} at the key `.job_description`. Output in <job_description> tag
   2. Using  and the resume from the resume_filepath at the key {{RESUME_FILEPATH}}

### 2. Analyze Stage

Using a distinct subagent, analyze the information from the job description and the resume to understand the job position fit and the knowledge gaps.


* <job_description>: Analyze the conversation history to understand the conversation flow and the context
* <job_position_fit_analysis_thinking>: Analyze the fit between job position requirements and the user experiences,
  skills and knowledge from the Resume (first interaction only or after receiving a new job description)
* <knowledge_gap_analysis_thinking>: Find the gaps between the job position requirements and the user resume (including the commented lines)
  (first interaction only or after receiving a new job description)
* <fit_score_analysis_thinking>: Calculate fit score percentage using this methodology:
  * **Requirement Classification**: Identify required skills (must-have) vs preferred skills (nice-to-have)
  * **Logical Operators**: Distinguish between AND conditions (all required) vs OR conditions (any required)
    * Pay attention to contextual clues: "proficient in at least one of Python, Java, C++" = OR condition despite AND syntax
    * "Experience with Python AND Django" = true AND condition
  * **Scoring Weights**:
    * Required skills (AND): Full weight (1.0), must have ALL to count
    * Required skills (OR): Full weight (1.0), need ANY to count
    * Preferred skills: Half weight (0.5)
    * Partial matches: 0.25 of full value, given the weights above
  * **Final Calculation**: (weighted matches / total weighted requirements) × 100
  (first interaction only or after receiving a new job description)
* <context_analysis_thinking>: Analyze the extra context provided and previous analysis performed
* <response_timing_thinking>: Create a response timing strategy and calculate both the ideal response timing range and the best still
  available response time range for the response to be sent
* <response_building_strategy_thinking>: Create a response building strategy
* <response_building_thinking>: Build the response based on the response building strategy
* <extra_recommendations_thinking>: Think on extra recommendations based on the context, conversation history, and previous thinking performed.
  The result of the recommendations can be empty, if there are no extra recommendations to be made

### Main Output

#### Main Output Structure

Your final output should include the following XML tags blocks and structure:

<output_structure>

```markdown
<response_timing>
<ideal_timing>[Use one of the datetime formats above for when response should have been sent for optimal impact]</ideal_timing>
<best_available_time>[Use one of the datetime formats above for next best available send time, considering current datetime and timing strategy]</best_available_time>
</response_timing>

<draft_response>

\```text
[Write the crafted response message here in a code block, to ease copy-paste]
\```

</draft_response>

<extra_recommendations>
[Extra recommendations if there are any, such as next steps, alternative approaches, timing adjustments, or whether to attach the resume]
</extra_recommendations>
```

</output_structure>

* **Required blocks**:
  * Your final output MUST include <response_timing> tag
* **Conditional blocks**: The <draft_response> block MUST be included following the logic below
* **Optional blocks**: You may include <extra_recommendations>, <ideal_timing> and <best_available_time> when applicable
* **Exclusions**: Do not include thinking analysis or additional explanations in the final output - these belong in your thinking output

#### Logic for Writing to Output

The output logic depends on presence and value of the `output_filepath` key:

* If the user does not provide the `output_filepath` key or the value is empty: output **All blocks** to console
* If the user provides the `output_filepath` key, its value is not empty, and its value and the value for
  the key `conversation_history_filepath` are:
  * The same:
    * Output **All blocks but the <draft_response> block** to console
    * Edit the `conversation_history_filepath` file with the Edit tool appending the content that would go into the <draft_response> block following
      the same pattern and keys as the other messages, i.e., in yaml format and without the XML tags
  * Different:
    * Write **All blocks** using the Write tool to the `output_filepath` file


## User Input

- The user will provide the path to 3 files:
  - `resume_filepath`: markdown filepath with the resume
  - `input_filepath`: markdown filepath with the input data, such as, job description, company information, etc
  - `output_filepath`: optional, filepath to output the response to

- input_filepath will be a path to a yaml file with the following keys:
  - `context`: Extra context provided by the user, such as, interest level, awareness of knowledge/skills/experience gaps, etc
  - `job_description`: Job description of the position I'm applying to in markdown format
  - `contact_name`: Contact name of the person to address the letter to, name provided by the YCombinator application form
  - `company_name`: Name of the company I'm applying to
  - `visa_information`: Information about the visa sponsorship requirements of the company

### User Input Example

#### Writing to Console

```text
resume_filepath: @resume.md
input_filepath: @input.yaml
output_filepath:
```

OR

```text
resume_filepath: @resume.md
input_filepath: @input.yaml
```

#### Writing to File

```text
resume_filepath: @resume.md
input_filepath: @input.yaml
output_filepath: @output.md
```

### Input File Example

```yaml
context:
  - I am interested in the position of Software Engineer at Google
job_description: |
  [Job description of the position I'm applying to in markdown format]
contact_name: John Doe
company_name: Awesome Startup
visa_information: Will Sponsor
```
