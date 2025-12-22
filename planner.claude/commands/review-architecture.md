---
description: Review architecture decisions with multi-agent orchestration
allowed-tools: Task, Read, Glob, Grep, WebSearch, AskUserQuestion, TodoWrite
argument-hint: <goal|requirements-path> [--architecture-path <path>] [--mode <quick|thorough>]
---

# /planner:review-architecture

Review architecture decisions with multi-agent orchestration for alignment with goals and requirements.

## Input Processing

Arguments: `<arguments>$ARGUMENTS</arguments>`

Parse the arguments:
1. `$context`: Goal string or path to requirements file (required)
2. `$architecture_path`: Path to architecture documentation (optional, will search if not provided)
3. `$mode`: Review mode - "quick" (single agent) or "thorough" (orchestrated) (default: "thorough")

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
│  ├── planner-architecture-reviewer (domain)         │
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
│  Single agent: planner-architecture-reviewer        │
└─────────────────────────────────────────────────────┘
```

## Execution Workflow

### Phase 1: Load Context

1. Initialize TodoWrite:
   - Load Context (in_progress)
   - Find Architecture Docs (pending)
   - Parallel Analysis (pending)
   - Adversarial Challenge (pending)
   - Synthesis (pending)
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

### Phase 3: Analysis (Mode-Dependent)

**If mode == "quick"**: Skip to Quick Mode Analysis below

**If mode == "thorough"** (default):

#### Step 3A: Parallel Analysis

1. Mark Parallel Analysis as in_progress


2. Launch agents in parallel:

   **Domain Reviewer** (planner-architecture-reviewer):

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

   **Structural Analyzer** (planner-review-analyzer):

   ```
   Use Task tool with planner-review-analyzer agent:

   Analyze the structure of this architecture document:
   {{architecture_content}}

   Architecture-specific checks:
   1. Components defined?
   2. Data flows described?
   3. Technology choices explained?
   4. Trade-offs documented?
   5. Security considerations?
   6. Deployment architecture?
   7. Integration points?

   Quality metrics and anti-patterns.
   Categorize findings by severity.
   ```

3. Collect outputs from both agents


#### Step 3B: Adversarial Challenge

1. Mark Adversarial Challenge as in_progress

2. Launch challenger agent:

   ```
   Use Task tool with planner-review-challenger agent:

   Challenge this architecture and the review findings:

   Architecture:
   {{architecture_content}}

   Context (Goal/Requirements):
   {{context_content}}

   Domain Review Findings:
   {{domain_review_output}}

   Structural Analysis:
   {{structural_analysis_output}}

   Focus on:
   1. Scale failure modes - What breaks at 10x load?
   2. Security vulnerabilities - Attack vectors?
   3. Technology risks - Will these choices age well?
   4. Complexity debt - Is this over-engineered?
   5. Missing components - What's not covered?
   6. Integration risks - What if external services change?
   7. Single points of failure - Where are the risks?

   Be rigorous but constructive.
   ```

3. Receive adversarial analysis


#### Step 3C: Synthesis

1. Mark Synthesis as in_progress

2. Launch synthesizer agent:

   ```
   Use Task tool with planner-review-synthesizer agent:

   Synthesize these architecture review findings:

   Domain Review:
   {{domain_review_output}}

   Structural Analysis:
   {{structural_analysis_output}}

   Adversarial Challenge:
   {{challenger_output}}

   Create unified report with:
   1. Overall architecture score
   2. Requirements coverage assessment
   3. Prioritized concerns
   4. Security/scalability risks
   5. Alternative recommendations
   ```

3. Receive synthesized report


### Quick Mode Analysis

If mode == "quick", use single agent:

1. Mark Analysis as in_progress

2. Launch `planner-architecture-reviewer` agent only:

   ```
   Use Task tool with planner-architecture-reviewer agent:

   Review this architecture:
   {{architecture_content}}

   Against this context:
   {{context_content}}

   Evaluate:
   1. Goal Alignment - Does architecture support goals?
   2. Requirements Coverage - Are NFRs addressed?
   3. Technical Soundness - Is design quality high?
   4. Maintainability - Is it sustainable?
   5. Scalability - Can it grow?
   6. Security - Is it secure?
   7. Patterns - Good practices or anti-patterns?

   Research best practices where helpful.
   ```

3. Proceed directly to Phase 4


### Phase 4: Interactive Review

1. Mark Interactive Review as in_progress

2. Present findings:

   **For Thorough Mode**:

   ```markdown
   ## Architecture Review (Multi-Agent Analysis)

   **Context**: {{goal_or_requirements}}
   **Architecture**: {{architecture_path}}
   **Overall Score**: {{score}}/5
   **Review Sources**: Architecture Reviewer, Structural Analyzer, Adversarial Challenger

   ### Executive Summary
   {{synthesized_summary}}

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

   ### Top Priority Issues
   1. {{p0_issue_1}}
   2. {{p0_issue_2}}

   ### Key Challenges (from Adversarial Analysis)
   - {{scale_risk}}
   - {{security_risk}}

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
   ```

   **For Quick Mode**:

   ```markdown
   ## Architecture Review

   **Context**: {{goal_or_requirements}}
   **Architecture**: {{architecture_path}}
   **Overall Score**: {{score}}/5

   ### Goal Alignment

   | Goal Aspect | Architectural Support | Gap? |
   |-------------|----------------------|------|
   | {{aspect}} | {{support}} | {{gap}} |

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
   - Would you like specific edit suggestions to apply?

4. If user wants to implement changes:
   - Present specific edits as code blocks
   - User applies changes manually with Edit tool
   - Document decisions in review discussion

### Completion

```markdown
## Architecture Review Complete

**Overall Score**: {{score}}/5
**Review Mode**: {{mode}}

### Summary

{{summary}}

### Key Decisions

1. {{decision}}

### Follow-up Items

1. {{item}}

### Suggested Edits

Present as code blocks for user to apply manually.

### Next Steps

1. Apply agreed changes to architecture docs
2. Document decisions in ADR
3. Review with team
```

## Usage Examples

### Against Goal (Thorough Mode)

```
/planner:review-architecture "Build scalable notification system"
```

### Quick Review

```
/planner:review-architecture "API v2" --mode quick
```

### Against Requirements

```
/planner:review-architecture docs/planning/requirements.md
```

### With Architecture Path

```
/planner:review-architecture "API v2" --architecture-path docs/architecture/api-v2-design.md
```

### Full Options

```
/planner:review-architecture docs/requirements.md --architecture-path docs/arch.md --mode thorough
```
