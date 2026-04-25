---
description: Terminate a single teammate. This discards in-flight work for that teammate.
argument-hint: "<teammate> [--force]"
allowed-tools: ToolSearch, SendMessage, Read, Write, Edit, Glob, Grep, Bash, Skill, AskUserQuestion
model: sonnet
---

See the `teammates:teammate-conventions` skill for the envelope-v1
definition, `team.json` shape, and runtime path layout. This command MUST
NOT duplicate that contract.

**Terminate is cooperative.** The Claude Code harness provides no
primitive to forcibly kill a single Agent teammate — there is no
per-member counterpart to `TeamDelete`. This command sends a
`control:kill` envelope and marks the registry entry `killed`; the
teammate itself is trusted to emit a final `teammate-status` block and
stop accepting new envelopes. A non-compliant teammate may continue to
run until the host session ends or the whole team is shut down via
`/shutdown`. State this bluntly in the report.

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

- `$teammate` (required, positional) — the first non-flag token. MUST
  match `^[a-z][a-z0-9-]{1,39}$`. If missing or invalid, abort with a
  message explaining the slug rule.
- `$force` (optional, boolean) — presence of the bare `--force` flag.
  Default `false`.

## Phase 3 — Preflight and confirm

1. Read `./.claudius/teammates/team.json`. If the file does not exist
   or cannot be parsed, abort with:

   > no active team — run `/create-team <name>` first

2. Confirm `$teammate` appears in `teammates[*].name`. If not, abort
   with:

   > teammate `<$teammate>` not found on team `<team.name>`

3. If `status == "killed"` already, emit a warning and exit cleanly
   with the current state — do not re-send the signal:

   > `<$teammate>` is already marked killed; no action taken

4. If `$force` is not set, call `AskUserQuestion` with:

   - **question**: ``Kill teammate `<$teammate>` on team `<team.name>`? This terminates the teammate and discards any in-flight work. Other teammates are not affected.``
   - **options**: `["Terminate", "Cancel"]`

   If the user picks `Cancel`, exit cleanly with no state change and
   report the cancellation.

## Phase 4 — Send terminate envelope

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
  "subject": "control:kill",
  "body": "Terminate immediately. Emit a final teammate-status with status=\"killed\" and stop."
}
```

Serialize to a single JSON string (no trailing newline) for the
`message` field and call:

```text
SendMessage(to=<$teammate>, message=<envelope-json-string>)
```

If the call fails, surface the harness error but STILL proceed to
Phase 5 — the whole point of `/kill` is that the registry must record
the intent to terminate even if the teammate is unreachable.

## Phase 5 — Update registry

1. Update the matching entry in `team.json#teammates[*]`:
   - Set `status` to `"killed"`.
   - Set `last_message_ts` to the envelope's `ts`.
2. **Do not remove the entry.** The record is retained so
   `/save-state` / `/save-state-all` can capture the full final roster
   and any later replacement spawn can detect the name collision.
3. Write the full object to `./.claudius/teammates/team.json.tmp` via
   `Write`, preserving `schema_version: 1`.
4. Rename atomically:

   ```bash
   mv ./.claudius/teammates/team.json.tmp ./.claudius/teammates/team.json
   ```

5. Append the envelope JSON (one line, followed by `\n`) to
   `./.claudius/teammates/logs/<$teammate>.log`. Create `logs/` if
   missing.

## Phase 6 — Report

Emit a short markdown summary. Be explicit that termination is
cooperative:

```markdown
## Teammate Killed

- **Teammate**: <$teammate>
- **Team**: <team.name>
- **Previous status**: <prior-status>
- **New status**: killed
- **Signal**: sent | failed (<error>)

> Note: termination is a cooperative signal. There is no harness
> primitive to forcibly stop a single teammate. The registry entry is
> retained for `/save-state` and collision detection; it is not
> deleted.

### Next Steps

- `/spawn <name> <agent-type>` — add a replacement teammate
- `/save-state-all` — checkpoint the remaining team
- `/shutdown` — tear down the whole team if desired
```
