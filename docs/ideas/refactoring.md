# Plugin Architecture Refactoring: Synthesis Document

**Session**: Ultrathink Ideation (5 rounds)
**Date**: 2026-01-19
**Plugins in Scope**: gitx, review-loop

## Executive Summary

After 5 rounds of multi-agent ideation and practical experimentation, we conclude:

1. **The current command→agent→skill hierarchy is architecturally sound**
2. **Selective extraction via archetypes** - Different agents need different treatment
3. **Two-Consumer Gate** - Only extract methodology when 2+ actual consumers exist
4. **`context: fork` + `agent` field works in user config but NOT in plugins** (current bug)
5. **Design for what works now; prepare for skill-primary future**

## Experiment Results

We tested `context: fork` + `agent` field behavior:

| Scenario | Result |
|----------|--------|
| Plugin: `agent` field in skill | NOT loaded (bug) |
| User config: `agent` field in skill | Works - agent footer appeared |
| Skill body vs Agent body | Skill body is primary, agent supplements |

**Conclusion**: The architecture IS designed for skill-with-agent-context, but there's a plugin-specific bug. Design for current capabilities; treat bug fix as future bonus.

## Archetype Classification Framework

### Agent Archetypes

| Archetype | Description | Extraction Strategy |
|-----------|-------------|---------------------|
| **Worker** | Executes defined tasks | HIGH - procedures are transferable |
| **Specialist** | Domain expert with methodology | SELECTIVE - extract taxonomies, keep judgment |
| **Orchestrator** | Coordinates multiple agents | LOW - coordination IS identity |
| **Analyzer** | Reviews and produces analysis | MEDIUM - extract output templates, keep process |

### Important Caveats (from Adversarial Analysis)

1. **Archetypes are heuristics, not rules** - Real agents blend roles
2. **Extraction benefit is orthogonal to archetype** - Complexity and reuse matter more
3. **Accept ambiguity** - Some agents fit multiple archetypes; use judgment

## Decision Framework

```
Stage 1: Is there a second consumer for the methodology?
  No  → Keep methodology in agent
  Yes → Go to Stage 2

Stage 2: What is the agent archetype?
  Worker     → Extract most methodology
  Specialist → Extract domain knowledge/taxonomies, keep analytical judgment
  Orchestrator → Keep orchestration, extract only utilities
  Analyzer   → Extract output templates/frameworks, keep analysis criteria

Stage 3: Preserve Discovery
  Leave summary stub in agent pointing to extracted skill
```

### "Consumer" Definition

A consumer is:
- An agent that uses the methodology via `Skill` tool
- An agent that has the skill in frontmatter `skills:` field
- A command that invokes the skill directly

NOT a consumer:
- Hypothetical future use
- User invoking skill via `/skill-name`

### Clarity Override

If extraction significantly improves agent readability (>100 lines reduced, clearer separation of concerns), extraction is allowed even with one consumer. Document the rationale.

## Concrete Recommendations

### Recommendation 1: Apply Archetype-Driven Extraction

**Confidence**: HIGH (works with current capabilities)

Systematically classify agents and apply prescribed extraction strategy.

#### gitx Agent Classification

| Agent | Lines | Archetype | Current Skills | Extraction Action |
|-------|-------|-----------|----------------|-------------------|
| `worktree/creator` | 112 | Worker | managing-worktrees | DONE - keep as-is |
| `worktree/remover` | ~80 | Worker | managing-worktrees | DONE - keep as-is |
| `branch/merger` | ~60 | Worker | managing-branches | DONE - keep as-is |
| `branch/remover` | ~50 | Worker | managing-branches | DONE - keep as-is |
| `issue/fix-orchestrator` | 360 | Orchestrator | parsing-issue-references | KEEP - coordination is identity |
| `conflict-resolver/conflict-analyzer` | 192 | Analyzer | classifying-issues-and-failures | Consider: extract conflict taxonomy |
| `address-review/review-comment-analyzer` | ~150 | Analyzer | categorizing-review-concerns | DONE - taxonomy extracted |
| `pr/creator` | ~100 | Worker | performing-pr-preflight-checks | Consider: extract PR creation procedure |

#### review-loop Agent Classification

| Agent | Archetype | Extraction Action |
|-------|-----------|-------------------|
| `orchestrator` | Orchestrator | KEEP - phase coordination is identity |
| `round-executor` | Worker | Consider: extract phase templates |
| `approval-verifier` | Analyzer | KEEP - decision logic specific |

### Recommendation 2: Keep Orchestrators Intact

**Confidence**: VERY HIGH

The `fix-orchestrator` and `review-loop:orchestrator` should NOT be refactored. Their coordination logic IS their identity.

**Rationale**:
- Phase coordination is not reusable across different workflows
- State management is specific to each orchestration context
- Orchestrators already delegate to specialized agents
- Extracting coordination leaves hollow shells

### Recommendation 3: Strict Two-Consumer Gate

**Confidence**: HIGH

Do not extract methodology unless two actual consumers exist. Resist premature abstraction.

**Implementation**:
- Before creating a new skill, identify two existing consumers
- Document consumer list in skill's SKILL.md
- Review PRs that extract skills for consumer count
- Allow discovery stubs without extraction

### Recommendation 4: Prepare for Skill-Primary Future

**Confidence**: MEDIUM (contingent on bug fix)

When the `context: fork` + `agent` bug is fixed in plugins:
- Skills with `agent` field can become direct entry points
- Worker agents can convert to persona files
- Commands become optional UX layer

**Preparation Actions**:
1. Track bug status in Claude Code GitHub issues
2. Document skill-primary pattern in plugin README
3. Time-box wait: if not fixed in 6 months, design without it

### Recommendation 5: Hybrid Progressive Migration

**Confidence**: HIGH

New functionality should follow skill-first thinking. Existing functionality follows conservative extraction.

**For New Features**:
1. Ask: "What is the reusable methodology here?"
2. Create skill first if methodology is non-trivial
3. Add agent only if persona/identity is needed beyond methodology
4. Add command only if user-facing entry point is needed

**For Existing Features**:
1. Apply Two-Consumer Gate strictly
2. Use discovery stubs when extracting
3. Don't refactor working orchestrators

## Rejected Approaches

| Approach | Verdict | Reason |
|----------|---------|--------|
| Skill-First Entry Points (Now) | WEAK | Bug prevents plugin support; commands have UX value |
| Skill Injection Optimization | WEAK | Confuses declaration with instruction |
| Command-Centric Orchestration | WEAK | Commands are wrong layer for orchestration |
| Skill-as-Contract Pattern | WEAK | Overengineered; requires new tooling |

## Risk Assessment

| Factor | Refactor Now | Wait for Bug Fix |
|--------|--------------|------------------|
| Bug uncertainty | High risk | Low risk |
| Technical debt | Starts accumulating | Continues accumulating |
| Effort efficiency | May need rework | Work done once correctly |

**Verdict**: Split refactoring into two phases:
1. **Now**: Extract skills based on current capabilities (archetype + two-consumer gate)
2. **After fix**: Convert thin commands to skill-with-agent pattern

## Blind Spots to Address

1. **Skill versioning**: What happens when a skill changes but agents expect old behavior?
2. **Cross-plugin dependencies**: Changes to gitx skills could break review-loop
3. **Testing strategy**: How to test skills in isolation?
4. **Performance**: More skills = more file reads = slower startup?
5. **Conflict resolution**: What if an agent loads two skills with conflicting guidance?

## Emerging Patterns

1. **Orchestration Immunity**: Orchestrators resist extraction; coordination is their value
2. **Taxonomy as Natural Extraction Point**: Classification systems are cleanest extraction candidates
3. **Output Templates as Extraction Candidates**: Structured output formats can be extracted without changing agent logic
4. **Worker Agents Already Aligned**: Existing gitx workers have corresponding skills (managing-branches, managing-worktrees)
5. **Discovery Stubs Enable Gradual Migration**: Agents can reference skills without being rewritten

## Concrete Next Steps

### Immediate (This PR)

1. ~~Run `context: fork` experiment~~ DONE
2. Document findings in this synthesis
3. Clean up test files from gitx

### Short-term (Next Sprint)

1. Audit gitx agents for Two-Consumer Gate violations
2. Add discovery stubs to agents that reference skills
3. Consider extracting conflict classification taxonomy

### Medium-term (When Bug Fixed)

1. Convert one worker agent to skill-primary pattern as proof-of-concept
2. Document migration playbook
3. Evaluate command consolidation opportunities

## Appendix: Feature Capabilities Reference

| Feature | Location | Purpose |
|---------|----------|---------|
| `context: fork` | Skills AND Commands | Run in isolated subagent context |
| `agent` field | Skills AND Commands | Specify which agent provides config when forked |
| `user-invocable: false` | Skills | Hide from slash menu, keep programmatic access |
| `disable-model-invocation: true` | Skills | Block Skill tool invocation |
| `skills:` in agent frontmatter | Agents | Inject skill content at startup |
| `hooks` | Skills AND Commands | Run shell commands on events |

## Sources

- Official Claude Code Skills documentation (2026-01-19)
- Official Best Practices documentation (2026-01-19)
- Practical experiment with `context: fork` + `agent` field
- CrewAI Agent/Task separation pattern
- Terraform module/provider pattern
- Microservices decomposition principles
