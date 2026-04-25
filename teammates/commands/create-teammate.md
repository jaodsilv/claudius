---
description: Generate a new teammate agent file (with baked-in conventions) and spawn it on the active team.
argument-hint: "<name> [--role=\"<one-line role>\"] [--description=\"<short desc>\"]"
allowed-tools: ToolSearch, Agent, SendMessage, Read, Write, Edit, Glob, Grep, Bash, Skill, AskUserQuestion
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

- `$name` — REQUIRED positional slug. Validate against
  `^[a-z][a-z0-9-]{1,39}$`. Reject if invalid.
- `--role="..."` — OPTIONAL one-line role statement. Store in `$role`.
- `--description="..."` — OPTIONAL short description. Store in
  `$description`.

If `$description` is missing, use AskUserQuestion to gather it:

```text
Question: "Short description (when should this teammate be invoked)?"
Header: "Description"
```

If `$role` is missing, fall back to `$role = $description`.

## Phase 3 — Preflight

1. Read `./.claudius/teammates/team.json`. If missing or empty, abort
   with `"no active team; run /team-create first"`.
2. Extract `$team = team.name` and `$teammates = teammates[]`.
3. If any existing teammate has `name == $name`, suggest `$name-2`
   (then `-3`, etc. until free) and abort so the user can re-run with
   the suggestion.

## Phase 4 — Generate agent file

Read the template:

```text
Read ${CLAUDE_PLUGIN_ROOT}/templates/teammate-agent.md.tmpl
```

Substitute placeholders:

- `{{name}}` → `$name`
- `{{description}}` → `$description`
- `{{team}}` → `$team`
- `{{role}}` → `$role` (falling back to `$description` when unset)
- `{{created}}` → ISO-8601 UTC now (e.g. `2026-04-18T12:34:56Z`)

Write the result to `./.claudius/teammates/agents/$name.md` using
Write. Store the absolute path in `$agent_file`.

## Phase 5 — Spawn

Call Agent with the general-purpose subtype and the teammate identity:

```text
Agent(
  subagent_type="general-purpose",
  name="$name",
  team_name="$team",
  prompt="You are teammate $name on team $team. Read your agent file at $agent_file. Follow the teammates:teammate-conventions skill. Wait for an envelope-v1 message before acting."
)
```

## Phase 6 — Register

Append to `team.json#teammates`:

```json
{
  "name": "$name",
  "agent_file": "./.claudius/teammates/agents/$name.md",
  "spawn_source": "generated",
  "spawned_at": "<ISO-8601 UTC now>",
  "status": "idle",
  "last_message_ts": null
}
```

Write atomically: serialize to `./.claudius/teammates/team.json.tmp`,
then rename over `team.json`. Preserve `schema_version` and all other
existing teammates.

## Phase 7 — Report

Emit a short success block:

```markdown
## Teammate Created

- **Name**: $name
- **Team**: $team
- **Agent File**: $agent_file
- **Status**: idle

### Next Steps

Send the teammate its first task:

`/send-message $name "<envelope-v1 body>"`
```

Envelope and status formats are defined by the
`teammates:teammate-conventions` skill; reference it rather than
duplicating the shapes here.
