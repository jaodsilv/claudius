---
name: gitx:committing-conventionally
description: >-
  Applies project-specific conventional commit conventions for this repository.
  Invoked when creating git commits, reviewing commit history, or planning changes.
  Use when needing project-specific scopes, custom types, or non-standard rules.
---

# Committing Conventionally

This skill provides project-specific extensions to standard Conventional Commits.
Claude already knows the standard specification (feat, fix, docs, etc.).

## Project-Specific Scopes

Use these scopes for commits in this repository:

1. **commands**: Changes to slash command definitions (`commands/*.md`)
2. **agents**: Changes to agent definitions (`agents/**/*.md`)
3. **skills**: Changes to skill definitions (`skills/**/*.md`)
4. **hooks**: Changes to git hooks or hook scripts
5. **scripts**: Changes to utility scripts
6. **templates**: Changes to output templates

## Custom Commit Types

Beyond standard types, this project uses:

1. **wip**: Work in progress (squash before merging)

   ```text
   wip(feature-x): initial implementation
   ```

## Project Rules

1. **No Co-Authors**: Do not add "Co-Authored-By" or similar footers
2. **Issue References**: Use `Fixes #123` or `Closes #123` in footer
3. **Scope Required**: Always use scope for commands, agents, and skills changes
4. **Body for Non-Trivial**: Include body explaining "why" for any change > 10 lines

## Validation Checklist

Before committing, verify:

- [ ] Type matches change nature (feat/fix/docs/chore/etc.)
- [ ] Scope matches affected component (if applicable)
- [ ] Description uses imperative mood ("add" not "added")
- [ ] No unrelated changes included
- [ ] Breaking changes marked with `!` or footer

## Reference

Standard specification: <https://www.conventionalcommits.org/>
