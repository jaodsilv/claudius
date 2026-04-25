---
description: Inspect or update teammates-plugin project config (gitignore, team.json defaults).
argument-hint: "[--init] [--set <key>=<value>] [--get <key>] [--show]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
model: sonnet
---

See the `teammates:teammate-conventions` skill for the `team.json` shape
and runtime-data locations this command edits.

This command uses no deferred tools, so it has no `ToolSearch` phase.

## Phase 1 — Parse args

From <arguments>$ARGUMENTS</arguments> accept exactly one mode:

- `--init` — create directories and gitignore entries.
- `--set <key>=<value>` — update a config key in `team.json`.
- `--get <key>` — print a single config value.
- `--show` — pretty-print `team.config` (default when no args given).

If more than one mode flag is present, abort with an error listing the
conflicting flags.

## Phase 2 — `--init`

Only execute when mode is `--init`.

1. Ensure the following directories exist (create if missing, silent if
   already present):
   - `./.claudius/teammates/`
   - `./.claudius/teammates/agents/`
   - `./.claudius/teammates/state/`
   - `./.claudius/teammates/logs/`

   Use `Bash`:

   ```bash
   mkdir -p ./.claudius/teammates/agents ./.claudius/teammates/state ./.claudius/teammates/logs
   ```

2. Read `.gitignore`. If missing, create it empty via `Write`.
3. For each required pattern — `./.claudius/teammates/state/` and
   `./.claudius/teammates/logs/` — check whether it already appears as a
   standalone line. Prefer the
   `gitx:validating-gitignore-patterns` skill if it can do the
   idempotent append in one call; otherwise `Grep` for the literal line
   and `Edit` to append missing entries.
4. Report which directories were created (vs. already present) and
   which gitignore lines were appended (vs. already present).

## Phase 3 — `--show`

Only execute when mode is `--show` (or no args).

1. Read `./.claudius/teammates/team.json`. If missing, print
   `_no team.json found — run /config-team --init then /create-team_`
   and stop.
2. Pretty-print `team.config` as fenced JSON:

   ````markdown
   ```json
   {
     "message_format": "envelope-v1",
     "default_model": "<value>",
     "agent_dir": "<value>"
   }
   ```
   ````

## Phase 4 — `--set key=value`

Only execute when mode is `--set`.

1. Split `$ARGUMENTS` value at the first `=` into `$key` and `$value`.
2. Allowed keys:
   - `default_model`
   - `agent_dir`

   Any other key → abort with:

   > Unknown config key `<$key>`. Allowed: default_model, agent_dir.

3. Read `./.claudius/teammates/team.json`. If missing, abort suggesting
   `/create-team` first.
4. Update `team.config.$key = $value`. Preserve `schema_version: 1` and
   every other field verbatim.
5. Write atomically:
   - `Write` to `./.claudius/teammates/team.json.tmp`
   - `Bash`: `mv ./.claudius/teammates/team.json.tmp ./.claudius/teammates/team.json`
6. Report the previous value and the new value.

## Phase 5 — `--get key`

Only execute when mode is `--get`.

1. Read `./.claudius/teammates/team.json`. If missing, abort with the
   same message as `--show`.
2. Allowed keys: `default_model`, `agent_dir`, `message_format`. Reject
   others with the same error as `--set`.
3. Print the current value of `team.config.$key` on a single line. If
   the key is absent from the config, print `_unset_`.

## Phase 6 — Final report

For every mode, finish with a one-line success summary. On any error,
abort the command with a non-zero result and a single clear sentence
identifying the failing phase.
