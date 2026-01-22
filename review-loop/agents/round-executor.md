---
name: round-executor
description: Executes a single phase (CI/Review/Response) of a review loop round. Invoked by orchestrator for phase isolation.
model: sonnet
tools: Task, Read, Write, Skill, Bash
skills:
  - gitx:managing-pr-metadata
  - review-loop:extending-loop-metadata
---

# Round Executor

Single-responsibility agent that executes one phase of a review loop round.

## Parse Input

From prompt, extract:

- `phase` (required): CI | REVIEW | RESPONSE
- `worktree` (required): Path to worktree with `.thoughts/pr/`

## Load State

1. Read metadata from `$worktree/.thoughts/pr/metadata.yaml`
2. Extract reviewLoop configuration:
   - `reviewer`, `developer`, `ciChecker`, `ciFixer` agent names
   - `promptsFile` path (if exists)
3. If `promptsFile` exists, read prompts from it

## Execute Phase

### CI Phase

When `phase=CI`:

1. Check current `turn` value from metadata
2. If `turn=CI-PENDING`:
   - Use Task tool to run `$ciChecker` agent with:
     ```xml
     <worktree>$worktree</worktree>
     <ci-status>$ciStatus from metadata</ci-status>
     ```
   - Wait for result
3. If `turn=CI-REVIEW` and `$ciFixer` is configured:
   - Use Task tool to run `$ciFixer` agent with:
     ```xml
     <worktree>$worktree</worktree>
     <ci-failures>$ciStatus failures from metadata</ci-failures>
     ```
   - Max 3 iterations of fix attempts
   - After fix, refresh metadata via `gitx:pr:metadata-fetcher`
4. Update metadata.turn based on CI result

### REVIEW Phase

When `phase=REVIEW`:

1. Build prompt with context from metadata:
   - `reviewCount` (round number)
   - `latestComments` (developer responses from previous round)
   - `latestCommit` (what to review)
   - Custom `reviewerPrompt` if provided

2. Use Task tool to run `$reviewer` agent with prompt

3. After reviewer completes:
   - The reviewer agent is expected to post review via gh CLI
   - Refresh metadata to capture new review via `gitx:pr:metadata-fetcher`
   - Or store raw output if reviewer returns inline

4. Update metadata.turn to RESPONSE

### RESPONSE Phase

When `phase=RESPONSE`:

1. Build prompt with review context from metadata:
   - `latestReviews` (feedback to address)
   - `reviewThreads` (inline comments)
   - Custom `developerPrompt` if provided

2. Use Task tool to run `$developer` agent with:
   ```xml
   <worktree>$worktree</worktree>
   <review>$latestReviews content</review>
   <threads>$reviewThreads if any</threads>
   ```

3. After developer completes:
   - The developer agent is expected to make changes and respond
   - Refresh metadata to capture updates
   - Increment `reviewCount` in metadata

4. Update metadata.turn to:
   - `CI-PENDING` if ciChecker is configured
   - `REVIEW` otherwise

## Update State

Use `gitx:managing-pr-metadata` skill to update the worktree with:

1. turn: "REVIEW"
2. updatedAt: "$timestamp"

For reviewCount increment after RESPONSE phase, use the skill to:

1. Read reviewCount from `$worktree`
2. Add 1 to the value
3. Update reviewCount with the new value

## Output

Return brief summary:

```
Phase: $phase completed
Next turn: $nextTurn
Issues: [none | summary of any problems]
```

## Error Handling

If agent Task fails:

1. Do NOT update turn state
2. Return error summary with:
   - Which agent failed
   - Error message if available
   - Current state preserved for retry

If metadata refresh fails:

1. Log warning but continue
2. State may be stale until next refresh
