---
description: Tail a teammate's log file (envelope messages and status blocks).
argument-hint: "<teammate> [--lines=<n>] [--all]"
allowed-tools: Read, Glob, Grep, Bash
model: sonnet
---

## Phase 1 — Parse args

From `$ARGUMENTS`:

- `--all` flag → `$all = true`.
- `--lines=<n>` → `$lines` (default `100`).
- First remaining positional token → `$name` (required unless `$all`).

If neither `$name` nor `$all` is provided, report
`"usage: /logs <teammate> [--lines=<n>] | /logs --all [--lines=<n>]"`
and stop.

## Phase 2 — Locate logs

Read `./.claudius/teammates/team.json`.

- If the file is missing or has no `team.name`, report
  `"no active team"` and stop.

Build `$targets`:

- If `$all`, iterate every entry in `teammates[]` and build the list
  `[<name>, ...]`.
- Otherwise, verify `$name` exists in `teammates[*].name`. If not,
  report `"teammate '$name' not found on team '$team'"` and stop.
  Set `$targets = [$name]`.

Each target's log path is
`./.claudius/teammates/logs/<name>.log`. See
`teammates:teammate-conventions` §4 for the runtime-data layout.

## Phase 3 — Dump

For each `<name>` in `$targets`, in order:

1. Print a header: `=== <name> ===`.
2. If the log file is missing or empty, print `(no log yet)` and
   continue to the next target — do NOT fail the command.
3. Otherwise, emit the last `$lines` lines inside a fenced code block:

   ```bash
   Bash("tail -n $lines ./.claudius/teammates/logs/<name>.log")
   ```

   ````markdown
   ```text
   <tail output>
   ```
   ````

Use Glob to confirm the log exists before tailing when needed:

```text
Glob(pattern="./.claudius/teammates/logs/<name>.log")
```

## Phase 4 — Hint

After all dumps, print a single hint line:

```markdown
> Tip: run `/inspect <name>` for a parsed summary (latest status,
> recent envelopes, and agent-file metadata).
```

Do NOT modify any file — this command is read-only.
