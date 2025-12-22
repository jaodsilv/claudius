---
description: Review requirements with multi-agent orchestration for quality, completeness, and testability
allowed-tools: Task, Read, Glob, Grep, AskUserQuestion, TodoWrite
argument-hint: <goal|roadmap-path> [--requirements-path <path>] [--mode <quick|thorough>]
---

# /planner:review-requirements

Review requirements document with multi-agent orchestration for quality, completeness, and testability.

## Input Processing

Arguments: `<arguments>$ARGUMENTS</arguments>`

Parse the arguments:
1. `$context`: Goal string or roadmap file path (required)
2. `$requirements_path`: Path to requirements file (default: "docs/planning/requirements.md")
3. `$mode`: Review mode - "quick" (single agent) or "thorough" (orchestrated) (default: "thorough")

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
    mode:
      type: string
      enum: [quick, thorough]
      default: thorough
      description: Review mode - quick uses single agent, thorough uses multi-agent orchestration
  required:
    - context
```

## Orchestration Pattern

```
Thorough Mode (default):
┌─────────────────────────────────────────────────────┐
│  Phase 1: Parallel Analysis                         │
│  ├── planner-requirements-reviewer (domain)         │
│  └── planner-review-analyzer (structural)           │
│                                                     │
│  Phase 2: Adversarial Challenge                     │
│  └── planner-review-challenger (devil's advocate)   │
│                                                     │
│  Phase 3: Synthesis                                 │
│  └── planner-review-synthesizer (merge findings)    │
│                                                     │
│  Phase 4: Interactive Refinement                    │
│  └── Present findings, refine with user             │
└─────────────────────────────────────────────────────┘

Quick Mode:
┌─────────────────────────────────────────────────────┐
│  Single agent: planner-requirements-reviewer        │
└─────────────────────────────────────────────────────┘
```

## Execution Workflow

### Phase 1: Load Documents

1. Initialize TodoWrite:
   - Load Documents (in_progress)
   - Parallel Analysis (pending)
   - Adversarial Challenge (pending)
   - Synthesis (pending)
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

### Phase 2: Analysis (Mode-Dependent)

**If mode == "quick"**: Skip to Quick Mode Analysis below

**If mode == "thorough"** (default):

#### Step 2A: Parallel Analysis

1. Mark Parallel Analysis as in_progress

2. Launch agents in parallel:


   **Domain Reviewer** (planner-requirements-reviewer):

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


   **Structural Analyzer** (planner-review-analyzer):

   ```
   Use Task tool with planner-review-analyzer agent:

   Analyze the structure of these requirements:
   {{requirements_content}}

   Requirements-specific checks:
   1. Functional requirements present and categorized?
   2. Non-functional requirements present?
   3. Constraints documented?
   4. Assumptions noted?
   5. Acceptance criteria for each requirement?
   6. Priority assigned to requirements?
   7. Stakeholders identified?

   Quality metrics and anti-patterns.
   Categorize findings by severity.
   ```

3. Collect outputs from both agents

#### Step 2B: Adversarial Challenge


1. Mark Adversarial Challenge as in_progress

2. Launch challenger agent:

   ```
   Use Task tool with planner-review-challenger agent:

   Challenge these requirements and the review findings:

   Requirements:
   {{requirements_content}}

   Context (Goal/Roadmap):
   {{context}}

   Domain Review Findings:
   {{domain_review_output}}

   Structural Analysis:
   {{structural_analysis_output}}

   Focus on:
   1. Missing requirements - What's not covered?
      - Security requirements
      - Performance targets
      - Error handling
      - Accessibility
      - Internationalization
   2. Conflicting requirements - Any contradictions?
   3. Unrealistic requirements - Any impossible to achieve?
   4. Vague requirements - What needs clarification?
   5. Edge cases - What's not considered?
   6. Testability gaps - What can't be verified?

   Be rigorous but constructive.
   ```

3. Receive adversarial analysis

#### Step 2C: Synthesis


1. Mark Synthesis as in_progress

2. Launch synthesizer agent:

   ```
   Use Task tool with planner-review-synthesizer agent:

   Synthesize these requirements review findings:

   Domain Review:
   {{domain_review_output}}

   Structural Analysis:
   {{structural_analysis_output}}

   Adversarial Challenge:
   {{challenger_output}}

   Create unified report with:
   1. Quality scores per dimension
   2. Requirement-by-requirement issues
   3. Gap analysis
   4. Suggested rewrites
   5. Missing requirements to add
   ```

3. Receive synthesized report

### Quick Mode Analysis


If mode == "quick", use single agent:

1. Mark Analysis as in_progress

2. Launch `planner-requirements-reviewer` agent only:

   ```
   Use Task tool with planner-requirements-reviewer agent:

   Review these requirements:
   {{requirements_content}}

   Against context: {{context}}

   For each requirement, evaluate:
   1. SMART Criteria
   2. Quality Attributes (atomic, traceable, testable, consistent)
   3. Issues (vague terms, missing criteria, conflicts)

   Be thorough - every requirement matters.
   ```

3. Proceed directly to Phase 3

### Phase 3: Interactive Refinement


1. Mark Interactive Refinement as in_progress

2. Present findings and iterate:

   **For Thorough Mode**:

   ```markdown
   ## Requirements Review (Multi-Agent Analysis)

   **Document**: {{requirements_path}}
   **Date**: {{date}}
   **Review Sources**: Requirements Reviewer, Structural Analyzer, Adversarial Challenger

   ### Executive Summary
   {{synthesized_summary}}

   ### Quality Summary

   | Dimension | Score | Notes |
   |-----------|-------|-------|
   | Clarity | X/5 | {{notes}} |
   | Completeness | X% | {{notes}} |
   | Testability | X/5 | {{notes}} |
   | Consistency | X/5 | {{notes}} |

   ### Top Priority Issues
   1. {{p0_issue_1}}
   2. {{p0_issue_2}}

   ### Requirements with Critical Issues

   #### FR-003: "System should be fast"

   **Issues**:
   - Not specific: What operation? What's fast?
   - Not measurable: No target response time
   - Not testable: No acceptance criteria

   **Suggested Rewrite**:
   "API endpoints shall respond within 200ms for 95% of requests under 1000 concurrent users."

   ### Gap Analysis (from Adversarial Challenge)

   #### Missing Requirements

   1. **Security: No authentication requirements**
      - Suggestion: Add FR for auth method
      - Draft: "System shall authenticate users via..."


   2. **Performance: No scalability target**
      - Suggestion: Add NFR for concurrent users
      - Draft: "System shall support 10,000 concurrent users"
   ```

   **For Quick Mode**:

   ```markdown
   ## Requirements Review

   **Document**: {{requirements_path}}

   ### Quality Summary

   | Dimension | Score |
   |-----------|-------|
   | Clarity | X/5 |
   | Completeness | X% |
   | Testability | X/5 |

   ### Requirements with Issues

   #### FR-003: "System should be fast"

   **Issue**: Not specific, not measurable, not testable

   **Suggested Rewrite**:
   "API endpoints shall respond within 200ms..."
   ```

3. Use AskUserQuestion to clarify each critical issue:
   - What operation should be fast?
   - What response time is acceptable?
   - Under what conditions (load, data size)?

4. For each issue:
   - Present the problem
   - Ask clarifying questions
   - Propose improved wording

   - Confirm with user
   - Note the resolution

### Phase 4: Final Report

1. Mark Final Report as in_progress

2. Generate updated requirements summary:

   ```markdown
   ## Requirements Review Report

   **Document**: {{requirements_path}}
   **Date**: {{date}}
   **Review Mode**: {{mode}}
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

3. Present suggested updates:
   - Show improved requirement text as code blocks
   - User applies changes with Edit tool
   - Or copy/paste into requirements file

### Completion

```markdown
## Requirements Review Complete

**Quality Score**: {{before}} → {{after}}
**Review Mode**: {{mode}}

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

1. **Requirements not found**: Suggest user run `/planner:gather-requirements` command
2. **User unresponsive**: Save progress, allow resume
3. **Too many issues**: Prioritize by severity, batch
4. **Agent failure**: Log error, continue with available outputs

## Usage Examples

### Basic Review (Thorough Mode)

```
/planner:review-requirements "Launch MVP by Q2"
```

### Quick Review

```
/planner:review-requirements "API v2" --mode quick
```

### Against Roadmap

```
/planner:review-requirements docs/planning/roadmap.md
```

### Custom Requirements Path

```
/planner:review-requirements "API v2" --requirements-path docs/api-v2/requirements.md
```

### Full Options

```
/planner:review-requirements docs/roadmap.md --requirements-path docs/reqs.md --mode thorough
```
