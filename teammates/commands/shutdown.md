---
description: Tear down the active team. Sends terminate signals to all members, then calls TeamDelete.
argument-hint: "[--skip-save] [--force]"
allowed-tools: ToolSearch, TeamDelete, SendMessage, Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill
model: sonnet
---

See the `teammates:teammate-conventions` skill for the envelope-v1
definition, `team.json` shape, and runtime path layout. This command MUST
NOT duplicate that contract.

`/shutdown` destroys the active team. Teams **cannot** be resumed after
`TeamDelete`; recovery depends entirely on a prior `/save-state-all`
manifest. This command defaults to recommending a state save before
destruction.

## Phase 1 — Load tools

Call:

```text
ToolSearch(query="select:TeamDelete,SendMessage", max_results=2)
```

If the call fails, or the response does not contain a schema for both
`TeamDelete` and `SendMessage`, abort immediately with the exact
human-readable error:

> teammate mode unavailable in this harness

Do not continue to later phases.

## Phase 2 — Parse args

From <arguments>$ARGUMENTS</arguments> extract:

- `$skipSave` (optional, boolean) — presence of the bare `--skip-save`
  flag. Default `false`.
- `$force` (optional, boolean) — presence of the bare `--force` flag.
  Default `false`.

## Phase 3 — Read registry and confirm

1. Read `./.claudius/teammates/team.json`. If the file does not exist
   or cannot be parsed, abort with:

   > no active team — nothing to shut down

2. Capture `team.name` into `$teamName` and the full member list into
   `$members`.

3. If `$force` is not set, call `AskUserQuestion` with:

   - **question**: ``Shut down team `<$teamName>` (<N> members)? Teams cannot be resumed after shutdown — only restored from a saved state manifest.``
   - **options**: `["Save state then shut down", "Shut down anyway", "Cancel"]`

   If the user picks `Cancel`, exit cleanly with no state change and
   report the cancellation.

   If the user picks `Save state then shut down`, set an in-memory
   flag `$saveFirst = true`. (Even if `$skipSave` was passed, the
   explicit user choice wins.)

   If the user picks `Shut down anyway`, set `$saveFirst = false`.

   When `$force` is set, default `$saveFirst = !$skipSave`.

## Phase 4 — Save state (if $saveFirst)

When `$saveFirst` is true, advise the operator to run `/save-state-all`
before this command proceeds. This command does **not** inline the
save logic; instead it emits:

> Recommended: run `/save-state-all` in a separate turn, confirm the
> manifest id, then re-run `/shutdown --force` (optionally with
> `--skip-save`).

Then, with `AskUserQuestion`:

- **question**: ``Have you completed `/save-state-all` and want to proceed with shutdown now?``
- **options**: `["Proceed with shutdown", "Cancel"]`

If the user picks `Cancel`, exit cleanly. Otherwise continue.

When `$saveFirst` is false (either the user chose `Shut down anyway`
or `--skip-save` + `--force` were combined), skip this phase entirely
and note in the final report that no save was performed.

## Phase 5 — Signal members

For each entry in `$members`, in declaration order, send a shutdown
envelope. Skip members already at `status == "killed"`.

Build an envelope-v1 JSON object (see
`teammates:teammate-conventions` §2):

```json
{
  "v": 1,
  "from": "orchestrator",
  "to": "<member.name>",
  "team": "<$teamName>",
  "ts": "<fresh ISO-8601 UTC>",
  "kind": "request",
  "subject": "control:shutdown",
  "body": "Team shutdown imminent. Emit a final status and stop."
}
```

Call:

```text
SendMessage(to=<member.name>, message=<envelope-json-string>)
```

Record each outcome as `ok` / `error(<err>)` / `skipped(killed)`. Do
NOT abort on individual failures — Phase 6 destroys the team
regardless. Append each successfully-sent envelope (one per line) to
`./.claudius/teammates/logs/<member.name>.log`.

## Phase 6 — TeamDelete

Call:

```text
TeamDelete(team_name=<$teamName>)
```

If the call fails, abort BEFORE clearing the registry and surface the
harness error verbatim. The signals sent in Phase 5 are already out;
this leaves the team in a degraded state that `/shutdown` can be
re-run against.

## Phase 7 — Clear registry

On a successful `TeamDelete`, overwrite `./.claudius/teammates/team.json`
with an empty-team sentinel (chosen over file deletion so downstream
tooling has a predictable schema to read):

1. Serialize:

   ```json
   {
     "schema_version": 1
   }
   ```

2. Write to `./.claudius/teammates/team.json.tmp` via `Write`.
3. Rename atomically:

   ```bash
   mv ./.claudius/teammates/team.json.tmp ./.claudius/teammates/team.json
   ```

Leave `./.claudius/teammates/state/` and `./.claudius/teammates/logs/`
untouched. Those are the operator's recovery material and must survive
shutdown.

## Phase 8 — Report

Emit a short markdown summary:

```markdown
## Team Shutdown Complete

- **Team**: <$teamName>
- **Members signaled**: <N-ok> / <N-total> (<N-err> errors, <N-skip> skipped)
- **State saved**: yes (manifest via `/save-state-all`) | no (--skip-save)
- **TeamDelete**: succeeded
- **Registry**: cleared (empty sentinel at `./.claudius/teammates/team.json`)
- **Preserved**: `./.claudius/teammates/state/`, `./.claudius/teammates/logs/`

### Next Steps

- `/restore-state <manifest-id>` — recreate the team from a saved
  manifest
- `/create-team <name>` — start a fresh team
```
