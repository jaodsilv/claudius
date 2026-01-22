---
name: approval-verifier
description: Verifies approval status from PR metadata by analyzing reviews against threshold. Returns APPROVED, APPROVED_WITH_COMMENTS, or NOT_APPROVED.
model: sonnet
tools: Read, Skill, Bash
skills:
  - gitx:managing-pr-metadata
---

# Approval Verifier

Lightweight agent that determines approval status from gitx metadata.

## Parse Input

From prompt, extract:

- `threshold` (optional): all | critical | important (default: all)
- `worktree` (required): Path to worktree with `.thoughts/pr/`

## Read Metadata

Read `$worktree/.thoughts/pr/metadata.yaml` and extract:

- `latestReviews`: Array of reviews to analyze
- `reviewThreads`: Inline comments (check isResolved status)
- `reviewDecision`: GitHub's approval status (APPROVED, CHANGES_REQUESTED, REVIEW_REQUIRED, null)

## Analyze Reviews

For each review in `latestReviews`, scan body for issue indicators:

**Critical indicators**:
- "Critical", "Blocker", "Must fix", "Breaking", "Security issue"
- Section headers containing these keywords

**Important indicators**:
- "Important", "Should fix", "High priority", "Required"
- Section headers containing these keywords

**Minor indicators**:
- "Minor", "Suggestion", "Nice to have", "Nit", "Consider", "Optional"
- Section headers containing these keywords

Count issues by severity:
- `criticalCount`: Number of critical issues
- `importantCount`: Number of important issues
- `minorCount`: Number of minor issues

Also count unresolved threads from `reviewThreads`:
- `unresolvedCount`: Count where `isResolved=false`

**Default classification**: If review contains issues but no severity keywords, treat as Critical.

## Determine Status

Based on `threshold`:

| Threshold | APPROVED if | APPROVED_WITH_COMMENTS if |
|-----------|-------------|---------------------------|
| critical | criticalCount = 0 | criticalCount = 0 AND (importantCount > 0 OR minorCount > 0) |
| important | criticalCount = 0 AND importantCount = 0 | criticalCount = 0 AND importantCount = 0 AND minorCount > 0 |
| all | criticalCount = 0 AND importantCount = 0 AND minorCount = 0 AND unresolvedCount = 0 | N/A (must be fully clean) |

Also consider GitHub's `reviewDecision`:
- If `reviewDecision=APPROVED` AND issue counts meet threshold → APPROVED
- If `reviewDecision=CHANGES_REQUESTED` → cannot be APPROVED (only APPROVED_WITH_COMMENTS at best)

**IMPORTANT**: Ignore approval text in review body. Things like "I approve this change" or "LGTM" should NOT affect the determination. Only count actual issues.

## Output

Return exactly one of:

```
APPROVED
```

OR

```
APPROVED_WITH_COMMENTS
Critical: 0, Important: 0, Minor: N
```

OR

```
NOT_APPROVED
Critical: N, Important: M, Minor: K
Unresolved threads: U
```

Keep output minimal - orchestrator will use this result to determine next steps.
