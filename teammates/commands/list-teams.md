---
description: List known teams (active + saved-state recoverable) in the current project.
argument-hint: ""
allowed-tools: Read, Glob, Grep, Bash
model: sonnet
---

See the `teammates:teammate-conventions` skill for the `team.json` shape
and runtime-data layout this command inspects.

This command uses no deferred tools, so it has no `ToolSearch` phase.

## Phase 1 — Active team

1. Read `./.claudius/teammates/team.json` if it exists.
2. If the file is missing or fails to parse as JSON with
   `schema_version: 1`, record `$activeTeam = null` and continue — the
   project simply has no active team.
3. Otherwise, extract:
   - `team.name`
   - `team.config.default_model`
   - `teammates[*].name` (for the member count and name list)

## Phase 2 — Recoverable teams

1. Call `Glob` with pattern
   `./.claudius/teammates/state/*.manifest.json`.
2. For each match, `Read` the file and pull:
   - `team` (team name at capture time)
   - `manifest_id`
   - `captured_at`
   - `members` — its length (and names, for the detail column)
3. On any per-file parse failure, skip that manifest and note it in the
   report as `(unreadable: <path>)`.

## Phase 3 — Report

Emit two markdown tables. If `$activeTeam` is `null`, print
`_no active team_` under the **Active** heading instead of the table.

```markdown
## Active

| Team | Members | Default Model |
| ---- | ------- | ------------- |
| <name> | <count> | <model> |

## Recoverable

| Team | Manifest ID | Captured At | Members |
| ---- | ----------- | ----------- | ------- |
| <team> | <manifest_id> | <captured_at> | <count> (<names>) |

Use `/restore-state <manifest_id>` to bring back.
```

If no manifests were found, print `_no recoverable teams_` in place of
the **Recoverable** table.
