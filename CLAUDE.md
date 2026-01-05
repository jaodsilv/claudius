# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
> "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
> document are to be interpreted as described in
> [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

## Custom Slash Commands and Sub-Agents Instructions

1. Follow the slash command/agent instructions thoroughly, do not skip any steps unless explicitly stated.
2. Do not assume anything without reading the instructions.
3. To add additional steps request explicit approval.

## Repository Overview

This is a personal configuration repository for Claude Code containing a comprehensive
plugin ecosystem with 60+ agents, 40+ commands, and 30+ skills organized into
specialized plugin directories.

## Plugin Ecosystem

### Core Plugins

#### dotclaude/

**Purpose**: General-purpose Claude Code configurations (legacy, no longer mounted as ~/.claude)

**Contents**:

1. `agents/` - 5 agents (coding-task-orchestrator, curator, prompt-to-pipeline-architect, pr-reviewer-2, walkthrough-generator)
2. `commands/` - 3 commands in 2 groups (coding-task/start, project/create, project/create-data)
3. `instructions/` - Agent creation guidelines
4. `shared/` - 7 reference documents (coding-task-workflow, conventional-branch, conventional-commits, rfc2119, semver, etc.)
5. `output-styles/` - 1 output style (candidate-response)
6. `skills/` - 16 skills in categories:
   - Code quality (1)
   - Conventional standards (2): branch, commits
   - Language-specific reviews (7): Go, Java, Markdown, Mermaid, Python, Rust, TypeScript
   - Principles (3): performance, security, SOLID
   - TDD (2): approach-selection, workflow
   - Job hunting (1)
7. `plugins/` - Plugin configurations

#### gitx/

**Purpose**: Extended Git/GitHub workflow plugin with multi-agent orchestration
**Contents**:

1. 14 agents in 4 groups:
   - `conflict-resolver/` - 3 agents for conflict resolution
   - `fix-issue/` - 4 agents for issue-to-PR workflow
   - `pr-create/` - 3 agents for PR creation
   - `respond/` - 4 agents for PR response handling
2. 15 commands: worktree, remove-worktree, remove-branch, rebase, merge, ignore,
   commit-push, next-issue, fix-issue, comment-to-issue, comment-to-pr, pr,
   respond, update-pr, merge-pr
3. 2 skills: conventional-commits, conventional-branch

**See**: `gitx/README.md` for detailed documentation

#### cc/

**Purpose**: Meta-toolkit for creating and improving Claude Code plugin components
**Contents**:

1. 13 agents:
   - Creator agents (4): command, skill, orchestration, output-style
   - Improver agents (6): command, agent, skill, plugin, orchestration, output-style
   - Architect agent (1): orchestration
   - Workflow agents (2): change-planner, component-writer
2. 11 commands: create-command, create-skill, create-orchestration,
   create-output-style, improve-command, improve-agent, improve-skill,
   improve-plugin, improve-orchestration, improve-output-style, bump-version
3. 2 skills: improvement-workflow, orchestration-patterns

**See**: `cc/README.md` for detailed documentation

#### planner.claude/

**Purpose**: Strategic planning with roadmapping, prioritization, and deep ideation
**Contents**:

1. 16 agents in 3 groups:
   - `github/` - 2 agents (issue-analyzer, issue-relationship-mapper)
   - `ideas/` - 5 agents (adversarial-critic, convergence-synthesizer, deep-thinker,
     facilitator, innovation-explorer)
   - `planner/` - 9 agents (architecture-reviewer, plan-reviewer, prioritization-engine,
     requirements-gatherer, requirements-reviewer, review-analyzer, review-challenger,
     review-synthesizer, roadmap-architect)
2. 9 commands: roadmap, prioritize, gather-requirements, review-plan,
   review-roadmap, review-prioritization, review-architecture, review-requirements,
   ideas
3. Multi-agent "Ultrathink" ideation with Opus extended thinking

**See**: `planner.claude/README.md` for detailed documentation

#### brainstorm.claude/

**Purpose**: Multi-agent requirements discovery through Socratic dialogue
**Contents**:

1. 6 agents: facilitator, domain-explorer, technical-analyst, constraint-analyst, requirements-synthesizer, specification-writer
2. 3 commands: start, continue, export
3. 1 skill: brainstorming
4. Templates for requirements and session summaries

**See**: `brainstorm.claude/README.md` for detailed documentation

### Specialized Plugins

#### doc-understanding.claude/

**Purpose**: Documentation downloading, conversion, and processing
**Contents**:

1. 4 agents: downloader, batch-downloader, converter, conversion-verifier
2. 1 command: /docs:download

**See**: `doc-understanding.claude/README.md` for detailed documentation

#### job-hunting.claude/

**Purpose**: Job hunting workflow configurations
**Contents**:

1. 19 agents:
   - Cover letter evaluators (14): ATS, communication, false-assertion-cleaner,
     impact, keywords, overlap, personalization, presentation, relevance,
     result-combiner, skills, tech-positioning, terminology, true-gaps
   - Interview preparation (1): interview-company-researcher
   - Job hunting workflow (4): cover-letter-improver, improver-standalone,
     shortener, message-parser
2. 4 commands: overlap-analysis, improve-cover-letter, eval-cover-letter, eval-cover-letterv2
3. 1 output style: tech-cover-letter-specialist
4. 1 skill: job-hunting

**See**: `job-hunting.claude/README.md` for detailed documentation

### Project-Specific Configuration

#### .claude/

**Purpose**: Project-specific Claude Code settings for this repository
**Contents**:

1. 7 agents:
   - `pr-quality-reviewer.md` - Comprehensive PR review
   - `pr-quick-reviewer.md` - Fast PR review
   - `pr-focused-reviewers/` - 5 specialized reviewers (architecture, documentation,
     performance, security, test-coverage)
2. `settings.local.json` - Local Claude Code settings

### Marketplace Plugins

#### jaodsilv-career/

**Purpose**: Career development skill
**Contents**: 1 skill (job-hunting) - 593 lines of career guidance

#### marketplace-curator/

**Purpose**: Marketplace curation tools
**Contents**: 1 agent (curator) for discovering and analyzing marketplace items

#### tdd-pro/

**Purpose**: Professional TDD workflow
**Contents**:

1. 3 agents: curator, file-output-writer, prompt-to-pipeline-architect
2. 4 skills: code-quality, conventional-branch, conventional-commits, tdd-workflow

### Community Plugins (Deprecated - Pending Cleanup)

These directories are scheduled for removal or consolidation:

1. `community-bundle/` - Meta plugin for installing all community collections
2. `community-devops/` - CI/CD & Infrastructure
3. `community-git-tools/` - Git workflow skills
4. `community-testing/` - Testing & QA skills

### Supporting Directories

#### curation/

**Purpose**: Marketplace curation analysis and reports
**Contents**: Analysis, decisions, inventory, outputs, reports

#### config/

**Purpose**: Markdownlint configurations (4 files)

#### scripts/

**Purpose**: Generate docs and validate plugins (2 Node.js scripts)

#### docs/

**Purpose**: Documentation directory

## Migration Notes

Content previously in `dotclaude/` is being split:

1. General configs remaining in `dotclaude/`
2. Documentation-related configs moving to `doc-understanding.claude/`
3. Job hunting specific configs moving to `job-hunting.claude/`
4. Future specialized configs using similar pattern
