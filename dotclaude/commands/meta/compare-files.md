---
description: Compare two files to determine which one better fits the guidelines
allowed-tools: Read, TodoWrite, Write, LS, Grep, Glob, Edit
argument-hint: file_a: <file_a> file_b: <file_b> guidelines: <guidelines> doc_type: <doc_type> output_type: <output_type> output_path: <output_path>
---

# Compare Files

## Context

Arguments: $ARGUMENTS

Start by parsing the arguments and replacing the placeholders below.
You should find the following arguments:

- file_a: to replace {{FILE_A}}
- file_b: to replace {{FILE_B}}
- guidelines: to replace {{GUIDELINES}}
- doc_type: to replace {{DOC_TYPE}}
- output_type: to replace {{OUTPUT_TYPE}}
- output_path: to replace {{OUTPUT_PATH}}

Tools:

- <file_a>Use the Read tool to read @{{FILE_A}}</file_a>
- <file_b>Use the Read tool to read @{{FILE_B}}</file_b>
- <guidelines>If provided, use the Read tool to read @{{GUIDELINES}}</guidelines>

## Task

You are an AI assistant tasked with comparing two Claude Code markdown document files to determine which one better fits
the guidelines and will perform better for the common task. Follow these instructions carefully:

1. Besides the 3 files you already read, you will be provided with the following input variables:

   <doc_type>{{DOC_TYPE}}</doc_type>
   <output_type>{{OUTPUT_TYPE}}</output_type>
   <output_path>{{OUTPUT_PATH}}</output_path>

2. First, determine the document type based on the <doc_type> variable. This will be either "output-style", "agent", or "command".

3. Based on the document type, focus on the following aspects during your comparison:
   - For output-style: Evaluate the formatting, clarity, and effectiveness of the output style.
   - For agent: Assess the agent's capabilities, instructions, and potential performance.
   - For command: Examine the command's functionality, usability, and adherence to best practices.

4. Develop a comparison strategy:
   a. Read and analyze both files.
   b. Identify the common goal or purpose of the files based on their content.
   c. List key criteria for evaluation based on the document type and inferred goal.
   d. Compare the files against these criteria and the provided guidelines.
   e. Assess which file better achieves the common goal.

5. Consider both the <file_a> and <file_b> files you read

6. If a <guidelines> file is provided, consider the content as the main guidelines for creation of a {{DOCUMENT_TYPE}} document
   If no guidelines file is provided, use your own knowledge of best practices for the given document type.

7. Conduct your comparison, keeping in mind the document type, inferred goal, and guidelines.
   Use a <scratchpad> to organize your thoughts and analysis:

   <scratchpad>
   [Your analysis and comparison notes here]
   </scratchpad>

8. Prepare your output based on the <output_type>:
   - If <output_type> is "Boolean" or not specified, your final output should be a single word:
     "true" if File B is better, or "false" if File A is better. If OUTPUT_TYPE is "Boolean", you should also include a <justification> tag.
     If an <output_path> is provided, write only the boolean value to the file
   - If <output_type> is "full", or "report", provide a detailed comparison report.
     If an <output_path> is provided, write the report to the file at the <output_path> path

9. For the final output:
   - If producing a Boolean result, do not add any tags. output only the boolean value
   - If producing a full report, use <full_report> tags

Remember, your final output should only include the requested result (Boolean or full report) within the appropriate tags.
Do not include your scratchpad or any other analysis in the final output.
