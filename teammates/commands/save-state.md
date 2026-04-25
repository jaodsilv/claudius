---
description: Snapshot one teammate's state (for recovery after /shutdown).
argument-hint: "<teammate> [--tail=<n>]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Skill
model: sonnet
---

Snapshot a single teammate to a state file that conforms to
`templates/state.schema.json`. See `teammates:teammate-conventions` for
the envelope and status-block shapes, and `docs/state-schema.md` for the
state file field reference.

This command performs reads and writes only; it does not use any
deferred tools, so no `ToolSearch` phase is required.

## Phase 1 — Preflight

1. Parse `<arguments>$ARGUMENTS</arguments>`:
   - `$name` (REQUIRED positional) — teammate slug.
   - `$tail` (OPTIONAL) — `--tail=<n>`, default `20`, hard-capped at
     `20` per `docs/state-schema.md` size discipline. Clamp silently.
2. Read `./.claudius/teammates/team.json`. Abort with a clear error if
   the file is missing or unparsable.
3. Locate the teammate entry with `name == $name`. If not found, abort
   with `"teammate <$name> not found on team <team.name>"`.
4. Extract:
   - `$team = team.name`
   - `$config = team.config`
   - `$agentFile = teammate.agent_file` (MAY be null for teammates
     spawned from an installed agent-type with no generated file).
   - `$spawnSource = teammate.spawn_source`

## Phase 2 — Build snapshot

Assemble the state JSON in memory:

- `schema_version`: `1`
- `state_id`: `"<$team>-<$name>-<unix-ts>"` where `<unix-ts>` is
  `$(date -u +%s)`.
- `captured_at`: ISO-8601 UTC now (`$(date -u +%Y-%m-%dT%H:%M:%SZ)`).
- `team.name`: `$team`
- `team.config`: `$config` copied verbatim.
- `teammate.name`: `$name`
- `teammate.agent_file`: `$agentFile` (MAY be null).
- `teammate.agent_file_sha256`:
  - If `$agentFile` is non-null AND the file exists, compute
    `sha256sum "$agentFile" | awk '{print $1}'` via Bash (Git Bash on
    Windows).
  - Else use the sha256 of the empty string:
    `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.
- `teammate.spawn_source`: `$spawnSource`.
- `teammate.last_status`: the latest `// teammate-status` JSON block
  parsed from `./.claudius/teammates/logs/<$name>.log`, or `null` if
  the log is missing or contains no status block. Use Grep with a
  regex that finds the `// teammate-status` marker and Read the JSON
  that follows.
- `teammate.recent_messages`: the last `$tail` envelope-v1 JSON
  objects appearing in the same log (chronological order). If the log
  is missing, use `[]`.
- `teammate.scratch.agent_body`: full UTF-8 text of `$agentFile` if it
  exists, else `""`.

The resulting object MUST validate against
`templates/state.schema.json`.

## Phase 3 — Persist

Write atomically:

1. Ensure the directory exists:

   ```bash
   mkdir -p ./.claudius/teammates/state
   ```

2. `Write` the JSON to
   `./.claudius/teammates/state/<state_id>.json.tmp`.
3. Rename with Bash:

   ```bash
   mv ./.claudius/teammates/state/<state_id>.json.tmp \
      ./.claudius/teammates/state/<state_id>.json
   ```

## Phase 4 — Report

Emit:

```markdown
## State Saved

- **Teammate**: <$name>
- **Team**: <$team>
- **State ID**: <state_id>
- **File**: ./.claudius/teammates/state/<state_id>.json
- **Size**: <bytes> bytes
- **Messages captured**: <len(recent_messages)> / <$tail>

### Next Steps

`/restore-state <state_id>`
```
