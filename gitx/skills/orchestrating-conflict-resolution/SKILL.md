---
description: >-
  Orchestrates multi-agent conflict resolution workflow for merge and rebase
  operations. Use when git conflicts occur during branch integration.
user-invocable: false
allowed-tools: Bash(git *), Agent, AskUserQuestion
model: opus
---

# Orchestrating Conflict Resolution

Multi-agent workflow for resolving git conflicts during merge/rebase operations.

## 5-Phase Workflow

### Phase 1: Conflict Analysis

Get conflict status and launch analyzer:

```bash
git status --porcelain | grep "^UU\|^AA\|^DD"
git diff --name-only --diff-filter=U
```

Use the Agent tool to spawn the agent `gitx:conflict-resolver:conflict-analyzer`:

```markdown
Agent(gitx:conflict-resolver:conflict-analyzer):
  prompt:
    Operation: [merge|rebase]
    Base Branch: $base_branch
    Conflicting Files: [list from git status]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

### Phase 2: Resolution Suggestions

Use the Agent tool to spawn the agent `gitx:conflict-resolver:resolution-suggester`:

```markdown
Agent(gitx:conflict-resolver:resolution-suggester):
  prompt:
    Conflict Analysis: [output from Phase 1]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

### Phase 3: User-Guided Resolution

Present options for each conflict using AskUserQuestion.
See [references/resolution-options.md](${CLAUDE_SKILL_DIR}/references/resolution-options.md) for details.

After each resolution: `git add <file>`

### Phase 4: Validation

Use the Agent tool to spawn the agent `gitx:conflict-resolver:merge-validator`:

```markdown
Agent(gitx:conflict-resolver:merge-validator):
  prompt:
    Resolved Files: [list]
    Operation: [merge|rebase]
```

**IMPORTANT**:

- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

If validation fails, report issues and allow fixing before continuing.

### Phase 5: Continue Operation

When all conflicts resolved and validated:

- **Rebase**: `git rebase --continue`
- **Merge**: Create merge commit with resolution summary

If more conflicts occur (during subsequent rebase commits), repeat Phases 1-5.
