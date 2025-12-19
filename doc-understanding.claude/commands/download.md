---

allowed-tools: Read, Task, TodoWrite, Write, LS, Grep, Glob, Edit
description: Downloads a document from a URL or a list of URLs
argument-hint: output-path: <output-folder> file-existing-mode: <file-existing-mode> url: <url> filename: <output-filename>
---

## Context

- Arguments: <arguments>$ARGUMENTS</arguments>
- Purpose: <purpose>Download documents from URLs and save them to a specified folder.</purpose>
- Parameters Schema: <schema>@.claude/shared/schemas/docs/download.yml</schema>
- Default Paremeters Values: <defaults>@.claude/shared/schemas/docs/download.defaults.yml</defaults>
- Template Prompt for sub-agent: <batch-download-template>@.claude/shared/templates/commands/docs/download/batch.md</batch-download-template>
- sub-agents: <subagent>@agent-docs:batch-downloader (subagent_type: "docs:batch-downloader")</subagent>

## Execution

Follow the instructions described in the numbered list below:

1. Parse arguments considering it as a yaml object and assign its values to variables of the same names
2. Organize the urls: Group the urls by domain and assign them to the variable `$urls-by-domain`
3. <foreach $domain, $urls in $urls-by-domain>
    1. Fill the template in the <batch-download-template> block from the section "Template Prompt for sub-agent Task tool" replacing the placeholders:
        - {{urls}} with the values of the variables `$urls` or `[(url: $url, filename: $filename, notes: $notes)]`
        - {{output-path}} with the value of the variable `$output-path`
        - {{file-existing-mode}} with the value of the variable `$file-existing-mode`
    2. Launch an async Task with the Task tool using the filled template as a prompt to the sub-agent
       <subagent>@agent-docs:batch-downloader (subagent_type: "docs:batch-downloader")</subagent>
4. </foreach>
5. Wait for all Tasks to complete

## Parameters

### Parameters Schema

```yaml
item: &item
  type: object
  description: An item to download
  properties:
    url:
      type: string
      description: The URL to download
    filename:
      type: string
      description: The filename to save the downloaded document to. If not specified, the filename will be inferred from the URL.
    notes:
      type: array
      description: Notes about the item, useful for restricting the scope of the content to be converted
      items:
        type: string
  required:
    - url

file-existing-mode: &file-existing-mode
  type: string
  enum:
    - overwrite # Overwrite the existing file
    - skip # Skip the current item if file already exists
    - rename # Rename the existing file by appending ".old" to the original name
    - append # Append the content to the existing file

download-arguments:
  type: object
  description: Arguments for the command /docs:download or /download
  properties:
    output-path:
      type: string
      description: The output folder
    file-existing-mode:
      <<: *file-existing-mode
  required:
    - urls
    - output-path
    - file-existing-mode
  oneOf:
    - urls:
        type: array
        description: URLs to download
        items:
          <<: *item
    - url:
        <<: *item
```

### Default Parameters Values

```yaml
arguments-defaults: &default
  output-path: .claude/shared/downloads
  file-existing-mode: skip
```

## Template Prompt for sub-agent Task tool

<batch-download-template>

```markdown
Please, consider the following when performing your task:

The output root to save the documents is:
<output-path>{{output-path}}</output-path>

If any file already exists, do as in the parameter:
<file-existing-mode>{{file-existing-mode}}</file-existing-mode>

The url-filename pairs to download are:
<urls>{{urls}}</urls>

Given those parameters, perform your regular task execution logic
```

</batch-download-template>

## Usage Examples

### Download multiple URLs using default values

```yaml
/docs:download
  <<: *default
  urls:
    - url: https://docs.anthropic.com/en/docs/claude-code/quickstart
      filename: general/quickstart.md
    - url: https://docs.anthropic.com/en/docs/claude-code/sdk
      filename: general/sdk.md
```

OR

### Download a single URL in a single line

```yaml
/docs:download output-path: .claude/downloads/refreshable-sources/ file-existing-mode: overwrite url: https://docs.anthropic.com/en/docs/claude-code/quickstart filename: general/quickstart.md
```
