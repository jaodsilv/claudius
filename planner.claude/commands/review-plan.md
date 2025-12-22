---
description: Review a plan file with multi-agent orchestration for comprehensive analysis
allowed-tools: Task, Read, Glob, Grep, AskUserQuestion, TodoWrite
argument-hint: <plan-path> [--goal <goal>] [--mode <quick|thorough>]
---

# /planner:review-plan

Review a plan file with multi-agent orchestration for comprehensive, multi-perspective analysis.

## Input Processing

Arguments: `<arguments>$ARGUMENTS</arguments>`

Parse the arguments:
1. `$plan_path`: Path to the plan file (required)
2. `$goal`: Goal context for evaluation (optional)
3. `$mode`: Review mode - "quick" (single agent) or "thorough" (orchestrated) (default: "thorough")

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
    mode:
      type: string
      enum: [quick, thorough]
      default: thorough
      description: Review mode - quick uses single agent, thorough uses multi-agent orchestration
  required:
    - plan_path
```

## Orchestration Pattern

```
Thorough Mode (default):
┌─────────────────────────────────────────────────────┐
│  Phase 1: Parallel Analysis                         │
│  ├── planner-plan-reviewer (domain-specific)        │
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

### Phase 1: Plan Loading

1. Initialize TodoWrite:
   - Load Plan (in_progress)
   - Parallel Analysis (pending)
   - Adversarial Challenge (pending)
   - Synthesis (pending)
   - Interactive Review (pending)

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

### Phase 3: Analysis (Mode-Dependent)

**If mode == "quick"**: Skip to Quick Mode Analysis below

**If mode == "thorough"** (default):

#### Step 3A: Parallel Analysis

1. Mark Parallel Analysis as in_progress

2. Launch agents in parallel:

   **Domain Reviewer** (planner-plan-reviewer):
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

   Identify strengths, areas for improvement, critical issues.
   ```

   **Structural Analyzer** (planner-review-analyzer):
   ```
   Use Task tool with planner-review-analyzer agent:

   Analyze the structure of this plan:
   {{plan_content}}

   Check:
   1. Required sections present
   2. Completeness percentage
   3. Best practices and anti-patterns
   4. Quality metrics (clarity, specificity, consistency)

   Categorize findings by severity: Critical, High, Medium, Low.
   ```

3. Collect outputs from both agents

#### Step 3B: Adversarial Challenge

1. Mark Adversarial Challenge as in_progress

2. Launch challenger agent:
   ```
   Use Task tool with planner-review-challenger agent:

   Challenge this plan and the review findings:

   Plan:
   {{plan_content}}

   Domain Review Findings:
   {{domain_review_output}}

   Structural Analysis:
   {{structural_analysis_output}}

   Your role:
   1. Challenge assumptions (explicit and implicit)
   2. Identify blind spots
   3. Analyze failure modes
   4. Question estimates
   5. Find what the reviewers missed

   Be rigorous but constructive.
   ```

3. Receive adversarial analysis

#### Step 3C: Synthesis

1. Mark Synthesis as in_progress

2. Launch synthesizer agent:
   ```
   Use Task tool with planner-review-synthesizer agent:

   Synthesize these review findings:

   Domain Review:
   {{domain_review_output}}

   Structural Analysis:
   {{structural_analysis_output}}

   Adversarial Challenge:
   {{challenger_output}}

   Create unified report:
   1. Deduplicate overlapping findings
   2. Resolve conflicts between perspectives
   3. Prioritize by severity and impact
   4. Generate actionable recommendations
   5. Create executive summary
   ```

3. Receive synthesized report

### Quick Mode Analysis

If mode == "quick", use single agent:

1. Mark Analysis as in_progress

2. Launch `planner-plan-reviewer` agent only:
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

3. Proceed directly to Phase 4

### Phase 4: Interactive Review

1. Mark Interactive Review as in_progress

2. Present findings to user:

   **For Thorough Mode**:
   ```markdown
   ## Plan Review Findings (Multi-Agent Analysis)

   **Overall Assessment**: {{score}}/5
   **Review Sources**: Domain Reviewer, Structural Analyzer, Adversarial Challenger

   ### Executive Summary
   {{synthesized_summary}}

   ### Top Priority Issues
   1. {{p0_issue_1}}
   2. {{p0_issue_2}}

   ### Quality Metrics
   | Dimension | Score | Notes |
   |-----------|-------|-------|
   | Goal Alignment | X/5 | {{notes}} |
   | Completeness | X% | {{notes}} |
   | Feasibility | X/5 | {{notes}} |
   | Clarity | X/5 | {{notes}} |
   | Risk Coverage | X/5 | {{notes}} |

   ### Key Challenges (from Adversarial Analysis)
   1. {{challenge1}}
   2. {{challenge2}}

   ### Quick Wins
   1. {{quick_win1}}
   ```

   **For Quick Mode**:
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

### Phase 5: Recommendations

1. Mark Recommendations as in_progress

2. Present actionable suggestions:
   ```markdown
   ## Improvement Recommendations

   ### Priority 0 - Critical (Address Immediately)

   1. **{{issue_title}}**
      - Current: {{current_state}}
      - Suggested: {{improvement}}
      - Impact: {{expected_benefit}}

   ### Priority 1 - High (Address Soon)

   1. **{{suggestion_title}}**
      ...

   ### Quick Wins

   1. {{quick_fix}}
   ```

3. Ask user:
   - Which recommendations should we address now?
   - Would you like specific edit suggestions to apply?

4. If user wants to implement changes:
   - Present specific edits as code blocks
   - User applies changes manually with Edit tool
   - Document decisions in review discussion

### Completion

Present summary:
```markdown
## Review Complete

**Plan Reviewed**: {{plan_path}}
**Review Mode**: {{mode}}
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
4. **Agent failure**: Log error, continue with available outputs

## Usage Examples

### Basic Review (Thorough Mode)

```
/planner:review-plan docs/planning/roadmap.md
```

### Quick Review

```
/planner:review-plan project-plan.md --mode quick
```

### With Goal Context

```
/planner:review-plan project-plan.md --goal "Launch MVP by Q2"
```

### Full Options

```
/planner:review-plan docs/plan.md --goal "Scale to 1M users" --mode thorough
```
