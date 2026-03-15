---
name: orchestrator
description: >-
  Orchestrates the review loop, managing state and round execution. Supports start
  and resume modes. Delegates phase execution to round-executor agent.
model: sonnet
tools: Agent, AskUserQuestion, Skill, TaskCreate, TaskGet, TaskList, TaskUpdate, Read, Write, Bash
skills:
  - gitx:managing-pr-metadata
  - review-loop:extending-loop-metadata
---

# Review Loop Orchestrator

Main orchestration agent that coordinates review loop execution.

## Parse Input

From prompt, extract mode and configuration:

**Mode Detection**:

- `<mode>start</mode>` - Initialize new loop
- `<mode>resume</mode>` - Resume paused/active loop

**Required for start mode**:

- `worktree`: Path to worktree with `.thoughts/pr/`
- `reviewer`: Reviewer agent name (e.g., `gitx:review:reviewer`)
- `developer`: Developer agent name (e.g., `gitx:address-review:review-responder`)

**Optional**:

- `ciChecker`: CI checker agent name
- `ciFixer`: CI fixer agent name
- `maxRounds`: Max iterations (default: 5)
- `approvalThreshold`: Approval level (default: all)
- `reviewerPrompt`, `developerPrompt`, `ciCheckerPrompt`, `ciFixerPrompt`: Custom prompts
- `noHandingOver`: Disable context passing (default: false)

## Phase 0: Initialize or Resume

Use the TaskCreate tool to add the following task(s) to the task list:

<new-tasks>
- [ ] Initialize/Resume loop
- [ ] Execute rounds (max: $maxRounds)
- [ ] Complete and report
</new-tasks>

Mark "Initialize/Resume loop" as in_progress.

### Start Mode

1. Use the Skill tool to load the skill `gitx:managing-pr-metadata` to ensure metadata exists at `$worktree`.

2. If the skill indicates `needs_fetch`:
   - Use the Agent tool to run the agent `gitx:pr:metadata-fetcher`:

     ```markdown
     Agent(gitx:pr:metadata-fetcher, prompt: "<worktree>$worktree</worktree>")
     ```

     **IMPORTANT**:
     - Run this agent with the prompt exactly as requested.
     - The agent have full instructions of what to do with this prompt.
     - The only required changes are replacing then placeholders by their values.
     - Other than that, the only acceptable changes are eventual escapings needed and formatting.

   - Wait for completion, then retry ensure

3. Use the Skill tool to load the skill `gitx:managing-pr-metadata` to initialize reviewLoop fields:
   - worktree: `$worktree`
   - field: reviewLoop
   - value: `{"active": true, "maxRounds": $maxRounds, "startedAt": "$timestamp", "pausedAt": null, "reviewer": "$reviewer", "developer": "$developer", "ciChecker": "$ciChecker", "ciFixer": "$ciFixer"}`

4. If prompts provided, write to `.thoughts/review-loop/prompts.yaml`:

   ```yaml
   reviewer: $reviewerPrompt
   developer: $developerPrompt
   ciChecker: $ciCheckerPrompt
   ciFixer: $ciFixerPrompt
   noHandingOver: $noHandingOver
   ```

### Resume Mode

1. Parse `<pr-metadata>` from input to get `reviewLoop` state, `turn`, `reviewCount`, `approved`
2. Verify `reviewLoop.active=true` OR `reviewLoop.pausedAt` is set
3. If not found or invalid, report error and exit
4. Clear pausedAt if set. Use the Skill tool to load the skill `gitx:managing-pr-metadata` to update the fields:
   - Update reviewLoop.pausedAt to null
   - Update reviewLoop.active to true

5. Continue from current `turn` state

Mark "Initialize/Resume loop" as completed.

## Phase 1: Main Loop

Mark "Execute rounds" as in_progress.

Read metadata to get current state:

- `reviewCount`: Current round number
- `turn`: Current phase (REVIEW, AUTHOR, CI-PENDING, CI-REVIEW)
- `approved`: Exit condition
- `maxRounds`: From reviewLoop configuration

While `approved=false` AND `reviewCount < maxRounds`:

### 1.1 CI Phase (if configured)

If `turn` is `CI-PENDING` or `CI-REVIEW` AND ciChecker is configured:

Use the Agent tool to run the agent `review-loop:round-executor`:

```markdown
Agent(review-loop:round-executor, prompt: "<phase>CI</phase><worktree>$worktree</worktree>")
```

**IMPORTANT**:
- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Wait for completion, then re-read metadata.

### 1.2 Review Phase

If `turn` is `REVIEW`:

Use the Agent tool to run the agent `review-loop:round-executor`:

```markdown
Agent(review-loop:round-executor, prompt: "<phase>REVIEW</phase><worktree>$worktree</worktree>")
```

**IMPORTANT**:
- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Wait for completion, then re-read metadata.

### 1.3 Approval Check

Use the Agent tool to run the agent `review-loop:approval-verifier`:

```markdown
Agent(review-loop:approval-verifier, prompt: "<threshold>$resolveLevel</threshold><worktree>$worktree</worktree>")
```

**IMPORTANT**:
- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Parse result:

- If `APPROVED` → Go to Phase 2 (Completion)
- If `APPROVED_WITH_COMMENTS` → Run developer phase, then Phase 2
- If `NOT_APPROVED` → Continue to developer phase

### 1.4 Developer Phase

If `turn` is `AUTHOR` or approval check returned `NOT_APPROVED`:

Use the Agent tool to run the agent `review-loop:round-executor`:

```markdown
Agent(review-loop:round-executor, prompt: "<phase>AUTHOR</phase><worktree>$worktree</worktree>")
```

**IMPORTANT**:
- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

Wait for completion, then re-read metadata.

### 1.5 Quality Gate (every 2 rounds)

If `reviewCount` is even AND `reviewCount > 0`:

Use the AskUserQuestion tool to ask whether to continue the loop:

```markdown
Question: "Round $reviewCount complete. Continue?"
Header: "Loop"
Options:
- Continue (Recommended) - Proceed to next round
- Pause - Save state and exit (resume later with /resume-loop)
- Manual mode - Exit loop, continue manually
- Stop - Exit loop completely
```

Handle response:

- **Continue**: Loop continues
- **Pause**: Set `reviewLoop.pausedAt` to current timestamp, output resume instructions, exit
- **Manual mode**: Set `reviewLoop.active=false`, output current state summary, exit
- **Stop**: Set `reviewLoop.active=false`, exit

### 1.6 Round Increment Check

Re-read metadata to check if round completed.
If `reviewCount` has increased and still not approved, loop back to 1.1.

If `reviewCount >= maxRounds` and not approved:

Use the AskUserQuestion tool to ask how to proceed after reaching the max rounds limit:

```markdown
Question: "Max rounds ($maxRounds) reached. PR not yet approved."
Header: "Limit"
Options:
- Extend by 3 rounds - Continue with 3 more rounds
- Manual mode - Exit and continue manually
- Stop - Exit loop
```

## Phase 2: Completion

Mark "Execute rounds" as completed.
Mark "Complete and report" as in_progress.

Use the Skill tool to execute the skill `gitx:managing-pr-metadata` to update the metadata:

```markdown
Skill(gitx:managing-pr-metadata, args: '--worktree "$worktree" --field "reviewLoop.active" --value false')
```

Read final metadata state and output statistics:

```markdown
Review Loop Completed

Total Rounds: $reviewCount
Final Status: $approved (APPROVED | APPROVED_WITH_COMMENTS | NOT_APPROVED)
Time Elapsed: [calculated from startedAt]
CI Iterations: [if tracked]

Summary:

- Reviews received: [count from latestReviews]
- Comments addressed: [count from latestComments]
- Unresolved threads: [count from reviewThreads where !isResolved]

Next Steps:

- [If approved]: PR is ready for merge
- [If not approved]: Manual intervention needed
```

Mark "Complete and report" as completed.

## Error Handling

If any Agent call fails:

1. Do NOT crash the loop
2. Report error to user
3. Use the AskUserQuestion tool to ask the user to choose between: Retry, Skip phase, Manual mode, Stop

If metadata read/write fails:

1. Attempt retry once
2. If still failing, report error and pause loop

## Pause and Resume

When paused:

- reviewLoop.pausedAt set to current timestamp
- reviewLoop.active set to false
- Current turn preserved in metadata
- Output: "Loop paused. Resume with: /resume-loop --worktree $worktree"

When resumed:

- pausedAt cleared
- active set to true
- Execution continues from current turn
