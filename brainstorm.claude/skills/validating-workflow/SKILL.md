---
name: brainstorm:validating-workflow
description: >-
  Validates brainstorming phase outputs before proceeding to next phase. Use when assessing quality gates between workflow phases.
allowed-tools:
model: opus
---

# Workflow Validation

Validates brainstorming phase outputs before proceeding to next phase. Use when assessing quality gates between workflow phases.

## When to Use

- After each brainstorm phase completes
- Before proceeding to the next phase
- When determining if early exit is appropriate
- When quality concerns arise during execution

## Validation Gates

### Gate 1: Post-Dialogue (After Phase 1)

**Criteria**:

- Clarity level is Medium or High
- At least 3 key insights captured
- Problem statement is articulated
- Target users are identified

**Pass**: Proceed to parallel analysis (Phases 2-4)
**Fail**: Additional dialogue batch needed

### Gate 2: Post-Analysis (After Phases 2-4)

**Criteria**:

- All three analysis phases completed
- Each analysis has at least 2 actionable findings
- No critical gaps identified
- Risks/constraints are documented

**Pass**: Proceed to synthesis (Phase 4.5)
**Fail**: Review incomplete analyses and rerun

### Gate 3: Post-Synthesis (After Phase 4.5)

**Criteria**:

- Unified context is coherent
- Conflicts between analyses are documented
- Recommendations align across analyses
- Clear direction identified for requirements

**Pass**: Proceed to requirements synthesis (Phase 5)
**Fail**: Re-run synthesis with clarifications

### Gate 4: Post-Requirements (After Phase 5)

**Criteria**:

- At least 5 requirements documented
- All requirements have SMART validation criteria
- MoSCoW prioritization applied
- Dependencies mapped

**Pass**: Proceed to specification (Phase 6)
**Fail**: Refine and consolidate requirements

### Gate 5: Post-Specification (After Phase 6)

**Criteria**:

- Document is complete (all required sections)
- No placeholder content remaining
- Cross-references valid
- Executive summary present

**Pass**: Session complete, ready for use
**Fail**: Refine specification

## Gate Check Template

For each gate, perform these steps:

1. **List criteria being checked** - Reference the gate definition above
2. **Assess each criterion**:
   - Record status: Pass/Fail
   - Note specific evidence or gaps
3. **Overall gate status**:
   - All criteria Pass = Gate Pass
   - Any criterion Fail = Gate Fail
4. **If Fail**: Specify remediation needed
   - Which analyses need attention
   - Which criteria were not met
   - Next action to take

## Integration with Start Command

The `start` command invokes this skill at phase transitions to:

- Verify quality before proceeding
- Capture gaps early
- Enable early exit when appropriate
- Track validation decisions in session log

## Phase Dependencies

```text
Phase 1 (Dialogue)
    ↓ [Gate 1]
Phases 2-4 (Parallel Analysis)
    ↓ [Gate 2]
Phase 4.5 (Synthesis)
    ↓ [Gate 3]
Phase 5 (Requirements)
    ↓ [Gate 4]
Phase 6 (Specification)
    ↓ [Gate 5]
Complete
```
