# Brainstorm Pro Plugin

Multi-agent requirements discovery through Socratic dialogue and systematic exploration for software/feature ideation.

## Overview

Brainstorm Pro transforms ambiguous software ideas into actionable specifications through a structured,
multi-phase workflow. It combines interactive Socratic dialogue with automated analysis to produce
comprehensive requirements documentation.

## Key Features

1. **Socratic Dialogue**: Interactive exploration through strategic questioning
2. **Multi-Agent Analysis**: Domain research, technical feasibility, constraint analysis
3. **Structured Output**: Professional specification documents
4. **Session Management**: Pause, resume, and export capabilities
5. **Configurable Depth**: Shallow, normal, or deep exploration modes

## Quick Start

### Start a Brainstorming Session

```text
/brainstorm:start topic: "Your software idea or feature concept"
```

### With Custom Depth

```text
/brainstorm:start topic: "AI-powered code review tool" --depth: deep
```

### With Custom Output Path

```text
/brainstorm:start topic: "Mobile notification system" --output-path: ./specs/notifications/
```

## Workflow Phases

### Phase 1: Socratic Dialogue

The facilitator agent conducts structured questioning to explore:

1. Problem and users
2. Scope and priorities
3. Constraints and edge cases

Rounds based on depth:

1. **Shallow**: 3 rounds (~15-30 min)
2. **Normal**: 5 rounds (~30-60 min)
3. **Deep**: 8 rounds (~60-120 min)

### Phase 2: Domain Exploration

The domain explorer researches:

1. Market landscape and competitors
2. Best practices and patterns
3. User expectations
4. Compliance considerations

### Phase 3: Technical Analysis

The technical analyst evaluates:

1. Feasibility assessment
2. Architecture options
3. Technology recommendations
4. Complexity estimation

### Phase 4: Constraint Analysis

The constraint analyst identifies:

1. Technical constraints
2. Business constraints
3. Resource constraints
4. Trade-offs and conflicts

### Phase 5: Requirements Synthesis

The requirements synthesizer produces:

1. Functional requirements (MoSCoW prioritized)
2. Non-functional requirements
3. Dependency mapping
4. Gap identification

### Phase 6: Document Generation

The specification writer creates:

1. Comprehensive specification document
2. Structured requirements document
3. Session summary

## Available Commands

| Command | Description |
|---------|-------------|
| `/brainstorm:start` | Start a new brainstorming session |
| `/brainstorm:continue` | Resume an interrupted session |
| `/brainstorm:export` | Regenerate session documents |

## Available Agents

| Agent | Purpose |
|-------|---------|
| `brainstorm-facilitator` | Drives Socratic dialogue |
| `brainstorm-domain-explorer` | Researches market and domain |
| `brainstorm-technical-analyst` | Evaluates technical feasibility |
| `brainstorm-constraint-analyst` | Identifies constraints |
| `brainstorm-requirements-synthesizer` | Consolidates requirements |
| `brainstorm-specification-writer` | Generates final documents |

## Output Artifacts

After a session completes, you'll find:

```text
{output_path}/
├── specification.md    # Full specification document
├── requirements.md     # Structured requirements
└── session-log.md      # Complete session log
```

**Note**: The `summary.md` file is created by the `/brainstorm:export` command for executive summaries.
It is not generated during the main session workflow.

## Parameters

### /brainstorm:start

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `topic` | string | (required) | The idea/feature to explore |
| `--depth` | enum | `normal` | Exploration depth: shallow, normal, deep |
| `--output-path` | string | `./brainstorm-output/` | Where to save outputs |

### /brainstorm:continue

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `--session-path` | string | (required) | Path to session directory |

### /brainstorm:export

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `--session-path` | string | (required) | Path to session directory |
| `--format` | enum | `markdown` | Output format: markdown, pdf, html |

## Best Practices

### Before Starting

1. Have a clear (even if rough) idea of what you want to build
2. Know your target users or audience
3. Have some sense of constraints (budget, timeline, team)

### During the Session

1. Answer questions thoughtfully - quality input produces quality output
2. Don't be afraid to say "I don't know" - that's valuable information
3. Challenge the facilitator's assumptions if they seem wrong
4. Take notes on insights that surprise you

### After the Session

1. Review the specification document critically
2. Address open questions before starting development
3. Share with stakeholders for feedback
4. Use requirements as input for your development process

## Integration with Other Workflows

### TDD Workflow

After brainstorming:

1. Use requirements to inform test design
2. Reference FR/NFR IDs in test cases
3. Use technical analysis for architecture decisions

### Project Planning

After brainstorming:

1. Create GitHub issues from requirements
2. Use complexity estimates for sprint planning
3. Reference constraints in technical decisions

## Troubleshooting

### Session Interrupted

Use `/brainstorm:continue` to resume from the last completed phase.

### Need to Regenerate Documents

Use `/brainstorm:export` to regenerate specification documents from the session log.

### Want Different Depth

Start a new session with the desired depth level. Session logs from different depths can be compared.

## License

MIT License - see repository for details.

## Author

João da Silva - [GitHub](https://github.com/jaodsilv)
