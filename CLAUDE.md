# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Base Instructions

- Read @CLAUDE.base.md as a base or as an extension for this CLAUDE.md file

## Repository Overview

This is a personal configuration repository for Claude Code custom base configs, sub agents, custom slash commands and workflows.

## Current Structure

- `README.md` - Basic project description
- `LICENSE` - MIT license file
- `.claude` - Project specific configuration for Claude Code
- `dotclaude` - Actual .claude mounted at `~/.claude`. This is where you should put non-project specific configuration.
- `CLAUDE.base.md` - Base configuration for Claude Code to copy to other projects
- `external-resources` - External resources for Claude Code.

### External Resources

- `super-claude` - Super Claude, a collection of Claude Code agents and prompts.
- `awesome-claude-prompts` - Awesome Claude Prompts, a collection of Claude Code prompts.
- `awesome-claude-code-agents` - Awesome Claude Code Agents, a collection of Claude Code agents.
- `awesome-claude-code-subagents` - Awesome Claude Code Subagents, a collection of Claude Code agents.
- `awesome-claude-code` - Awesome Claude Code, a collection of Claude Code resources.

### `dotclaude/`

- `agents` - Personal agents for Claude Code.
- `commands` - Personal commands for Claude Code.
- `hooks` - Personal hooks for Claude Code.
- `scripts` - Scripts for Claude Code, including agent-evolution.sh.
- `shared` - Shared resources for Claude Code of documents there were not created here nor are they part of the submodules.
- `logs` - Logs for Claude Code Agents.

#### `dotclaude/scripts`

- `agent-evolution.sh` - Script to evolve agents by looping agent evaluation and improvements.

### `dotclaude/shared`

- `docs` - Shared documents for Claude Code.
- `downloads` - Shared downloads for Claude Code.

## Specialized Claude Configurations

This repository now uses specialized .claude directories for different workflows:

### dotclaude/

**Mount Location**: `~/.claude`
**Purpose**: General-purpose Claude Code configurations
**Contents**: General agents, commands, shared resources, instructions, scripts

### doc-understanding.claude/

**Purpose**: Documentation downloading, conversion, and processing workflow configurations
**Contents**:

1. Documentation download agents and commands
2. Document format converters
3. Conversion quality verifiers
4. Batch processing tools

**Related Functionality**:

1. `/docs:download` command for fetching documentation from URLs
2. Agent system for parallel document processing
3. Format conversion and verification workflows

### job-hunting.claude/

**Purpose**: Job hunting workflow configurations
**Contents**:

1. Job hunting agents (cover letter evaluators, etc.)
2. Job hunting slash commands (`/jobs:*`)
3. Job hunting shared resources

**Related Repos**:

1. job-hunting-automation (Python tools)
2. job-applications (private materials)
3. latex-templates (resume templates)

### personal-projects.claude/

**Purpose**: Personal project configurations (placeholder)
**Status**: To be populated as needed

### learning.claude/

**Purpose**: Learning and educational project configurations (placeholder)
**Status**: To be populated as needed

## Migration Notes

Content previously in `dotclaude/` has been split:

1. General configs remain in `dotclaude/`
2. Documentation-related configs moved to `doc-understanding.claude/`
3. Job hunting specific configs moved to `job-hunting.claude/`
4. Future specialized configs will use similar pattern

## Application Purpose

This repository is a personal configuration repository for Claude Code custom base configs, sub agents, custom slash commands and workflows.

## Frequently Used Commands

### Custom Slash Commands

<!-- TODO: Add custom slash commands -->

### Custom Sub-Agents

<!-- TODO: Add custom sub-agents -->

### Custom Python Agents

<!-- TODO: Add custom python agents -->

### Custom Workflows

<!-- TODO: Add custom workflows -->

## Development Notes

This repository is in early stages and will contain:

- Custom slash command configurations
- Sub agent definitions
- Personal workflow configurations for Claude Code
- Scripts for Claude Code
