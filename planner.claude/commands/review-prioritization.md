---
description: Review prioritization alignment with multi-agent orchestration
allowed-tools: Task, Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
argument-hint: <goal|roadmap-path> [--prioritization-path <path>] [--mode <quick|thorough>]
---

# /planner:review-prioritization

Review issue prioritization with multi-agent orchestration for alignment with a goal or roadmap.

## Input Processing

Arguments: `<arguments>$ARGUMENTS</arguments>`

Parse the arguments:

1. `$context`: Goal string or roadmap file path (required)
2. `$prioritization_path`: Path to prioritization file (default: "docs/planning/prioritization.md")
3. `$mode`: Review mode - "quick" (single agent) or "thorough" (orchestrated) (default: "thorough")

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
    mode:
      type: string
      enum: [quick, thorough]
      default: thorough
      description: Review mode - quick uses single agent, thorough uses multi-agent orchestration
  required:
    - context
```

## Orchestration Pattern

```text
Thorough Mode (default):
┌─────────────────────────────────────────────────────┐
│  Phase 1: Parallel Analysis                         │
│  ├── planner-plan-reviewer (domain: prioritization) │
│  └── planner-review-analyzer (structural)           │
│                                                     │
│  Phase 2: Adversarial Challenge                     │
│  └── planner-review-challenger (devil's advocate)   │
│                                                     │
│  Phase 3: Synthesis                                 │
│  └── planner-review-synthesizer (merge findings)    │
│                                                     │
│  Phase 4: Interactive Discussion                    │
│  └── Present findings, gather user feedback         │
└─────────────────────────────────────────────────────┘

Quick Mode:
┌─────────────────────────────────────────────────────┐
│  Single agent analysis using planner-plan-reviewer  │
└─────────────────────────────────────────────────────┘
```

## Execution Workflow

### Phase 1: Load Artifacts

1. Initialize TodoWrite:
   - Load Artifacts (in_progress)
   - Parallel Analysis (pending)
   - Adversarial Challenge (pending)
   - Synthesis (pending)
   - Interactive Review (pending)
   - Recommendations (pending)

2. Load prioritization matrix:

   ```text
   Read: {{prioritization_path}}
   ```

3. Determine context type:
   - If file exists at `$context`: Load as roadmap
   - Otherwise: Treat as goal string

4. Load context:

   ```text
   If roadmap: Read: {{context}}
   If goal: Use as string
   ```

### Phase 2: Context Analysis

1. If roadmap:
   - Extract phases and milestones
   - Identify key deliverables
   - Note dependencies

2. If goal:
   - Parse key outcomes
   - Identify success criteria
   - Note constraints

3. From prioritization:
   - List all prioritized issues
   - Note assigned priorities
   - Identify framework used

### Phase 3: Analysis (Mode-Dependent)

Select analysis path based on mode:

1. If mode == "quick": Skip to Quick Mode Analysis below
2. If mode == "thorough" (default): Continue with parallel analysis

#### Step 3A: Parallel Analysis

1. Mark Parallel Analysis as in_progress

2. Launch agents in parallel:

   **Domain Reviewer** (planner-plan-reviewer - prioritization mode):

   ```text
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

   For each priority level, list issues and assess alignment.
   ```

   **Structural Analyzer** (planner-review-analyzer):

   ```text
   Use Task tool with planner-review-analyzer agent:

   Analyze the structure of this prioritization matrix:
   {{prioritization_content}}

   Prioritization-specific checks:
   1. Framework identified and consistently applied?
   2. All items have scores/rationale?
   3. Dependencies documented?
   4. Effort estimates present?
   5. Categories well-distributed?

   Quality metrics and anti-patterns.
   Categorize findings by severity.
   ```

3. Collect outputs from both agents

#### Step 3B: Adversarial Challenge

1. Mark Adversarial Challenge as in_progress

2. Launch challenger agent:

   ```text
   Use Task tool with planner-review-challenger agent:

   Challenge this prioritization and the review findings:

   Prioritization:
   {{prioritization_content}}

   Context (Goal/Roadmap):
   {{context_content}}

   Domain Review Findings:
   {{domain_review_output}}

   Structural Analysis:
   {{structural_analysis_output}}

   Focus on:
   1. Over-prioritized items - Should any P0s be P1s?
   2. Under-prioritized items - Are critical items buried?
   3. Missing issues - What important items aren't listed?
   4. Bias detection - Is there stakeholder bias?
   5. Dependency risks - What if high-priority item is blocked?
   6. Framework gaming - Were scores manipulated?

   Be rigorous but constructive.
   ```

3. Receive adversarial analysis

#### Step 3C: Synthesis

1. Mark Synthesis as in_progress

   ```text
   Use Task tool with planner-review-synthesizer agent:

   Synthesize these prioritization review findings:

   Domain Review:
   {{domain_review_output}}

   Structural Analysis:
   {{structural_analysis_output}}

   Adversarial Challenge:
   {{challenger_output}}

   Create unified report with:
   1. Alignment score
   2. Priority adjustment recommendations
   3. Missing issue suggestions
   4. Coverage gaps
   5. Quick wins
   ```

2. Receive synthesized report

### Quick Mode Analysis

If mode == "quick", use single agent:

1. Mark Analysis as in_progress

2. Launch `planner-plan-reviewer` agent only:

   ```text
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

3. Proceed directly to Phase 4

### Phase 4: Interactive Review

1. Mark Interactive Review as in_progress

2. Present findings:

   ```markdown
   ## Prioritization Alignment Review (Multi-Agent Analysis)

   **Context**: {{goal_or_roadmap}}
   **Prioritization**: {{prioritization_path}}
   **Overall Alignment**: {{score}}/5
   **Review Sources**: Domain Reviewer, Structural Analyzer, Adversarial Challenger

   ### Executive Summary

   {{synthesized_summary}}

   ### Alignment by Priority Level

   #### P0 - Critical

   | Issue | Title     | Alignment | Notes             |
   | ----- | --------- | --------- | ----------------- |
   | #123  | Auth API  | Strong    | Core Phase 1      |
   | #124  | UI Polish | Weak      | Not goal-critical |

   #### P1 - High

   ...

   ### Top Priority Issues

   1. {{p0_issue_1}}
   2. {{p0_issue_2}}

   ### Key Challenges (from Adversarial Analysis)

   - {{over_prioritized}}
   - {{under_prioritized}}

   ### Coverage Analysis

   | Goal Aspect | Covered By | Priority |
   | ----------- | ---------- | -------- |

   | Authentication | #123 | P0 |
   | User Profile | - | Not covered |

   ### Quick Wins

   1. {{quick_win}}
   ```

   **For Quick Mode**:

   ```markdown
   ## Prioritization Alignment Review

   **Context**: {{goal_or_roadmap}}
   **Prioritization**: {{prioritization_path}}
   **Overall Alignment**: {{score}}/5

   ### Alignment by Priority Level

   #### P0 - Critical

   | Issue | Title    | Alignment | Notes        |
   | ----- | -------- | --------- | ------------ |
   | #123  | Auth API | Strong    | Core Phase 1 |

   ### Coverage Analysis

   | Goal Aspect    | Covered By | Priority |
   | -------------- | ---------- | -------- |
   | Authentication | #123       | P0       |

   ### Concerns

   1. **Issue #124 may be over-prioritized**
      - Reason: UI polish not critical for MVP
      - Suggestion: Move to P2
   ```

3. Use AskUserQuestion:
   - Do you agree with the alignment assessment?
   - Are there strategic reasons for current priorities?

   - Should we adjust any priorities?

4. Discuss and refine analysis

### Phase 5: Recommendations

1. Mark Recommendations as in_progress

2. Present suggestions:

   ````markdown
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

   ### Suggested Label Commands

   Run these commands to apply priority changes:

   ```bash
   gh issue edit 127 --add-label "P0" --remove-label "P1"
   gh issue edit 124 --add-label "P2" --remove-label "P0"
   ```
   ````

3. Ask user:
   - Which changes should we apply?
   - Would you like specific edit suggestions to apply?

4. If user wants to implement changes:
   - Present gh commands for label updates (user runs them)
   - Show edit suggestions as code blocks for manual application
   - Document decisions in review discussion

### Completion

````markdown
## Prioritization Review Complete

**Alignment Score**: {{score}}/5
**Review Mode**: {{mode}}

### Summary

{{summary}}

### Agreed Changes

1. {{change}}

### Suggested Commands

Run these commands to apply label changes:

```bash
gh issue edit ... --add-label "P0"
```
````

### Next Steps

1. Run suggested label commands
2. Create missing issues manually
3. Re-run prioritization: `/planner:prioritize ALL`

## Usage Examples

### Against Goal (Thorough Mode)

```text
/planner:review-prioritization "Ship MVP authentication by end of month"
```

### Quick Review

```text
/planner:review-prioritization "API v2" --mode quick
```

### Against Roadmap

```text
/planner:review-prioritization docs/planning/roadmap.md
```

### Custom Prioritization Path

```text
/planner:review-prioritization "API v2" --prioritization-path docs/api-v2/priorities.md
```

### Full Options

```text
/planner:review-prioritization docs/roadmap.md --prioritization-path docs/priorities.md --mode thorough
```
