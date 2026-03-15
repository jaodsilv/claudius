---
description: >-
  Provides the canonical output format for structured analyses.
  Use when writing analysis files to ensure consistent structure
  that downstream consumers (planners, fixers) can reliably parse.
user-invocable: false
model: sonnet
---

# Structuring Analysis Output

Canonical format for all analysis output files in the analyzer plugin.

## Full Analysis Format

Use the template in `${CLAUDE_SKILL_DIR}/references/analysis-schema.md` for the complete analysis file.

Key sections:
1. **Metadata** — Input type, timestamp, source description
2. **Executive Summary** — 2-3 sentence overview
3. **Findings** — Ordered by severity (critical first), each with:
   - Description, root cause, affected files, suggested approach
   - Severity (critical/high/medium/low) and effort (trivial/minor/moderate/significant)
4. **Cross-Cutting Concerns** — Patterns that span multiple findings
5. **Recommended Order** — Suggested sequence for addressing findings

## Compact Summary Format

10-15 lines containing:
- Input type and total finding count
- Top findings (1-2 lines each, severity-ordered)
- Overall assessment and recommended next step

## Severity Levels

Use the definitions in `${CLAUDE_SKILL_DIR}/references/severity-levels.md` for consistent severity assignment.

## Writing Guidelines

1. **Be specific**: Include file paths and line numbers whenever possible
2. **Be actionable**: Each finding should have a clear suggested approach
3. **Be ordered**: Critical findings first, informational last
4. **Be concise**: Full analysis should be scannable; details in findings
5. **Attribute evidence**: Link claims to specific code, logs, or error messages
