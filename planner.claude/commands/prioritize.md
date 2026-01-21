---
description: Prioritize GitHub issues using RICE, MoSCoW, or custom frameworks
allowed-tools: Task, Read, Write, Bash, Glob, Grep, TodoWrite, AskUserQuestion, Skill
argument-hint: <issue-numbers|ALL> [--framework <RICE|MoSCoW|WeightedScoring>] [--output <path>]
model: opus
---

# /planner:prioritize

Prioritize GitHub issues using configurable prioritization frameworks.

## Input Processing

Arguments: `<arguments>$ARGUMENTS</arguments>`

Parse the arguments:

1. `$issues`: Issue numbers (comma-separated) or "ALL" (required)
2. `$framework`: Prioritization framework (default: "RICE")
3. `$output`: Output path (default: "docs/planning/")

## Parameters Schema

```yaml
prioritize-arguments:
  type: object
  properties:
    issues:
      type: string
      description: Issue numbers (comma-separated, e.g., "1,2,3") or "ALL"
    framework:
      type: string
      enum: [RICE, MoSCoW, WeightedScoring]
      default: RICE
      description: Prioritization framework to apply
    output:
      type: string
      default: "docs/planning/"
      description: Output directory
  required:
    - issues
```

## Execution Workflow

### Phase 1: Initialization

1. Initialize TodoWrite:
   - Phase 1: Initialization (in_progress)
   - Phase 2: Issue Fetching (pending)
   - Phase 3: Relationship Mapping (pending)
   - Phase 4: Framework Application (pending)
   - Phase 5: Interactive Review (pending)
   - Phase 6: Output Generation (pending)

2. Load prioritization skill:

   ```text
   Invoke the Skill `planner:prioritizing-work` for prioritization framework guidance.
   ```

3. Verify gh CLI:

   ```bash
   gh auth status
   ```

   If not available/authenticated, inform user and exit.

### Phase 2: Issue Fetching

1. Launch `issue-analyzer` agent:

   ```text
   Use Task tool with `planner/issue-analyzer` agent:

   Fetch and analyze issues: {{issues}}

   For each issue, extract:
   - Number and title
   - Labels (priority, type, effort)
   - Milestone
   - Description/body
   - Comments (for context)
   - Linked PRs (for status)

   Parse effort and priority signals from labels.
   ```

2. Receive structured issue data

### Phase 3: Relationship Mapping

1. Mark Phase 3 as in_progress

2. Launch `issue-relationship-mapper` agent:

   ```text
   Use Task tool with `planner/issue-relationship-mapper` agent:

   Map dependencies for issues: {{issue_list}}

   Identify:
   - Blocking relationships
   - Issue dependencies
   - Critical paths
   - Parallel work opportunities
   ```

3. Receive dependency graph

### Phase 4: Framework Application

1. Mark Phase 4 as in_progress

2. Launch `prioritization-engine` agent:

   ```text
   Use Task tool with `planner/prioritization-engine` agent:

   Apply {{framework}} framework to prioritize:

   Issues:
   {{issue_data}}

   Dependencies:
   {{dependency_graph}}

   For RICE:
   - Estimate Reach from issue scope
   - Assess Impact from problem severity
   - Gauge Confidence from available data
   - Estimate Effort from labels/complexity

   For MoSCoW:
   - Classify by criticality
   - Validate effort distribution

   Generate ranked priority list with rationale.
   ```

3. Receive prioritized list

### Phase 5: Interactive Review

1. Mark Phase 5 as in_progress

2. Present draft rankings to user:

   ```markdown
   ## Draft Prioritization

   ### P0 - Critical

   | #   | Title | Score | Effort |
   | --- | ----- | ----- | ------ |

   ### P1 - High Priority

   ...

   ### Dependency Considerations

   Note: Issue #X should be done before #Y due to...
   ```

3. Use AskUserQuestion:
   - Do these rankings look right?
   - Should any priorities be adjusted?
   - Are there issues that should be higher/lower?

4. Incorporate user feedback into final rankings

### Phase 6: Output Generation

1. Mark Phase 6 as in_progress

2. Ensure output directory:

   ```bash
   mkdir -p {{output}}
   ```

3. Write prioritization matrix to `{{output}}/prioritization.md`

4. Include:
   - Ranked issue list by priority
   - Framework scoring breakdown

   - Dependency graph (Mermaid)
   - Recommendations
   - Suggested label updates

### Completion

Present summary:

````markdown
## Prioritization Complete

**Framework**: {{framework}}
**Issues Analyzed**: {{count}}

### Top Priority Issues (P0)

1. #{{issue1}} - {{title1}}
2. #{{issue2}} - {{title2}}

### Suggested Actions

1. Apply priority labels:

   ```bash

   gh issue edit {{issue}} --add-label "P0"
   ```
````

1. Focus next sprint on: #{{top_issues}}

### Output

See `{{output}}/prioritization.md` for full analysis.

## Error Handling

1. **gh not authenticated**: Prompt user to run `gh auth login`
2. **No issues found**: Report and suggest checking filters
3. **Missing label data**: Note assumptions made in scoring

## Usage Examples

### Prioritize All Issues

```text
/planner:prioritize ALL
```

### Specific Issues with MoSCoW

```text
/planner:prioritize 1,2,3 --framework MoSCoW
```

### Custom Output

```text
/planner:prioritize ALL --framework RICE --output docs/sprint-planning/
```
