---
description: Reviews architecture decisions with multi-agent orchestration. Use for validating technical designs against goals.
allowed-tools: Task, Read, Glob, Grep, WebSearch, Skill, AskUserQuestion, TodoWrite
argument-hint: <goal|requirements-path> [--architecture-path <path>] [--mode <quick|thorough>]
model: opus
---

# /planner:review-architecture

Reviews architecture decisions with multi-agent orchestration for alignment with goals and requirements.

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
  required: [context]
```

## Workflow

### 1. Load Skill

Use Skill tool: `planner:orchestrating-reviews`

### 2. Domain Context

**Artifact Type**: architecture
**Primary Artifact Path**: `{{architecture_path}}` (discover via Glob if not provided)
**Domain Reviewer Agent**: `planner:planner:architecture-reviewer`
**Evaluation Dimensions**:

- Technical Soundness - Are design decisions well-justified?
- Scalability - Can the architecture handle growth?
- Security - Are security considerations addressed?
- Maintainability - Is the design modular and evolvable?
- Trade-offs - Are alternatives and trade-offs documented?

## Usage Examples

```text
/planner:review-architecture "Build scalable notification system"
/planner:review-architecture "API v2" --mode quick
/planner:review-architecture docs/requirements.md --architecture-path docs/arch.md
```

## Error Handling

- Context not provided: Prompt user for goal or requirements
- Architecture not found: Search with Glob, present options
- Agent timeout: Report partial results
- Multiple architecture docs found: Present list, ask user to select primary
- Diagram files not renderable: Note in report, continue with text analysis
- Missing referenced dependencies: Flag as finding, include in review output
