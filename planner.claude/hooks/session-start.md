---

type: SessionStart
description: Check for optional dependencies and inform user of available capabilities
---

# Planner Session Start Hook

## Purpose

Check for optional plugin dependencies and available tools at session start.
Early detection prevents cryptic failures mid-workflow.

## Checks

### 1. GitHub CLI (gh)

Run: `gh --version`

**If available**:

- Log: "GitHub CLI detected - full issue prioritization available"

**If not available**:

- Warn: "GitHub CLI (gh) not found - /planner:prioritize requires gh for issue fetching. Install from <https://cli.github.com/>/>"

### 2. Brainstorm Pro Plugin

Check for: `brainstorm.claude/.claude-plugin/plugin.json` or installed brainstorm-pro plugin

**If available**:

- Log: "Brainstorm Pro detected - /planner:gather-requirements can use enhanced brainstorming"

**If not available**:

- Info: "Tip: Install brainstorm-pro for deeper requirements discovery with Socratic dialogue"

### 3. Output Directory

Check for: `docs/planning/`

**If not exists**:

- Info: "Output directory docs/planning/ will be created on first use"

## Output Format

Present findings as a brief status summary. Concise output avoids cluttering
session start while still surfacing actionable information:

```text
Planner Plugin Ready
├── GitHub CLI: [Available|Not found]
├── Brainstorm Pro: [Available|Not installed]
└── Output: docs/planning/
```
