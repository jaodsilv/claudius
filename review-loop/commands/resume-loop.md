---
description: Resumes a paused review loop session with optional config overrides
argument-hint: "[[--worktree] <worktree>] [--config <path>] [--reviewer <agent>] [--developer <agent>] [--max-rounds <n>]"
model: sonnet
tools: Task, Read, AskUserQuestion
skills:
  - review-loop:loading-config
---

# Resume Review Loop

Lightweight command that finds a paused/active review loop, re-reads configuration,
applies any overrides, and resumes execution.

## Step 0: Hook Additional Context Parsing

IGNORE the worktree argument from `$ARGUMENTS`. Instead, parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`
- `pr-metadata`: contains sub-tags:
  - `review-loop`: JSON object with reviewLoop state
  - `turn`: current turn state
  - `review-count`: current round number
  - `approved`: approval status

## Parse Arguments

Parse `$ARGUMENTS` to extract (EXCLUDING worktree which comes from additional context):

**Configuration** (optional overrides):
- `config`: Path to config file
- `reviewer`: Override reviewer agent
- `developer`: Override developer agent
- `ciChecker`: Override CI checker agent
- `ciFixer`: Override CI fixer agent
- `maxRounds`: Override max rounds

## Validate Loop State

Parse `<review-loop>` from context. Check for valid resumable state:

- `reviewLoop.active = true` OR
- `reviewLoop.pausedAt` is set (not null)

If `<pr-metadata>` was not provided (no metadata file):
  Report error: "No PR metadata found. Start a loop first with /start-loop."
  Exit.

If `reviewLoop` section doesn't exist:
  Report error: "No active or paused review loop found in this worktree."
  Exit.

If `reviewLoop.active = false` AND `reviewLoop.pausedAt` is null:
  Report error: "Review loop completed. Start a new loop with /start-loop."
  Exit.

## Load Configuration (for overrides)

Re-read configuration to allow changes between sessions:

### Step 1: Check for Explicit --config

If `--config` provided:
1. Read and parse YAML file at specified path
2. If file not found: ERROR "Config file not found: $path" and exit

### Step 2: Auto-detect Config (if no --config)

Search in order:
1. `$worktree/.config/review-loop/config.yaml` (project-level)
2. `~/.config/review-loop/config.yaml` (user-level)

Try to read each path. Use first one that exists.

### Step 3: Merge Configuration

Apply precedence: CLI args > config file > metadata values (from paused state)

For each field:
- If CLI arg provided → use CLI arg (override)
- Else if config has value → use config value (updated config)
- Else → use value from metadata (preserved from start)

**Always preserved from metadata** (cannot override):
- `worktree` - inherent to the session
- `reviewCount` - history must be preserved
- `turn` - continues from current state
- `startedAt` - original start time

**Can be overridden**:
- `reviewer` - swap reviewer mid-session
- `developer` - swap developer mid-session
- `ciChecker` - add/remove CI checking
- `ciFixer` - add/remove CI fixing
- `maxRounds` - extend/reduce remaining rounds
- `approvalThreshold` - change approval strictness
- Custom prompts

## Report Override Summary

If any overrides were applied, output:

```
Configuration changes for resumed loop:
  - Reviewer: $oldReviewer → $newReviewer (if changed)
  - Developer: $oldDeveloper → $newDeveloper (if changed)
  - Max Rounds: $oldMaxRounds → $newMaxRounds (if changed)
  ...
```

## Report State Before Resume

Output current state summary using values from context:

```
Resuming Review Loop

Worktree: $worktree
Round: $reviewCount (from <review-count>)
Current Turn: $turn (from <turn>)
Paused At: $pausedAt (from reviewLoop.pausedAt, or "Active" if not paused)

Agents:
- Reviewer: $reviewer
- Developer: $developer
- CI Checker: $ciChecker (or "Not configured")
- CI Fixer: $ciFixer (or "Not configured")

Settings:
- Max Rounds: $maxRounds
- Approval Threshold: $approvalThreshold
```

## Delegate to Orchestrator

Using Task tool, run `review-loop:orchestrator` agent:

```xml
<mode>resume</mode>
<worktree>$worktree</worktree>
<pr-metadata>$pr_metadata</pr-metadata>
<reviewer>$reviewer</reviewer>
<developer>$developer</developer>
<ciChecker>$ciChecker</ciChecker>
<ciFixer>$ciFixer</ciFixer>
<maxRounds>$maxRounds</maxRounds>
<approvalThreshold>$approvalThreshold</approvalThreshold>
```

Where `$pr_metadata` is the full `<pr-metadata>` block received from the hook context.

The orchestrator will:
1. Update metadata with any config changes
2. Clear pausedAt timestamp
3. Set active to true
4. Continue from current turn state
