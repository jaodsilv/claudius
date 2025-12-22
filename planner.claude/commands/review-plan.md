---
description: Review a plan file and provide actionable suggestions
allowed-tools: Task, Read, Glob, Grep, AskUserQuestion, TodoWrite
argument-hint: <plan-path> [--goal <goal>]
---

# /planner:review-plan

Review a plan file interactively and provide actionable suggestions.

## Input Processing

Arguments: `<arguments>$ARGUMENTS</arguments>`

Parse the arguments:
1. `$plan_path`: Path to the plan file (required)
2. `$goal`: Goal context for evaluation (optional)

## Parameters Schema

```yaml
review-plan-arguments:
  type: object
  properties:
    plan_path:
      type: string
      description: Path to the plan file to review
    goal:
      type: string
      description: Optional goal for alignment checking
  required:
    - plan_path
```

## Execution Workflow

### Phase 1: Plan Loading

1. Initialize TodoWrite:
   - Load Plan (in_progress)
   - Analysis (pending)
   - Interactive Review (pending)
   - Suggestions (pending)

2. Read the plan file:
   ```
   Read: {{plan_path}}
   ```

3. If file not found, prompt user for correct path

4. Extract plan structure:
   - Identify sections
   - Note milestones
   - Map dependencies
   - Find deliverables

### Phase 2: Context Gathering

1. If goal not provided, attempt to extract from plan

2. If still unclear, ask user:
   ```
   What is the primary goal this plan should achieve?
   ```

3. Gather related context:
   - Search for requirements docs
   - Check for related plans
   - Look for existing issues

### Phase 3: Analysis

1. Mark Analysis as in_progress

2. Launch `planner-plan-reviewer` agent:
   ```
   Use Task tool with planner-plan-reviewer agent:

   Review this plan:
   {{plan_content}}

   Goal (if provided):
   {{goal}}

   Evaluate across dimensions:
   1. Goal Alignment - Does it achieve the goal?
   2. Completeness - Are all elements present?
   3. Feasibility - Is it realistic?
   4. Clarity - Is it actionable?
   5. Risk Coverage - Are risks addressed?

   Identify:
   - Strengths
   - Areas for improvement
   - Critical issues
   - Missing elements
   ```

3. Receive detailed analysis

### Phase 4: Interactive Review

1. Mark Interactive Review as in_progress

2. Present findings to user:
   ```markdown
   ## Plan Review Findings

   **Overall Assessment**: {{score}}/5

   ### Summary
   {{executive_summary}}

   ### Dimension Scores
   | Dimension | Score | Notes |
   |-----------|-------|-------|
   | Goal Alignment | X/5 | {{notes}} |
   | Completeness | X% | {{notes}} |
   | Feasibility | X/5 | {{notes}} |
   | Clarity | X/5 | {{notes}} |
   | Risk Coverage | X/5 | {{notes}} |

   ### Key Findings
   1. {{finding1}}
   2. {{finding2}}
   ```

3. Use AskUserQuestion to discuss:
   - Does this assessment match your sense?
   - Which areas should we focus on?
   - Are there concerns I should investigate more?

4. Iterate based on user input:
   - Dive deeper into specific areas
   - Clarify findings
   - Provide more detail where requested

### Phase 5: Suggestions

1. Mark Suggestions as in_progress

2. Present actionable suggestions:
   ```markdown
   ## Improvement Suggestions

   ### High Priority

   1. **{{suggestion1_title}}**
      - Current: {{current_state}}
      - Suggested: {{improvement}}
      - Impact: {{expected_benefit}}

   ### Medium Priority

   1. **{{suggestion2_title}}**
      ...

   ### Quick Wins

   1. {{quick_fix}}
   ```

3. Ask user:
   - Which suggestions should we address now?
   - Do you want me to help implement any changes?

4. If user wants changes, offer to:
   - Edit the plan file
   - Create updated version
   - Document for later

### Completion

Present summary:
```markdown
## Review Complete

**Plan Reviewed**: {{plan_path}}
**Overall Score**: {{score}}/5

### Key Takeaways

1. {{takeaway1}}
2. {{takeaway2}}

### Agreed Actions

1. {{action1}}

### Follow-up Recommended

- {{followup}}
```

## Error Handling

1. **File not found**: Suggest similar paths, ask for correction
2. **Plan too large**: Summarize sections, offer detailed review
3. **Goal unclear**: Ask for goal before evaluation

## Usage Examples

### Basic Review

```
/planner:review-plan docs/planning/roadmap.md
```

### With Goal Context

```
/planner:review-plan project-plan.md --goal "Launch MVP by Q2"
```
