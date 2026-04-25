---
description: List teammates on the active team with their statuses.
argument-hint: ""
allowed-tools: Read, Glob, Grep, Bash
model: sonnet
---

## Phase 1 — Load team

Read `./.claudius/teammates/team.json`.

- If the file is missing, empty, or has no `team.name`, report
  `"no active team"` and stop.
- Otherwise store `$team = team.name` and `$teammates = teammates[]`.

If `$teammates` is empty, report
`"team '$team' has no teammates yet"` and stop.

## Phase 2 — Collate statuses

For each teammate entry in `$teammates`, determine the best-available
status:

1. **Preferred source** — the most recent `// teammate-status` block
   in `./.claudius/teammates/logs/<name>.log`, if that log exists.
   Parse the fenced JSON block with the `// teammate-status` leading
   line (see `teammates:teammate-conventions` for the schema). Use its
   `status`, `task` (for the `current_task` column), and `ts` (to
   compare with `last_message_ts`).
2. **Fallback** — if no log exists or no status block is found, use
   the teammate's `status` field from `team.json` and leave
   `current_task` blank.

Use Grep to locate the last status block efficiently, e.g.:

```text
Grep(pattern="// teammate-status",
     path="./.claudius/teammates/logs/<name>.log",
     output_mode="content",
     -n=true)
```

Take the highest line number match and Read that region to extract the
JSON body.

## Phase 3 — Report

Emit a single markdown table:

```markdown
## Team: $team

| name | status | spawn_source | last_message_ts | current_task |
|------|--------|--------------|-----------------|--------------|
| <name> | <status> | <spawn_source> | <last_message_ts or `-`> | <task or empty> |
```

Rules:

- One row per teammate in the order they appear in `team.json`.
- `last_message_ts` from `team.json#teammates[*].last_message_ts`;
  render `null` as `-`.
- `current_task` is empty when the status came from the fallback
  source or the block had no `task` field.
- Do NOT modify any file — this command is read-only.
