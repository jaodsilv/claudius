---
description: >-
  Provides input classification heuristics for determining analysis strategy.
  Use when analyzing unknown input to determine what type of content it is
  and what investigation approach to apply.
user-invocable: false
model: sonnet
---

# Classifying Inputs

Determine the input type to select the appropriate analysis strategy.

## Classification Heuristics

| Input Type | Indicators | Analysis Strategy |
|-----------|------------|-------------------|
| `review-comment` | File paths with line numbers, review vocabulary ("nit:", "please change", "consider", "suggestion:"), diff hunks, inline code references | Map to code locations, check surrounding context, understand reviewer intent |
| `ci-log` | Build/test output, exit codes, timestamps, CI system markers (GitHub Actions, Jenkins, CircleCI), step names, artifact references | Extract error lines, parse stack traces, identify failing tests/builds |
| `error-text` | Stack traces, exception class names, error codes, "at line" references, segfault/panic messages | Parse trace to find origin, locate source files, check error handling |
| `task-description` | Natural language, imperative mood ("add", "fix", "implement"), describes behavior/feature, acceptance criteria | Search codebase for relevant areas, identify affected components |
| `generic` | None of the above indicators present | Keyword-based broad exploration, look for patterns in content |

## Decision Process

1. **Scan for strong indicators**: Check for definitive markers (stack traces → error-text, exit codes → ci-log)
2. **Check for moderate indicators**: File:line references could be review-comment OR error-text — look for review vocabulary to disambiguate
3. **Fall back to content analysis**: If no strong/moderate indicators, check if it reads like a task description (imperative verbs, feature language)
4. **Default to generic**: If none of the above match

## Confidence Levels

- **High confidence**: Multiple indicators from the same type (e.g., stack trace + exception name → error-text)
- **Medium confidence**: Single strong indicator or multiple weak ones
- **Low confidence**: Ambiguous input — classify as `generic` and note the ambiguity

## Type-Specific Investigation Queries

After classification, use these templates for codebase exploration:

| Type | Exploration Focus |
|------|-------------------|
| `review-comment` | "Explore the file(s) mentioned: [files]. Focus on lines [N-M] and surrounding context." |
| `ci-log` | "Explore files from the stack trace: [files]. Check for recent changes that could cause [error type]." |
| `error-text` | "Explore the source of [exception/error]: [file:line]. Trace the call chain to find the root cause." |
| `task-description` | "Explore areas related to [keywords]. Find components, services, or modules that handle [functionality]." |
| `generic` | "Search for [key terms] across the codebase. Look for related patterns in filenames, function names, and comments." |
