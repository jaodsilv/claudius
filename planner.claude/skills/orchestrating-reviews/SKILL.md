---
name: planner:orchestrating-reviews
description: >-
  Provides multi-agent review orchestration pattern for planning artifacts.
  Use when implementing review commands that use domain reviewers, structural
  analysis, adversarial challenge, and synthesis phases.
---

# Orchestrating Reviews Skill

## Pattern Overview

The **Diverge-Challenge-Synthesize** workflow enables comprehensive artifact review through multi-agent collaboration.

| Phase | Purpose | Agents |
|-------|---------|--------|
| 1. Parallel Analysis | Independent domain + structural review | Domain reviewer, review-analyzer |
| 2. Adversarial Challenge | Challenge assumptions, find blind spots | review-challenger |
| 3. Synthesis | Deduplicate, resolve conflicts, prioritize | review-synthesizer |
| 4. Presentation | Interactive feedback loop | Main orchestrator |

**When to use**: Multi-perspective review of plans, roadmaps, requirements, architecture, or prioritization artifacts.

## Mode Selection

| Mode | Description | Use When |
|------|-------------|----------|
| Thorough | Full 4-phase orchestration | Default; comprehensive review needed |
| Quick | Single domain reviewer only | Time-constrained; focused feedback |

## Phase Structure

### Phase 1: Parallel Analysis

Launch two agents concurrently:

1. **Domain-specific reviewer** (e.g., `plan-reviewer`, `architecture-reviewer`)
   - Evaluates artifact against domain best practices
   - Identifies gaps, risks, and improvement opportunities

2. **review-analyzer**
   - Structural and cross-cutting analysis
   - Consistency, completeness, dependencies

### Phase 2: Adversarial Challenge

**review-challenger** receives:
- Original artifact
- Combined findings from Phase 1

Tasks:
- Challenge assumptions in the artifact
- Question findings from Phase 1
- Identify blind spots and unconsidered scenarios

### Phase 3: Synthesis

**review-synthesizer** receives all prior findings and:
- Deduplicates overlapping issues
- Resolves conflicting recommendations
- Prioritizes by impact and effort
- Generates unified, actionable recommendations

### Phase 4: Interactive Presentation

The orchestrator:
1. Presents synthesized findings to user
2. Uses `AskUserQuestion` for feedback on priorities
3. Iterates on suggestions based on user input

## Agent Invocation Pattern

```text
Use Task tool with @[agent-name]:
  Context: [artifact path], [goal if any]
  Mode: [thorough|quick]
  Phase: [1|2|3|4]
```

Example:
```text
Task @planner/review-analyzer:
  Context: docs/roadmap.md
  Mode: thorough
  Phase: 1
```

## Output Format

Reference `templates/review-report.md` for the standard output structure.

Key sections:
- Executive Summary
- Critical Issues
- Recommendations (prioritized)
- Questions for Stakeholders

## Error Handling

| Scenario | Action |
|----------|--------|
| File not found | Suggest similar paths via glob search |
| Artifact too large | Summarize sections before full analysis |
| Goal unclear | Ask user to clarify evaluation criteria |
| Agent timeout | Retry with reduced scope or quick mode |
