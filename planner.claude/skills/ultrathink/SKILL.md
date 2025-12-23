---
name: Ultrathink Ideation Methodology
description: This skill should be used when the user asks for "deep ideation", "creative brainstorming", "novel solutions", "Ultrathink session", or needs multi-agent ideation with extended thinking and adversarial analysis.
version: 1.0.0
---

# Ultrathink Ideation Methodology

Multi-agent deep ideation combining extended thinking, iterative refinement, and adversarial challenge for generating robust, novel solutions.

## Core Principles

### Extended Thinking

Use Opus model with extended thinking enabled:

1. **Deep Exploration** - Allow 10+ minute reasoning chains
2. **Multiple Hypotheses** - Generate diverse solution paths
3. **Edge Case Analysis** - Explore corner cases thoroughly
4. **Emergent Insights** - Let unexpected connections surface

### Multi-Pass Iteration

Each round builds on the previous:

1. **First Pass**: Broad exploration, divergent thinking
2. **Second Pass**: Depth on promising ideas
3. **Third Pass**: Refinement and synthesis
4. **Nth Pass**: Polish and finalize

### Adversarial Challenge

Every idea is stress-tested:

1. **Assumption Questioning** - Challenge implicit beliefs
2. **Failure Mode Analysis** - How could this fail?
3. **Counter-Arguments** - What's the opposite view?
4. **Stress Testing** - Edge cases and extremes

## Ideation Process

### Phase 1: Context Gathering

Before ideation, gather:

1. **Goal Definition**
   - What problem are we solving?
   - What does success look like?
   - What constraints exist?

2. **Existing Context**
   - Relevant documents (roadmaps, requirements)
   - Open issues and discussions
   - Previous attempts and learnings

3. **Scope Boundaries**
   - What's in scope?
   - What's explicitly out of scope?
   - Time and resource constraints?

### Phase 2: Divergent Ideation

Launch parallel ideation agents:

```text
┌─────────────────┐  ┌─────────────────┐
│  Deep Thinker   │  │   Innovation    │
│    (Opus)       │  │    Explorer     │
│                 │  │    (Opus)       │
│ Extended        │  │                 │
│ thinking on     │  │ Cross-domain    │
│ core problem    │  │ research and    │
│                 │  │ novel approaches│
└────────┬────────┘  └────────┬────────┘
         │                    │
         └──────────┬─────────┘
                    ▼
              Idea Pool
```

#### Deep Thinker Prompt Pattern

```text
You are engaging in deep, extended thinking about: [TOPIC]

Context:
[CONTEXT]

Goal:
[GOAL]

Take your time. Explore this problem deeply:

1. What is the core essence of this problem?
2. What are the non-obvious dimensions?
3. What assumptions are we making?
4. What would a 10x solution look like?
5. What patterns from other domains apply?

Generate multiple distinct solution approaches.
For each approach, explore implications deeply.
```

#### Innovation Explorer Prompt Pattern

```text
You are exploring innovative approaches to: [TOPIC]

Research and explore:
1. How have others solved similar problems?
2. What cutting-edge technologies apply?
3. What would a completely different industry do?
4. What emerging trends could we leverage?
5. What would a naive newcomer try?

Seek inspiration from:
- Adjacent industries
- Academic research
- Startup innovations
- Historical solutions
- Unconventional sources
```

### Phase 3: Adversarial Analysis

Challenge each idea with the Adversarial Critic:

```text
┌─────────────────┐
│   Adversarial   │
│     Critic      │
│    (Opus)       │
│                 │
│ Challenge each  │
│ idea rigorously │
└─────────────────┘
```

#### Critic Prompt Pattern

```text
You are a rigorous critic analyzing proposed solutions.

Ideas to challenge:
[IDEAS]

For each idea, analyze:

1. ASSUMPTIONS
   - What must be true for this to work?
   - Which assumptions are most fragile?
   - What if assumptions are wrong?

2. FAILURE MODES
   - How could this fail completely?
   - What are the degraded failure states?
   - What's the worst-case scenario?

3. COUNTER-ARGUMENTS
   - What would opponents say?
   - What alternative approaches exist?
   - Why might this be the wrong direction?

4. STRESS TESTS
   - What happens at 10x scale?
   - What if resources are halved?
   - How does this handle edge cases?

Be thorough but fair. Identify genuine weaknesses,
not just theoretical concerns.
```

### Phase 4: Convergence Synthesis

Merge insights into coherent proposals:

```text
┌─────────────────┐
│   Convergence   │
│   Synthesizer   │
│    (Opus)       │
│                 │
│ Merge and       │
│ refine ideas    │
└─────────────────┘
```

#### Synthesis Prompt Pattern

```text
You are synthesizing multi-agent ideation outputs.

Deep Thinker Output:
[OUTPUT]

Innovation Explorer Output:
[OUTPUT]

Adversarial Critic Analysis:
[ANALYSIS]

Create coherent proposals by:

1. PATTERN IDENTIFICATION
   - What themes emerge across outputs?
   - What synergies exist between ideas?
   - What complementary strengths combine?

2. CRITICISM INTEGRATION
   - Which ideas survived criticism?
   - How can weak ideas be strengthened?
   - What modifications address concerns?

3. PROPOSAL FORMATION
   - Create 3-5 distinct proposals
   - Each should be complete and actionable
   - Rank by viability and impact

4. GAP ANALYSIS
   - What remains unexplored?
   - What questions need user input?
   - What requires further research?
```

### Phase 5: Interactive Refinement

Present to user for feedback:

```text
┌─────────────────┐
│   Facilitator   │
│   (Sonnet)      │
│                 │
│ Present ideas   │
│ Gather feedback │
│ Guide next round│
└─────────────────┘
```

#### Presentation Format

```markdown
## Ultrathink Session: Round [N]

### Top Proposals

#### Proposal 1: [Name]

**Viability**: [Score]/10 | **Novelty**: [Score]/10

**Summary**: [2-3 sentences]

**Key Innovation**: [What makes this unique]

**Challenges Identified**:

1. [Challenge from critic]
2. [Challenge from critic]

**Open Questions**:

1. [Question requiring input]

---

### User Input Requested

1. Which proposals resonate most?
2. What aspects need deeper exploration?
3. Any new directions to consider?
4. Should we proceed to another round?
```

## Round Management

### When to Continue

Continue to another round when:

- User requests deeper exploration
- Major new directions identified
- Proposals still lack clarity
- Important aspects unexplored

### When to Conclude

Stop ideation when:

- User is satisfied with proposals
- Diminishing returns observed
- Time/round limit reached
- Clear winner emerged

### Between-Round Synthesis

Between rounds, preserve:

- Top proposals
- Key insights
- User feedback
- Open questions

## Quality Criteria

### Idea Evaluation

Score each proposal on:

| Criterion   | Description                       | Weight |
| ----------- | --------------------------------- | ------ |
| Novelty     | How new/different is this?        | 20%    |
| Feasibility | Can this be implemented?          | 25%    |
| Impact      | Will this solve the problem well? | 30%    |
| Robustness  | Did it survive criticism?         | 25%    |

### Novelty Assessment

```text
10 = Revolutionary, paradigm-shifting
8 = Highly innovative, new approach
6 = Creative combination of existing ideas
4 = Incremental improvement
2 = Standard solution
```

### Feasibility Assessment

```text
10 = Straightforward, clear path
8 = Achievable with known methods
6 = Challenging but doable
4 = Requires significant breakthroughs
2 = Highly speculative
```

### Impact Assessment

```text
10 = Completely solves problem, exceeds goals
8 = Significantly addresses problem
6 = Partially addresses problem
4 = Minor improvement
2 = Marginal impact
```

### Robustness Assessment

```text
10 = Survived all challenges intact
8 = Minor adjustments needed
6 = Moderate concerns addressed
4 = Significant weaknesses remain
2 = Fundamental issues unresolved
```

## Output Format

### Session Summary

```markdown
# Ultrathink Session: [Topic]

**Session ID**: [ID]
**Rounds Completed**: [N]
**Duration**: [Time]

## Executive Summary

[3-5 sentence summary of outcomes]

## Top Proposals

### 1. [Proposal Name]

**Scores**: Viability [X] | Novelty [X] | Impact [X] | Robustness [X]

[Detailed description]

### 2. [Proposal Name]

...

## Key Insights

1. [Insight from ideation]
2. [Insight from criticism]
3. [Insight from synthesis]

## Discarded Ideas

| Idea   | Reason Discarded |
| ------ | ---------------- |
| [Idea] | [Reason]         |

## Open Questions

1. [Remaining question]

## Recommended Next Steps

1. [Action item]
2. [Action item]
```

## Best Practices

1. **Start with clear goals** - Vague problems lead to vague ideas
2. **Embrace divergence first** - Don't converge too early
3. **Take criticism seriously** - Weak ideas fail fast
4. **Iterate with purpose** - Each round should deepen, not repeat
5. **Involve the user** - Their feedback is essential
6. **Document everything** - Ideas may be useful later
7. **Know when to stop** - Diminishing returns are real
8. **Follow through** - Great ideas need execution
