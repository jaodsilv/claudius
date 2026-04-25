---
description: Send a message to a single teammate in the current team.
argument-hint: "<teammate> <message> [--subject=\"<short label>\"] [--kind=request|status|reply] [--correlation-id=<id>]"
allowed-tools: ToolSearch, SendMessage, Read, Write, Edit, Glob, Grep, Bash, Skill
model: sonnet
---

See the `teammates:teammate-conventions` skill for the envelope-v1
definition, `team.json` shape, and runtime path layout. This command MUST
NOT duplicate that contract.

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
- `$body` (required) — everything remaining after `$teammate`, with
  any of the recognized flags below stripped out. Trim leading/trailing
  whitespace.
- `$subject` (optional) — value of `--subject="<short label>"`. If
  unset, default to the first ~60 characters of `$body` (trimmed, with
  any trailing partial word cut at a word boundary).
- `$kind` (optional, default `"request"`) — value of
  `--kind=request|status|reply`. Reject any other value.
- `$correlationId` (optional) — value of `--correlation-id=<id>`. If
  unset, omit the field from the envelope entirely.

If `$body` is empty after flag stripping, abort with:

> send-message requires a non-empty message body

## Phase 3 — Preflight

1. Read `./.claudius/teammates/team.json`. If the file does not exist
   or cannot be parsed, abort with:

   > no active team — run `/create-team <name>` first

2. Confirm `$teammate` appears in `teammates[*].name`. If not, abort
   with:

   > teammate `<$teammate>` not found on team `<team.name>`; run
   > `/list-teammates` to see the roster

3. Compute the UTF-8 byte size of `$body`. If it exceeds 8192 bytes
   (8 KB cap per `teammates:teammate-conventions` §2), truncate to the
   last whole codepoint within 8 KB, append `"\n\n…[truncated]"`, and
   emit a warning before continuing:

   > warning: body exceeds 8 KB; truncated to 8192 bytes

## Phase 4 — Build envelope

Construct the envelope-v1 JSON object (schema defined in
`teammates:teammate-conventions` §2). Use the active team from
`team.json#team.name` and a fresh ISO-8601 UTC timestamp for `ts`:

```json
{
  "v": 1,
  "from": "orchestrator",
  "to": "<$teammate>",
  "team": "<team.name>",
  "ts": "<fresh ISO-8601 UTC>",
  "kind": "<$kind>",
  "subject": "<$subject>",
  "body": "<$body>"
}
```

Include `"correlation_id": "<$correlationId>"` only when the flag was
provided. Serialize to a single JSON string (no trailing newline) for
the `message` field.

## Phase 5 — Send

Call:

```text
SendMessage(to=<$teammate>, message=<envelope-json-string>)
```

If the call fails, surface the harness error verbatim and skip Phase 6
(do not update the registry on failure). Proceed to Phase 7 with a
failure result.

## Phase 6 — Update registry

On a successful send:

1. Update the matching entry in `team.json#teammates[*]`:
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

## Phase 7 — Report

Emit a short markdown summary:

```markdown
## Message Sent

- **To**: <$teammate>
- **Team**: <team.name>
- **Subject**: <$subject>
- **Kind**: <$kind>
- **Body size**: <N> bytes<, truncated if applicable>
- **Result**: sent | failed (<error>)
```
