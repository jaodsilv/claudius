---
description: Multi-agent Ultrathink deep ideation session with Opus extended thinking
argument-hint: "[[--goal] <goal> | [--roadmap-path] <roadmap-path>] [--mode <full|focused>] [--rounds <number>] [--output <path>]"
allowed-tools: Agent, Read, Write, Glob, Grep, WebSearch, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Skill
model: opus
---

# /planner:ideas

Launch a multi-agent Ultrathink deep ideation session using Opus extended thinking, multi-pass iteration, and adversarial analysis.

## Arguments Parsing

Extract from `$ARGUMENTS`:

- `$input`: Goal to ideate on, or path to roadmap file (required). It's value it the substring of everything that comes before any flags.
- `$mode`: Session mode - "full" (all agents) or "focused" (subset) (default: "full")
- `$rounds`: Number of ideation rounds (default: 3, minimum: 1, maximum: 5)
- `$output`: Output path (default: "docs/planning/ideas/")

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

1. Use the TaskCreate tool to add the following task(s) to the task list:

   <new-tasks>
   - [ ] Initialization (in_progress)
   - [ ] Round 1 (pending)
   - [ ] Round 2 (pending)
   - [ ] Round 3 (pending)
   - [ ] Finalization (pending)
   </new-tasks>

2. Ultrathink the goal and constraints before orchestrating the multi-agent workflow.

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

2. Check mode and launch appropriate agents:

   **If mode is "full" (default)**: Launch both agents in parallel
   **If mode is "focused"**: Launch only Deep Thinker (skip Innovation Explorer)

3. Launch ideation agents:

   **Deep Thinker (Opus with extended thinking)**:

   Use the Agent tool to spawn the agent `planner:ideas:deep-thinker` to deeply explore the problem:

   ```markdown
   Agent(planner:ideas:deep-thinker):
     prompt:
       Topic: {{goal}}

       Previous round insights (if any):
       {{previous_insights}}

       User feedback from last round (if any):
       {{user_feedback}}

       Round: {{current_round}} of {{max_rounds}}
   ```

   **IMPORTANT**:
   - Run this agent with the prompt exactly as requested.
   - The agent have full instructions of what to do with this prompt.
   - The only required changes are replacing then placeholders by their values.
   - Other than that, the only acceptable changes are eventual escapings needed and formatting.

   **Innovation Explorer (Opus with web research)**:

   Use the Agent tool to spawn the agent `planner:ideas:innovation-explorer` to explore innovative approaches:

   ```markdown
   Agent(planner:ideas:innovation-explorer):
     prompt:
       Topic: {{goal}}

       Previous findings (if any):
       {{previous_findings}}

       User interests (if any):
       {{user_interests}}

       Round: {{current_round}} of {{max_rounds}}
   ```

   **IMPORTANT**:
   - Run this agent with the prompt exactly as requested.
   - The agent have full instructions of what to do with this prompt.
   - The only required changes are replacing then placeholders by their values.
   - Other than that, the only acceptable changes are eventual escapings needed and formatting.

4. Collect outputs from both agents

#### Step 2: Adversarial Analysis

Use the Agent tool to spawn the agent `planner:ideas:adversarial-critic` to challenge the generated ideas:

```markdown
Agent(planner:ideas:adversarial-critic):
  prompt:
    Ideas to challenge:

    From Deep Thinker:
    {{deep_thinker_output}}

    From Innovation Explorer:
    {{innovation_output}}
```

**IMPORTANT**:
- Run this agent with the prompt exactly as requested.
- The agent have full instructions of what to do with this prompt.
- The only required changes are replacing then placeholders by their values.
- Other than that, the only acceptable changes are eventual escapings needed and formatting.

1. Receive critique and challenges

#### Step 3: Synthesis

1. Use the Agent tool to spawn the agent `planner:ideas:convergence-synthesizer` to synthesize the ideas into coherent proposals:

   ```markdown
   Agent(planner:ideas:convergence-synthesizer):
     prompt:
       Deep Thinker Output:
       {{deep_thinker_output}}

       Innovation Explorer Output:
       {{innovation_output}}

       Adversarial Critic Analysis:
       {{critic_output}}
   ```

   **IMPORTANT**:
   - Run this agent with the prompt exactly as requested.
   - The agent have full instructions of what to do with this prompt.
   - The only required changes are replacing then placeholders by their values.
   - Other than that, the only acceptable changes are eventual escapings needed and formatting.

2. Receive synthesized proposals

#### Step 4: User Interaction

1. Use the Agent tool to spawn the agent `planner:ideas:facilitator` to present proposals and gather user feedback:

   ```markdown
   Agent(planner:ideas:facilitator):
     prompt:
       Round: {{current_round}} of {{max_rounds}}

       Synthesized Proposals:
       {{synthesis_output}}
   ```

   **IMPORTANT**:
   - Run this agent with the prompt exactly as requested.
   - The agent have full instructions of what to do with this prompt.
   - The only required changes are replacing then placeholders by their values.
   - Other than that, the only acceptable changes are eventual escapings needed and formatting.

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
