# Presets

A preset is a JSON file under `teammates/presets/<name>.json` that
`/create-team --from-preset=<name>` can instantiate directly. Presets
save you from typing the same `/create-teammate` + `/spawn` + bootstrap
dance every time you want a known team shape.

## Schema

```json
{
  "schema_version": 1,
  "name": "<preset-name>",
  "description": "<one-liner>",
  "team_config": {
    "message_format": "envelope-v1",
    "default_model": "sonnet"
  },
  "members": [
    {
      "name": "<teammate-name>",
      "agent_type": "generated | <installed-agent-type-id>",
      "description": "<used as the agent file's `description` frontmatter when agent_type == 'generated'>",
      "role": "<optional multi-line role body; falls back to description>"
    }
  ],
  "bootstrap_messages": [
    { "to": "<teammate-name>", "body": "<initial instructions>" }
  ]
}
```

### Field notes

- `name` MUST match `^[a-z][a-z0-9-]{1,39}$` and SHOULD equal the
  filename stem.
- `members[*].agent_type`:
  - `"generated"` — `/create-team` generates an agent file from the
    template with the supplied `description` and `role`.
  - any other string — treated as an installed agent type id; `/spawn`
    is used instead.
- `bootstrap_messages` are sent in order after every member has been
  spawned. Each is wrapped in an envelope-v1 with `kind: "bootstrap"`.

## Authoring workflow

1. Copy `code-review-team.json` and rename it.
2. Update `name`, `description`, `members`, `bootstrap_messages`.
3. Validate name collisions inside the preset (the loader rejects them
   with a clear error).
4. Dry-run: `/create-team <preset-name> --from-preset=<preset-name>
   --dry-run` (if implemented) or simply run it in an empty project.

## Example

See [`code-review-team.json`](./code-review-team.json) — a 3-member PR
review squad used by the plugin's smoke test.

## Naming conventions

- Preset names should describe the team shape, not the project (e.g.
  `code-review-team`, not `myapp-team`).
- Prefer stable, role-oriented teammate names inside presets
  (`reviewer`, `tester`, `security-auditor`) over project-specific ones.
