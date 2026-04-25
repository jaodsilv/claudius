---
description: Signal a teammate to suspend work after current task unit.
argument-hint: "<teammate>"
allowed-tools: ToolSearch, SendMessage, Read, Write, Edit, Glob, Grep, Bash, Skill
model: sonnet
---

See the `teammates:teammate-conventions` skill for the envelope-v1
definition, `team.json` shape, and runtime path layout. This command MUST
NOT duplicate that contract.

Pause is a **cooperative protocol-level signal**. The Claude Code harness
has no native primitive to pause an Agent. Generated teammate agents honor
`control:pause` because the scaffold template instructs them to. Teammates
spawned from an installed agent type receive the same signal on a
best-effort basis — compliance depends on that agent's behavior.

## Phase 1 — Load tools

Call:

```text
ToolSearch(query="select:SendMessage", max_results=1)
```

If the call fails, or the response does not contain a schema for
`SendMessage`, abort immediately with the exact human-readable error:

> teammate mode unavailable in this harness

Do not continue to later phases.

## Phase 2 — Parse args

From <arguments>$ARGUMENTS</arguments> extract:

- `$teammate` (required, positional) — the first token before any
  whitespace. MUST match `^[a-z][a-z0-9-]{1,39}$`. If missing or
  invalid, abort with a message explaining the slug rule.

## Phase 3 — Preflight

1. Read `./.claudius/teammates/team.json`. If the file does not exist
   or cannot be parsed, abort with:

   > no active team — run `/create-team <name>` first

2. Confirm `$teammate` appears in `teammates[*].name`. If not, abort
   with:

   > teammate `<$teammate>` not found on team `<team.name>`; run
   > `/list-teammates` to see the roster

3. Inspect the existing `status` on that entry:
   - If `status == "paused"`, emit a warning and continue (the pause
     signal is idempotent):

     > warning: `<$teammate>` is already paused; re-sending signal

   - If `status == "killed"`, emit a warning and continue — pause is a
     no-op against a killed teammate but we still record the attempt:

     > warning: `<$teammate>` is marked killed; pause signal will have
     > no effect

## Phase 4 — Send pause envelope

Build an envelope-v1 JSON object (schema defined in
`teammates:teammate-conventions` §2) using the active team from
`team.json#team.name` and a fresh ISO-8601 UTC timestamp for `ts`:

```json
{
  "v": 1,
  "from": "orchestrator",
  "to": "<$teammate>",
  "team": "<team.name>",
  "ts": "<fresh ISO-8601 UTC>",
  "kind": "request",
  "subject": "control:pause",
  "body": "Suspend work after current task unit. Do not accept new requests until you receive control:resume."
}
```

Serialize to a single JSON string (no trailing newline) for the
`message` field and call:

```text
SendMessage(to=<$teammate>, message=<envelope-json-string>)
```

If the call fails, surface the harness error verbatim and skip Phase 5
(do not update the registry on failure). Proceed to Phase 6 with a
failure result.

## Phase 5 — Update registry

On a successful send:

1. Update the matching entry in `team.json#teammates[*]`:
   - Set `status` to `"paused"`.
   - Set `last_message_ts` to the envelope's `ts`.
2. Write the full object to `./.claudius/teammates/team.json.tmp` via
   `Write`, preserving `schema_version: 1` and all other fields.
3. Rename atomically:

   ```bash
   mv ./.claudius/teammates/team.json.tmp ./.claudius/teammates/team.json
   ```

4. Append the envelope JSON (one line, followed by `\n`) to
   `./.claudius/teammates/logs/<$teammate>.log`. Create the `logs/`
   directory if missing.

## Phase 6 — Report

Emit a short markdown summary:

```markdown
## Teammate Paused

- **Teammate**: <$teammate>
- **Team**: <team.name>
- **Previous status**: <prior-status>
- **New status**: paused | unchanged (send failed)
- **Result**: sent | failed (<error>)

### Next Steps

- `/resume <$teammate>` — lift the pause
- `/inspect <$teammate>` — view current status block
```
