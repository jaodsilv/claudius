# gitx - Extended Git/GitHub Workflow Plugin

Extended git/GitHub workflow commands for Claude Code, providing comprehensive worktree management,
issue tracking, pull request workflows, and branch operations with **multi-agent orchestration**
for improved output quality.

## Overview

The **gitx** plugin extends Claude Code with powerful git and GitHub workflow commands that
streamline your development process. It builds upon the `commit-commands` plugin from the official
marketplace and adds:

1. Worktree management for isolated feature development
2. Issue-driven development workflows
3. Pull request creation and response handling
4. Branch operations (rebase, merge, cleanup)
5. Conventional commits and branch naming
6. **Multi-agent orchestration** for complex workflows

## Requirements

1. **git** - Git version control system
2. **gh** - GitHub CLI (authenticated via `gh auth login`)
3. **Optional**: `commit-commands@claude-plugins-official` for enhanced commit workflows
4. **Optional**: `feature-dev` or `tdd-workflow` plugins for full fix-issue workflow

## Installation

```bash
# Install from plugin directory
claude --plugin-dir /path/to/gitx

# Or install from marketplace (when published)
claude plugin install gitx
```

## Commands

### Branch/Worktree Management

| Command | Description |
|---------|-------------|
| `/gitx:worktree [ISSUE\|TASK\|BRANCH]` | List or create git worktrees |
| `/gitx:remove-worktree [NAME] [-f] [-r]` | Remove worktree, branch, optionally remote |
| `/gitx:remove-branch [-f] [-r] [-ro]` | Remove branch (local and/or remote) |
| `/gitx:rebase [--base BRANCH]` | Rebase current branch onto base (orchestrated conflict resolution) |
| `/gitx:merge [--base BRANCH]` | Merge base branch into current (orchestrated conflict resolution) |
| `/gitx:ignore [PATTERN]` | Add files or patterns to .gitignore |

### Commit/Push

| Command | Description |
|---------|-------------|
| `/gitx:commit-push` | Commit and push with conventional commit message |

### Issue Management

| Command | Description |
|---------|-------------|
| `/gitx:next-issue [-d]` | Get next issue by priority labels |
| `/gitx:fix-issue [ISSUE]` | Full orchestrated workflow: analyze → plan → worktree → develop → push |
| `/gitx:comment-to-issue [ISSUE] [comment]` | Comment on a GitHub issue |

### Pull Request Management

| Command | Description |
|---------|-------------|
| `/gitx:pr` | Create PR with orchestrated change analysis and description generation |
| `/gitx:respond [--ci] [text]` | Orchestrated response to PR reviews or CI failures |
| `/gitx:update-pr` | Update PR title and description based on commits |
| `/gitx:comment-to-pr [PR] [comment]` | Comment on a pull request |
| `/gitx:merge-pr [PR]` | Merge PR and close related issues |

## Multi-Agent Orchestration

The gitx plugin uses specialized agents to improve output quality through parallel analysis, sequential execution, and quality gates.

### Orchestration Architecture

```text
gitx/agents/
├── respond/              # PR Response orchestration
├── fix-issue/            # Issue fix orchestration
├── pr-create/            # PR creation orchestration
└── conflict-resolver/    # Shared conflict resolution
```

### Agent Workflows

#### Respond Workflow (4 agents)

Handles PR review comments and CI failures:

```text
┌─────────────────────────────────────────────────┐
│                    PARALLEL                      │
│  ┌──────────────────┐  ┌──────────────────────┐ │
│  │ review-comment-  │  │  ci-failure-         │ │
│  │ analyzer         │  │  analyzer            │ │
│  └────────┬─────────┘  └──────────┬───────────┘ │
└───────────┼────────────────────────┼────────────┘
            │                        │
            └──────────┬─────────────┘
                       ▼
            ┌──────────────────────┐
            │  code-change-planner │
            └──────────┬───────────┘
                       ▼
            ┌──────────────────────┐
            │  respond-synthesizer │ → User Approval
            └──────────────────────┘
```

#### Fix-Issue Workflow (4 agents)

Complete issue-to-PR workflow:

```text
┌──────────────────┐
│  issue-analyzer  │ → Extract requirements
└────────┬─────────┘
         ▼
┌──────────────────────┐
│  codebase-navigator  │ → Find relevant files
└────────┬─────────────┘
         ▼
┌────────────────────────┐
│  implementation-planner │ → Create plan
└────────┬────────────────┘
         ▼
    [USER APPROVAL]
         ▼
┌────────────────────────┐
│  workflow-coordinator  │ → Orchestrate development
└────────────────────────┘
```

#### PR Creation (3 agents)

```text
┌────────────────────┐
│   change-analyzer  │
└─────────┬──────────┘
          ▼
┌─────────────────────────────────────┐
│              PARALLEL                │
│ ┌──────────────────┐ ┌────────────┐ │
│ │ description-     │ │ review-    │ │
│ │ generator        │ │ preparer   │ │
│ └──────────────────┘ └────────────┘ │
└─────────────────────────────────────┘
          ▼
    [USER APPROVAL]
```

#### Conflict Resolution (3 agents, shared)

Used by both rebase and merge:

```text
┌────────────────────┐
│  conflict-analyzer │ → Understand both sides
└─────────┬──────────┘
          ▼
┌────────────────────────┐
│  resolution-suggester  │ → Generate solutions
└─────────┬──────────────┘
          ▼
    [USER CHOICE]
          ▼
┌──────────────────┐
│  merge-validator │ → Verify resolution
└──────────────────┘
```

### Quality Features

1. **Tiered Prioritization**: Issues categorized as Critical/High/Medium/Low
2. **Quality Gates**: User approval required before destructive operations
3. **Conflict Detection**: Conflicting recommendations highlighted for user decision
4. **Graceful Fallback**: Manual mode available if orchestration fails

## Command Details

### `/gitx:worktree`

Creates isolated worktrees for feature development as sibling directories.

```bash
# List existing worktrees
/gitx:worktree

# Create worktree from issue number
/gitx:worktree 123
/gitx:worktree #123

# Create worktree from task description
/gitx:worktree "add user authentication"

# Create worktree with specific branch name
/gitx:worktree feature/my-feature
```

### `/gitx:remove-worktree`

Safely removes worktrees with junction/symlink detection to prevent data loss.

```bash
# Remove current worktree
/gitx:remove-worktree

# Remove specific worktree
/gitx:remove-worktree feature-issue-123

# Force remove and delete remote branch
/gitx:remove-worktree feature-issue-123 -f -r
```

**Flags:**
- `-f, --force`: Force removal even with uncommitted changes
- `-r, --remove-remote`: Also delete the remote branch

### `/gitx:remove-branch`

```bash
# Remove current branch
/gitx:remove-branch

# Remove specific branch and remote
/gitx:remove-branch feature/old-feature -r

# Remove only remote branch
/gitx:remove-branch feature/remote-only -ro
```

**Flags:**
- `-f, --force`: Force delete unmerged branch
- `-r, --remove-remote`: Also delete remote branch
- `-ro, --remote-only`: Only delete remote, keep local

### `/gitx:rebase` and `/gitx:merge`

```bash
# Rebase onto main (default)
/gitx:rebase

# Rebase onto specific branch
/gitx:rebase --base develop

# Merge main into current
/gitx:merge

# Merge specific branch
/gitx:merge --base release/v2.0
```

**Orchestrated conflict resolution** provides:
- Analysis of what both sides changed
- AI-suggested resolutions with confidence levels
- Validation before continuing

### `/gitx:next-issue`

Finds the next issue to work on based on priority labels.

```bash
# Get just the issue number
/gitx:next-issue

# Get issue with full details
/gitx:next-issue -d
```

**Priority order:**
1. `priority:critical`
2. `priority:high`
3. `priority:medium`
4. `priority:low`

### `/gitx:fix-issue`

Complete orchestrated workflow for fixing an issue:

```bash
/gitx:fix-issue 123
```

This command:
1. **Analyzes** the issue to extract requirements and complexity
2. **Explores** the codebase to find relevant files and patterns
3. **Plans** the implementation with phased approach
4. **Gets approval** from you on the plan
5. **Creates** a worktree for isolated development
6. **Delegates** to your chosen workflow (feature-dev, TDD, or manual)
7. **Commits and pushes** when complete

### `/gitx:pr`

Creates a pull request with orchestrated analysis:

```bash
/gitx:pr
```

Features:
- Comprehensive change analysis
- AI-generated title and description
- Review preparation (suggested reviewers, focus areas)
- Self-review checklist
- Supports draft PRs

### `/gitx:respond`

Orchestrated response to PR feedback:

```bash
# Respond to review comments (default)
/gitx:respond

# Respond to CI failures
/gitx:respond --ci

# Provide context for response
/gitx:respond --ci "The test was flaky, added retry logic"
```

Features:
- Parallel analysis of review comments and CI failures
- Categorized by type (code-style, logic, security, etc.)
- Prioritized action plan (Critical → High → Medium → Low)
- Quality gates for significant changes

### `/gitx:merge-pr`

Merges a PR and handles cleanup.

```bash
# Merge current branch's PR
/gitx:merge-pr

# Merge specific PR
/gitx:merge-pr 123
```

Features:
- Checks mergeable status and CI
- Offers merge strategy choice (squash, merge, rebase)
- Auto-closes related issues
- Cleans up local branch

## Bundled Skills

### conventional-commits

Provides guidance for writing commit messages following the [Conventional Commits](https://www.conventionalcommits.org/) specification.

**Commit types:**
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation
- `style:` - Formatting
- `refactor:` - Code restructuring
- `test:` - Tests
- `chore:` - Maintenance

### conventional-branch

Provides guidance for branch naming following the [Conventional Branch](https://conventional-branch.github.io/) specification.

**Branch types:**
- `feature/` - New features
- `bugfix/` - Bug fixes
- `hotfix/` - Urgent fixes
- `release/` - Release prep
- `chore/` - Maintenance

## Configuration

The plugin checks for dependencies at session start and warns if:
- `git` is not installed
- `gh` CLI is not installed or authenticated

## Cross-Platform Support

The plugin works on both Windows and Unix-like systems:
- Windows: Uses PowerShell for junction point detection
- Unix/macOS: Uses bash for symlink detection

## Error Handling

All commands include:
- Pre-flight validation
- Clear error messages
- Suggested fixes
- Graceful degradation when optional features unavailable
- **Fallback to manual mode** if orchestration fails

## Design Notes

### Worktree Creation Without Start-Point

The worktree commands (`/gitx:worktree`, `/gitx:fix-issue`) intentionally omit the start-point argument
when creating worktrees:

```bash
# We use this (no start-point):
git worktree add -b <branch-name> <path>

# NOT this (with start-point):
git worktree add -b <branch-name> <path> origin/main
```

**Why?** When a start-point like `origin/main` is specified, git automatically sets the new branch to
track that remote branch. This causes issues when you later push and create a PR - the branch appears
to track `origin/main` instead of its own remote branch.

By omitting the start-point, git uses HEAD, and the sync workflow (fetch → stash → pull → stash pop)
ensures HEAD is up-to-date before worktree creation. This gives the same result without the tracking issue.

## Plugin Structure

```text
gitx/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── agents/
│   ├── respond/             # PR response agents
│   ├── fix-issue/           # Issue fix agents
│   ├── pr-create/           # PR creation agents
│   └── conflict-resolver/   # Conflict resolution agents
├── commands/                # Slash commands
├── hooks/                   # Session start dependency check
├── scripts/                 # Cross-platform helpers
├── shared/
│   └── output-templates/    # Structured output formats
└── skills/
    ├── conventional-commits/
    └── conventional-branch/
```

## Related Plugins

- `commit-commands@claude-plugins-official` - Core commit and clean commands
- `feature-dev@claude-plugins-official` - Feature development workflow
- `pr-review-toolkit@claude-plugins-official` - PR review tools
- `tdd-workflows@claude-code-workflows` - Test-driven development

## License

MIT
