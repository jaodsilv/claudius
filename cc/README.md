# cc - Claude Code Meta-Tools

A meta-toolkit for creating, improving, and managing Claude Code plugin components.

## Overview

The `cc` plugin provides specialized tools for plugin developers who want to:

1. Create new plugin components (commands, skills, orchestrations)
2. Improve existing components with interactive workflows
3. Design multi-agent orchestrations

## Prerequisites

This plugin requires `plugin-dev@claude-plugins-official`. Install it first:

```bash
/plugin install plugin-dev@claude-plugins-official
```

## Installation

```bash
/plugin install cc@jaodsilv-claudius-marketplace
```

## Commands

### Creation Commands

| Command | Description |
|---------|-------------|
| `/cc:create-command` | Create a new slash command with best practices |
| `/cc:create-skill` | Create a new skill with progressive disclosure |
| `/cc:create-orchestration` | Create a multi-agent orchestration workflow |
| `/cc:create-output-style` | Create a new output-style with formatting guidance |

### Improvement Commands

| Command | Description |
|---------|-------------|
| `/cc:improve-command` | Analyze and improve an existing command |
| `/cc:improve-agent` | Analyze and improve an existing agent |
| `/cc:improve-skill` | Analyze and improve an existing skill |
| `/cc:improve-plugin` | Comprehensive plugin-wide improvement |
| `/cc:improve-orchestration` | Improve an orchestration workflow |
| `/cc:improve-output-style` | Analyze and improve an existing output-style |

## Agents

### Creator Agents

| Agent | Purpose |
|-------|---------|
| `@cc:command-creator` | Creates commands following plugin-dev best practices |
| `@cc:skill-creator` | Creates skills with progressive disclosure |
| `@cc:orchestration-creator` | Creates multi-agent orchestrations |
| `@cc:output-style-creator` | Creates output-styles with formatting guidance |

### Improver Agents

| Agent | Purpose |
|-------|---------|
| `@cc:command-improver` | Analyzes command quality and suggests improvements |
| `@cc:agent-improver` | Analyzes agent quality and suggests improvements |
| `@cc:skill-improver` | Analyzes skill structure and suggests improvements |
| `@cc:plugin-improver` | Comprehensive plugin analysis |
| `@cc:orchestration-improver` | Analyzes orchestration workflows |
| `@cc:output-style-improver` | Analyzes output-style quality and suggests improvements |

### Architect Agent

| Agent | Purpose |
|-------|---------|
| `@cc:orchestration-architect` | Designs orchestration architectures |

## Skills

| Skill | Purpose |
|-------|---------|
| `improvement-workflow` | Patterns for interactive analyze-suggest-approve-apply workflows |
| `orchestration-patterns` | Patterns for multi-agent coordination |

## Usage Examples

### Creating a Command

```bash
/cc:create-command deploy --plugin ./my-plugin
```

### Improving an Agent

```bash
/cc:improve-agent ./my-plugin/agents/my-agent.md
```

### Creating an Orchestration

```bash
/cc:create-orchestration code-review --plugin ./my-plugin
```

## Interactive Improvement Workflow

All improvement commands follow an interactive pattern:

1. **Analysis**: Load component, apply analysis framework, categorize by severity
2. **Presentation**: Show suggestions grouped by CRITICAL/HIGH/MEDIUM/LOW
3. **Approval**: Interactive selection of improvements to apply
4. **Application**: Apply changes with before/after display

## License

MIT
