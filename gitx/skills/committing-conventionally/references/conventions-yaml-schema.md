# Commit Conventions YAML Schema

Project-specific commit conventions are injected via hook as additional context
(within `<commit-conventions>` tags). They are NOT searched for at runtime.

## YAML Format

The file supports two top-level keys: `rules` and `types`.

### `rules[]` — Custom Commit Rules

Each rule has a `title` and `description`:

```yaml
rules:
  - title: <title>
    description: <description>
```

### `types[]` — Custom Commit Types

Each type has a `type`, optional `scope`, `description`, and `examples`:

```yaml
types:
  - type: <type>
    scope: <restricted-scope>
    description: <description>
    examples:
      - <example>
```

## Full Example

```yaml
rules:
  - title: No Co-Authors
    description: Do not add "Co-Authored-By" or similar footers
  - title: Issue References
    description: Use `Fixes #123` or `Closes #123` in footer
  - title: Scope Required
    description: Always use scope for any change
  - title: Body for Non-Trivial
    description: Include body explaining "why" for any change > 10 lines
types:
  - type: wip
    scope: null
    description: Work in progress (squash before merging)
    examples:
      - "wip(feature-x): initial implementation"
```

## Usage

When commit conventions are present in additional context (within `<commit-conventions>` tags),
apply those rules and types alongside the skill's default rules. Rules from the YAML
take precedence when they conflict with defaults.
