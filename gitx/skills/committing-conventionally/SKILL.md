---
description: >-
  Applies custom conventional commit conventions.
  Invoked when creating git commits or creating PRs.
  Use when needing project-specific scopes, custom types, or non-standard rules.
allowed-tools: Read, Grep, Glob
model: opus
user-invocable: false
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

## Project-Specific Conventions

If commit conventions are provided in the context (within `<commit-conventions>` tags),
apply those rules and types alongside the defaults defined here.

See `${CLAUDE_SKILL_DIR}/references/conventions-yaml-schema.md` for the YAML schema.

## Validation Checklist

Before committing, verify:

- [ ] Type matches change nature (feat/fix/docs/chore/etc.)
- [ ] Scope matches affected component (if applicable)
- [ ] Description uses imperative mood ("add" not "added")
- [ ] No unrelated changes included
- [ ] Breaking changes marked with ! or footer

## Edge Cases

| Change | Type | Reason |
| :----- | :--- | :----- |
| Update dependencies | `build` | Build tool/system change |
| Config file cleanup | `chore` | Maintenance, no feature impact |
| Fix typo in docs | `docs` | Documentation, not code |
| Rename variable for clarity | `refactor` | Code change, same behavior |
| Add missing type annotation | `style` | Formatting/style, no logic change |

## Generating a Commit Message

Consider the following information:

- Task or Issue: You may have received in the input a description of the task
  performed or issue fixed within `<task>` tags. If so, use it to generate a
  commit message instead of the staged files.
- Staged files: If the Task or Issue was not provided, use the Bash tool to run
  the command `git diff --cached`.
- Recent Commit:
  <recent-commits>
  !`git log -n 5 --format="## Commit %h%n%n%B%n"`
  </recent-commits>

Generate and return a commit message following the Conventional Commits specification
and the custom rules defined in this skill and considering recent commits and either
the task description or the staged files.

### Output Format

Output using the following format

```markdown
<commit-message>
[Generated Commit message]
</commit-message>
```

## Reference

Standard specification: <https://www.conventionalcommits.org/>
