---
description: Rebuild teammates from a saved state-id or manifest-id, re-creating the team if needed.
argument-hint: "<state-id-or-manifest-id> [--no-replay]"
allowed-tools: ToolSearch, TeamCreate, Agent, SendMessage, Read, Write, Edit, Glob, Grep, Bash, Skill, AskUserQuestion
model: sonnet
---

Rebuild one teammate or a whole team from files written by `/save-state`
or `/save-state-all`. See `teammates:teammate-conventions` for the
envelope and team.json shapes, and `docs/state-schema.md` for the state
file reference and the drift-handling algorithm this command implements.

## Phase 1 — Load tools

```text
ToolSearch(query="select:TeamCreate,Agent,SendMessage", max_results=3)
```

If the call fails or does not return schemas for all three of
`TeamCreate`, `Agent`, and `SendMessage`, abort with:

> teammate mode unavailable in this harness

## Phase 2 — Resolve id

Parse `<arguments>$ARGUMENTS</arguments>`:

- `$id` (REQUIRED positional).
- `$noReplay` = true if `--no-replay` present, else false.

Classify `$id` against `./.claudius/teammates/state/`:

- If a file `<$id>.manifest.json` exists, OR `$id` ends in
  `.manifest.json`, OR `$id` matches `^[a-z0-9][a-z0-9-]*-[0-9]+$` AND
  `<$id>.manifest.json` exists → **manifest mode**.
- Else if `<$id>.json` exists → **single-state mode**.
- Else abort: `"no state or manifest found for id <$id>"`.

In manifest mode: Read the manifest JSON, then Read every referenced
`<members[*].state_id>.json`. Fail fast on any missing member file.

In single-state mode: Read `<$id>.json`. Build a synthetic one-member
"manifest" in memory so Phase 5 can share the same loop.

Validate every loaded state file against `templates/state.schema.json`
(field presence, types, patterns). Abort on any validation failure.

## Phase 3 — Preflight

Read `./.claudius/teammates/team.json` if it exists.

- If absent → proceed to Phase 4 (team will be created).
- If present and `team.name != <state.team.name>` → abort:
  `"active team <current> differs from state team <saved>; /shutdown the active team first"`.
- If present and `team.name == <state.team.name>` → the team is
  already live. Ask the user via `AskUserQuestion`:

  ```text
  Question: "Team <name> already exists. How should restore proceed?"
  Options:
    - "abort"            (default, safest)
    - "restore-missing"  (spawn only members not currently in team.json)
    - "replace"          (destructive — caller must /shutdown first)
  ```

  On `abort`, stop. On `replace`, abort with a message instructing the
  user to run `/shutdown` first (this command does not delete teams).
  On `restore-missing`, continue with `$skipExisting = true`.

## Phase 4 — TeamCreate (if team missing)

If `team.json` did not exist in Phase 3:

```text
TeamCreate(
  team_name=<state.team.name>,
  default_model=<state.team.config.default_model>
)
```

On failure, surface the harness error and abort before spawning.

## Phase 5 — Per-member restore

For each member state loaded in Phase 2:

1. **Skip** if `$skipExisting` and `team.json` already lists this name.
2. **Drift check**. If `teammate.agent_file` is non-null:
   - If the file is missing OR
     `sha256sum <agent_file> | awk '{print $1}'` differs from
     `teammate.agent_file_sha256`:
     - `Write` `teammate.scratch.agent_body` back to
       `teammate.agent_file` (creating parent dirs if needed).
     - Record `$drift[name] = true` and warn the user in Phase 7.
   - Else `$drift[name] = false`.
3. **Resolve subagent type** from `teammate.spawn_source`:
   - `"generated"` → `general-purpose`
   - `"agent-type:<id>"` → `<id>` (verbatim)
   - `"preset:<name>"` → `general-purpose` (preset members are
     generated files)
4. **Spawn**:

   ```text
   Agent(
     subagent_type=<resolved-type>,
     name=<teammate.name>,
     team_name=<state.team.name>,
     prompt="You are teammate <name> on team <team>. Read your agent file at <agent_file>. Follow teammates:teammate-conventions. Your prior context is being replayed as bootstrap messages; wait for them before acting."
   )
   ```

5. **Replay** (unless `$noReplay`):
   For each envelope in `teammate.recent_messages` (chronological
   order), force `kind: "bootstrap"` while preserving every other
   field (including `correlation_id` and `in_reply_to`), then:

   ```text
   SendMessage(to=<teammate.name>, message=<envelope-json>)
   ```

   Count replayed envelopes per member into `$replayed[name]`.

## Phase 6 — Persist registry

Build the updated `team.json`:

- `schema_version: 1`.
- `team.name` = `<state.team.name>`.
- `team.created` = existing value if `team.json` existed, else now.
- `team.config` = `<state.team.config>` (trust saved values).
- `teammates[]`: one entry per restored member, merged with any
  existing entries being kept under `restore-missing`:
  - `name`, `agent_file`, `spawn_source` from the state file.
  - `spawned_at` = ISO-8601 UTC now.
  - `status` = `"idle"`.
  - `last_message_ts`: if `teammate.last_status.ts` exists, carry it
    forward; else `null`.

Write atomically:

```bash
# Write JSON to ./.claudius/teammates/team.json.tmp
mv ./.claudius/teammates/team.json.tmp ./.claudius/teammates/team.json
```

## Phase 7 — Report

Emit:

```markdown
## Team Restored

- **Team**: <team>
- **Source**: <manifest-id or state-id>
- **Restored members**: <N>

| Teammate | Drift repaired? | Messages replayed | Status |
|----------|-----------------|-------------------|--------|
| <name>   | yes / no        | <$replayed[name]> | idle   |
```

If any member had `$drift[name] == true`, include a prominent WARNING
line above the table listing the affected agent files: the on-disk
content differed from the saved snapshot and was overwritten from
`scratch.agent_body`.
