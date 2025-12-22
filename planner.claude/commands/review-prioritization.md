---
description: Review prioritization alignment with goal or roadmap
allowed-tools: Task, Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
argument-hint: <goal|roadmap-path> [--prioritization-path <path>]
---

# /planner:review-prioritization

Review issue prioritization for alignment with a goal or roadmap.

## Input Processing

Arguments: `<arguments>$ARGUMENTS</arguments>`

Parse the arguments:
1. `$context`: Goal string or roadmap file path (required)
2. `$prioritization_path`: Path to prioritization file (default: "docs/planning/prioritization.md")

## Parameters Schema

```yaml
review-prioritization-arguments:
  type: object
  properties:
    context:
      type: string
      description: Goal or path to roadmap file
    prioritization_path:
      type: string
      default: "docs/planning/prioritization.md"
      description: Path to prioritization matrix
  required:
    - context
```

## Execution Workflow

### Phase 1: Load Artifacts

1. Initialize TodoWrite:
   - Load Artifacts (in_progress)
   - Context Analysis (pending)
   - Alignment Check (pending)
   - Interactive Review (pending)
   - Recommendations (pending)

2. Load prioritization matrix:
   ```
   Read: {{prioritization_path}}
   ```

3. Determine context type:
   - If file exists at `$context`: Load as roadmap
   - Otherwise: Treat as goal string

4. Load context:
   ```
   If roadmap: Read: {{context}}
   If goal: Use as string
   ```

### Phase 2: Context Analysis

1. Mark Context Analysis as in_progress

2. If roadmap:
   - Extract phases and milestones
   - Identify key deliverables
   - Note dependencies

3. If goal:
   - Parse key outcomes
   - Identify success criteria
   - Note constraints

4. From prioritization:
   - List all prioritized issues
   - Note assigned priorities
   - Identify framework used

### Phase 3: Alignment Check

1. Mark Alignment Check as in_progress

2. Launch `planner-plan-reviewer` agent:
   ```
   Use Task tool with planner-plan-reviewer agent:

   Review this prioritization:
   {{prioritization_content}}

   Against this context:
   {{context_content}}

   Check:
   1. Priority Alignment - Do P0/P1 items align with goal/roadmap?
   2. Coverage - Are all goal aspects covered by issues?
   3. Sequencing - Do priorities respect dependencies?
   4. Gaps - Are there goal areas with no issues?
   5. Mismatches - High priority items that don't contribute?

   For each priority level:
   - List issues
   - Assess alignment with goal/roadmap
   - Note any concerns
   ```

3. Receive alignment analysis

### Phase 4: Interactive Review

1. Mark Interactive Review as in_progress

2. Present findings:
   ```markdown
   ## Prioritization Alignment Review

   **Context**: {{goal_or_roadmap}}
   **Prioritization**: {{prioritization_path}}
   **Overall Alignment**: {{score}}/5

   ### Alignment by Priority Level

   #### P0 - Critical
   | Issue | Title | Alignment | Notes |
   |-------|-------|-----------|-------|
   | #123 | Auth API | Strong | Core Phase 1 |
   | #124 | UI Polish | Weak | Not goal-critical |

   #### P1 - High
   ...

   ### Coverage Analysis

   | Goal Aspect | Covered By | Priority |
   |-------------|------------|----------|
   | Authentication | #123 | P0 |
   | User Profile | - | Not covered |

   ### Concerns

   1. **Issue #124 may be over-prioritized**
      - Reason: UI polish not critical for MVP
      - Suggestion: Move to P2

   2. **Missing coverage for user profile**
      - No issue addresses this goal area
      - Suggestion: Create issue or deprioritize aspect
   ```

3. Use AskUserQuestion:
   - Do you agree with the alignment assessment?
   - Are there strategic reasons for current priorities?
   - Should we adjust any priorities?

4. Discuss and refine analysis

### Phase 5: Recommendations

1. Mark Recommendations as in_progress

2. Present suggestions:
   ```markdown
   ## Priority Adjustment Recommendations

   ### Raise Priority

   1. **#127 → P1 to P0**
      - Reason: Directly blocks Phase 1 milestone
      - Context: Dependency for #123

   ### Lower Priority

   1. **#124 → P0 to P2**
      - Reason: Not goal-critical
      - Context: Can be deferred to Phase 2

   ### Create New Issues

   1. **User Profile Setup**
      - Goal area: User profile
      - Suggested priority: P1
      - Description: [draft]

   ### Close/Defer

   1. **#130 - Defer to post-MVP**
      - Reason: Nice-to-have, not goal-aligned

   ### Label Updates

   ```bash
   gh issue edit 127 --add-label "P0" --remove-label "P1"
   gh issue edit 124 --add-label "P2" --remove-label "P0"
   ```
   ```

3. Ask user:
   - Which changes should we apply?
   - Want me to update labels?

### Completion

```markdown
## Prioritization Review Complete

**Alignment Score**: {{score}}/5

### Summary

{{summary}}

### Agreed Changes

1. {{change}}

### Next Steps

1. Apply label updates
2. Create missing issues
3. Re-run prioritization: `/planner:prioritize ALL`
```

## Usage Examples

### Against Goal

```
/planner:review-prioritization "Ship MVP authentication by end of month"
```

### Against Roadmap

```
/planner:review-prioritization docs/planning/roadmap.md
```

### Custom Prioritization Path

```
/planner:review-prioritization "API v2" --prioritization-path docs/api-v2/priorities.md
```
