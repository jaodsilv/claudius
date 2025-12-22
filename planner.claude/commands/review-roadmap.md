---
description: Review a roadmap with multi-agent orchestration against a goal
allowed-tools: Task, Read, Glob, Grep, AskUserQuestion, TodoWrite
argument-hint: <goal> [--roadmap-path <path>] [--mode <quick|thorough>]
---

# /planner:review-roadmap

Review a roadmap with multi-agent orchestration for alignment with a goal and overall quality.

## Input Processing

Arguments: `<arguments>$ARGUMENTS</arguments>`

Parse the arguments:
1. `$goal`: Goal to evaluate roadmap against (required)
2. `$roadmap_path`: Path to roadmap (default: "docs/planning/roadmap.md")
3. `$mode`: Review mode - "quick" (single agent) or "thorough" (orchestrated) (default: "thorough")

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
    mode:
      type: string
      enum: [quick, thorough]
      default: thorough
      description: Review mode - quick uses single agent, thorough uses multi-agent orchestration
  required:
    - goal
```

## Orchestration Pattern

```
Thorough Mode (default):
┌─────────────────────────────────────────────────────┐
│  Phase 1: Parallel Analysis                         │
│  ├── planner-plan-reviewer (domain: roadmap)        │
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

### Phase 1: Roadmap Loading

1. Initialize TodoWrite:
   - Load Roadmap (in_progress)
   - Parallel Analysis (pending)
   - Adversarial Challenge (pending)
   - Synthesis (pending)
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

1. Analyze each phase against the goal:
   - Does this phase contribute to the goal?
   - Is there a clear line from phase → goal?
   - Are there phases that don't contribute?

2. Check milestones:
   - Do milestones represent progress toward goal?
   - Are success criteria aligned with goal metrics?

3. Assess overall trajectory:
   - Will completing this roadmap achieve the goal?
   - What gaps exist between roadmap and goal?

### Phase 3: Analysis (Mode-Dependent)

**If mode == "quick"**: Skip to Quick Mode Analysis below

**If mode == "thorough"** (default):

#### Step 3A: Parallel Analysis

1. Mark Parallel Analysis as in_progress

2. Launch agents in parallel:


   **Domain Reviewer** (planner-plan-reviewer - roadmap mode):

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

   Identify alignment issues, structural problems, missing elements.

   ```

   **Structural Analyzer** (planner-review-analyzer):

   ```
   Use Task tool with planner-review-analyzer agent:

   Analyze the structure of this roadmap:
   {{roadmap_content}}

   Roadmap-specific structure checks:
   1. Goal statement present?
   2. Phases defined with clear boundaries?
   3. Milestones with success criteria?
   4. Deliverables per phase?
   5. Dependencies mapped?
   6. Risks identified?
   7. Timeline (relative or absolute)?

   Quality metrics and anti-patterns to detect.
   Categorize findings by severity.
   ```

3. Collect outputs from both agents

#### Step 3B: Adversarial Challenge


1. Mark Adversarial Challenge as in_progress

2. Launch challenger agent:

   ```
   Use Task tool with planner-review-challenger agent:

   Challenge this roadmap and the review findings:

   Roadmap:
   {{roadmap_content}}

   Goal: {{goal}}

   Domain Review Findings:
   {{domain_review_output}}

   Structural Analysis:
   {{structural_analysis_output}}

   Focus on:
   1. Timeline assumptions - are they optimistic?
   2. Dependency risks - what if X is delayed?
   3. Phase sequencing - could this order fail?
   4. Missing phases - what's not covered?
   5. Goal alignment gaps - will this really achieve the goal?
   6. Resource assumptions - are they realistic?

   Be rigorous but constructive.
   ```

3. Receive adversarial analysis


#### Step 3C: Synthesis

1. Mark Synthesis as in_progress

2. Launch synthesizer agent:

   ```
   Use Task tool with planner-review-synthesizer agent:

   Synthesize these roadmap review findings:

   Domain Review:
   {{domain_review_output}}

   Structural Analysis:
   {{structural_analysis_output}}

   Adversarial Challenge:
   {{challenger_output}}

   Create unified report with:
   1. Goal alignment score
   2. Prioritized issues
   3. Structural improvements
   4. Risk mitigations
   5. Timeline adjustments
   ```

3. Receive synthesized report

### Quick Mode Analysis


If mode == "quick", use single agent:

1. Mark Analysis as in_progress

2. Launch `planner-plan-reviewer` agent only (roadmap mode):

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

3. Proceed directly to Phase 4


### Phase 4: Interactive Review

1. Mark Interactive Review as in_progress

2. Present findings:

   **For Thorough Mode**:

   ```markdown
   ## Roadmap Review: {{goal}} (Multi-Agent Analysis)

   **Roadmap**: {{roadmap_path}}
   **Overall Alignment**: {{alignment_score}}/5
   **Review Sources**: Domain Reviewer, Structural Analyzer, Adversarial Challenger

   ### Executive Summary
   {{synthesized_summary}}

   ### Goal Alignment Analysis

   | Phase | Alignment | Contribution | Issue |
   |-------|-----------|--------------|-------|
   | Phase 1 | Strong/Weak/None | {{contribution}} | {{issue}} |

   ### Top Priority Issues
   1. {{p0_issue_1}}
   2. {{p0_issue_2}}

   ### Key Challenges (from Adversarial Analysis)
   - {{timeline_risk}}
   - {{dependency_risk}}

   ### Milestone Quality

   | Milestone | SMART Score | Issue |

   |-----------|-------------|-------|
   | M1 | 4/5 | Not time-bound |

   ### Quick Wins
   1. {{quick_win}}
   ```

   **For Quick Mode**:

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
   - Which recommendations should we address?
   - Would you like specific edit suggestions to apply?

4. If user wants to implement changes:
   - Present specific edits as code blocks
   - User applies changes manually with Edit tool
   - Document decisions in review discussion

### Completion

```markdown
## Roadmap Review Complete

**Goal**: {{goal}}
**Review Mode**: {{mode}}
**Alignment Score**: {{score}}/5

### Summary

{{summary}}

### Agreed Changes

1. {{change}}

### Suggested Edits

Present as code blocks for user to apply manually.

### Next Steps

1. Apply agreed changes to roadmap
2. Review with stakeholders
3. Create Phase 1 tasks
```

## Usage Examples

### Basic Review (Thorough Mode)

```
/planner:review-roadmap Implement user authentication by Q2
```

### Quick Review

```
/planner:review-roadmap Launch mobile app --mode quick
```

### Custom Roadmap Path

```
/planner:review-roadmap Launch mobile app --roadmap-path docs/mobile/roadmap.md
```

### Full Options

```
/planner:review-roadmap "Scale to 1M users" --roadmap-path docs/scaling-roadmap.md --mode thorough
```
