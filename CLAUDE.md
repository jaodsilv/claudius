# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Base Instructions

1. Read @CLAUDE.base.md as a base or as an extension for this CLAUDE.md file

## Repository Overview

This is a personal configuration repository for Claude Code containing a comprehensive plugin ecosystem with 60+ agents, 40+ commands, and 30+ skills organized into specialized plugin directories.

## Plugin Ecosystem

### Core Plugins

#### dotclaude/

**Mount Location**: `~/.claude`
**Purpose**: General-purpose Claude Code configurations

**Contents**:

1. `agents/` - 5 agents (coding-task-orchestrator, curator, prompt-to-pipeline-architect, pr-reviewer-2, walkthrough-generator)
2. `commands/` - 3 commands in 2 groups (coding-task/start, project/create, project/create-data)
3. `instructions/` - Agent creation guidelines
4. `shared/` - 7 reference documents (coding-task-workflow, conventional-branch, conventional-commits, rfc2119, semver, etc.)
5. `output-styles/` - 1 output style (candidate-response)
6. `skills/` - 19 skills in categories:
   - Code quality
   - Conventional standards (branch, commits)
   - Language-specific reviews (Go, Java, Markdown, Mermaid, Python, Rust, TypeScript)
   - Principles (performance, security, SOLID)
   - TDD workflow
7. `plugins/` - Plugin configurations

#### gitx/

**Purpose**: Extended Git/GitHub workflow plugin with multi-agent orchestration
**Contents**:

1. 14 agents in 4 groups:
   - `conflict-resolver/` - 3 agents for conflict resolution
   - `fix-issue/` - 4 agents for issue-to-PR workflow
   - `pr-create/` - 3 agents for PR creation
   - `respond/` - 4 agents for PR response handling
2. 14 commands: worktree, remove-worktree, remove-branch, rebase, merge, ignore, commit-push, next-issue, fix-issue, comment-to-issue, pr, respond, update-pr, comment-to-pr, merge-pr
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
2. 11 commands: create-command, create-skill, create-orchestration, create-output-style, improve-command, improve-agent, improve-skill, improve-plugin, improve-orchestration, improve-output-style, bump-version
3. 2 skills: improvement-workflow, orchestration-patterns

**See**: `cc/README.md` for detailed documentation

#### planner.claude/

**Purpose**: Strategic planning with roadmapping, prioritization, and deep ideation
**Contents**:

1. 9 agents for planning workflows
2. 9 commands: roadmap, prioritize, gather-requirements, review-plan, review-roadmap, review-prioritization, review-architecture, review-requirements, ideas
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

1. 18 agents:
   - Cover letter evaluators (14): ATS, impact, keywords, gaps, overlap, relevance, skills, tech-positioning, terminology, personalization, communication, presentation, false-assertion-cleaner, result-combiner
   - Job hunting workflow (4): cover-letter-improver, improver-standalone, shortener, message-parser
2. 4 commands: overlap-analysis, improve-cover-letter, eval-cover-letter, eval-cover-letterv2
3. 1 output style: tech-cover-letter-specialist
4. 1 skill: job-hunting

**See**: `job-hunting.claude/README.md` for detailed documentation

### Placeholder Plugins

#### personal-projects.claude/

**Purpose**: Personal project configurations (placeholder)
**Status**: To be populated as needed

#### learning.claude/

**Purpose**: Learning and educational project configurations (placeholder)
**Status**: To be populated as needed

### Project-Specific Configuration

#### .claude/

**Purpose**: Project-specific Claude Code settings for this repository
**Contents**:

1. 8 agents:
   - `pr-quality-reviewer.md` - Comprehensive PR review
   - `pr-quick-reviewer.md` - Fast PR review
   - `pr-focused-reviewers/` - 5 specialized reviewers (architecture, documentation, performance, security, test-coverage)
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

### External Resources (via data repository)

External resources are stored in the paired data repository (`claudius-data`) and accessed via the `data/` junction link:

1. `data/external-resources/super-claude` - Super Claude, a collection of Claude Code agents and prompts
2. `data/external-resources/awesome-claude-prompts` - Awesome Claude Prompts
3. `data/external-resources/awesome-claude-code-agents` - Awesome Claude Code Agents
4. `data/external-resources/awesome-claude-code-subagents` - Awesome Claude Code Subagents
5. `data/external-resources/awesome-claude-code` - Awesome Claude Code resources
6. `data/external-resources/dynamic-sub-agents` - Dynamic Sub-Agents

**Note**: These submodules are automatically updated weekly via GitHub Actions in the data repository.

**Development Setup**: To access external resources, create a junction link to the data repository:

```cmd
# Windows (run as Administrator or with Developer Mode enabled)
mklink /J data D:\src\claudius\data
```

```bash
# Linux/macOS
ln -s /path/to/claudius-data data
```

## Migration Notes

Content previously in `dotclaude/` has been split:

1. General configs remain in `dotclaude/`
2. Documentation-related configs moved to `doc-understanding.claude/`
3. Job hunting specific configs moved to `job-hunting.claude/`
4. Future specialized configs will use similar pattern
