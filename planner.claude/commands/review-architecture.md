---
description: Review architecture decisions against goals and requirements
allowed-tools: Task, Read, Glob, Grep, WebSearch, AskUserQuestion, TodoWrite
argument-hint: <goal|requirements-path> [--architecture-path <path>]
---

# /planner:review-architecture

Review architecture decisions for alignment with goals and requirements.

## Input Processing

Arguments: `<arguments>$ARGUMENTS</arguments>`

Parse the arguments:
1. `$context`: Goal string or path to requirements file (required)
2. `$architecture_path`: Path to architecture documentation (optional, will search if not provided)

## Parameters Schema

```yaml
review-architecture-arguments:
  type: object
  properties:
    context:
      type: string
      description: Goal or path to requirements file
    architecture_path:
      type: string
      description: Path to architecture documentation
  required:
    - context
```

## Execution Workflow

### Phase 1: Load Context

1. Initialize TodoWrite:
   - Load Context (in_progress)
   - Find Architecture Docs (pending)
   - Analysis (pending)
   - Interactive Review (pending)
   - Recommendations (pending)

2. Determine context type:
   - If file exists at `$context`: Load as requirements
   - Otherwise: Treat as goal string

3. Load context:
   ```
   If requirements: Read: {{context}}
   If goal: Use as string
   ```

### Phase 2: Find Architecture Docs

1. Mark Find Architecture as in_progress

2. If architecture_path provided:
   ```
   Read: {{architecture_path}}
   ```

3. If not provided, search:
   ```
   Glob: **/architecture*.md, **/design*.md, **/adr/*.md
   ```

4. If multiple found, ask user to select

5. If none found, ask:
   - Is there architecture documentation elsewhere?
   - Should we analyze the codebase instead?

6. Extract architecture elements:
   - Components identified
   - Data flows mapped
   - Technologies chosen
   - Design decisions noted

### Phase 3: Analysis

1. Mark Analysis as in_progress

2. Launch `planner-architecture-reviewer` agent:
   ```
   Use Task tool with planner-architecture-reviewer agent:

   Review this architecture:
   {{architecture_content}}

   Against this context:
   {{context_content}}

   Evaluate:
   1. Goal Alignment - Does architecture support goals?
   2. Requirements Coverage - Are NFRs addressed?
      - Performance requirements met?
      - Security requirements covered?
      - Scalability needs addressed?
      - Reliability guarantees possible?
   3. Technical Soundness - Is design quality high?
   4. Maintainability - Is it sustainable long-term?
   5. Scalability - Can it grow?
   6. Security - Is it secure?
   7. Patterns - Good practices or anti-patterns?

   Research best practices where helpful.
   ```

3. Receive detailed analysis

### Phase 4: Interactive Review

1. Mark Interactive Review as in_progress

2. Present findings:
   ```markdown
   ## Architecture Review

   **Context**: {{goal_or_requirements}}
   **Architecture**: {{architecture_path}}
   **Overall Score**: {{score}}/5

   ### Goal Alignment

   | Goal Aspect | Architectural Support | Gap? |
   |-------------|----------------------|------|
   | {{aspect}} | {{support}} | {{gap}} |

   ### Requirements Coverage

   #### Performance Requirements
   | Requirement | Addressed? | How | Concern |
   |-------------|------------|-----|---------|

   #### Security Requirements
   ...

   #### Scalability Requirements
   ...

   ### Dimension Scores

   | Dimension | Score | Key Finding |
   |-----------|-------|-------------|
   | Goal Alignment | X/5 | {{finding}} |
   | Technical Soundness | X/5 | {{finding}} |
   | Maintainability | X/5 | {{finding}} |
   | Scalability | X/5 | {{finding}} |
   | Security | X/5 | {{finding}} |

   ### Patterns Identified

   **Good Practices**:
   1. {{pattern}}: {{why_good}}

   **Concerns**:
   1. {{anti_pattern}}: {{issue}}

   ### Industry Comparison

   {{how_this_compares}}
   ```

3. Use AskUserQuestion:
   - Does this assessment align with your understanding?
   - Are there trade-offs I should know about?
   - Which areas are most concerning?

4. Dive deeper based on user interest

### Phase 5: Recommendations

1. Mark Recommendations as in_progress

2. Present suggestions:
   ```markdown
   ## Architecture Recommendations

   ### High Priority

   1. **Address {{concern}}**
      - Current: {{current_state}}
      - Issue: {{problem}}
      - Suggested: {{solution}}
      - Trade-off: {{trade_off}}

   ### Medium Priority

   1. **Consider {{improvement}}**
      - Benefit: {{benefit}}
      - Cost: {{cost}}

   ### Research Needed

   1. **Investigate {{topic}}**
      - Why: {{reason}}
      - Questions: {{questions}}

   ### Alternative Approaches

   For {{aspect}}, consider:
   1. {{alternative1}}: {{pros_cons}}
   2. {{alternative2}}: {{pros_cons}}
   ```

3. Ask user:
   - Which recommendations should be prioritized?
   - Are there constraints I should factor in?
   - Want me to create issues for follow-up?

### Completion

```markdown
## Architecture Review Complete

**Overall Score**: {{score}}/5

### Summary

{{summary}}

### Key Decisions

1. {{decision}}

### Follow-up Items

1. {{item}}

### Next Steps

1. Address critical concerns
2. Document decisions in ADR
3. Review with team
```

## Usage Examples

### Against Goal

```
/planner:review-architecture "Build scalable notification system"
```

### Against Requirements

```
/planner:review-architecture docs/planning/requirements.md
```

### With Architecture Path

```
/planner:review-architecture "API v2" --architecture-path docs/architecture/api-v2-design.md
```
