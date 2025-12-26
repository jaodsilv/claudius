# Planner Plugin

Strategic planning plugin for Claude Code with project roadmapping, issue prioritization, and deep ideation capabilities.

## Features

1. **Roadmap Generation** - Create project roadmaps with phases, milestones, and dependencies
2. **Issue Prioritization** - Prioritize GitHub issues using RICE, MoSCoW, or custom frameworks
3. **Requirements Gathering** - Structured requirements discovery with optional brainstorm-pro integration
4. **Multi-Agent Reviews** - Review plans, roadmaps, architecture, and requirements with orchestrated multi-agent analysis
5. **Ultrathink Ideation** - Multi-agent deep ideation using Opus extended thinking

## Multi-Agent Orchestration

All review commands use the **Diverge-Challenge-Synthesize** pattern for higher quality output:

```text
Thorough Mode (default):
┌─────────────────────────────────────────────────────┐
│  Phase 1: Parallel Analysis                         │
│  ├── Domain Reviewer (goal alignment, quality)      │
│  └── Structural Analyzer (patterns, completeness)   │
│                                                     │
│  Phase 2: Adversarial Challenge                     │
│  └── Review Challenger (devil's advocate)           │
│                                                     │
│  Phase 3: Synthesis                                 │
│  └── Review Synthesizer (merge, prioritize)         │
│                                                     │
│  Phase 4: Interactive Discussion                    │
│  └── Present findings, gather user feedback         │
└─────────────────────────────────────────────────────┘
```

Use `--mode quick` to skip orchestration and use a single agent (faster, lower cost).

## Commands

| Command                                 | Description                                                   |
| --------------------------------------- | ------------------------------------------------------------- |
| `/planner:roadmap <goal>`               | Create a project roadmap for achieving a goal                 |
| `/planner:prioritize <issues\|ALL>`     | Prioritize GitHub issues using configurable frameworks        |
| `/planner:gather-requirements <goal>`   | Gather requirements, optionally leveraging brainstorm-pro     |
| `/planner:review-plan <path>`           | Review a plan file with multi-agent analysis                  |
| `/planner:review-roadmap <goal>`        | Review a roadmap against a goal with orchestrated analysis    |
| `/planner:review-prioritization <goal>` | Review prioritization alignment with adversarial challenge    |
| `/planner:review-architecture <goal>`   | Review architecture decisions with multi-perspective analysis |
| `/planner:review-requirements <goal>`   | Review requirements quality with gap analysis                 |
| `/planner:ideas <goal>`                 | Multi-agent Ultrathink ideation session                       |

### Review Command Options

All review commands support:

```text
--mode quick      # Single agent (faster, lower cost)
--mode thorough   # Multi-agent orchestration (default)
```

## Ultrathink Ideation

The `/planner:ideas` command launches a sophisticated multi-agent ideation workflow:

1. **Deep Thinker** (Opus) - Extended thinking with deep reasoning chains
2. **Innovation Explorer** (Sonnet) - Efficient cross-domain research and novel approaches
3. **Adversarial Critic** (Opus) - Devil's advocate stress testing
4. **Convergence Synthesizer** (Opus) - Merges and refines multi-agent ideas
5. **Facilitator** (Sonnet) - Orchestrates session and user interaction

Each round builds on the previous, with user input between rounds to guide direction.

### Model Selection Rationale

- **Opus agents**: Used for deep reasoning, adversarial analysis, and synthesis where quality is paramount
- **Sonnet agents**: Used for research, orchestration, and efficient coordination where speed matters
- **Haiku agents**: Used for fast structural analysis and GitHub data parsing

### Extended Thinking

Opus agents Ultrathink complex problems before generating outputs to enable thorough analysis.

> **Note**: "Ultrathink" is a keyword that triggers Claude's extended thinking mode, enabling deeper reasoning chains.

## Output Location

All artifacts are written to `docs/planning/`:

```text
docs/planning/
├── roadmap.md           # From /planner:roadmap
├── prioritization.md    # From /planner:prioritize
├── requirements.md      # From /planner:gather-requirements
├── ideas/               # From /planner:ideas
│   └── session-*.md
└── reviews/             # From /planner:review-*
    └── *-review-*.md
```

## GitHub Integration

Requires GitHub CLI (`gh`) for issue prioritization:

```bash
# Verify gh is installed
gh --version

# Authenticate if needed
gh auth login
```

The plugin reads:

- Issue details, labels, comments
- Linked pull requests
- Milestone information
- Cross-references and dependencies

## Optional Dependencies

- **brainstorm-pro** - Enhanced requirements gathering via `/brainstorm:start`

## Prioritization Frameworks

### RICE

- **Impact** - Impact per user (3/2/1/0.5/0.25)
- **Confidence** - Estimate confidence (100%/80%/50%)
- **Effort** - Person-weeks required
- Score = (Reach × Impact × Confidence) / Effort

### MoSCoW

- **Must Have** - Critical for delivery
- **Should Have** - Important but not critical
- **Could Have** - Desirable if resources permit
- **Won't Have** - Explicitly excluded

### Weighted Scoring

- Score each item per criterion
- Calculate weighted total

## Usage Examples

### Create a Roadmap

```text
/planner:roadmap Implement user authentication with OAuth2 and SSO support
```

### Prioritize All Issues

```text
/planner:prioritize ALL --framework RICE
```

### Deep Ideation Session

```text
/planner:ideas How can we improve developer experience in our CLI tool? --rounds 3
```

### Review Architecture

```text
/planner:review-architecture Build a scalable notification system --architecture-path docs/architecture.md
```

## License

MIT
