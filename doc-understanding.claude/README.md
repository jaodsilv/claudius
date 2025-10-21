# Document Understanding Plugin

A specialized Claude Code plugin for downloading, converting, and processing documentation from various sources.

## Purpose

This plugin provides tools and workflows for:

1. Downloading documentation from URLs
2. Converting documentation to different formats
3. Verifying conversion quality
4. Batch processing multiple documentation sources

## Mount Location

This plugin should be mounted at `~/.claude` alongside or instead of the default `dotclaude` configuration, or in a project-specific `.claude` directory.

## Plugin Structure

```
doc-understanding.claude/
├── README.md                           # This file
├── commands/                          # Custom slash commands
│   └── docs/
│       └── download.md               # /docs:download command
└── agents/                           # Sub-agents
    └── docs/
        ├── downloader.md            # Single document downloader
        ├── batch-downloader.md      # Batch document downloader
        ├── converter.md             # Document format converter
        └── conversion-verifier.md   # Conversion quality verifier
```

## Commands

### `/docs:download`

Downloads documentation from one or more URLs and saves them to a specified folder.

**Usage Examples:**

1. Download multiple URLs:

   ```yaml
   /docs:download
     output-path: .claude/shared/downloads
     file-existing-mode: skip
     urls:
       - url: https://docs.anthropic.com/en/docs/claude-code/quickstart
         filename: general/quickstart.md
       - url: https://docs.anthropic.com/en/docs/claude-code/sdk
         filename: general/sdk.md
   ```

2. Download a single URL:

   ```yaml
   /docs:download output-path: .claude/downloads/ file-existing-mode: overwrite url: https://example.com/docs filename: docs.md
   ```

**Parameters:**

1. `output-path` (required): The output folder for downloaded documents
2. `file-existing-mode` (required): How to handle existing files - `overwrite`, `skip`, `rename`, or `append`
3. `url` or `urls` (required): Single URL or array of URLs to download
4. `filename` (optional): Output filename (inferred from URL if not specified)
5. `notes` (optional): Array of notes about content scope restrictions

**Default Values:**

1. `output-path`: `.claude/shared/downloads`
2. `file-existing-mode`: `skip`

## Agents

### `docs:downloader`

Single document downloader agent for fetching individual documents from URLs.

**Sub-agent Type**: `docs:downloader`

### `docs:batch-downloader`

Batch document downloader that processes multiple URLs in parallel, organized by domain.

**Sub-agent Type**: `docs:batch-downloader`

### `docs:converter`

Document format converter for transforming documents between different formats.

**Sub-agent Type**: `docs:converter`

### `docs:conversion-verifier`

Conversion quality verifier that checks and validates document conversions.

**Sub-agent Type**: `docs:conversion-verifier`

## Integration

This plugin integrates seamlessly with Claude Code's command and agent system. Simply mount it in your `.claude` directory and the commands and agents will be available for use.

## Development

This plugin follows the standard Claude Code plugin structure with:

1. Commands in `commands/` directory
2. Agents in `agents/` directory
3. Shared resources (schemas, templates) inline or in `shared/` directory

## License

Same license as the parent repository.
