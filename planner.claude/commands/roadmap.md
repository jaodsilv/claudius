---
description: Create a project roadmap with phases, milestones, and deliverables
argument-hint: "[[--goal] <goal>] [--phases <number>] [--horizon <weeks|months>] [--output <path>]"
allowed-tools: Agent, Read, Write, Edit, Glob, Grep, Bash, WebSearch, TaskCreate, TaskGet, TaskList, TaskUpdate, AskUserQuestion, Skill
model: opus
---

# /planner:roadmap

Create a structured project roadmap for achieving a goal.

## Arguments Parsing

Extract from `$ARGUMENTS`:

- `$goal`: First positional argument. The project goal to roadmap (required).
  Its value is the substring of everything that comes before any flags.
- `$phases`: Number of development phases (default: 4)
- `$horizon`: Planning horizon (e.g., "8 weeks", "3 months". Default: "12 weeks")
- `$output`: Output directory for roadmap (default: "docs/planning/")

## Execution Workflow

### Phase 1: Goal Analysis

1. Use the TaskCreate tool to add the following task(s) to the task list:

   <new-tasks>
   - [ ] Phase 1: Goal Analysis (in_progress)
   - [ ] Phase 2: Context Gathering (pending)
   - [ ] Phase 3: GitHub Integration (pending)
   - [ ] Phase 4: Roadmap Generation (pending)
   - [ ] Phase 5: Output Generation (pending)
   </new-tasks>

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

3. Use the Skill tool to load the skill `planner:roadmapping` for roadmap creation guidance and patterns.

### Phase 3: GitHub Integration

1. Mark Phase 3 as in_progress

2. Check if gh CLI is available:

   ```bash
   gh --version
   ```

3. If gh CLI is available, use the Agent tool to spawn the agent `planner:github:issue-analyzer` to analyze relevant issues:

   ```markdown
   Agent(planner:github:issue-analyzer):
     prompt: Analyze open issues relevant to: $goal
   ```

   **IMPORTANT**:
   - Run this agent with the prompt exactly as requested.
   - The agent have full instructions of what to do with this prompt.
   - The only required changes are replacing then placeholders by their values.
   - Other than that, the only acceptable changes are eventual escapings needed and formatting.

4. Collect issue insights for roadmap integration

### Phase 4: Roadmap Generation

1. Mark Phase 4 as in_progress

2. Use the Agent tool to spawn the agent `planner:creators:roadmap-architect` to design the roadmap:

   ```markdown
   Agent(planner:creators:roadmap-architect):
     prompt:
       Create a roadmap for:
       Goal: $goal
       Phases: $phases
       Horizon: $horizon

       Context gathered:
       {{context_summary}}

       GitHub issues relevant:
       {{github_issues}}
   ```

   **IMPORTANT**:
   - Run this agent with the prompt exactly as requested.
   - The agent have full instructions of what to do with this prompt.
   - The only required changes are replacing then placeholders by their values.
   - Other than that, the only acceptable changes are eventual escapings needed and formatting.

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
