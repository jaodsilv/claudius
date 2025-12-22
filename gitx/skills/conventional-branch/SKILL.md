# Conventional Branch

## When to Use This Skill

This skill is automatically invoked when:

1. Creating new git branches
2. Reviewing branch naming
3. Planning branch strategy
4. Validating branch names before creation

## Overview

Conventional Branch provides a structured and standardized naming convention for Git branches that makes branch purposes immediately
clear, enables CI/CD automation, and improves team collaboration.

## Branch Naming Format

```text
<type>/<description>
```text

## Branch Types

### Main Branches

**main** (or **master** / **develop**)
- Primary development branch
- Long-lived, protected
- No prefix needed

```text
main
develop
```text

### Feature Branches

**feature/** - New features and enhancements

```text
feature/user-authentication
feature/add-dark-mode
feature/issue-123-payment-integration
feature/api-v2-endpoints
```text

**Use for:**
- New functionality
- Feature enhancements
- New components or modules

### Bug Fix Branches

**bugfix/** - Non-urgent bug fixes

```text
bugfix/fix-login-error
bugfix/issue-456-validation-bug
bugfix/correct-date-formatting
bugfix/resolve-memory-leak
```text

**Use for:**
- Standard bug fixes
- Issues found during development
- Non-critical problems

### Hotfix Branches

**hotfix/** - Urgent production fixes

```text
hotfix/security-vulnerability
hotfix/critical-crash-fix
hotfix/payment-gateway-down
hotfix/v1.2.1-patch
```text

**Use for:**
- Critical production bugs
- Security vulnerabilities
- Urgent patches
- Emergency fixes

### Release Branches

**release/** - Release preparation

```text
release/v1.2.0
release/v2.0.0-beta
release/2025-Q1
release/sprint-15
```text

**Use for:**
- Version release preparation
- Release candidate testing
- Final pre-release adjustments
- Version-specific work

### Chore Branches

**chore/** - Maintenance and non-code changes

```text
chore/update-dependencies
chore/refactor-tests
chore/improve-documentation
chore/configure-ci
chore/cleanup-unused-code
```text

**Use for:**
- Dependency updates
- Documentation changes
- CI/CD configuration
- Code cleanup and refactoring
- Tooling improvements

## Naming Rules

### 1. Character Set

**Allowed:**
- Lowercase letters: `a-z`
- Numbers: `0-9`
- Hyphens: `-` (to separate words)
- Dots: `.` (for version numbers in release branches)

**Not Allowed:**
- Uppercase letters
- Underscores `_`
- Spaces
- Special characters (`@`, `#`, `$`, etc.)

```text
✅ feature/add-user-profile
✅ release/v1.2.0
✅ bugfix/issue-789-null-check

❌ feature/Add_User_Profile
❌ Feature/add user profile
❌ feature/add-user-profile!
```text

### 2. Hyphen and Dot Rules

**DO:**
- Use single hyphens to separate words
- Use dots in version numbers (release branches only)

**DON'T:**
- Use consecutive hyphens or dots
- Start or end with hyphen or dot

```text
✅ feature/new-login-page
✅ release/v1.2.0

❌ feature/new--login-page
❌ feature/-new-login
❌ feature/new-login-
❌ release/v1.-2.0
```text

### 3. Clarity and Conciseness

**Good:**

```text
feature/oauth-integration
bugfix/null-pointer-error
hotfix/sql-injection-patch
release/v2.0.0
chore/upgrade-webpack
```text

**Too Vague:**

```text
feature/new-stuff
bugfix/fix-bug
hotfix/urgent
```text

**Too Verbose:**

```text
feature/implement-complete-user-authentication-system-with-oauth-and-jwt
bugfix/fix-the-issue-where-users-cannot-login-when-username-has-spaces
```text

### 4. Ticket Number Integration

Include ticket/issue numbers for traceability:

```text
feature/issue-123-user-dashboard
bugfix/JIRA-456-validation-error
hotfix/PROD-789-memory-leak
chore/task-321-update-docs
```text

**Format options:**
- `<type>/issue-<number>-<description>`
- `<type>/<TRACKER>-<number>-<description>`
- `<type>/<number>-<description>`

## Complete Examples

### Feature Development

```text
# Simple feature
feature/search-functionality

# With issue number
feature/issue-234-advanced-search

# Specific component
feature/api-rate-limiting

# User story based
feature/us-567-export-reports
```text

### Bug Fixes

```text
# Standard bug fix
bugfix/fix-dropdown-alignment

# With issue tracking
bugfix/bug-891-session-timeout

# Specific area
bugfix/api-error-handling

# Component-specific
bugfix/navbar-mobile-display
```text

### Hotfixes

```text
# Security issue
hotfix/xss-vulnerability-patch

# Critical bug
hotfix/data-corruption-fix

# Production issue
hotfix/prod-payment-failure

# Version-specific
hotfix/v1.2.3-security-patch
```text

### Releases

```text
# Semantic versioning
release/v1.0.0
release/v2.3.1

# Beta releases
release/v3.0.0-beta.1
release/v2.5.0-rc.2

# Date-based
release/2025-Q2
release/2025-03-15

# Sprint-based
release/sprint-24
```text

### Chores

```text
# Dependencies
chore/update-npm-packages
chore/upgrade-react-18

# Documentation
chore/update-api-docs
chore/add-contributing-guide

# Configuration
chore/configure-prettier
chore/setup-eslint

# Cleanup
chore/remove-deprecated-code
chore/refactor-utils
```text

## Workflow Integration

### Feature Workflow

```bash
# Create branch from main
git checkout main
git pull
git checkout -b feature/issue-123-new-dashboard

# Work and commit
# ...

# Merge back to main via PR
```text

### Hotfix Workflow

```bash
# Create from main/production
git checkout main
git checkout -b hotfix/critical-security-fix

# Fix and test
# ...

# Merge to both main and develop
```text

### Release Workflow

```bash
# Create release branch
git checkout develop
git checkout -b release/v1.2.0

# Prepare release (version bump, changelog, etc.)
# ...

# Merge to main and back to develop
```text

## CI/CD Integration

Branch types enable automated workflows:

```yaml
# Example CI/CD triggers
feature/* → Run tests, lint
bugfix/* → Run tests, lint
hotfix/* → Run tests, deploy to staging
release/* → Run full test suite, build artifacts
main → Deploy to production
```text

## Best Practices

### DO

1. Create descriptive, clear branch names
2. Use appropriate type prefixes
3. Include issue/ticket numbers when available
4. Keep names concise but meaningful
5. Use hyphens to separate words
6. Follow team conventions consistently
7. Delete branches after merging

### DON'T

1. Use generic names like `temp`, `test`, `wip`
2. Include personal names in branches
3. Create long, overly detailed names
4. Use special characters or spaces
5. Mix multiple concerns in one branch
6. Leave stale branches around
7. Reuse old branch names

## Validation Checklist

Before creating a branch, verify:

- [ ] Type prefix is appropriate
- [ ] Name uses only lowercase, numbers, hyphens (and dots for versions)
- [ ] No consecutive, leading, or trailing hyphens/dots
- [ ] Description is clear and concise
- [ ] Issue/ticket number included (if applicable)
- [ ] Name follows team conventions
- [ ] Purpose is immediately understandable

## Common Patterns

### Issue-Driven Development

```text
feature/issue-123-user-profile
bugfix/bug-456-login-error
```text

### Component-Based

```text
feature/auth-oauth-integration
bugfix/api-error-handling
chore/database-migration-scripts
```text

### Version-Based

```text
release/v1.2.0
hotfix/v1.1.1-patch
```text

### Time-Based

```text
release/2025-Q1
release/sprint-15
```text

## Integration with Conventional Commits

Branch names and commit messages work together:

```bash
# Branch
feature/user-authentication

# Commits
feat(auth): implement OAuth2 login flow
feat(auth): add JWT token validation
test(auth): add authentication integration tests

# PR merge commit
feat: add user authentication system (#123)
```text

## Benefits

1. **Clear Communication**
   - Branch purpose is immediately obvious
   - Easy to find related branches
   - Team members understand context

2. **Automation-Friendly**
   - CI/CD can trigger based on branch type
   - Different workflows for different types
   - Automated deployment strategies

3. **Scalability**
   - Works well in large teams
   - Multiple developers on different tasks
   - Easy to manage many concurrent branches

4. **Traceability**
   - Link branches to issues/tickets
   - Track feature development
   - Audit and compliance support

5. **Better Organization**
   - Logical grouping of branches
   - Easy to clean up old branches
   - Clear project history

## Reference

Full specification: <https://conventional-branch.github.io/>

This skill helps maintain organized, professional branch management that integrates seamlessly with modern development workflows and CI/CD pipelines.
