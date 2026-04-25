---
description: Create a new teammate team, optionally bootstrapped from a preset.
argument-hint: "<team-name> [--from-preset=<preset-name>] [--model=<model>]"
allowed-tools: ToolSearch, TeamCreate, Agent, SendMessage, Read, Write, Edit, Glob, Grep, Bash, Skill, AskUserQuestion
model: sonnet
---

See the `teammates:teammate-conventions` skill for the message envelope
and team.json shape.

## Phase 1 — Load tools

Call:

```text
ToolSearch(query="select:TeamCreate,SendMessage,Agent", max_results=3)
```

If the call fails, or the response does not contain a schema for every
one of `TeamCreate`, `SendMessage`, and `Agent`, abort immediately with
the exact human-readable error:

> teammate mode unavailable in this harness

Do not continue to later phases.

## Phase 2 — Parse args

From <arguments>$ARGUMENTS</arguments> extract:

- `$teamName` (required, positional) — the first non-flag token. MUST
  match `^[a-z][a-z0-9-]{1,39}$`. If missing or invalid, abort with a
  message explaining the slug rule.
- `$preset` (optional) — value of `--from-preset=<name>`.
- `$model` (optional, default `sonnet`) — value of `--model=<model>`.

## Phase 3 — Preflight

1. Read `./.claudius/teammates/team.json` if it exists.
2. If parsing succeeds and `team.name == $teamName`, abort with:

   > Team `<$teamName>` already exists. Try `<$teamName>-2`.

   Increment the `-N` suffix until the suggested name is free.
3. If the file does not exist, treat the current project as having no
   active team and proceed.

## Phase 4 — Load preset (only if `$preset` is set)

1. Read `${CLAUDE_PLUGIN_ROOT}/presets/$preset.json`. On read failure,
   abort with a clear error.
2. Validate against the preset schema documented in
   `${CLAUDE_PLUGIN_ROOT}/presets/README.md`:
   - `schema_version == 1`
   - `members[*].name` matches `^[a-z][a-z0-9-]{1,39}$`
   - no duplicate `members[*].name` values
   - every `bootstrap_messages[*].to` refers to an existing member name
3. Name-collision-check: for every member, ensure no file exists at
   `./.claudius/teammates/agents/<member-name>.md`. If any collision is
   found, abort listing all colliding names before any writes.
4. For each member with `agent_type == "generated"`:
   - Read `${CLAUDE_PLUGIN_ROOT}/templates/teammate-agent.md.tmpl`.
   - Substitute placeholders:
     - `{{name}}` → member name
     - `{{description}}` → `member.description`
     - `{{team}}` → `$teamName`
     - `{{created}}` → current ISO-8601 UTC timestamp
     - `{{role}}` → `member.role` if present, else `member.description`
   - Write the substituted content to
     `./.claudius/teammates/agents/<member-name>.md` via `Write`.

If `$preset` is unset, treat the team as empty (zero members) for the
remaining phases.

## Phase 5 — TeamCreate

Call:

```text
TeamCreate(name=$teamName, default_model=$model)
```

If it fails, abort and surface the harness error. Do not attempt to
write `team.json` unless `TeamCreate` succeeded.

## Phase 6 — Spawn members

For each preset member (order preserved):

- If `member.agent_type == "generated"`, use
  `subagent_type="general-purpose"`.
- Otherwise, use `subagent_type=member.agent_type` verbatim.

Call:

```text
Agent(
  name=<member-name>,
  team_name=$teamName,
  subagent_type=<resolved-subagent-type>,
  prompt="You have been spawned as teammate <member-name> on team <$teamName>. Read your agent file at ./.claudius/teammates/agents/<member-name>.md and wait for an envelope-v1 message."
)
```

Record each spawn's timestamp in `$spawnedAt[<member-name>]` for the
persistence phase.

## Phase 7 — Bootstrap messages

For each entry in `preset.bootstrap_messages` (order preserved), build
an envelope-v1 JSON object (see `teammates:teammate-conventions`):

```json
{
  "v": 1,
  "from": "orchestrator",
  "to": "<entry.to>",
  "team": "<$teamName>",
  "ts": "<fresh ISO-8601 UTC>",
  "kind": "bootstrap",
  "subject": "bootstrap",
  "body": "<entry.body>"
}
```

Then call:

```text
SendMessage(to=<entry.to>, message=<json-string>)
```

If any `SendMessage` fails, report the failure and continue with the
remaining entries; do not roll back spawns.

## Phase 8 — Persist `team.json`

Write `./.claudius/teammates/team.json` atomically:

1. Serialize the following object:

   ```json
   {
     "schema_version": 1,
     "team": {
       "name": "<$teamName>",
       "created": "<ISO-8601 UTC>",
       "config": {
         "message_format": "envelope-v1",
         "default_model": "<$model>",
         "agent_dir": "./.claudius/teammates/agents"
       }
     },
     "teammates": [
       {
         "name": "<member-name>",
         "agent_file": "./.claudius/teammates/agents/<member-name>.md",
         "spawn_source": "preset:<$preset>" ,
         "spawned_at": "<spawnedAt[member-name]>",
         "status": "idle",
         "last_message_ts": null
       }
     ]
   }
   ```

   When `$preset` is unset, use `spawn_source: "generated"` for any
   generated member or `"agent-type:<id>"` for installed-agent members.
2. Write to `./.claudius/teammates/team.json.tmp` via `Write`.
3. Rename with `Bash`:

   ```bash
   mv ./.claudius/teammates/team.json.tmp ./.claudius/teammates/team.json
   ```

Preserve `schema_version: 1` on every write.

## Phase 9 — Report

Emit a short markdown summary:

```markdown
## Team Created

- **Team**: <$teamName>
- **Default model**: <$model>
- **Members**: <N> (<comma-separated-names>)
- **Preset**: <$preset or "none">

### Next Steps

- `/list-teams`
- `/send-message <member> "<envelope body>"`
```
