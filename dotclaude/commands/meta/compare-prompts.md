---
description: Compare two pairs of Claude prompts to determine which one better fits the guidelines
allowed-tools: Read, TodoWrite, Write, LS, Grep, Glob, Edit
argument-hint: system_prompt_a: <system_prompt_a> user_prompt_a: <user_prompt_a> system_prompt_b: <system_prompt_b> user_prompt_b: <user_prompt_b> guidelines: <guidelines> output_type: <output_type>
---

# Compare Prompts

## Context

Arguments: $ARGUMENTS

Start by parsing the arguments and replacing the placeholders below.
You should find the following arguments:

- system_prompt_a: to replace {{SYSTEM_PROMPT_A}}
- user_prompt_a: to replace {{USER_PROMPT_A}}
- system_prompt_b: to replace {{SYSTEM_PROMPT_B}}
- user_prompt_b: to replace {{USER_PROMPT_B}}
- guidelines: to replace {{GUIDELINES}}
- output_type: to replace {{OUTPUT_TYPE}}
- output_path: to replace {{OUTPUT_PATH}}

Tools:

- <guidelines>If provided, use the Read tool to read @{{GUIDELINES}}.
  If no guidelines are provided, use your own knowledge of the topic to create appropriate guidelines</guidelines>

## Task

You are tasked with comparing two pairs of Claude prompts, each pair consisting of a system prompt and a user prompt.
Your goal is to determine which pair best fits the provided guidelines. Follow these instructions carefully:

1. First, review the <guidelines> guidelines for evaluating Claude prompts.
   If no specific guidelines were provided, use your general knowledge about effective prompt writing for AI language models.

2. Now, examine the two pairs of prompts:

   Pair A:
   <system_prompt_a>
   {{SYSTEM_PROMPT_A}}
   </system_prompt_a>

   <user_prompt_a>
   {{USER_PROMPT_A}}
   </user_prompt_a>

   Pair B:
   <system_prompt_b>
   {{SYSTEM_PROMPT_B}}
   </system_prompt_b>

   <user_prompt_b>
   {{USER_PROMPT_B}}
   </user_prompt_b>

3. Analyze and compare the two pairs of prompts:
   a. Infer the goal of each prompt pair based on their content.
   b. Evaluate how well each pair adheres to the guidelines.
   c. Consider factors such as clarity, specificity, and potential effectiveness.
   d. Identify strengths and weaknesses of each pair.

4. Before providing your final answer, use a <scratchpad> to outline your comparison strategy and key points of analysis.
   This will help organize your thoughts and ensure a thorough evaluation.

5. Prepare your output based on the specified OUTPUT_TYPE:

   **OUTPUT_TYPE is {{OUTPUT_TYPE}}**

   If OUTPUT_TYPE is "Boolean":
   - In your <answer>, provide a single word: "True" if Pair B is better, or "False" if Pair A is better.
   - Before the <answer>, include a <justification> explaining your reasoning.

   If OUTPUT_TYPE is "full", or "report", or not specified:
   - In your <answer>, provide a detailed comparison of the two prompt pairs.
   - Include your assessment of which pair better fits the guidelines and why.
   - Organize your report with clear headings and bullet points for readability.

6. Your final output should only include the content specified in step 5. Do not include the scratchpad
   or any other extraneous information in your final answer.

7. If an <output_path> is provided, write the final output to the file at the <output_path> path

Remember, your task is to evaluate and compare the prompts, not to complete the task that the prompts describe.
