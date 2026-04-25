---
description: Send the same message to every teammate on the active team; report per-recipient results.
argument-hint: "<message> [--subject=\"<short label>\"] [--exclude=<name1>,<name2>]"
allowed-tools: ToolSearch, SendMessage, Read, Write, Edit, Glob, Grep, Bash, Skill
model: sonnet
---

See the `teammates:teammate-conventions` skill for the envelope-v1
definition and `team.json` shape. This command MUST NOT duplicate that
contract.

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

- `$body` (required) — everything remaining after the recognized flags
  below are stripped out. Trim leading/trailing whitespace.
- `$subject` (optional) — value of `--subject="<short label>"`. If
  unset, default to the first ~60 characters of `$body` (trimmed, with
  any trailing partial word cut at a word boundary).
- `$exclude` (optional) — comma-separated list from
  `--exclude=<name1>,<name2>`. Split on `,`, trim each, discard empty
  tokens.

If `$body` is empty after flag stripping, abort with:

> broadcast requires a non-empty message body

## Phase 3 — Preflight

1. Read `./.claudius/teammates/team.json`. If the file does not exist
   or cannot be parsed, abort with:

   > no active team — run `/create-team <name>` first

2. Build the recipient list: every `teammates[*].name` that is NOT in
   `$exclude`. If the resulting list is empty, abort with:

   > broadcast has no recipients after applying --exclude

3. Compute the UTF-8 byte size of `$body`. If it exceeds 8192 bytes
   (8 KB cap per `teammates:teammate-conventions` §2), truncate to the
   last whole codepoint within 8 KB, append `"\n\n…[truncated]"`, and
   emit a warning before continuing:

   > warning: body exceeds 8 KB; truncated to 8192 bytes

## Phase 4 — Iterate

For each recipient in the list (order preserved), build an envelope-v1
JSON object (schema defined in `teammates:teammate-conventions` §2):

```json
{
  "v": 1,
  "from": "orchestrator",
  "to": "<recipient-name>",
  "team": "<team.name>",
  "ts": "<fresh ISO-8601 UTC per recipient>",
  "kind": "broadcast",
  "subject": "<$subject>",
  "body": "<$body>"
}
```

Then call:

```text
SendMessage(to=<recipient-name>, message=<envelope-json-string>)
```

Record `{name, ok: true|false, error?: <harness message>, ts: <envelope ts>}`
in `$results[<recipient-name>]`. NEVER abort the loop on a single
failure — continue with the remaining recipients and capture the error
for the final report.

## Phase 5 — Update registry

After the loop completes:

1. For every recipient with `ok: true`, update the matching entry in
   `team.json#teammates[*]`:
   - Set `last_message_ts` to that recipient's envelope `ts`.
2. Write the full object to `./.claudius/teammates/team.json.tmp` via
   `Write`, preserving `schema_version: 1` and all other fields.
3. Rename atomically:

   ```bash
   mv ./.claudius/teammates/team.json.tmp ./.claudius/teammates/team.json
   ```

4. For every recipient with `ok: true`, append the envelope JSON (one
   line, followed by `\n`) to `./.claudius/teammates/logs/<name>.log`.
   Create the `logs/` directory if missing.

Failed recipients do NOT have their `last_message_ts` updated and do
NOT receive a log append.

## Phase 6 — Report

Emit a markdown table followed by a summary line:

```markdown
## Broadcast Results

- **Team**: <team.name>
- **Subject**: <$subject>
- **Body size**: <N> bytes<, truncated if applicable>

| name | status | error |
|------|--------|-------|
| <name1> | sent | — |
| <name2> | failed | <error message> |

**Summary**: <total> total, <success> sent, <fail> failed.
```
