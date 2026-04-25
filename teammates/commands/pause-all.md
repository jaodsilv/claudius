---
description: Pause every teammate on the active team.
argument-hint: "[--exclude=<name1>,<name2>]"
allowed-tools: ToolSearch, SendMessage, Read, Write, Edit, Glob, Grep, Bash, Skill
model: sonnet
---

See the `teammates:teammate-conventions` skill for the envelope-v1
definition, `team.json` shape, and runtime path layout. This command MUST
NOT duplicate that contract.

Pause is a **cooperative protocol-level signal** — see `/pause` for the
single-teammate variant. This command fans out the same signal to every
member of the active team and never aborts on per-member failure; each
result is reported in a table so the operator can retry individuals.

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
  Split on commas, trim whitespace from each entry. Each entry MUST
  match `^[a-z][a-z0-9-]{1,39}$`. If any entry is invalid, abort with
  a message explaining the slug rule.

If `$exclude` is unset, treat it as an empty set.

## Phase 3 — Read registry

Read `./.claudius/teammates/team.json`. If the file does not exist or
cannot be parsed, abort with:

> no active team — run `/create-team <name>` first

If `teammates[]` is empty, emit:

> team `<team.name>` has no members; nothing to pause

and exit cleanly with a zero-row report.

Build the target list: every `teammates[*].name` not in `$exclude`.
Members already at `status == "killed"` are skipped silently and
reported as `skipped (killed)` in the final table.

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
     "subject": "control:pause",
     "body": "Suspend work after current task unit. Do not accept new requests until you receive control:resume."
   }
   ```

2. Call:

   ```text
   SendMessage(to=<member.name>, message=<envelope-json-string>)
   ```

3. Record the outcome in a per-member result row:
   - `ok` — send succeeded; stage `status = "paused"` and
     `last_message_ts = <ts>`.
   - `error(<harness error>)` — send failed; do NOT stage any
     registry change for this member.
   - `skipped(<reason>)` — excluded by `--exclude` or already
     `killed`.

Do NOT abort the loop when any single `SendMessage` fails. Continue
with the remaining members.

Append each successfully-sent envelope (one JSON object per line) to
`./.claudius/teammates/logs/<member.name>.log`. Create `logs/` if
missing.

## Phase 5 — Persist registry

After the loop, if any member was staged to `"paused"`:

1. Apply the staged `status` / `last_message_ts` updates to the
   in-memory `team.json` object.
2. Write the full object to `./.claudius/teammates/team.json.tmp` via
   `Write`, preserving `schema_version: 1`.
3. Rename atomically:

   ```bash
   mv ./.claudius/teammates/team.json.tmp ./.claudius/teammates/team.json
   ```

If no member was successfully paused, skip the write entirely.

## Phase 6 — Report

Emit a markdown table with one row per processed member plus a summary
line:

```markdown
## Pause-All Complete

- **Team**: <team.name>
- **Targeted**: <N>
- **Paused**: <N-ok>
- **Failed**: <N-err>
- **Skipped**: <N-skip>

| Teammate | Previous | New | Result |
|----------|----------|-----|--------|
| <name>   | idle     | paused | ok |
| <name>   | working  | working | error(<err>) |
| <name>   | killed   | killed | skipped(killed) |

### Next Steps

- `/resume-all` — lift all pauses at once
- `/resume <name>` — lift a single pause
```
