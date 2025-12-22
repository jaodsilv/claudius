---
description: Review a roadmap against a goal
allowed-tools: Task, Read, Glob, Grep, AskUserQuestion, TodoWrite
argument-hint: <goal> [--roadmap-path <path>]
---

# /planner:review-roadmap

Review a roadmap for alignment with a goal and overall quality.

## Input Processing

Arguments: `<arguments>$ARGUMENTS</arguments>`

Parse the arguments:
1. `$goal`: Goal to evaluate roadmap against (required)
2. `$roadmap_path`: Path to roadmap (default: "docs/planning/roadmap.md")

## Parameters Schema

```yaml
review-roadmap-arguments:
  type: object
  properties:
    goal:
      type: string
      description: Goal to evaluate roadmap against
    roadmap_path:
      type: string
      default: "docs/planning/roadmap.md"
      description: Path to roadmap file
  required:
    - goal
```

## Execution Workflow

### Phase 1: Roadmap Loading

1. Initialize TodoWrite:
   - Load Roadmap (in_progress)
   - Goal Alignment Check (pending)
   - Structure Analysis (pending)
   - Interactive Review (pending)
   - Recommendations (pending)

2. Load roadmap:
   ```
   Read: {{roadmap_path}}
   ```

3. If not found, search for roadmaps:
   ```
   Glob: **/roadmap*.md
   ```

4. Extract roadmap structure:
   - Phases identified
   - Milestones listed
   - Dependencies mapped
   - Risks noted

### Phase 2: Goal Alignment Check

1. Mark Goal Alignment as in_progress

2. Analyze each phase against the goal:
   - Does this phase contribute to the goal?
   - Is there a clear line from phase → goal?
   - Are there phases that don't contribute?

3. Check milestones:
   - Do milestones represent progress toward goal?
   - Are success criteria aligned with goal metrics?

4. Assess overall trajectory:
   - Will completing this roadmap achieve the goal?
   - What gaps exist between roadmap and goal?

### Phase 3: Structure Analysis

1. Mark Structure Analysis as in_progress

2. Launch `planner-plan-reviewer` agent (specialized for roadmaps):
   ```
   Use Task tool with planner-plan-reviewer agent:

   Review this roadmap:
   {{roadmap_content}}

   Evaluate against goal: {{goal}}

   Roadmap-specific checks:
   1. Phase sequencing - logical order?
   2. Dependencies - correctly mapped?
   3. Milestones - SMART criteria met?
   4. Timeline - realistic?
   5. Risk coverage - adequate?
   6. Resource considerations - addressed?

   Identify:
   - Alignment issues
   - Structural problems
   - Missing phases or milestones
   - Unrealistic assumptions
   ```

3. Receive detailed analysis

### Phase 4: Interactive Review

1. Mark Interactive Review as in_progress

2. Present findings:
   ```markdown
   ## Roadmap Review: {{goal}}

   **Roadmap**: {{roadmap_path}}
   **Overall Alignment**: {{alignment_score}}/5

   ### Goal Alignment Analysis

   | Phase | Alignment | Contribution |
   |-------|-----------|--------------|
   | Phase 1 | Strong/Weak/None | {{contribution}} |

   ### Key Findings

   **Strengths**:
   1. {{strength}}

   **Concerns**:
   1. {{concern}}

   ### Milestone Quality

   | Milestone | SMART Score | Issue |
   |-----------|-------------|-------|
   | M1 | 4/5 | Not time-bound |
   ```

3. Use AskUserQuestion to discuss:
   - Does this capture your sense of alignment?
   - Are there phases that feel misaligned?
   - What timeline concerns do you have?

4. Dive deeper based on user interest

### Phase 5: Recommendations

1. Mark Recommendations as in_progress

2. Present improvement suggestions:
   ```markdown
   ## Roadmap Recommendations

   ### Alignment Fixes

   1. **Strengthen Phase 2 connection to goal**
      - Add milestone: {{milestone}}
      - Deliverable needed: {{deliverable}}

   ### Structural Improvements

   1. **Reorder Phase 3 and 4**
      - Reason: {{reason}}
      - Dependency: {{dependency}}

   ### Missing Elements

   1. Add risk mitigation for {{risk}}
   2. Include buffer time in Phase {{n}}

   ### Timeline Adjustments

   1. Phase 2 may need more time because...
   ```

3. Ask user:
   - Which recommendations should we implement?
   - Want me to update the roadmap?

### Completion

```markdown
## Roadmap Review Complete

**Goal**: {{goal}}
**Alignment Score**: {{score}}/5

### Summary

{{summary}}

### Agreed Changes

1. {{change}}

### Next Steps

1. Update roadmap with changes
2. Review with stakeholders
3. Create Phase 1 tasks
```

## Usage Examples

### Basic Review

```
/planner:review-roadmap Implement user authentication by Q2
```

### Custom Roadmap Path

```
/planner:review-roadmap Launch mobile app --roadmap-path docs/mobile/roadmap.md
```
