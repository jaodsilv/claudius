# State file schema

Human-readable companion to
[`templates/state.schema.json`](../templates/state.schema.json).

State files let `/restore-state` rebuild teammates after `/shutdown` —
which is necessary because the underlying `TeamCreate` primitive cannot
be resumed once the team has been deleted.

## One state file per teammate

`/save-state <name>` writes a single JSON file at:

```
./.claudius/teammates/state/<state-id>.json
```

with `state_id = <team>-<name>-<unix-ts>`.

`/save-state-all` writes one such file per teammate **and** a manifest:

```
./.claudius/teammates/state/<team>-<ts>.manifest.json
```

The manifest has its own mini-schema:

```json
{
  "schema_version": 1,
  "manifest_id": "<team>-<unix-ts>",
  "captured_at": "<ISO-8601>",
  "team": "<team-name>",
  "members": [
    { "name": "<teammate-name>", "state_id": "<state-id>" }
  ]
}
```

`/restore-state` accepts either a single `state-id` or a `manifest-id`.
Given a manifest, it restores every member and issues a single
`TeamCreate` up front.

## Field reference

| Field                            | Purpose |
|----------------------------------|---------|
| `schema_version`                 | Always `1`. Bump on breaking changes. |
| `state_id`                       | `<team>-<name|all>-<unix-ts>`. Also the filename stem. |
| `captured_at`                    | ISO-8601 UTC timestamp when the snapshot was taken. |
| `team.name`                      | Must match `^[a-z][a-z0-9-]{1,39}$`. |
| `team.config.message_format`     | Always `"envelope-v1"` for schema v1. |
| `team.config.default_model`      | Model used when the team was created (e.g. `"sonnet"`). |
| `team.config.agent_dir`          | Where generated agent files live; usually `./.claudius/teammates/agents`. |
| `teammate.name`                  | Slug matching `^[a-z][a-z0-9-]{1,39}$`. |
| `teammate.agent_file`            | Relative path to the agent definition used at spawn. |
| `teammate.agent_file_sha256`     | SHA-256 of the file contents at save time. |
| `teammate.spawn_source`          | `"generated"`, `"preset:<name>"`, or `"agent-type:<id>"`. |
| `teammate.last_status`           | Most recent `teammate-status` block (nullable). |
| `teammate.recent_messages`       | Tail of envelope-v1 messages; replayed on restore to prime context. |
| `teammate.scratch.agent_body`    | Full text of `agent_file` at save time. Used to **rebuild** the file if its SHA drifted between save and restore. |
| `teammate.scratch.*`             | Opaque bag; commands may stash additional primers here. |

## Drift handling

`/restore-state` flow:

1. Read the JSON, validate against the schema.
2. If the team does not exist in the registry, call `TeamCreate`.
3. Compute SHA-256 of `teammate.agent_file` on disk.
4. If it differs from `teammate.agent_file_sha256`, rebuild the file
   from `scratch.agent_body` and warn the user that the on-disk file
   had drifted.
5. Spawn via `Agent(name=teammate.name, team_name=team.name, ...)`.
6. Replay `recent_messages` via `SendMessage` with `kind: "bootstrap"`
   envelopes so the teammate's context mirrors pre-shutdown state.
7. Update `team.json` accordingly.

## Size discipline

Keep `recent_messages` capped at the last 20 envelopes. For longer
histories, prefer recomputing context rather than bloating state files;
state is an operational rehydrator, not an archive.
