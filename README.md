[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)
[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/jaodsilv/claudius/main.svg)](https://results.pre-commit.ci/latest/github/jaodsilv/claudius/main)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
[![Conventional Branch](https://img.shields.io/badge/Conventional%20Branch-1.0.0-blue)](https://github.com/conventional-branch/conventional-branch)
[![Code License](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/jaodsilv/claudius?tab=MIT-1-ov-file)

# claudius

Personal Claude Code configuration repository with a comprehensive plugin ecosystem containing 60+ agents, 40+ commands, and 30+ skills.

## Repository Structure

### Core Plugins

#### dotclaude/

General-purpose Claude Code configurations (legacy, no longer mounted as ~/.claude).

1. 5 agents (coding-task-orchestrator, curator, prompt-to-pipeline-architect, pr-reviewer, walkthrough-generator)
2. 3 commands in 2 groups (coding-task/start, project/create, project/create-data)
3. 16 skills (code quality, conventional standards, language reviews, principles, TDD, job-hunting)
4. 7 shared reference documents

#### gitx/

Extended Git/GitHub workflow plugin with multi-agent orchestration.

1. 14 agents in 4 groups (conflict-resolver, fix-issue, pr-create, respond)
2. 15 commands (worktree, fix-issue, pr, respond, merge, rebase, etc.)
3. 2 skills (conventional-commits, conventional-branch)

#### cc/

Meta-toolkit for creating and improving Claude Code plugin components.

1. 13 agents (creators, improvers, architect, workflow)
2. 11 commands (create-*, improve-*, bump-version)
3. 2 skills (improvement-workflow, orchestration-patterns)

#### planner.claude/

Strategic planning with roadmapping, prioritization, and deep ideation.

1. 16 agents in 3 groups (github, ideas, planner)
2. 9 commands (roadmap, prioritize, review-*, ideas)
3. Multi-agent "Ultrathink" ideation with Opus extended thinking

#### brainstorm.claude/

Multi-agent requirements discovery through Socratic dialogue.

1. 6 agents (facilitator, domain-explorer, technical-analyst, constraint-analyst, requirements-synthesizer, specification-writer)
2. 3 commands (start, continue, export)

### Specialized Plugins

#### doc-understanding.claude/

Documentation downloading, conversion, and processing.

1. 4 agents (downloader, batch-downloader, converter, conversion-verifier)
2. 1 command (/docs:download)

#### job-hunting.claude/

Job hunting workflow configurations.

1. 19 agents (14 cover letter evaluators + 1 interview researcher + 4 workflow agents)
2. 4 commands (overlap-analysis, improve-cover-letter, eval-cover-letter, eval-cover-letterv2)
3. 1 skill (job-hunting)

### Marketplace Plugins

1. **jaodsilv-career/** - Career development skill (593 lines)
2. **marketplace-curator/** - Marketplace curation tools
3. **tdd-pro/** - Professional TDD workflow

### Community Plugins (Deprecated)

These directories are scheduled for removal or consolidation:

1. **community-bundle/** - Meta plugin for all community collections
2. **community-devops/** - CI/CD & Infrastructure
3. **community-git-tools/** - Git workflow skills
4. **community-testing/** - Testing & QA skills

### Supporting Directories

1. **.claude/** - Project-specific PR reviewers (7 agents)
2. **curation/** - Marketplace curation analysis and reports
3. **config/** - Markdownlint configurations
4. **scripts/** - Generate docs and validate plugins
5. **docs/** - Documentation

## Claude Code Marketplace

This repository provides a curated marketplace of Claude Code plugins.

### Installation

Add this marketplace to Claude Code:

```bash
/plugin marketplace add jaodsilv/claudius
```

Then install any plugin:

```bash
/plugin install [plugin-name]
```

### Plugin Catalog

#### Original Plugins (3)

1. **tdd-pro** - Professional TDD workflow
   - 7-phase TDD process with multi-agent coordination
   - Conventional commits and branch management
   - Code quality and testing automation
   - Keywords: `tdd`, `testing`, `workflow`, `automation`

2. **doc-understanding** - Documentation automation pipeline
   - Batch documentation download and conversion
   - Multi-agent coordination (4 agents)
   - Format verification and quality checks
   - Keywords: `documentation`, `download`, `conversion`, `automation`

3. **job-hunting** - Career development automation
   - Cover letter evaluation and improvement (14 agents)
   - Interview preparation and company research
   - Resume tailoring and ATS optimization
   - Keywords: `job-hunting`, `career`, `cover-letter`, `interview`

#### Featured Plugins (4)

1. **gitx** - Extended Git/GitHub workflows
   - Multi-agent orchestration for PR creation and response
   - Issue-driven development with worktree management
   - Conflict resolution with AI suggestions
   - Keywords: `git`, `github`, `pr`, `workflow`

2. **cc** - Plugin development meta-toolkit
   - Create commands, skills, orchestrations
   - Interactive improvement workflows
   - Multi-agent orchestration architecture
   - Keywords: `plugin`, `development`, `meta`, `toolkit`

3. **planner** - Strategic planning
   - Project roadmapping with phases and milestones
   - Issue prioritization (RICE, MoSCoW frameworks)
   - Deep ideation with Opus extended thinking
   - Keywords: `planning`, `roadmap`, `prioritization`, `ideation`

4. **brainstorm** - Requirements discovery
   - Multi-agent Socratic dialogue
   - Domain exploration and constraint analysis
   - Professional specification generation
   - Keywords: `requirements`, `brainstorm`, `specification`, `discovery`

#### Community Collections (Deprecated)

These collections are scheduled for removal or consolidation:

1. **community-testing** - TDD workflow and code quality skills
2. **community-documentation** - PRD, Roadmap, JTBD frameworks
3. **community-devops** - CI/CD automation, Kubernetes agents
4. **community-prompts** - Agent orchestration tools
5. **community-git-tools** - Conventional commits and PR workflows
6. **community-best-of** - Top-rated tools across categories

#### Meta-Plugins (2)

1. **marketplace-curator**
   - Tools for curating your own marketplace
   - Discovery agent for 13+ sources
   - Analysis and categorization tools

2. **community-bundle** (Deprecated)
   - Single-command install of all community collections

### Quick Start

**Install Featured Plugins**:

```bash
/plugin marketplace add jaodsilv/claudius
/plugin install gitx          # Git/GitHub workflows
/plugin install cc            # Plugin development toolkit
/plugin install planner       # Strategic planning
/plugin install brainstorm    # Requirements discovery
```

**Install Original Plugins**:

```bash
/plugin install tdd-pro           # TDD workflow
/plugin install job-hunting       # Career development
/plugin install doc-understanding # Documentation automation
```

### Unique Differentiators

1. **Multi-Agent Orchestration** (gitx, planner, brainstorm)
   - Parallel analysis with specialized agents
   - Diverge-Challenge-Synthesize patterns
   - Quality gates and user approval workflows

2. **Extended Thinking** (planner)
   - Opus "Ultrathink" for deep ideation
   - Multi-round refinement sessions
   - Cross-domain innovation exploration

3. **Career Development** (job-hunting)
   - **ONLY career/job-hunting tool** in the ecosystem
   - 593 lines of comprehensive guidance
   - Cover letters, resumes, interviews, negotiation

4. **Plugin Development** (cc)
   - Meta-toolkit for creating plugins
   - Interactive improvement workflows
   - Orchestration architecture design

## How to Use This Repository

### Option 1: Marketplace Installation (Recommended)

The easiest way to use this repository is through the Claude Code marketplace:

1. **Add the marketplace**:

   ```bash
   /plugin marketplace add jaodsilv/claudius
   ```

2. **Browse available plugins**:

   ```bash
   /plugin list
   ```

3. **Install plugins**:

   ```bash
   /plugin install gitx              # Git workflows
   /plugin install planner           # Strategic planning
   /plugin install job-hunting       # Career tools
   ```

### Option 2: Direct Repository Usage

If you prefer to fork and customize:

1. git clone or fork into your src folder
2. Create a new branch for your own stuff, this will make it easier to merge with whatever I add later
3. Copy everything from your own ~/.claude into the .claude here
4. If needed add whatever file you have with secrets in the .gitignore, this .gitignore already includes .credentials.json

## Motivation for Plugin Architecture

The monolithic `dotclaude/` directory was causing:

1. Slow Claude Code startup
2. Missing slash commands in some sessions
3. Missing agents in some sessions

Splitting into specialized directories:

1. Improves startup performance
2. Reduces context loading
3. Makes configurations more maintainable
4. Allows for workflow-specific customization

## Contributing

If you feel you have anything relevant to share, commit and create a PR, I'll be happy to include anything I find useful.
