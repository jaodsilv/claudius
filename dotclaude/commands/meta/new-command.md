---
description: Create a new Claude Code's Custom Slash Command to perform a specific task
allowed-tools: Read, TodoWrite, Write, LS, Grep, Glob, Edit
argument-hint: task: <task> guidelines: <guidelines>
---

# New Command

## Context

Arguments: $ARGUMENTS

Start by parsing the arguments and replacing the placeholders below.
You should find the following arguments:

- task: to replace {{TASK}}
- guidelines: to replace {{GUIDELINES}}
- output_path: to replace {{OUTPUT_PATH}}

Tools:

- <guidelines>If provided, use the Read tool to read @{{GUIDELINES}}.
  If no guidelines are provided, use your own knowledge of the topic to create appropriate guidelines</guidelines>

You are tasked with creating a Claude Code's Custom Slash Command to perform a specific task.
This prompt is designed to be used with Claude Code, utilizing the Claude Sonnet 4 model with thinking enabled.
Your goal is to create a comprehensive and effective prompt that will enable the AI to complete the given task accurately.

Besides the guidelines you might have read, you will be working with the following input variable:

<task>
{{TASK}}
</task>

Follow these steps to create the Custom Slash Command:

1. Think hard to create a strategy for performing the task. Think about the steps involved, any potential challenges,
and how to approach the task efficiently. Write your strategy inside <strategy> tags.

2. Think hard to write a prompt that will guide the AI in completing the task. The prompt should be clear, concise,
and provide all necessary information. Include the following elements in your prompt:
   1. A brief introduction explaining the task
   2. Any relevant background information or context
   3. Step-by-step instructions for completing the task
   4. Guidelines for handling edge cases or potential issues
   5. Instructions for formatting the output

3. Remember that the command may require arguments. These arguments are passed as a single string in $ARGUMENTS.

4. Write your prompt inside <prompt> tags in your scratchpad.

5. After creating the prompt, develop the YAML frontmatter for the Custom Slash Command. Include the following fields:

   1. allowed-tools: Think to create the list of tools that should be available for this command. See the guidelines for the available tools.
   2. description: A brief description of what the command does
   3. argument-hint: A short hint about the expected arguments
   4. model: Specify if a model different from the default is needed

6. Write the YAML frontmatter inside <yaml> tags in your scratchpad.

Include instructions in your prompt for parsing and using these arguments effectively.

Your final output should be structured as follows:

<response>
<strategy>
[Your strategy for completing the task]
</strategy>

[The status of the file creation]
</response>

And you should output to the OUTPUT_PATH path the following content:

<custom_slash_command>

```markdown
---
[YAML frontmatter for the Custom Slash Command]
---

[Your prompt for the AI to complete the task]
```

</custom_slash_command>

Ensure that your prompt and YAML frontmatter are complete and ready to be used as a Claude Code's Custom Slash Command.
Do not include any additional explanations or notes in your final output.

You should write the content that is within the markdown code block that is written between the <custom_slash_command> tags.
Write that content to the file at the <output_path> path
