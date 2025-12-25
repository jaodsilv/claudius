---
description: Multi-agent Ultrathink deep ideation session with Opus extended thinking
allowed-tools: Task, Read, Write, Glob, Grep, WebSearch, AskUserQuestion, TodoWrite, Skill
argument-hint: <goal|roadmap-path> [--mode <full|focused>] [--rounds <number>] [--output <path>]
---

# /planner:ideas

Launch a multi-agent Ultrathink deep ideation session using Opus extended thinking, multi-pass iteration, and adversarial analysis.

## Input Processing

Arguments: `<arguments>$ARGUMENTS</arguments>`

Parse the arguments:

1. `$input`: Goal description or path to roadmap file (required)
2. `$mode`: Session mode - "full" (all agents) or "focused" (subset) (default: "full")
3. `$rounds`: Number of ideation rounds (default: 3)
4. `$output`: Output path (default: "docs/planning/ideas/")

## Parameters Schema

```yaml
ideas-arguments:
  type: object
  properties:
    input:
      type: string
      description: Goal to ideate on, or path to roadmap file
    mode:
      type: string
      enum: [full, focused]
      default: full
      description: Session mode (full=all agents, focused=subset)
    rounds:
      type: number
      default: 3
      minimum: 1
      maximum: 5
      description: Number of ideation rounds
    output:
      type: string
      default: "docs/planning/ideas/"
      description: Output directory
  required:
    - input
```

## Ultrathink Workflow

```text
Round N (repeat for --rounds):
    ┌─────────────────────────────────────────────────┐
    │  1. Parallel Ideation (Opus agents)             │
    │     - Deep Thinker (extended thinking)          │
    │     - Innovation Explorer (research)            │
    │                                                 │
    │  2. Adversarial Analysis                        │
    │     - Adversarial Critic (challenge ideas)      │
    │                                                 │
    │  3. Synthesis                                   │
    │     - Convergence Synthesizer (merge ideas)     │
    │                                                 │
    │  4. User Interaction                            │
    │     - Facilitator (present, gather feedback)    │
    │     - Decide: continue or conclude              │
    └─────────────────────────────────────────────────┘
```

## Execution Workflow

### Initialization

1. Initialize TodoWrite:
   - Initialization (in_progress)
   - Round 1 (pending)
   - Round 2 (pending)
   - Round 3 (pending)
   - Finalization (pending)

2. Load ultrathink skill:

   ```text
   Use Skill tool to load: planner:ultrathink
   ```

3. Generate session ID: `session-{{timestamp}}`

4. Parse input:
   - If file path: Read roadmap/goal from file
   - If string: Use as goal directly

5. Ensure output directory:

   ```bash
   mkdir -p {{output}}
   ```

6. Set session context:

   ```text
   Goal: {{goal}}
   Mode: {{mode}}
   Max Rounds: {{rounds}}
   ```

### Round Loop

For each round (1 to {{rounds}}):

#### Step 1: Parallel Ideation

1. Mark Round N as in_progress

2. Launch ideation agents in parallel:

   **Deep Thinker (Opus with extended thinking)**:

   ```text
   Use Task tool with planner-ideas-deep-thinker agent:

   Topic: {{goal}}

   Previous round insights (if any):
   {{previous_insights}}

   User feedback from last round (if any):
   {{user_feedback}}

   Round: {{current_round}} of {{max_rounds}}

   Engage in extended, deep thinking:
   1. Deconstruct the problem thoroughly
   2. Generate multiple distinct approaches
   3. Explore non-obvious solutions
   4. Challenge assumptions
   5. Make cross-domain connections

   Take your time - extended thinking is valuable here.
   ```

   **Innovation Explorer (Opus with web research)**:

   ```text
   Use Task tool with planner-ideas-innovation-explorer agent:

   Topic: {{goal}}

   Previous findings (if any):
   {{previous_findings}}

   User interests (if any):
   {{user_interests}}

   Round: {{current_round}} of {{max_rounds}}

   Explore:
   1. State-of-the-art solutions
   2. Cross-domain inspiration
   3. Emerging technologies
   4. Unconventional approaches
   5. Novel combinations
   ```

3. Collect outputs from both agents

#### Step 2: Adversarial Analysis

```text
Use Task tool with planner-ideas-adversarial-critic agent:

Ideas to challenge:

From Deep Thinker:
{{deep_thinker_output}}

From Innovation Explorer:
{{innovation_output}}

For each idea:
1. Challenge underlying assumptions
2. Identify failure modes
3. Generate counter-arguments
4. Stress test under extremes
5. Find logical inconsistencies

Be rigorous but constructive.
```

1. Receive critique and challenges

#### Step 3: Synthesis

1. Launch Convergence Synthesizer:

   ```text
   Use Task tool with planner-ideas-convergence-synthesizer agent:

   Deep Thinker Output:
   {{deep_thinker_output}}

   Innovation Explorer Output:
   {{innovation_output}}

   Adversarial Critic Analysis:
   {{critic_output}}

   Synthesize into coherent proposals:
   1. Merge complementary ideas
   2. Address identified weaknesses
   3. Create hybrid proposals
   4. Rank by viability and impact
   5. Identify remaining gaps
   ```

2. Receive synthesized proposals

#### Step 4: User Interaction

1. Launch Facilitator for presentation:

   ```text
   Use Task tool with planner-ideas-facilitator agent:

   Round: {{current_round}} of {{max_rounds}}

   Synthesized Proposals:
   {{synthesis_output}}

   Present proposals clearly and gather user feedback:
   1. Show top proposals with scores
   2. Highlight key innovations
   3. Note main concerns
   4. Ask focused questions
   5. Determine if another round needed
   ```

2. Present to user through AskUserQuestion:
   - Which proposals resonate most?
   - What aspects need deeper exploration?
   - Any new directions to consider?
   - Continue to Round N+1? (if not last round)

3. Decision:
   1. If user wants to continue AND rounds remaining: Proceed to next round
   2. If user satisfied: Proceed to Finalization
   3. If last round reached: Proceed to Finalization

4. Between rounds, preserve:
   1. Top proposals
   2. Key insights
   3. User feedback
   4. New directions

### Finalization

1. Mark Finalization as in_progress

2. Generate final synthesis document:
   - Use ideas-synthesis template
   - Include all rounds' insights

   - Rank final proposals
   - Document discarded ideas
   - List open questions
   - Provide next steps

3. Write to `{{output}}/session-{{session_id}}.md`

4. Present completion summary:

   ```markdown
   ## Ultrathink Session Complete

   **Goal**: {{goal}}
   **Rounds**: {{completed_rounds}}
   **Duration**: {{duration}}

   ### Top Proposals

   1. **{{proposal1_name}}** (Score: {{score}}/10)
      {{proposal1_summary}}

   2. **{{proposal2_name}}** (Score: {{score}}/10)
      {{proposal2_summary}}

   ### Key Insights

   1. {{insight1}}
   2. {{insight2}}

   ### Output

   See `{{output}}/session-{{session_id}}.md` for full synthesis.

   ### Recommended Next Steps

   1. {{next_step1}}
   2. {{next_step2}}
   ```

5. Mark all todos complete

## Mode Variations

### Full Mode (default)

All agents engaged:

1. Deep Thinker
2. Innovation Explorer
3. Adversarial Critic
4. Facilitator

### Focused Mode

Use subset of agents for faster iteration:

1. Deep Thinker
2. Adversarial Critic
3. Facilitator

Faster execution but less diverse ideation. Use when time-constrained or exploring
a narrow problem space.

## Error Handling

1. **Goal unclear**: Prompt for clarification
2. **Agent failure**: Log error, continue with available outputs
3. **User cancellation**: Save progress, allow resume
4. **Context overflow**: Summarize and continue

## Usage Examples

### Basic Ideation

```text
/planner:ideas How can we improve developer onboarding experience?
```

### From Roadmap

```text
/planner:ideas docs/planning/roadmap.md
```

### Multiple Rounds

```text
/planner:ideas Build a better CLI tool --rounds 5
```

### Focused Session

```text
/planner:ideas Quick authentication approach --mode focused --rounds 2
```
