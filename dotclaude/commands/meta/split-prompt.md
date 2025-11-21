---
description: Split a prompt into a system prompt and a user prompt
allowed-tools: Read, TodoWrite, Write, LS, Grep, Glob, Edit
argument-hint: prompt: <prompt> guidelines: <guidelines>
---

# Split Prompt

## Context

Arguments: $ARGUMENTS

Start by parsing the arguments and replacing the placeholders below.
You should find the following arguments:

* prompt: to replace {{PROMPT}}
* guidelines: to replace {{GUIDELINES}}
* output_path: to replace {{OUTPUT_PATH}}

Tools:

* <guidelines>If provided, use the Read tool to read @{{GUIDELINES}}.
  If no guidelines are provided, use your own knowledge of the topic to create appropriate guidelines</guidelines>

## Task

You are tasked with creating separate System and User Prompts from a given input prompt. This task aims to optimize the performance
of language models by clearly distinguishing between context/instructions (System Prompt) and specific task details (User Prompt).

Here is the input prompt you will be working with:

<prompt>
{{PROMPT}}
</prompt>

If provided, use the following guidelines to inform your approach:

<guidelines>
{{GUIDELINES}}
</guidelines>

To complete this task effectively, follow these steps:

1. Carefully read and analyze the given prompt.

2. Create a strategy for splitting the prompt. Consider the following:
   * Identify general instructions or context that apply to all interactions.
   * Isolate specific task details or questions.
   * Determine which parts set the tone or style for the interaction.

3. Infer the goal of the prompt based on its content. Ask yourself:
   * What is the primary objective of this prompt?
   * What kind of response or output is it seeking?
   * Are there any specific constraints or requirements mentioned?

4. Separate the prompt into two distinct components:
   * System Prompt: Include general context, overall instructions, and guidelines that set the framework for the interaction.
   * User Prompt: Include the specific task, question, or input that requires a direct response.

5. Refine both prompts to ensure they are clear, concise, and effective when used together.

After completing these steps, provide your output in the following format:

<system_prompt>
[Insert your created System Prompt here]
</system_prompt>

<user_prompt>
[Insert your created User Prompt here]
</user_prompt>

<explanation>
[Provide a brief explanation of your strategy and reasoning for the separation]
</explanation>

Remember, your final output should only include the system_prompt, user_prompt, and explanation tags with their respective content.

Do not include any of your thought process or intermediate steps in the final output.

If an <output_path> is provided, write the final output to the file at the dotclaude/prompts/<output_path> path
