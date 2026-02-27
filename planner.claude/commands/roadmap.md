---
description: Create a project roadmap with phases, milestones, and deliverables
argument-hint: "[[--goal] <goal>] [--phases <number>] [--horizon <weeks|months>] [--output <path>]"
allowed-tools: Task, Read, Write, Edit, Glob, Grep, Bash, WebSearch, TodoWrite, AskUserQuestion, Skill
model: opus
---

# /planner:roadmap

Create a structured project roadmap for achieving a goal.

## Arguments Parsing

Extract from `$ARGUMENTS`:

- `$goal`: Firs positional argument. The project goal to roadmap (required). It's value it the substring of everything that comes before any flags.
- `$phases`: Number of development phases (default: 4)
- `$horizon`: Planning horizon (e.g., "8 weeks", "3 months". Default: "12 weeks")
- `$output`: Output directory for roadmap (default: "docs/planning/")

## Execution Workflow

### Phase 1: Goal Analysis

1. Initialize TodoWrite with phases:
   - Phase 1: Goal Analysis (in_progress)
   - Phase 2: Context Gathering (pending)
   - Phase 3: GitHub Integration (pending)
   - Phase 4: Roadmap Generation (pending)
   - Phase 5: Output Generation (pending)

2. Validate goal is provided

3. If goal is vague, use AskUserQuestion:
   - What specific outcome do you want?
   - What constraints exist (timeline, resources)?
   - What's explicitly out of scope?

### Phase 2: Context Gathering

1. Mark Phase 2 as in_progress

2. Search for existing context:
   - Requirements documents
   - Existing plans or specs
   - Related issues or PRs

3. Load the `planner:roadmapping` skill for roadmap creation guidance and patterns.

### Phase 3: GitHub Integration

1. Mark Phase 3 as in_progress

2. Check if gh CLI is available:

   ```bash
   gh --version
   ```

3. If gh CLIT is available, launch the `planner:github:issue-analyzer` agent with the prompt:

   ```text
   Analyze open issues relevant to: $goal

   Identify:
   - Issues that relate to this goal
   - Existing work in progress
   - Potential blockers
   - Effort indicators from labels
   ```

4. Collect issue insights for roadmap integration

### Phase 4: Roadmap Generation

1. Mark Phase 4 as in_progress

2. Launch `planner:creators:roadmap-architect` agent with the prompt:

   ```text
   Create a roadmap for:
   Goal: $goal
   Phases: $phases
   Horizon: $horizon

   Context gathered:
   {{context_summary}}

   GitHub issues relevant:
   {{github_issues}}

   Design phases with:
   - Clear objectives per phase
   - SMART milestones
   - Concrete deliverables
   - Dependencies mapped
   - Risks identified
   ```

3. Receive roadmap structure from agent

### Phase 5: Output Generation

1. Mark Phase 5 as in_progress

2. Ensure output directory exists:

   ```bash
   mkdir -p {{output}}
   ```

3. Write roadmap using the template to `{{output}}/roadmap.md`

4. Generate Mermaid Gantt chart visualization

5. If GitHub issues found, add section for:
   - Issue-to-phase mapping
   - Suggested issue updates

### Completion

1. Mark all todos as completed

2. Present summary:

   ```markdown
   ## Roadmap Created

   **Goal**: {{goal}}
   **Phases**: {{phases}}
   **Horizon**: {{horizon}}

   ### Generated Artifacts

   1. `{{output}}/roadmap.md` - Full roadmap document

   ### Key Phases

   1. {{phase1_name}}: {{phase1_summary}}
   2. {{phase2_name}}: {{phase2_summary}}
      ...

   ### Critical Milestones

   1. {{milestone1}}
   2. {{milestone2}}

   ### Recommended Next Steps

   1. Review roadmap with stakeholders
   2. Create GitHub issues for Phase 1 tasks
   3. Set up milestone tracking
   ```

## Error Handling

1. **Goal not provided**: Prompt user for goal
2. **gh CLI not available**: Continue without GitHub integration. Roadmap generation
   still works; GitHub issue mapping is skipped.
3. **No relevant issues**: Note in output and continue
4. **Output directory issues**: Report error and suggest fix

## Usage Examples

### Basic Usage

```text
/planner:roadmap Implement user authentication with OAuth2
```

### With Options

```text
/planner:roadmap Build a notification system --phases 5 --horizon "6 months"
```

### Custom Output

```text
/planner:roadmap API v2 redesign --output docs/api-v2/
```
