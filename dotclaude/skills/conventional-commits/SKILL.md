---
name: dotclaude:conventional-commits
description: >-
  Provides lightweight convention for commit messages that creates an explicit
  commit history, enables automated tooling, and integrates with Semantic Versioning.
---

# Conventional Commits

## When to Use This Skill

This skill is automatically invoked when:

1. Creating git commit messages
2. Reviewing commit history
3. Planning commits for a change
4. Evaluating commit message quality

## Overview

The Conventional Commits specification provides a lightweight convention for commit messages that creates an explicit commit history,
enables automated tooling, and integrates with Semantic Versioning.

## Commit Message Format

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Core Commit Types

### Required Types

1. **feat:** - New feature (correlates with MINOR in SemVer)

   ```text
   feat: add user authentication system
   feat(auth): implement OAuth2 login flow
   ```

2. **fix:** - Bug fix (correlates with PATCH in SemVer)

   ```text
   fix: prevent race condition in request handling
   fix(api): correct validation error messages
   ```

3. **BREAKING CHANGE** - Breaking API change (correlates with MAJOR in SemVer)
   - Use `!` after type/scope OR footer `BREAKING CHANGE:`

   ```text
   feat!: redesign authentication API

   feat(api)!: remove deprecated endpoints

   chore: update dependencies

   BREAKING CHANGE: Node 14+ now required
   ```

### Additional Types

Use these for better commit categorization:

1. **build:** - Build system or external dependencies

   ```text
   build: upgrade webpack to v5
   build(deps): update all npm packages
   ```

2. **chore:** - Maintenance tasks

   ```text
   chore: update .gitignore
   chore(release): bump version to 2.1.0
   ```

3. **ci:** - CI configuration changes

   ```text
   ci: add automated testing workflow
   ci(actions): configure dependabot
   ```

4. **docs:** - Documentation only

   ```text
   docs: update API documentation
   docs(readme): add installation instructions
   ```

5. **style:** - Code style changes (no logic change)

   ```text
   style: format code with prettier
   style(components): fix indentation
   ```

6. **refactor:** - Code restructuring (no feat/fix)

   ```text
   refactor: extract helper functions
   refactor(auth): simplify token validation
   ```

7. **perf:** - Performance improvements

   ```text
   perf: optimize database queries
   perf(cache): implement Redis caching
   ```

8. **test:** - Adding or updating tests

   ```text
   test: add unit tests for auth module
   test(e2e): improve test coverage
   ```

## Scope

Optional component identifier in parentheses:

```text
feat(parser): add array parsing support
fix(api): handle null responses
docs(contributing): update pr guidelines
```

## Description

- MUST immediately follow the type/scope
- Short summary of changes (imperative mood preferred)
- No period at the end
- Lowercase first letter (by convention)

**Good:**

```text
fix: prevent memory leak in event listeners
feat: add dark mode toggle
```

**Avoid:**

```text
fix: Fixed the bug.
feat: Added new feature.
```

## Body

- Begins one blank line after description
- Free-form, multiple paragraphs allowed
- Explains the "why" and "what", not the "how"
- Provide context and motivation

```text
fix: prevent racing of requests

Introduce a request id and a reference to latest request. Dismiss
incoming responses other than from latest request.

Remove timeouts which were used to mitigate the racing issue but are
obsolete now.
```

## Footers

- One blank line after body
- Format: `token: value` or `token #value`
- Use hyphens in multi-word tokens: `Reviewed-by: John Doe`
- Common footers:
  - `BREAKING CHANGE:` - Describe breaking changes
  - `Refs:` - Reference issues/PRs
  - `Reviewed-by:` - Code review attribution
  - `Closes:` or `Fixes:` - Auto-close issues

```text
fix: correct user validation logic

Updated validation to handle edge cases properly and added
comprehensive test coverage.

Refs: #123, #456
Reviewed-by: Jane Smith
Closes: #789
```

## Complete Examples

### Simple Feature

```text
feat: add user profile page
```

### Feature with Scope and Body

```text
feat(dashboard): implement real-time data updates

Add WebSocket connection for live data streaming.
Implement automatic reconnection on connection loss.
Add loading states and error handling.
```

### Bug Fix with Footer

```text
fix: resolve memory leak in component cleanup

Previously, event listeners were not being properly removed
when components unmounted, causing memory accumulation.

Closes: #234
```

### Breaking Change (Method 1: Using !)

```text
feat!: redesign configuration API

Replace JSON config with YAML format for better readability
and comment support.
```

### Breaking Change (Method 2: Using Footer)

```text
chore: update minimum Node version

BREAKING CHANGE: Node 16+ is now required due to use of
native ES modules and crypto APIs.
```

### Multiple Footers

```text
fix: prevent data corruption on concurrent writes

Implement pessimistic locking mechanism to ensure data
integrity during concurrent update operations.

Refs: #123, #456
Reviewed-by: Alice Johnson
Tested-by: Bob Williams
Closes: #123
```

## Best Practices

### DO

1. Use imperative mood: "add" not "added" or "adds"
2. Be specific and concise in descriptions
3. Group related changes in single commits when possible
4. Use scope to provide context
5. Explain "why" in the body, not "what" (code shows what)
6. Reference issues in footers
7. Use BREAKING CHANGE for incompatible API changes

### DON'T

1. Mix unrelated changes in one commit
2. Write vague descriptions like "fix bug" or "update code"
3. Include periods at end of description
4. Use past tense ("added", "fixed")
5. Commit without testing changes
6. Skip conventional format for "quick fixes" (stay consistent)

## Integration with Semantic Versioning

- `fix:` → PATCH (0.0.X)
- `feat:` → MINOR (0.X.0)
- `BREAKING CHANGE` → MAJOR (X.0.0)

This enables automated version bumping and changelog generation.

## Handling Special Cases

### Multiple Commits

If a change touches multiple concerns:

```text
feat(auth): implement OAuth2 login
test(auth): add OAuth2 integration tests
docs(auth): document OAuth2 configuration
```

### Reverting Commits

```text
revert: let us never speak of the noodle incident

Refs: 676104e, a215868
```

### Work in Progress

Use `wip:` type for incomplete work (if needed):

```text
wip(feature-x): initial implementation
```

Then squash before merging to main.

## Common Mistakes to Avoid

1. **Wrong type**: Using `fix` for new features or `feat` for bug fixes
2. **Too broad**: Combining multiple unrelated changes
3. **Too granular**: Separate commits for fixing typos in same file
4. **No context**: Description doesn't explain what was changed
5. **Missing BREAKING CHANGE**: Not marking incompatible changes

## Validation Checklist

Before committing, verify:

- [ ] Type is appropriate (feat/fix/docs/etc.)
- [ ] Scope is relevant (if used)
- [ ] Description is clear and concise
- [ ] Description uses imperative mood
- [ ] Body explains "why" if change is non-trivial
- [ ] BREAKING CHANGE is marked if applicable
- [ ] Related issues are referenced
- [ ] No unrelated changes included

## Reference

Full specification: <https://www.conventionalcommits.org/>

This skill helps maintain a clean, semantic commit history that enables:

1. Automated changelog generation
2. Semantic version bumping
3. Clear communication of changes
4. Easier code review and project navigation
5. Better collaboration across teams
