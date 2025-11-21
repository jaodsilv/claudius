---
description: Create a new Claude Code's Custom Output Style
allowed-tools: Read, TodoWrite, Write, LS, Grep, Glob, Edit
argument-hint: task: <task> guidelines: <guidelines>
---

# New Output Style

## Context

Arguments: $ARGUMENTS

Arguments are passed as a single string in yaml format.

arguments format:

```yaml
task: <task>
guidelines: <guidelines>
output_path: <output_path>
```

Start by parsing the arguments and replacing the placeholders below.
Assign the values from the parameters to the variables below:

- $TASK: for the `task` argument
- $GUIDELINES: for the `guidelines` argument. This is optional.
- $OUTPUT_PATH: for the `output_path` argument

## Task

You are tasked with creating a Claude Code's Custom Output Style to perform a given task. This output style is intended
for use with Claude Code, specifically the Claude Sonnet 4 model with thinking enabled. Your goal is to create a prompt
template that will guide the AI in completing the specified task effectively.

Besides the guidelines you read, you will be working with the following input variables:

<task>
$TASK
</task>

<output-path>
$OUTPUT_PATH
</output-path>

<guidelines-path>
$GUIDELINES
</guidelines-path>

- <guidelines>If provided, use the Read tool to read @$GUIDELINES.
  If no guidelines are provided, use your own knowledge of the topic to create appropriate guidelines</guidelines>
Follow these steps to create the Custom Output Style:

1. Carefully read and analyze the TASK and GUIDELINES (if provided).

2. In a <strategy> section, outline your approach for creating the output style. Consider the following:
   - Key components needed to complete the task
   - Potential challenges or complexities
   - How to structure the prompt for clarity and effectiveness
   - Any specific techniques or methods that would be helpful

3. Create the YAML frontmatter for the Custom Output Style. Include the following fields:
   - name: A concise, descriptive name for the output style
   - description: A brief explanation of what the output style does and how it works

4. Develop the prompt template. Your prompt should:
   - Clearly explain the task and any relevant context
   - Provide step-by-step instructions for completing the task
   - Include any necessary background information or guidelines
   - Specify the desired format for the output
   - Incorporate appropriate use of Claude's capabilities, such as thinking or step-by-step reasoning

Your final response should be structured as follows:

<response>
<strategy>
[Your strategy for creating the output style]
</strategy>

[The status of the file creation]
</response>

And you should output to the OUTPUT_PATH path the following content:

<custom_output_style>

```markdown
---
name: [Output style name]
description: [Output style description]
---

[Your prompt template]
```

</custom_output_style>

Remember to focus on creating a clear, effective prompt template that will enable Claude to successfully complete the given task.

You should write the content that is within the markdown code block that is written between the <custom_slash_command> tags.
