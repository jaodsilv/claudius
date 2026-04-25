---
description: Resume every paused teammate on the active team.
argument-hint: "[--exclude=<name1>,<name2>] [--all]"
allowed-tools: ToolSearch, SendMessage, Read, Write, Edit, Glob, Grep, Bash, Skill
model: sonnet
---

See the `teammates:teammate-conventions` skill for the envelope-v1
definition, `team.json` shape, and runtime path layout. This command MUST
NOT duplicate that contract.

Resume is a **cooperative protocol-level signal** — see `/resume` for the
single-teammate variant. By default this command targets only members
currently marked `status == "paused"` in the registry. Pass `--all` to
send the resume signal to every non-killed member regardless of recorded
status (useful if the registry has drifted).

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

- `$exclude` (optional) — value of `--exclude=<name1>,<name2>,...`.
  Split on commas, trim whitespace. Each entry MUST match
  `^[a-z][a-z0-9-]{1,39}$`. If any entry is invalid, abort with a
  message explaining the slug rule.
- `$all` (optional, boolean) — presence of the bare `--all` flag.

If `$exclude` is unset, treat it as an empty set. Default `$all` to
`false`.

## Phase 3 — Read registry

Read `./.claudius/teammates/team.json`. If the file does not exist or
cannot be parsed, abort with:

> no active team — run `/create-team <name>` first

Build the target list:

- If `$all` is `false` (default): every `teammates[*]` whose `status ==
  "paused"` and whose name is not in `$exclude`.
- If `$all` is `true`: every `teammates[*]` whose `status != "killed"`
  and whose name is not in `$exclude`.

Members filtered out by `$exclude` or by the `killed` guard are
reported as `skipped(...)` rows. If the resulting target list is
empty, emit:

> no paused teammates on team `<team.name>`; nothing to resume

and exit cleanly with a zero-row report.

## Phase 4 — Iterate and send

For each target member, in declaration order:

1. Build an envelope-v1 JSON object (see
   `teammates:teammate-conventions` §2):

   ```json
   {
     "v": 1,
     "from": "orchestrator",
     "to": "<member.name>",
     "team": "<team.name>",
     "ts": "<fresh ISO-8601 UTC>",
     "kind": "request",
     "subject": "control:resume",
     "body": "Resume processing. Accept new requests."
   }
   ```

2. Call:

   ```text
   SendMessage(to=<member.name>, message=<envelope-json-string>)
   ```

3. Record the outcome in a per-member result row:
   - `ok` — send succeeded; stage `last_message_ts = <ts>`. Stage
     `status = "idle"` only when the prior status was `"paused"`
     (preserve `working`/`blocked`/etc. reported by the teammate).
   - `error(<harness error>)` — send failed; do NOT stage any
     registry change.
   - `skipped(<reason>)` — excluded, not paused (when `$all` is
     false), or already `killed`.

Do NOT abort the loop when any single `SendMessage` fails. Continue
with the remaining members.

Append each successfully-sent envelope (one JSON object per line) to
`./.claudius/teammates/logs/<member.name>.log`. Create `logs/` if
missing.

## Phase 5 — Persist registry

After the loop, if any member was staged for update:

1. Apply the staged `status` / `last_message_ts` updates to the
   in-memory `team.json` object.
2. Write to `./.claudius/teammates/team.json.tmp` via `Write`,
   preserving `schema_version: 1`.
3. Rename atomically:

   ```bash
   mv ./.claudius/teammates/team.json.tmp ./.claudius/teammates/team.json
   ```

If no member was successfully resumed, skip the write entirely.

## Phase 6 — Report

Emit a markdown table with one row per processed member plus a summary:

```markdown
## Resume-All Complete

- **Team**: <team.name>
- **Mode**: paused-only | all
- **Targeted**: <N>
- **Resumed**: <N-ok>
- **Failed**: <N-err>
- **Skipped**: <N-skip>

| Teammate | Previous | New | Result |
|----------|----------|-----|--------|
| <name>   | paused   | idle | ok |
| <name>   | paused   | paused | error(<err>) |
| <name>   | idle     | idle | skipped(not-paused) |

### Next Steps

- `/inspect` — view current status blocks for the team
- `/send-message <name> "..."` — dispatch new work
```
