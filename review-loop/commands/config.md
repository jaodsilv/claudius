---
description: Interactive wizard to configure review-loop for project or user level
argument-hint: [--project | --user] [--edit]
model: sonnet
tools: Read, Write, AskUserQuestion, Glob, Bash
skills:
  - review-loop:loading-config
---

# Review Loop Configuration Wizard

Interactive command to create or edit review-loop configuration.

## Parse Arguments

Extract from `$ARGUMENTS`:

- `--project`: Configure project-level (`.config/review-loop/config.yaml`)
- `--user`: Configure user-level (`~/.config/review-loop/config.yaml`)
- `--edit`: Edit existing config instead of creating new

## Step 1: Choose Config Level

If neither `--project` nor `--user` provided, use AskUserQuestion:

```
Question: "Where should the configuration be saved?"
Header: "Config Level"
Options:
  - label: "Project (Recommended)"
    description: "Save to .config/review-loop/config.yaml in current project"
  - label: "User"
    description: "Save to ~/.config/review-loop/config.yaml for all projects"
```

## Step 2: Determine Config Path

Based on level:
- Project: `$CWD/.config/review-loop/config.yaml`
- User: `~/.config/review-loop/config.yaml`

## Step 3: Check Existing Config

Try to read config at determined path.

If config exists AND `--edit` not specified:

```
Question: "Config already exists. What would you like to do?"
Header: "Existing"
Options:
  - label: "Edit existing"
    description: "Modify the current configuration"
  - label: "Replace"
    description: "Start fresh with new configuration"
  - label: "Cancel"
    description: "Exit without changes"
```

If "Cancel" selected, exit with message: "Configuration cancelled."

If editing existing config, parse current values to use as defaults in following steps.

## Step 4: Configure Reviewer Agent

Use AskUserQuestion:

```
Question: "Which agent should review the code?"
Header: "Reviewer"
Options:
  - label: "pr-review-toolkit:code-reviewer (Recommended)"
    description: "Comprehensive PR review with specialized sub-agents"
  - label: "gitx:review:reviewer"
    description: "Standard gitx PR reviewer"
  - label: "Custom agent"
    description: "Specify your own reviewer agent"
```

If "Custom agent" selected, the user will provide the agent name in the "Other" field.

Store as `$reviewer`.

## Step 5: Configure Developer Agent

Use AskUserQuestion:

```
Question: "Which agent should address review feedback?"
Header: "Developer"
Options:
  - label: "gitx:address-review:review-responder (Recommended)"
    description: "Multi-agent response handler for PR feedback"
  - label: "Custom agent"
    description: "Specify your own developer agent"
```

Store as `$developer`.

## Step 6: Configure CI Integration

Use AskUserQuestion:

```
Question: "Enable CI status checking?"
Header: "CI"
Options:
  - label: "Yes - Full CI integration (Recommended)"
    description: "Check CI status and auto-fix failures"
  - label: "Yes - Check only"
    description: "Check CI status but don't auto-fix"
  - label: "No"
    description: "Skip CI integration"
```

Based on selection:
- "Full CI integration":
  - `$ciChecker` = `gitx:address-review:ci-status-checker`
  - `$ciFixer` = `gitx:address-review:ci-status-fixer`
- "Check only":
  - `$ciChecker` = `gitx:address-review:ci-status-checker`
  - `$ciFixer` = null
- "No":
  - `$ciChecker` = null
  - `$ciFixer` = null

## Step 7: Configure Max Rounds

Use AskUserQuestion:

```
Question: "Maximum review rounds before stopping?"
Header: "Max Rounds"
Options:
  - label: "5 (Recommended)"
    description: "Good balance for most PRs"
  - label: "3"
    description: "Quick iterations for small changes"
  - label: "10"
    description: "Extended for complex PRs"
  - label: "Custom"
    description: "Specify your own limit"
```

If "Custom" selected, user provides number in "Other" field.

Store as `$maxRounds`.

## Step 8: Configure Approval Threshold

Use AskUserQuestion:

```
Question: "When should the loop consider PR approved?"
Header: "Threshold"
Options:
  - label: "All issues resolved (Recommended)"
    description: "Stop only when all feedback addressed"
  - label: "Critical issues only"
    description: "Stop when no critical/blocker issues remain"
  - label: "Important and above"
    description: "Stop when no critical or important issues remain"
```

Map to values:
- "All issues resolved" → `all`
- "Critical issues only" → `critical`
- "Important and above" → `important`

Store as `$approvalThreshold`.

## Step 9: Custom Prompts (Optional)

Use AskUserQuestion:

```
Question: "Add custom instructions for agents?"
Header: "Prompts"
Options:
  - label: "No - Use defaults (Recommended)"
    description: "Agents use their built-in behavior"
  - label: "Yes - Add custom prompts"
    description: "Provide custom instructions for agents"
```

If "Yes" selected, inform user:
"You can add custom prompts by editing the config file after creation.
The prompts section allows customizing reviewer, developer, ciChecker, and ciFixer instructions."

## Step 10: Generate Config Content

Build YAML config:

```yaml
# Review Loop Configuration
# Generated by /review-loop:config
# Location: $configPath

version: 1

# Agents
reviewer: "$reviewer"
developer: "$developer"
```

If CI is configured, add:
```yaml

# CI Integration
ciChecker: "$ciChecker"
ciFixer: "$ciFixer"
```

Add loop settings:
```yaml

# Loop Settings
maxRounds: $maxRounds
approvalThreshold: $approvalThreshold
```

If custom prompts were requested, add commented template:
```yaml

# Custom Prompts (edit as needed)
# prompts:
#   reviewer: |
#     Your custom reviewer instructions here.
#   developer: |
#     Your custom developer instructions here.
```

## Step 11: Ensure Directory Exists

Using Bash tool, create parent directory if needed:

For project-level:
```bash
mkdir -p "$CWD/.config/review-loop"
```

For user-level:
```bash
mkdir -p "$HOME/.config/review-loop"
```

## Step 12: Write Config File

Using Write tool, save the generated config to `$configPath`.

## Step 13: Report Success

Output summary:

```
Configuration saved!

Location: $configPath

Settings:
  Reviewer:    $reviewer
  Developer:   $developer
  CI Checker:  $ciChecker (or "Not configured")
  CI Fixer:    $ciFixer (or "Not configured")
  Max Rounds:  $maxRounds
  Threshold:   $approvalThreshold

To start a review loop:
  /start-loop

To edit this config:
  /config --edit [--project | --user]
```
