---
description: Identify teammates blocking team progress by age of blocked/long-running/error status.
argument-hint: "[--top=<n>]"
allowed-tools: Read, Glob, Grep, Bash
model: sonnet
---

## Phase 1 — Load data

Read `./.claudius/teammates/team.json`.

- If the file is missing, empty, or has no `team.name`, report
  `"no active team"` and stop.
- Otherwise store `$team = team.name` and `$teammates = teammates[]`.
- If `$teammates` is empty, report `"team '$team' has no teammates yet"`
  and stop.

Parse `--top=<n>` from `$ARGUMENTS` into `$top` (default `3`).

For each teammate, locate the most recent `// teammate-status` JSON
block in `./.claudius/teammates/logs/<name>.log`. Use Grep to find the
last match, then Read the region to extract the JSON body:

```text
Grep(pattern="// teammate-status",
     path="./.claudius/teammates/logs/<name>.log",
     output_mode="content",
     -n=true)
```

Tail the tail of the log if needed for the JSON payload:

```bash
Bash("tail -n 50 ./.claudius/teammates/logs/<name>.log")
```

If the log is missing or has no status block, fall back to
`team.json#teammates[*].status` with no `ts`, `task`, or `blockers`.

The status block schema is defined in
`teammates:teammate-conventions` §3 — do not duplicate it here.

## Phase 2 — Score

Build a ranked list using three priority tiers. Within each tier, sort
by `ts` ascending (oldest first). Teammates with status `idle` or
`done` are ignored.

1. **Tier 1**: `status == "blocked"` — team is waiting on external
   input; age directly signals blocking severity.
2. **Tier 2**: `status == "working"` — ordered by `ts` ascending so
   the longest-running task floats up. Fall-back entries with no `ts`
   sort last within the tier.
3. **Tier 3**: `status == "error"` — errored teammates consume
   attention without progressing; older errors rank higher.

Compute `age` as the difference between "now" (ISO-8601 UTC) and `ts`.
Render it as a compact string (`12m`, `3h`, `2d`). Use `-` when `ts`
is unavailable.

If the ranked list is empty, report
`"no bottlenecks: all teammates idle or done"` and stop.

## Phase 3 — Report

Truncate the ranked list to `$top` entries and emit:

```markdown
## Bottlenecks for team: $team (top $top)

| rank | name | status | age | task | blockers | suggested next action |
|------|------|--------|-----|------|----------|-----------------------|
| 1 | <name> | <status> | <age> | <task or `-`> | <blockers joined by `; ` or `-`> | <suggestion> |
```

Suggested next actions, by tier:

- `blocked` — `unblock via /inspect <name>` (look at blockers list).
- `working` — `check progress via /inspect <name>`.
- `error` — `review log via /logs <name>` and restart if needed.

Do NOT modify any file — this command is read-only.
