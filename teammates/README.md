# teammates

Ergonomic slash-command surface over Claude Code's teammate-mode primitives
(`Agent` `name`/`team_name`, `TeamCreate`, `TeamDelete`, `SendMessage`).

## What it provides

- **21 slash commands** for spawning, managing, messaging, observing, and
  persisting parallel teammate agents.
- **`teammate-conventions` skill** defining the message envelope, status
  reporting format, and runtime-data locations that every teammate and
  command must respect.
- **`code-review-team` preset** — a ready-to-run 3-member example team.
- **State save/restore** workflow to work around the fact that teams cannot
  be resumed after `/shutdown`.

## Requirements

Teammate mode primitives must be available in the current harness session.
Every command that uses them loads their schemas via `ToolSearch` at the
top of its body and aborts with a human-readable error if loading fails.

## Directory layout

```
teammates/
├── .claude-plugin/plugin.json
├── commands/                       # 21 slash command definitions
├── skills/teammate-conventions/    # message/status/layout contract
├── templates/                      # agent scaffold + state JSON Schema
├── presets/                        # shareable team definitions
├── docs/                           # human-readable state schema doc
└── README.md
```

Runtime artifacts live under your project at `./.claudius/teammates/`:

```
./.claudius/teammates/
├── team.json                       # active team + teammate registry
├── agents/<name>.md                # generated teammate agent files
├── state/<state-id>.json           # snapshots for /save-state(-all)
├── state/<team>-<ts>.manifest.json # manifest listing state_ids
└── logs/<name>.log                 # per-teammate log buffer
```

### Gitignore

The state and log directories are runtime buffers — add them to
`.gitignore`:

```gitignore
.claudius/teammates/state/
.claudius/teammates/logs/
```

`/config-team --init` appends these entries for you.

## Command reference

| Category       | Commands |
|----------------|----------|
| Discovery      | `/list-teammates`, `/list-teams` |
| Creation       | `/create-teammate`, `/spawn`, `/create-team` |
| Lifecycle      | `/pause`, `/pause-all`, `/resume`, `/resume-all`, `/kill`, `/shutdown` |
| Communication  | `/send-message`, `/msg`, `/broadcast` |
| Observation    | `/find-bottleneck`, `/inspect`, `/logs` |
| Config         | `/config-team` |
| State          | `/save-state`, `/save-state-all`, `/restore-state` |

`/create-teammate` **generates a new agent definition file** with team
conventions baked in. `/spawn` instantiates a teammate **from an existing
agent type** already installed in this harness.

`/msg` is a thin alias for `/send-message` — behavior stays in lockstep.

## Smoke test

Run these end-to-end once the plugin is installed. If teammate-mode tools
are unavailable, each step will abort with a clear message.

1. `/create-team code-review-team --from-preset=code-review-team`
   → `team.json` written; 3 agent files generated; `TeamCreate` called
   once; 3 `Agent` spawns observed; bootstrap messages delivered.
2. `/list-teammates` → 3 rows with `status: idle`.
3. `/send-message reviewer "review HEAD~1"` → `SendMessage` called with
   the envelope defined by `teammate-conventions`.
4. `/broadcast "standup"` → 3 sequential `SendMessage` calls + per-member
   results table.
5. `/inspect reviewer` + `/logs reviewer` → populated status and
   messages.
6. `/save-state-all` → 3 state JSONs + 1 manifest JSON.
7. `/shutdown` → `TeamDelete` called, registry cleared.
8. `/restore-state <manifest-id>` → 3 teammates re-spawn with the same
   names and `last_status` values.

## Risks & mitigations

- **Deferred tools unavailable in a session** — every command ToolSearches
  for the tools it needs first and aborts cleanly.
- **Name collisions** — `/create-teammate` and `/spawn` read `team.json`
  first and reject duplicates.
- **Agent-file drift between save and restore** — `agent_file_sha256` is
  stored in state; `/restore-state` detects drift and rebuilds from the
  embedded `scratch.agent_body`.
- **`/msg` and `/send-message` diverging** — `/msg.md` is a pure alias;
  the Wave 3 lint asserts it contains only the delegation stub.
- **Partial broadcast failures** — `/broadcast` sends sequentially and
  reports a per-teammate table; never aborts on first failure.
- **Runtime dir committed by accident** — `/config-team --init` writes
  the gitignore entries above.

## Authoring presets

See [`presets/README.md`](./presets/README.md).

## State file format

See [`docs/state-schema.md`](./docs/state-schema.md). The machine-readable
schema is at [`templates/state.schema.json`](./templates/state.schema.json).
