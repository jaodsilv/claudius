---
description: Show a teammate's latest status, last messages, and agent-file metadata.
argument-hint: "<teammate> [--messages=<n>]"
allowed-tools: Read, Glob, Grep, Bash
model: sonnet
---

## Phase 1 — Preflight

Parse `$ARGUMENTS`:

- First positional token → `$name` (required).
- `--messages=<n>` → `$messages` (default `10`).

If `$name` is missing, report `"usage: /inspect <teammate> [--messages=<n>]"`
and stop.

Read `./.claudius/teammates/team.json`.

- If the file is missing or has no `team.name`, report
  `"no active team"` and stop.
- Find the entry where `teammates[*].name == $name`. If none, report
  `"teammate '$name' not found on team '$team'"` and stop.
- Store the entry as `$tm` and `$team = team.name`.

## Phase 2 — Status

Tail the log and extract the most recent `// teammate-status` JSON
block (schema in `teammates:teammate-conventions` §3):

```bash
Bash("tail -n 100 ./.claudius/teammates/logs/$name.log")
```

```text
Grep(pattern="// teammate-status",
     path="./.claudius/teammates/logs/<name>.log",
     output_mode="content",
     -n=true)
```

Take the highest line number match and Read that region to capture the
fenced JSON body. If no log or no status block exists, fall back to
`$tm.status` with a note that the value came from `team.json`.

## Phase 3 — Messages

Scan the log for envelope-v1 JSON objects. Heuristic: a line (or
multi-line JSON block) containing `"v": 1` AND a `"kind"` field whose
value is one of `request`, `reply`, `status`, `broadcast`, or
`bootstrap`. Envelope schema is in `teammates:teammate-conventions` §2.

```text
Grep(pattern="\"v\"\\s*:\\s*1",
     path="./.claudius/teammates/logs/<name>.log",
     output_mode="content",
     -n=true)
```

Take the last `$messages` envelopes. For each, capture `ts`, `kind`,
`from`, `to`, `subject`. Truncate subjects over 60 chars.

## Phase 4 — Agent file

If `$tm.agent_file` is non-null:

```bash
Bash("stat -c '%Y %s' \"$tm.agent_file\"")   # mtime epoch, size bytes
Bash("sha256sum \"$tm.agent_file\"")         # Git Bash on Windows
```

Convert mtime to ISO-8601 UTC; keep `sha256` short (first 12 chars).
If the file is missing, capture that fact and continue — do not fail.

## Phase 5 — Report

Emit four sections:

````markdown
## Teammate: $name (team: $team)

### Identity

- **name**: $name
- **spawn_source**: $tm.spawn_source
- **spawned_at**: $tm.spawned_at
- **agent_file**: $tm.agent_file or `-`
- **last_message_ts**: $tm.last_message_ts or `-`

### Status

```json
<the parsed // teammate-status block, or a note if unavailable>
```

### Recent messages (last N of $messages)

| ts | kind | from | to | subject |
|----|------|------|----|---------|
| <ts> | <kind> | <from> | <to> | <subject> |

### Agent file

- **path**: $tm.agent_file
- **mtime**: <iso-8601> (or `missing`)
- **size**: <bytes>
- **sha256**: <first 12 chars>
````

Do NOT modify any file — this command is read-only.
