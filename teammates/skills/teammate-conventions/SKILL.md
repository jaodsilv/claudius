---
description: >-
  Defines the message envelope, status reporting format, runtime-data
  locations, and deferred-tool loading pattern that every teammates-plugin
  command and generated teammate agent must follow. Use when authoring,
  reading, or reviewing any component that coordinates teammate-mode agents.
user-invocable: false
version: 1.0.0
allowed-tools: Read
model: sonnet
---

# Teammate Conventions

The shared contract between commands in the `teammates` plugin and the
teammate agents they spawn. Every command that uses deferred tools
(`TeamCreate`, `TeamDelete`, `SendMessage`) and every generated teammate
agent file must respect this contract.

## 1. Deferred-tool loading pattern

`TeamCreate`, `TeamDelete`, and `SendMessage` schemas are **not** loaded
by default. Declaring them in `allowed-tools` grants permission but does
**not** fetch the schema.

Every command body that uses any of these tools MUST begin with:

> **Phase 1 — Load tools**: Call
> `ToolSearch(query="select:<comma-separated-tool-names>", max_results=<n>)`.
> If the call fails or does not return a schema for each requested tool,
> report `"teammate mode unavailable in this harness"` and abort the
> command with a non-zero result.

Never call a deferred tool before its schema is loaded; doing so raises
`InputValidationError` with no useful context for the user.

## 2. Message envelope (`envelope-v1`)

Every `SendMessage` body sent by a command or teammate MUST be a single
JSON object with these fields (in this order for readability):

```json
{
  "v": 1,
  "from": "<sender-name>",
  "to": "<recipient-name>",
  "team": "<team-name>",
  "ts": "<ISO-8601 UTC timestamp>",
  "kind": "request | reply | status | broadcast | bootstrap",
  "subject": "<short human label, <=80 chars>",
  "body": "<free-form markdown payload>",
  "in_reply_to": "<optional: subject of the message this replies to>",
  "correlation_id": "<optional: opaque string for multi-turn exchanges>"
}
```

- `v` is the envelope version. Currently always `1`.
- `from`/`to` use teammate names as registered in `team.json`. For the
  orchestrator, use `"orchestrator"`.
- `team` matches `team.json#team.name`.
- `kind` is one of:
  - `request` — asks the recipient to do something.
  - `reply` — response to a prior `request`.
  - `status` — unsolicited status update.
  - `broadcast` — one-to-many message; `to` is `"*"`.
  - `bootstrap` — initial instructions sent right after spawn.
- `body` is markdown; 8 KB cap before truncation.

Sending the raw JSON in the `message` field of `SendMessage` is
REQUIRED — this is what teammate agents parse on receipt.

## 3. Status block

Every teammate agent MUST emit a JSON status block after each task unit
and before handing control back. The block is a standalone fenced code
block with info string `json`, and its **first line inside the fence** is
the literal sentinel `// teammate-status` (a comment-style marker for
greppability, not valid JSON — parsers strip it before JSON-decoding the
rest of the block). Only one status block per response is required; if
multiple are emitted, `/inspect` and `/find-bottleneck` use the last.

````markdown
```json
// teammate-status
{
  "v": 1,
  "name": "<teammate-name>",
  "team": "<team-name>",
  "ts": "<ISO-8601 UTC timestamp>",
  "status": "idle | working | blocked | done | error",
  "task": "<short description of the current or just-completed unit>",
  "progress": "<optional free text, e.g. '2/3 files reviewed'>",
  "blockers": ["<optional list of strings>"],
  "next": "<optional: what the teammate will do next>"
}
```
````

Commands like `/inspect` and `/find-bottleneck` parse these blocks from
the teammate's output / log file to report state.

`status` values a TEAMMATE may self-report:
- `idle` — ready to accept work, no active task.
- `working` — currently processing a task.
- `blocked` — waiting on external input (user or another teammate).
- `done` — task just finished successfully.
- `error` — task failed; `blockers` SHOULD describe why.

`paused` and `killed` are REGISTRY-only lifecycle states set by
`/pause`(-all) and `/kill` on `team.json#teammates[*].status`. A
teammate does NOT self-report these in its own status block.

## 4. Runtime data locations

All paths are relative to the project working directory.

| Path                                             | Contents |
|--------------------------------------------------|----------|
| `./.claudius/teammates/team.json`                | Active team name, config, and teammate registry. |
| `./.claudius/teammates/agents/<name>.md`         | Generated teammate agent definition files. |
| `./.claudius/teammates/state/<state-id>.json`    | `/save-state` snapshots. |
| `./.claudius/teammates/state/<team>-<ts>.manifest.json` | `/save-state-all` manifests. |
| `./.claudius/teammates/logs/<name>.log`          | Per-teammate log buffer (status blocks, inbox, outbox). |

`state/` and `logs/` MUST be gitignored.

## 5. `team.json` shape

```json
{
  "schema_version": 1,
  "team": {
    "name": "<team-name>",
    "created": "<ISO-8601>",
    "config": {
      "message_format": "envelope-v1",
      "default_model": "sonnet",
      "agent_dir": "./.claudius/teammates/agents"
    }
  },
  "teammates": [
    {
      "name": "<teammate-name>",
      "agent_file": "./.claudius/teammates/agents/<name>.md",
      "spawn_source": "generated | agent-type:<id> | preset:<name>",
      "spawned_at": "<ISO-8601>",
      "status": "idle | working | blocked | done | error | paused | killed",
      "last_message_ts": "<ISO-8601 or null>"
    }
  ]
}
```

`team.json` is the single source of truth for which team is "current"
and which teammates exist. All commands read it first and write it back
atomically (write temp, rename).

## 6. Agent file frontmatter (for generated teammates)

Files at `./.claudius/teammates/agents/<name>.md` MUST have this
frontmatter:

```yaml
---
name: <teammate-name>
description: <short, imperative, describes when to invoke>
team: <team-name>
model: sonnet
tools: Read, Grep, Glob, Bash, Edit, Write, SendMessage, Skill
created: <ISO-8601>
generated-by: teammates:create-teammate
---
```

The body sections are fixed — see `templates/teammate-agent.md.tmpl`.

## 7. Name validation

Teammate and team names MUST match `^[a-z][a-z0-9-]{1,39}$`. Slugify
user-provided display names before writing `team.json`. On collision,
suggest `<name>-2`, `<name>-3`, etc., but NEVER silently rename.

Reserved literals that are exempt from the slug regex:

- `"orchestrator"` — valid `from`/`to`; represents the slash-command
  caller. Teammates MUST NOT be named `orchestrator`.
- `"*"` — valid ONLY as the `to` value on a `kind: "broadcast"`
  envelope. Invalid in any other position.

## 7a. Canonical abort string

Every command that aborts because teammate-mode tools are unavailable
MUST report the exact string `"teammate mode unavailable in this
harness"`. Paraphrasing breaks user-facing consistency and the plugin's
lint checks.

## 7b. Timestamp format

Every `ts` and `captured_at` value is ISO-8601 UTC with second
precision, `Z` suffix, no offset alternative: `YYYY-MM-DDTHH:MM:SSZ`.
Millisecond precision is permitted but not required. Mixing formats in
`team.json#teammates[*].last_message_ts` breaks string-compare sorting.

## 8. Authoring checklist

### Command authors

- [ ] Frontmatter lists every deferred tool that the command actually
      invokes under `allowed-tools` (pure-delegation aliases should NOT
      list deferred tools).
- [ ] Body opens with the Phase 1 `ToolSearch` step whenever the
      command directly calls `TeamCreate`, `TeamDelete`, or
      `SendMessage`.
- [ ] Reads `./.claudius/teammates/team.json` before acting.
- [ ] Validates any user-supplied name against `^[a-z][a-z0-9-]{1,39}$`
      before using it, and rejects/suggests on collision.
- [ ] Uses the envelope-v1 shape for every `SendMessage`.
- [ ] Appends each sent envelope to
      `./.claudius/teammates/logs/<recipient>.log` on success.
- [ ] Writes `team.json` atomically (temp + rename) and preserves
      `schema_version`.
- [ ] Reports the canonical abort string (§7a) when teammate mode is
      unavailable.
- [ ] References this skill by name (`teammates:teammate-conventions`)
      rather than duplicating the envelope or status-block definition.

### Teammate agent authors (generated files)

- [ ] Frontmatter matches §6 exactly (field names and order).
- [ ] Body emits a `// teammate-status` block (§3) after each task
      unit.
- [ ] Every outbound message uses the envelope-v1 shape (§2).
- [ ] Self-reported `status` uses only the five values in §3; never
      `paused`/`killed`.
- [ ] Replies preserve `correlation_id`/`in_reply_to` from the
      originating request.
