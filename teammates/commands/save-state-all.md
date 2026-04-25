---
description: Snapshot every teammate on the active team; write a manifest for /restore-state.
argument-hint: "[--tail=<n>]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Skill
model: sonnet
---

Snapshot every teammate on the active team and write a manifest that
`/restore-state` can consume. Each member's state file conforms to
`templates/state.schema.json`; the manifest shape is documented in
`docs/state-schema.md`.

No deferred tools are used, so no `ToolSearch` phase is required.

## Phase 1 — Preflight

1. Parse `<arguments>$ARGUMENTS</arguments>`:
   - `$tail` (OPTIONAL) — `--tail=<n>`, default `20`, hard-capped at
     `20`. Clamp silently.
2. Read `./.claudius/teammates/team.json`. Abort on missing or
   unparsable file.
3. Let `$team = team.name`, `$config = team.config`,
   `$members = teammates[]`.
4. If `$members` is empty, abort with
   `"team <$team> has no teammates; nothing to save"`.
5. Compute `$ts = $(date -u +%s)` once; reuse for every member so all
   state files share the same batch timestamp.

## Phase 2 — Iterate and snapshot

For each member in `$members`, build the state file **using the same
logic as `save-state.md` Phase 2** (this duplication is intentional —
no Agent dispatch is used; state-building is cheap and sequential
keeps the code linear):

1. `state_id = "<$team>-<member.name>-<$ts>"`.
2. `captured_at` = ISO-8601 UTC now (recomputed per member so the
   timestamp reflects actual capture time).
3. Copy `team.name` / `team.config` from `team.json`.
4. `teammate.agent_file` = `member.agent_file` (MAY be null).
5. `teammate.agent_file_sha256`:
   - sha256 of the file if it exists
     (`sha256sum "<path>" | awk '{print $1}'`), else the empty-string
     sha256
     `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.
6. `teammate.spawn_source` = `member.spawn_source`.
7. `teammate.last_status` = latest `// teammate-status` block from
   `./.claudius/teammates/logs/<member.name>.log`, or `null`.
8. `teammate.recent_messages` = tail of `$tail` envelope-v1 objects
   from the same log, or `[]`.
9. `teammate.scratch.agent_body` = full file text, or `""`.

Persist each state file atomically:

```bash
mkdir -p ./.claudius/teammates/state
# Write JSON to ./.claudius/teammates/state/<state_id>.json.tmp
mv ./.claudius/teammates/state/<state_id>.json.tmp \
   ./.claudius/teammates/state/<state_id>.json
```

Collect `($memberName, $stateId)` pairs into `$manifestMembers`.

## Phase 3 — Write manifest

Build the manifest object:

```json
{
  "schema_version": 1,
  "manifest_id": "<$team>-<$ts>",
  "captured_at": "<ISO-8601 UTC now>",
  "team": "<$team>",
  "members": [
    { "name": "<member-name>", "state_id": "<state-id>" }
  ]
}
```

Write atomically to
`./.claudius/teammates/state/<$team>-<$ts>.manifest.json`:

```bash
# Write JSON to <manifest-path>.tmp
mv ./.claudius/teammates/state/<$team>-<$ts>.manifest.json.tmp \
   ./.claudius/teammates/state/<$team>-<$ts>.manifest.json
```

## Phase 4 — Report

Emit:

```markdown
## Team State Saved

- **Team**: <$team>
- **Manifest**: ./.claudius/teammates/state/<$team>-<$ts>.manifest.json
- **Members**: <N>

| Teammate | State ID |
|----------|----------|
| <name>   | <state_id> |

### Next Steps

`/restore-state <$team>-<$ts>`  (manifest id — restores the whole team)
`/restore-state <state_id>`     (single teammate)
```
