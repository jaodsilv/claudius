# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
> "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
> document are to be interpreted as described in
> [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

## Skills, Custom Slash Commands and Sub-Agents Instructions

- **CRITICAL**: Always use scripts and paths from the installed plugin versions (under `~/.claude/`), NOT from the current repository source.
- Follow the skill/slash command/agent instructions thoroughly, do not skip any steps unless explicitly stated.
- Do not assume anything without reading the instructions.
- To add additional steps request explicit approval.

## Repository Overview

This is a personal configuration repository for Claude Code containing a comprehensive
plugin ecosystem with 60+ agents, 40+ commands, and 30+ skills organized into
specialized plugin directories.

## Plugin Ecosystem

### Plugins Ready to use and install

#### gitx/

**Purpose**: Extended Git/GitHub workflow plugin with multi-agent orchestration
**See**: `gitx/README.md` for detailed documentation

#### cc/

**Purpose**: Meta-toolkit for creating and improving Claude Code plugin components
**See**: `cc/README.md` for detailed documentation

#### planner.claude/

**Purpose**: Strategic planning with roadmapping, prioritization, and deep ideation
**See**: `planner.claude/README.md` for detailed documentation

#### brainstorm.claude/

**Purpose**: Multi-agent requirements discovery through Socratic dialogue
**See**: `brainstorm.claude/README.md` for detailed documentation

### Supporting Directories

#### config/

**Purpose**: Markdownlint configurations

#### scripts/

**Purpose**: Generate docs, validate plugins, and shared hook libraries

- **CRITICAL**: `scripts/lib/` is the **single source of truth** for all plugin hook libraries
(`logging.sh`, `args-helper.sh`, `args-validator.sh`, `hook-output.sh`, `text-styles.sh`,
`count-tokens.py`).
- Each plugin's `hooks/scripts/lib/` is a **hard copy** of this directory and are synced by a CI job workflow.
- **NEVER edit files inside `<plugin>/hooks/scripts/lib/`**, instead edit `scripts/lib/` directly.

#### docs/

**Purpose**: Documentation directory

### Deprecated Folders

**IMPORTANT**: Do not touch unless you are requested to, but you take anything from there to build something new

- community-*/ - Community plugins
- curation/ - Marketplace curation analysis and reports
- doc-understanding.claude/ - Documentation downloading, conversion, and processing
- dotclaude/ - Legacy pré-plugins era agents, commands, and skills. Some parts may still be pending migration
- jaodsilv-career/ - Career development skill
- job-hunting.claude/ - Job hunting workflow configurations
- marketplace-curator/ - Marketplace curation tools
- tdd-pro/ - TDD workflow

### `dotclaude/` Migration Notes

Content previously in `dotclaude/` is being split:

1. General configs remaining in `dotclaude/`
2. Documentation-related configs moving to `doc-understanding.claude/`
3. Job hunting specific configs moving to `job-hunting.claude/`
4. Future specialized configs using similar pattern
