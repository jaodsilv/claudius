---
name: orchestrator
description: >-
  Orchestrates the review loop, managing state and round execution. Supports start
  and resume modes. Delegates phase execution to round-executor agent.
model: sonnet
tools: Task, AskUserQuestion, Skill, TodoWrite, Read, Write, Bash
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

Create TodoWrite:

```text
- [ ] Initialize/Resume loop
- [ ] Execute rounds (max: $maxRounds)
- [ ] Complete and report
```

Mark "Initialize/Resume loop" as in_progress.

### Start Mode

1. Use `gitx:managing-pr-metadata` skill to ensure metadata exists at `$worktree`.

2. If the skill indicates `needs_fetch`:
   - Run Task with `gitx:pr:metadata-fetcher`:
     ```xml
     <worktree>$worktree</worktree>
     ```
   - Wait for completion, then retry ensure

3. Initialize reviewLoop fields using `gitx:managing-pr-metadata` skill:
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

1. Read metadata from `$worktree/.thoughts/pr/metadata.yaml`
2. Verify `reviewLoop.active=true` OR `reviewLoop.pausedAt` is set
3. If not found or invalid, report error and exit
4. Clear pausedAt if set, using `gitx:managing-pr-metadata` skill:
   - Update reviewLoop.pausedAt to null
   - Update reviewLoop.active to true

5. Continue from current `turn` state

Mark "Initialize/Resume loop" as completed.

## Phase 1: Main Loop

Mark "Execute rounds" as in_progress.

Read metadata to get current state:
- `reviewCount`: Current round number
- `turn`: Current phase (REVIEW, RESPONSE, CI-PENDING, CI-REVIEW)
- `approved`: Exit condition
- `maxRounds`: From reviewLoop configuration

While `approved=false` AND `reviewCount < maxRounds`:

### 1.1 CI Phase (if configured)

If `turn` is `CI-PENDING` or `CI-REVIEW` AND ciChecker is configured:

Run Task with `review-loop:round-executor`:
```xml
<phase>CI</phase>
<worktree>$worktree</worktree>
```

Wait for completion, then re-read metadata.

### 1.2 Review Phase

If `turn` is `REVIEW`:

Run Task with `review-loop:round-executor`:
```xml
<phase>REVIEW</phase>
<worktree>$worktree</worktree>
```

Wait for completion, then re-read metadata.

### 1.3 Approval Check

Run Task with `review-loop:approval-verifier`:
```xml
<threshold>$resolveLevel</threshold>
<worktree>$worktree</worktree>
```

Parse result:
- If `APPROVED` → Go to Phase 2 (Completion)
- If `APPROVED_WITH_COMMENTS` → Run developer phase, then Phase 2
- If `NOT_APPROVED` → Continue to developer phase

### 1.4 Developer Phase

If `turn` is `RESPONSE` or approval check returned `NOT_APPROVED`:

Run Task with `review-loop:round-executor`:
```xml
<phase>RESPONSE</phase>
<worktree>$worktree</worktree>
```

Wait for completion, then re-read metadata.

### 1.5 Quality Gate (every 2 rounds)

If `reviewCount` is even AND `reviewCount > 0`:

Use AskUserQuestion:
```
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

Use AskUserQuestion:
```
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

Update metadata using `gitx:managing-pr-metadata` skill:

- worktree: `$worktree`
- field: reviewLoop.active
- value: false

Read final metadata state and output statistics:

```
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

If any Task fails:
1. Do NOT crash the loop
2. Report error to user
3. Use AskUserQuestion to offer: Retry, Skip phase, Manual mode, Stop

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
