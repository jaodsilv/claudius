---
description: Starts a review loop orchestration for iterative code review and fixes
argument-hint: [--config <path>] [--reviewer <agent>] [--developer <agent>] [options]
model: sonnet
tools: Task, Read, AskUserQuestion
skills:
  - review-loop:loading-config
---

# Start Review Loop

Lightweight command that loads configuration, parses arguments, and delegates to the orchestrator agent.

## Parse Arguments

Parse `$ARGUMENTS` (XML or CLI format) to extract:

**Configuration**:
- `config`: Path to config file (optional, enables explicit config)

**Agents** (can come from config or CLI):
- `reviewer`: Reviewer agent name
- `developer`: Developer agent name
- `ciChecker`: CI checker agent name
- `ciFixer`: CI fixer agent name

**Settings** (can come from config or CLI):
- `worktree`: Path to worktree (default: current directory)
- `maxRounds`: Max iterations (default: 5)
- `approvalThreshold`: Approval level - all, critical, important (default: all)

**Prompts** (can come from config or CLI):
- `reviewerPrompt`: Custom prompt for reviewer
- `developerPrompt`: Custom prompt for developer
- `ciCheckerPrompt`: Custom prompt for CI checker
- `ciFixerPrompt`: Custom prompt for CI fixer

**Flags**:
- `noHandingOver`: Disable context passing between rounds (default: false)

## Load Configuration

### Step 1: Check for Explicit --config

If `--config` provided:
1. Read and parse YAML file at specified path
2. If file not found: ERROR "Config file not found: $path" and exit

### Step 2: Auto-detect Config (if no --config)

Search in order:
1. `$worktree/.config/review-loop/config.yaml` (project-level)
2. `~/.config/review-loop/config.yaml` (user-level)

Try to read each path. Use first one that exists.
If none found, continue with CLI args only.

### Step 3: Merge with CLI Arguments

Apply precedence: CLI args > config file > hardcoded defaults

For each field:
- If CLI arg provided → use CLI arg
- Else if config has value → use config value
- Else → use hardcoded default (if any)

Hardcoded defaults:
- `maxRounds`: 5
- `approvalThreshold`: all

### Step 4: Extract Prompts from Config

If config file has `prompts` section:
- `reviewerPrompt` = config.prompts.reviewer (if not overridden by CLI)
- `developerPrompt` = config.prompts.developer (if not overridden by CLI)
- `ciCheckerPrompt` = config.prompts.ciChecker (if not overridden by CLI)
- `ciFixerPrompt` = config.prompts.ciFixer (if not overridden by CLI)

## Validate Required Arguments

After merge, if `reviewer` is still missing:
  Use AskUserQuestion:
  ```
  Question: "Which agent should perform code review?"
  Header: "Reviewer"
  Options:
    - label: "pr-review-toolkit:code-reviewer (Recommended)"
      description: "Comprehensive PR review with specialized sub-agents"
    - label: "gitx:review:reviewer"
      description: "Standard gitx PR reviewer"
    - label: "Custom"
      description: "Specify a different agent"
  ```

After merge, if `developer` is still missing:
  Use AskUserQuestion:
  ```
  Question: "Which agent should address review feedback?"
  Header: "Developer"
  Options:
    - label: "gitx:address-review:review-responder (Recommended)"
      description: "Multi-agent response handler for PR feedback"
    - label: "Custom"
      description: "Specify a different agent"
  ```

## Report Configuration Source

Output brief summary of where config came from:

If explicit --config used:
  "Using config: $configPath"

If auto-detected:
  "Using config: $configPath (auto-detected)"

If no config found:
  "No config file found, using CLI arguments"

## Determine Worktree

If `worktree` not provided:
1. Check if current directory contains `.thoughts/pr/metadata.yaml`
2. If found, use current directory
3. If not found, use current directory anyway (orchestrator will handle metadata creation)

## Delegate to Orchestrator

Using Task tool, run `review-loop:orchestrator` agent:

```xml
<mode>start</mode>
<worktree>$worktree</worktree>
<reviewer>$reviewer</reviewer>
<developer>$developer</developer>
<ciChecker>$ciChecker</ciChecker>
<ciFixer>$ciFixer</ciFixer>
<maxRounds>$maxRounds</maxRounds>
<approvalThreshold>$approvalThreshold</approvalThreshold>
<reviewerPrompt>$reviewerPrompt</reviewerPrompt>
<developerPrompt>$developerPrompt</developerPrompt>
<ciCheckerPrompt>$ciCheckerPrompt</ciCheckerPrompt>
<ciFixerPrompt>$ciFixerPrompt</ciFixerPrompt>
<noHandingOver>$noHandingOver</noHandingOver>
```

The orchestrator will handle all loop logic, state management, and reporting.
