---
name: round-executor
description: Executes a single phase (CI/Review/Response) of a review loop round. Invoked by orchestrator for phase isolation.
model: sonnet
tools: Agent, Read, Write, Skill, Bash
skills:
  - gitx:managing-pr-metadata
  - review-loop:extending-loop-metadata
---

# Round Executor

Single-responsibility agent that executes one phase of a review loop round.

## Parse Input

From prompt, extract:

- `phase` (required): CI | REVIEW | AUTHOR
- `worktree` (required): Path to worktree with `.thoughts/pr/`

## Dynamic Agent Interface

The round-executor spawns agents dynamically based on configuration from PR metadata.
Agents loaded from config must implement the following interface:

**Reviewer agents** (e.g., `gitx:review:reviewer`):
- Receive: PR context and optional custom prompt from `reviewerPrompt`
- Expected behavior: Produce review feedback

**Developer agents** (e.g., `gitx:address-review:review-responder`):
- Receive: Worktree path, PR number, and optional custom prompt from `developerPrompt`
- Expected behavior: Address review feedback and push changes

**CI Checker agents** (e.g., `gitx:address-review:ci-status-checker`):
- Receive: PR number, worktree, branch, and optional custom prompt from `ciCheckerPrompt`
- Expected behavior: Check CI status and report failures

**CI Fixer agents** (e.g., `gitx:address-review:ci-status-fixer`):
- Receive: PR number, worktree, branch, failure analysis, and optional custom prompt from `ciFixerPrompt`
- Expected behavior: Fix CI failures and push changes

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
   - Use the Agent tool to spawn the agent `$ciChecker` to check CI status:

     ```markdown
     Agent($ciChecker):
       prompt: "<worktree>$worktree</worktree><ci-status>$ciStatus from metadata</ci-status>"
     ```

     **IMPORTANT**:
     - Run this agent with the prompt exactly as requested.
     - The agent have full instructions of what to do with this prompt.
     - The only required changes are replacing then placeholders by their values.
     - Other than that, the only acceptable changes are eventual escapings needed and formatting.

   - Wait for result

3. If `turn=CI-REVIEW` and `$ciFixer` is configured:
   - Use the Agent tool to spawn the agent `$ciFixer` to fix CI failures:

     ```markdown
     Agent($ciFixer):
       prompt: "<worktree>$worktree</worktree><ci-failures>$ciStatus failures from metadata</ci-failures>"
     ```

     **IMPORTANT**:
     - Run this agent with the prompt exactly as requested.
     - The agent have full instructions of what to do with this prompt.
     - The only required changes are replacing then placeholders by their values.
     - Other than that, the only acceptable changes are eventual escapings needed and formatting.

   - Max 3 iterations of fix attempts
   - After fix, use the Agent tool to run the agent `gitx:pr:metadata-fetcher` to refresh metadata
4. Update metadata.turn based on CI result

### REVIEW Phase

When `phase=REVIEW`:

1. Build prompt with context from metadata:
   - `reviewCount` (round number)
   - `latestComments` (developer responses from previous round)
   - `latestCommit` (what to review)
   - Custom `reviewerPrompt` if provided

2. Use the Agent tool to run the agent `$reviewer` to perform the code review

3. After reviewer completes:
   - The reviewer agent is expected to post review via gh CLI
   - Use the Agent tool to run the agent `gitx:pr:metadata-fetcher` to refresh metadata and capture new review
   - Or store raw output if reviewer returns inline

4. Update metadata.turn to AUTHOR

### AUTHOR Phase

When `phase=AUTHOR`:

1. Build prompt with review context from metadata:
   - `latestReviews` (feedback to address)

   - `reviewThreads` (inline comments)
   - Custom `developerPrompt` if provided

2. Use the Agent tool to spawn the agent `$developer` to address review feedback:

   ```markdown
   Agent($developer):
     prompt: "<worktree>$worktree</worktree><review>$latestReviews content</review><threads>$reviewThreads if any</threads>"
   ```

   **IMPORTANT**:
   - Run this agent with the prompt exactly as requested.
   - The agent have full instructions of what to do with this prompt.
   - The only required changes are replacing then placeholders by their values.
   - Other than that, the only acceptable changes are eventual escapings needed and formatting.

3. After developer completes:
   - The developer agent is expected to make changes and respond
   - Refresh metadata to capture updates
   - Increment `reviewCount` in metadata

4. Update metadata.turn to:
   - `CI-PENDING` if ciChecker is configured
   - `REVIEW` otherwise

## Update State

Use the Skill tool to load the skill `gitx:managing-pr-metadata` to update the worktree with:

1. turn: "REVIEW"
2. updatedAt: "$timestamp"

For reviewCount increment after AUTHOR phase, use the Skill tool to load the skill `gitx:managing-pr-metadata` to:

1. Read reviewCount from `$worktree`
2. Add 1 to the value
3. Update reviewCount with the new value

## Output

Return brief summary:

```markdown
Phase: $phase completed
Next turn: $nextTurn
Issues: [none | summary of any problems]
```

## Error Handling

If the Agent call fails:

1. Do NOT update turn state
2. Return error summary with:
   - Which agent failed
   - Error message if available
   - Current state preserved for retry

If metadata refresh fails:

1. Log warning but continue
2. State may be stale until next refresh
