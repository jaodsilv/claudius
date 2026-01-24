---
name: gitx:committing-conventionally
description: >-
  Applies custom conventional commit conventions.
  Invoked when creating git commits or creating PRs.
  Use when needing project-specific scopes, custom types, or non-standard rules.
allowed-tools: Read, Grep, Glob
model: sonnet
---

# Committing Conventionally

This skill provides custom extensions to standard Conventional Commits.
Claude already knows the standard specification (feat, fix, docs, etc.).

## Custom Commit Types

Beyond standard types, this project uses:

1. **wip**: Work in progress (squash before merging)

   ```text
   wip(feature-x): initial implementation
   ```

## Custom Commit Rules

1. **No Co-Authors**: Do not add "Co-Authored-By" or similar footers
2. **Issue References**: Use `Fixes #123` or `Closes #123` in footer
3. **Scope Required**: Always use scope for any change
4. **Body for Non-Trivial**: Include body explaining "why" for any change > 10 lines

## User or project-defined Commit Types

Look for a file called `commit-conventions.yaml` in the .claude folder of the repository or the of the user's home directory:

- ~/.claude/commit-conventions.yaml
- .claude/commit-conventions.yaml

If it exists, parse them, and use AskUserQuestion to ask if you are confused or instructions are conflicting

### `commit-conventions.yaml` Format

```yaml
rules:
  - title: <title>
    description: <description>
types:
  - type: <type>
    scope: <restricted-scope>
    description: <description>
    examples:
      - <example>
```

Example using the rules from this file:

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

## Validation Checklist

Before committing, verify:

- [ ] Type matches change nature (feat/fix/docs/chore/etc.)
- [ ] Scope matches affected component (if applicable)
- [ ] Description uses imperative mood ("add" not "added")
- [ ] No unrelated changes included
- [ ] Breaking changes marked with ! or footer

## Edge Cases

| Change | Type | Reason |
|--------|------|--------|
| Update dependencies | `build` | Build tool/system change |
| Config file cleanup | `chore` | Maintenance, no feature impact |
| Fix typo in docs | `docs` | Documentation, not code |
| Rename variable for clarity | `refactor` | Code change, same behavior |
| Add missing type annotation | `style` | Formatting/style, no logic change |

## Reference

Standard specification: <https://www.conventionalcommits.org/>
