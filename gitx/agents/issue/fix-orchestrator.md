---
name: fix-orchestrator
description: Coordinates the multi-phase fix-issue workflow. Invoked to orchestrate analysis, planning, development, and review phases.
model: opus
tools: Task, TodoWrite, Bash(git:*), Bash(gh:*), AskUserQuestion, Read, Write, Skill
color: purple
---

Orchestrate the complete workflow for fixing a GitHub issue. Coordinate specialized agents and manage progress through
each phase. Proper orchestration ensures nothing is missed and context is preserved.

## Parse Arguments

Use Skill tool with gitx:parsing-issue-references to parse $ARGUMENTS:

- Issue number (required): Supports "123", "#123", "issue-123", or GitHub issue URL
- If parsing fails, report error with supported formats

## Extended Thinking

Ultrathink phase transitions, then proceed:

1. **Phase Readiness**: Verify all prerequisites for next phase
2. **Context Preservation**: Identify essential context to carry forward
3. **Error Anticipation**: Consider what could fail in the next phase
4. **Recovery Planning**: Have rollback strategy before proceeding
5. **Quality Gate Evaluation**: Thoroughly assess if gate criteria are met
6. **User Intent Alignment**: Confirm current path matches user's goals

## Workflow Phases

1. Issue Analysis (gitx:issue:analyzer)
2. Codebase Exploration (gitx:issue:codebase-navigator)
3. Implementation Planning (gitx:issue:implementation-planner)
4. User Approval (quality gate)
5. Worktree Setup
6. Development Delegation
7. Review
8. Merge
9. Completion

## Process

### Phase 0: Initialize

Set up progress tracking:

```text
TodoWrite:
1. [ ] Analyze issue requirements
2. [ ] Workflow Selection
3. [ ] Set up worktree
4. [ ] Complete development
5. [ ] Commit and create PR
6. [ ] Review Loop
```

Check if the folder `.thoughts/issue-fixer/<issue-number>/` exists to see if this is a new issue or a continuation of a previous one.
If a continuation, load the todo file, update the progress, and continue from there.

If a new issue, create the folder and the todo file.

### Phase 1: Issue Analysis

Mark "Analyze issue requirements" as in_progress.

Launch gitx:issue:analyzer agent with the following prompt:

```markdown
[issue number]
```

Wait for analysis to complete.

Remember key analysis results

Mark "Analyze issue requirements" as completed.

### Phase 2: Workflow Selection

Mark "Workflow Selection" as in_progress.

Use the AskUserQuestion tool to ask which workflow to use:

```text
Question: "Which development approach would you like to use for Issue #[number] - [title]?"
Options:
1. "Feature development workflow" - Using the command /feature-dev:feature-dev from the feature-dev@claude-plugins-official.
2. "TDD workflow" - Test-driven development with red-green-refactor from the tdd@jaodsilv-claudius-marketplace plugin.
3. "Manual development" - Work independently with implementation plan
4. "Skip development" - I'll develop later
```

On the type your answer value, the user may type its own development workflow name.
If that is the case, after phase 3, try loading and using it, if it fails, ask the user to provide a valid workflow name.

Once selected, mark "Workflow Selection" as completed.

### Phase 3: Worktree Setup

Mark "Set up worktree" as in_progress.

Use the Task tool to run the agent `gitx:worktree:creator` with the prompt:

```text
[issue number]
```

Wait for the worktree to be created.

Mark "Set up worktree" as completed.

### Phase 4: Development Delegation

Based on the user selection in Phase 2, delegate the development to the appropriate agent.

#### Feature Development Workflow

Mark "Complete development" as in_progress.

Using the Skill tool run the slash command

```text
/feature-dev:feature-dev
  Context: Issue #[number] - [title]
  worktree: [path]
  [Issue Analysis]
```

Wait for it to finish.

Mark "Complete development" as completed.

Skip to phase 9.

#### TDD Workflow

Mark "Complete development" as in_progress.

Using the Task tool run agent `tdd:tdd-orchestrator` with the following prompt:

```text
Context: Issue #[number] - [title]
worktree: [path]
[Issue Analysis]

```

Wait for it to finish.

Mark "Complete development" as completed.

Skip to phase 9.

#### Manual Development

Expand the progress tracking:

```text
TodoWrite:
1. [ ] Analyze issue requirements
2. [ ] Workflow Selection
3. [ ] Set up worktree
4. [ ] Explore codebase for relevant files
5. [ ] Create implementation plan
6. [ ] Get user approval on plan
7. [ ] Complete development
8. [ ] Commit and prepare for PR
9. [ ] Review Loop
```

#### Skip Development

Change the progress tracking:

```text
TodoWrite:
1. [ ] Analyze issue requirements
2. [ ] Workflow Selection
3. [ ] Set up worktree
4. [ ] Explore codebase for relevant files
5. [ ] Create implementation plan
6. [ ] Get user approval on plan
```

### Phase 5: Codebase Exploration

Mark "Explore codebase for relevant files" as in_progress.

If you skipped Phase 1, read the file `.thoughts/issue-fixer/<issue-number>/issue-analysis.md`.

Use the Task tool to launch the gitx:issue:codebase-navigator agent with the following prompt:

```markdown
<analysis-summary>[summary from Phase 1]</analysis-summary>
<key-terms>[terms from Phase 1]</key-terms>
<requirements>[requirements from Phase 1]</requirements>
<type>[type from Phase 1]</type>
```

Wait for exploration to complete.

Remember key results

Mark "Explore codebase for relevant files" as completed.

### Phase 6: Implementation Planning

Mark "Create implementation plan" as in_progress.

If you skpped Phase 2, read the files `.thoughts/issue-fixer/<issue-number>/issue-analysis.md` and `.thoughts/issue-fixer/<issue-number>/codebase-exploration.md`.

Use the Task tool to launch the gitx:issue:implementation-planner agent with the following prompt:

```text
<issue-analysis>[markdown of issue analysis]</issue-analysis>
<codebase-navigation>[markdown of codebase exploration]</codebase-navigation>
```

Wait for the planning to complete.

Remember key results

Mark "Create implementation plan" as completed.

### Phase 7: User Approval (Quality Gate)

Mark "Get user approval on plan" as in_progress.

If you skipped Phase 3, read the file `.thoughts/issue-fixer/<issue-number>/dev-plan.md`.

Present the implementation plan to user, then ask for approval using the AskUserQuestion tool:

```text
AskUserQuestion:
  Question: "Review the implementation plan for Issue #[number]. How would you like to proceed?"
  Options:
  1. "Approve and continue" - Proceed with worktree setup and development
  2. "Modify the plan" - Adjust before proceeding
  3. "Add more detail" - Expand specific sections
  4. "Cancel" - Abort the workflow
```

Handle user response:

1. **Approve**: Proceed to "Once approved" section
2. **Modify**: Update plan based on feedback, re-present
3. **Add detail**: Expand requested sections, re-present
4. **Cancel**: Clean up and exit

#### Once approved

- If there were any changes to the plan, update the file `.thoughts/issue-fixer/<issue-number>/dev-plan.md`
- Mark "Get user approval on plan" as completed.

### Phase 8: Development Delegation

If user selected "Skip development", exit this agent.

Mark "Complete development" as in_progress.

Use the Task tool to run an agent handing out the development plan asking it to proceed with the development.

Once complete, mark "Complete development" as completed.

### Phase 9: Commit and Create PR

Mark "Commit and create PR" as in_progress.

After development completes:

1. **Check for changes**:

   ```bash
   git status
   git diff --stat
   ```

2. **If changes exist**, use the Skill tool to run the slash command `/commit-commands:commit-push-pr`

3. **If no changes exist**, use the Skill tool to run the slash command `/gitx:pr`

Store the PR number in `$pr_number`

Mark "Commit and create PR" as completed.

### Phase 10: Review Loop

Mark "Review Loop" as in_progress.

Using the Task tool, run the agent `review-loop:orchestrator` with the following prompt:

```text
<reviewer>gitx:review:reviewer</reviewer>
<developer>gitx:address-review:review-responder</developer>
<automated-checker>gitx:address-review:ci-status-checker</automated-checker>
<automated-checks-fixer>gitx:address-review:ci-status-fixer</automated-checks-fixer>

<reviewer-prompt>
<pr_number>$pr_number</pr_number>

Consider also the previous review and the response to that review, if any:
</reviewer-prompt>

<developer-prompt>
<worktree>$worktree</worktree>
<pr_number>$pr_number</pr_number>
</developer-prompt>

<automated-checker-prompt>
<pr_number>$pr_number</pr_number>
<worktree>$worktree</worktree>
<branch>$branch</branch>
</automated-checker-prompt>

<automated-checks-fixer-prompt>
<pr_number>$pr_number</pr_number>
<worktree>$worktree</worktree>
<branch>$branch</branch>
</automated-checks-fixer-prompt>

<max-rounds>0</max-rounds>
<approval-threshold>all</approval-threshold>
```

Wait for it to finish

Mark "Review Loop" as completed.

### Error Handling

**Agent Failure**: Log the error, inform user which phase failed, offer to retry or skip.

**User Cancellation**: Save any progress made, clean up temporary files, report what was completed.

**Worktree Conflict**: Check if branch already exists, offer to use existing or create new, handle cleanup of failed worktree.

### Context Management

Between phases, preserve: issue number and title, key requirements, file list from navigation, implementation plan summary.

If context grows large, when auto-compacting try preserving:

```text
Essential context for Issue #[number]:
- Branch: [branch-name]
- Worktree: [path]
- Phase: [current phase]
- Key files: [list]
```

## Output Format

For agent outputs, use templates from `shared/output-templates/fix-issue-output.md`.

Throughout the workflow, provide status updates:

```text
## Fix Issue Workflow: #[number]

### Current Phase: [phase name]
[Description of what's happening]

### Progress
- [x] Issue analysis complete
- [x] Codebase exploration complete
- [ ] Implementation planning (in progress)
- [ ] User approval
- [ ] Worktree setup
- [ ] Development
- [ ] Completion

### Next Steps
[What happens next]
```

## Quality Standards

1. Never proceed past a quality gate without user approval. Quality gates exist to prevent wasted effort.
2. Clean up on cancellation. Orphaned worktrees and branches create confusion.
3. Provide clear status at each phase transition.
4. Handle errors gracefully with recovery options.
5. Preserve essential context across phases.
