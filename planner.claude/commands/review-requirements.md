---
description: Review requirements for quality, completeness, and testability (interactive)
allowed-tools: Task, Read, Glob, Grep, AskUserQuestion, TodoWrite
argument-hint: <goal|roadmap-path> [--requirements-path <path>]
---

# /planner:review-requirements

Review requirements document interactively for quality, completeness, and testability.

## Input Processing

Arguments: `<arguments>$ARGUMENTS</arguments>`

Parse the arguments:
1. `$context`: Goal string or roadmap file path (required)
2. `$requirements_path`: Path to requirements file (default: "docs/planning/requirements.md")

## Parameters Schema

```yaml
review-requirements-arguments:
  type: object
  properties:
    context:
      type: string
      description: Goal or path to roadmap file
    requirements_path:
      type: string
      default: "docs/planning/requirements.md"
      description: Path to requirements document
  required:
    - context
```

## Execution Workflow

This is a highly interactive review process.

### Phase 1: Load Documents

1. Initialize TodoWrite:
   - Load Documents (in_progress)
   - Individual Review (pending)
   - Gap Analysis (pending)
   - Interactive Refinement (pending)
   - Final Report (pending)

2. Load requirements:
   ```
   Read: {{requirements_path}}
   ```

3. Determine context type:
   - If file exists at `$context`: Load as roadmap
   - Otherwise: Treat as goal string

4. Parse requirements structure:
   - Functional requirements list
   - Non-functional requirements list
   - Constraints noted
   - Assumptions identified

### Phase 2: Individual Requirement Review

1. Mark Individual Review as in_progress

2. Launch `planner-requirements-reviewer` agent:
   ```
   Use Task tool with planner-requirements-reviewer agent:

   Review these requirements:
   {{requirements_content}}

   Against context: {{context}}

   For each requirement, evaluate:
   1. SMART Criteria
      - Specific: Single interpretation?
      - Measurable: Quantifiable criteria?
      - Achievable: Realistic?
      - Relevant: Aligned with goal?
      - Time-bound: Scoped?

   2. Quality Attributes
      - Atomic: One thing per requirement?
      - Traceable: Linked to goal?
      - Testable: Can verify?
      - Consistent: No conflicts?

   3. Issues
      - Vague terms?
      - Missing acceptance criteria?
      - Conflicts with others?

   Be thorough - every requirement matters.
   ```

3. Receive requirement-by-requirement analysis

### Phase 3: Gap Analysis

1. Mark Gap Analysis as in_progress

2. Check coverage:
   - All goal aspects covered?
   - NFRs for each category?
   - Edge cases considered?
   - Error scenarios addressed?

3. Common gaps to check:
   - Security requirements
   - Performance targets
   - Error handling
   - Accessibility
   - Internationalization

4. Identify conflicts:
   - Requirements contradicting each other
   - Impossible combinations
   - Priority conflicts

### Phase 4: Interactive Refinement

1. Mark Interactive Refinement as in_progress

2. Present findings and iterate:

   **Round 1: Critical Issues**
   ```markdown
   ## Requirements with Critical Issues

   ### FR-003: "System should be fast"

   **Issues**:
   - Not specific: What operation? What's fast?
   - Not measurable: No target response time
   - Not testable: No acceptance criteria

   **Questions**:
   1. What operation should be fast?
   2. What response time is acceptable?
   3. Under what conditions (load, data size)?

   **Suggested Rewrite**:
   "API endpoints shall respond within 200ms for 95% of
   requests under 1000 concurrent users."
   ```

   Use AskUserQuestion to clarify each critical issue.

   **Round 2: Moderate Issues**
   ```markdown
   ### FR-007: "Users can upload files"

   **Issue**: Unbounded scope - what file types? What size limit?

   **Questions**:
   1. What file types are allowed?
   2. What's the maximum file size?
   3. Are there storage limits per user?
   ```

   Continue iterating with user.

   **Round 3: Gaps**
   ```markdown
   ### Missing Requirements

   1. **Security: No authentication requirements**
      - Suggestion: Add FR for auth method
      - Draft: "System shall authenticate users via..."

   2. **Performance: No scalability target**
      - Suggestion: Add NFR for concurrent users
      - Draft: "System shall support 10,000 concurrent users"
   ```

   Ask user for input on each gap.

3. For each issue:
   - Present the problem
   - Ask clarifying questions
   - Propose improved wording
   - Confirm with user
   - Note the resolution

### Phase 5: Final Report

1. Mark Final Report as in_progress

2. Generate updated requirements (if changes made):
   ```markdown
   ## Requirements Review Report

   **Document**: {{requirements_path}}
   **Date**: {{date}}
   **Issues Found**: {{issue_count}}
   **Issues Resolved**: {{resolved_count}}

   ### Quality Summary

   | Dimension | Before | After |
   |-----------|--------|-------|
   | Clarity | X/5 | Y/5 |
   | Completeness | X% | Y% |
   | Testability | X/5 | Y/5 |

   ### Changes Made

   #### Rewrites

   | ID | Original | Updated |
   |----|----------|---------|
   | FR-003 | "System should be fast" | "API endpoints shall respond within 200ms..." |

   #### Added

   1. FR-015: [New requirement]

   ### Remaining Issues

   1. {{remaining_issue}}

   ### Recommendations

   1. {{recommendation}}
   ```

3. Offer to update the requirements file:
   - Apply all agreed changes
   - Or provide diff for manual application

### Completion

```markdown
## Requirements Review Complete

**Quality Score**: {{before}} → {{after}}

### Summary

- Reviewed: {{count}} requirements
- Issues found: {{issues}}
- Issues resolved: {{resolved}}
- Gaps filled: {{gaps}}

### Updated Document

{{if_updated}}
See `{{requirements_path}}` for updated requirements.

### Outstanding Items

1. {{item}}

### Next Steps

1. Validate with stakeholders
2. Create test cases from requirements
3. Map to implementation tasks
```

## Error Handling

1. **Requirements not found**: Offer to run `/planner:gather-requirements`
2. **User unresponsive**: Save progress, allow resume
3. **Too many issues**: Prioritize by severity, batch

## Usage Examples

### Basic Review

```
/planner:review-requirements "Launch MVP by Q2"
```

### Against Roadmap

```
/planner:review-requirements docs/planning/roadmap.md
```

### Custom Requirements Path

```
/planner:review-requirements "API v2" --requirements-path docs/api-v2/requirements.md
```
