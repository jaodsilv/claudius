---
description: Gather and structure project requirements, optionally using brainstorm-pro
allowed-tools: Task, Read, Write, Glob, Grep, Skill, AskUserQuestion, WebSearch, TodoWrite
argument-hint: <goal> [--use-brainstorm] [--depth <shallow|normal|deep>] [--output <path>]
---

# /planner:gather-requirements

Gather requirements for a goal through structured discovery, optionally leveraging the brainstorm-pro plugin.

## Input Processing

Arguments: `<arguments>$ARGUMENTS</arguments>`

Parse the arguments:
1. `$goal`: Goal to gather requirements for (required)
2. `$use_brainstorm`: Use brainstorm-pro if available (default: auto-detect)
3. `$depth`: Exploration depth (default: "normal")
4. `$output`: Output path (default: "docs/planning/")

## Parameters Schema

```yaml
gather-requirements-arguments:
  type: object
  properties:
    goal:
      type: string
      description: The goal to gather requirements for
    use_brainstorm:
      type: boolean
      default: null
      description: Force use of brainstorm-pro (null = auto-detect)
    depth:
      type: string
      enum: [shallow, normal, deep]
      default: normal
      description: Exploration depth
    output:
      type: string
      default: "docs/planning/"
      description: Output directory
  required:
    - goal
```

## Execution Workflow

### Phase 1: Plugin Detection

1. Initialize TodoWrite:
   - Phase 1: Setup (in_progress)
   - Phase 2: Requirements Gathering (pending)
   - Phase 3: Synthesis (pending)
   - Phase 4: Documentation (pending)

2. Check for brainstorm-pro plugin:
   - Look for `brainstorm.claude/.claude-plugin/plugin.json`
   - Or check installed plugins

3. If brainstorm-pro available AND (use_brainstorm == true OR null):
   - Inform user: "Brainstorm Pro detected - using enhanced discovery"
   - Go to Phase 2A (Brainstorm Integration)

4. Otherwise:
   - Go to Phase 2B (Standalone Gathering)

### Phase 2A: Brainstorm Integration

If using brainstorm-pro:

1. Delegate to brainstorm:

   /brainstorm:start topic: "{{goal}}" --depth: {{depth}} --output-path: {{output}}
   ```

2. Wait for brainstorm completion

3. Read brainstorm outputs:
   - `{{output}}/specification.md`
   - `{{output}}/requirements.md`

4. Transform to planner format:
   - Extract functional requirements
   - Extract non-functional requirements
   - Map stakeholders
   - Document constraints

5. Proceed to Phase 3

### Phase 2B: Standalone Gathering

If not using brainstorm:

1. Mark Phase 2 as in_progress

2. Launch `planner-requirements-gatherer` agent:
   ```
   Use Task tool with planner-requirements-gatherer agent:

   Gather requirements for: {{goal}}
   Depth: {{depth}}

   Conduct structured requirements discovery:

   1. Understand the problem space
   2. Identify stakeholders and users
   3. Discover functional requirements
   4. Discover non-functional requirements
   5. Document constraints
   6. Note assumptions

   Be interactive - ask clarifying questions as needed.
   ```

3. The agent will interact with user through AskUserQuestion

4. Receive structured requirements

### Phase 3: Synthesis

1. Mark Phase 3 as in_progress

2. Synthesize requirements:
   - Apply SMART criteria to each requirement
   - Prioritize using MoSCoW
   - Check for conflicts
   - Identify gaps
   - Note open questions

3. Load prioritization skill for framework guidance:

   Use Skill tool to load: planner:prioritization
   ```

4. Create traceability matrix (requirements → goals)

### Phase 4: Documentation

1. Mark Phase 4 as in_progress

2. Ensure output directory:
   ```bash
   mkdir -p {{output}}
   ```

3. Write requirements document to `{{output}}/requirements.md`

4. Use the requirements-summary template

5. Include:
   - Executive summary
   - Functional requirements (MoSCoW prioritized)
   - Non-functional requirements
   - Stakeholders
   - Constraints
   - Assumptions
   - Open questions
   - Traceability matrix

### Completion

Present summary:

## Requirements Gathered

**Goal**: {{goal}}
**Method**: {{brainstorm or standalone}}
**Depth**: {{depth}}

### Summary

- **Functional Requirements**: {{count}}
  - Must Have: {{must_count}}
  - Should Have: {{should_count}}
  - Could Have: {{could_count}}

- **Non-Functional Requirements**: {{nfr_count}}

- **Stakeholders Identified**: {{stakeholder_count}}

### Key Requirements

1. {{fr1_name}}: {{fr1_summary}}
2. {{fr2_name}}: {{fr2_summary}}

### Open Questions

1. {{question1}}

### Output

See `{{output}}/requirements.md` for full documentation.

### Recommended Next Steps

1. Review requirements with stakeholders
2. Validate with technical team
3. Create roadmap: `/planner:roadmap {{goal}}`
```

## Error Handling

1. **Goal not provided**: Prompt for goal
2. **Brainstorm requested but not available**: Fall back to standalone
3. **User not responsive**: Document current state, allow resume

## Usage Examples

### Basic Usage

```
/planner:gather-requirements Build a user notification system
```

### Force Brainstorm

```
/planner:gather-requirements API authentication redesign --use-brainstorm
```

### Deep Exploration

```
/planner:gather-requirements Mobile app launch --depth deep
```
