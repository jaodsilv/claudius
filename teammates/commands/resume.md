---
description: Signal a paused teammate to resume work.
argument-hint: "<teammate>"
allowed-tools: ToolSearch, SendMessage, Read, Write, Edit, Glob, Grep, Bash, Skill
model: sonnet
---

See the `teammates:teammate-conventions` skill for the envelope-v1
definition, `team.json` shape, and runtime path layout. This command MUST
NOT duplicate that contract.

Resume is the inverse of `/pause`: a **cooperative protocol-level
signal**. Generated teammate agents honor `control:resume` because the
scaffold template instructs them to. The signal is sent even when the
teammate is not currently marked `paused`, because the registry status
may have drifted from the teammate's actual state.

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

3. Inspect the existing `status`:
   - If `status != "paused"`, emit a warning and continue (we still
     send the signal in case the registry has drifted):

     > warning: `<$teammate>` is not currently paused (status=<s>);
     > sending resume signal anyway

   - If `status == "killed"`, emit a warning and continue — resume is
     a no-op against a killed teammate:

     > warning: `<$teammate>` is marked killed; resume signal will
     > have no effect

## Phase 4 — Send resume envelope

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
  "subject": "control:resume",
  "body": "Resume processing. Accept new requests."
}
```

Serialize to a single JSON string (no trailing newline) for the
`message` field and call:

```text
SendMessage(to=<$teammate>, message=<envelope-json-string>)
```

If the call fails, surface the harness error verbatim and skip Phase 5.
Proceed to Phase 6 with a failure result.

## Phase 5 — Update registry

On a successful send, only update the registry if the prior status was
`"paused"` (do not overwrite `working`, `blocked`, etc., since those
reflect teammate-reported state):

1. If prior `status == "paused"`, set `status = "idle"` on the matching
   entry in `team.json#teammates[*]`.
2. Set `last_message_ts` to the envelope's `ts` regardless.
3. Write the full object to `./.claudius/teammates/team.json.tmp` via
   `Write`, preserving `schema_version: 1` and all other fields.
4. Rename atomically:

   ```bash
   mv ./.claudius/teammates/team.json.tmp ./.claudius/teammates/team.json
   ```

5. Append the envelope JSON (one line, followed by `\n`) to
   `./.claudius/teammates/logs/<$teammate>.log`. Create the `logs/`
   directory if missing.

## Phase 6 — Report

Emit a short markdown summary:

```markdown
## Teammate Resumed

- **Teammate**: <$teammate>
- **Team**: <team.name>
- **Previous status**: <prior-status>
- **New status**: idle | <unchanged-status>
- **Result**: sent | failed (<error>)

### Next Steps

- `/send-message <$teammate> "..."` — dispatch new work
- `/inspect <$teammate>` — view current status block
```
