---
description: Find tags for a given file
allowed-tools: Read, TodoWrite, Write, LS, Grep, Glob, Edit
argument-hint: filepath: <filepath> tags: <tags>
---

# Find Tags

## Context

Arguments: $ARGUMENTS

Arguments are passed as a single string in yaml format.

arguments format:

```yaml
filepath: <filepath>
tags: <tags>
```

Start by parsing the arguments and assign the values from the parameters to the variables below:

- $FILEPATH: for the `filepath` argument
- $TAGS: for the `tags` argument

You are an AI assistant tasked with creating and updating a list of tags for content classification.
These tags will be used to categorize files for various guidelines related to Claude Code development.
Your goal is to analyze the content of a given file and suggest new tags or update existing ones to improve the classification system.

You will be provided with two inputs:
<filepath>
$FILEPATH
</filepath>

This is the path of the file you need to analyze.

<current_tags>
$TAGS
</current_tags>

This is the current list of tags that have been created so far.

To complete this task, follow these steps:

1. Analyze the content of the file at the given filepath. Pay attention to the main topics, themes, and concepts discussed in the file.

2. Review the current list of tags and identify any gaps or areas where new tags could be beneficial.

3. Create new tags based on the file content. Consider the following guidelines when creating tags:
   - Tags should be concise and descriptive
   - Use lowercase letters and underscores for spaces (e.g., "custom_commands")
   - Avoid overly specific tags that might only apply to one file
   - Create tags that can be useful for categorizing multiple files
   - Consider creating both broad category tags and more specific subtags

4. If you find existing tags that can be applied to the current file, include them in your updated list.

5. Organize the tags into a logical structure, grouping related tags together.

6. Provide your final output as a comprehensive list of tags, including both new and existing tags that are relevant to the file content.

Your final output should be formatted as follows:

<updated_tags>
$TAGS
[List of new tags here, one per line]
</updated_tags>

Remember, your task is to augment and improve the existing tag list based on the content of the file.
Do not remove any existing tags unless they are clearly irrelevant or redundant. Focus on adding new,
useful tags that will help in categorizing and filtering files for the various Claude Code development guidelines.
