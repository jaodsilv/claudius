---
description: Spawn a teammate on the active team from an installed agent type.
argument-hint: "<name> <agent-type-id> [--description=\"<short desc>\"]"
allowed-tools: ToolSearch, Agent, SendMessage, Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill
model: sonnet
---

## Phase 1 — Load tools

Deferred tool schemas must be loaded before use. Call:

```text
ToolSearch(query="select:Agent,SendMessage", max_results=2)
```

If the call fails or does not return schemas for both `Agent` and
`SendMessage`, abort with the message
`"teammate mode unavailable in this harness"`.

## Phase 2 — Parse arguments

From $ARGUMENTS extract:

- `$name` — REQUIRED teammate slug. Validate against
  `^[a-z][a-z0-9-]{1,39}$`. Reject if invalid.
- `$agent_type` — REQUIRED. The id to pass as `subagent_type` to the
  Agent tool (e.g. `general-purpose`, `code-reviewer`, any harness- or
  plugin-installed agent).
- `--description="..."` — OPTIONAL short description. Store in
  `$description`. If missing, default to
  `"teammate spawned from agent type $agent_type"`.

Unlike `/create-teammate`, this command does NOT produce an agent
definition file on disk. The teammate's behavior comes from the
installed agent type.

## Phase 3 — Preflight

1. Read `./.claudius/teammates/team.json`. If missing or empty, abort
   with `"no active team; run /team-create first"`.
2. Extract `$team = team.name` and `$teammates = teammates[]`.
3. If any existing teammate has `name == $name`, suggest `$name-2`
   (then `-3`, etc.) and abort so the user can re-run with the free
   name.

## Phase 4 — Spawn

Call Agent with the requested subtype and the teammate identity. The
teammate must be told up front to follow the envelope-v1 contract:

```text
Agent(
  subagent_type="$agent_type",
  name="$name",
  team_name="$team",
  prompt="You are teammate $name on team $team, instantiated from agent type $agent_type. Follow teammates:teammate-conventions envelope-v1 for all inter-teammate messages. Wait for an envelope-v1 message before acting."
)
```

## Phase 5 — Register

Append to `team.json#teammates`:

```json
{
  "name": "$name",
  "agent_file": null,
  "spawn_source": "agent-type:$agent_type",
  "spawned_at": "<ISO-8601 UTC now>",
  "status": "idle",
  "last_message_ts": null
}
```

Notes:

- `agent_file` is `null` for spawn-from-type teammates. There is no
  generated file under `./.claudius/teammates/agents/` for them.
- `/save-state` MUST record `spawn_source` so restore can re-spawn the
  teammate via the original agent type.

Write atomically: serialize to `./.claudius/teammates/team.json.tmp`
and rename over `team.json`. Preserve `schema_version` and existing
teammates.

## Phase 6 — Report

Emit a short success block:

```markdown
## Teammate Spawned

- **Name**: $name
- **Team**: $team
- **Agent Type**: $agent_type
- **Status**: idle

### Next Steps

Send the teammate its first task:

`/send-message $name "<envelope-v1 body>"`
```

Envelope and status formats are defined by the
`teammates:teammate-conventions` skill; reference it rather than
duplicating the shapes here.
