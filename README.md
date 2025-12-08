[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)
[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/jaodsilv/claude/main.svg)](https://results.pre-commit.ci/latest/github/jaodsilv/claude/main)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
[![Conventional Branch](https://img.shields.io/badge/Conventional%20Branch-1.0.0-blue)](https://github.com/conventional-branch/conventional-branch)
[![Code License](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/jaodsilv/claude?tab=MIT-1-ov-file)

# Claude 🤖

My custom base config for my personal projects, including a very basic `CLAUDE.md` (named `CLAUDE.base.md`, the `CLAUDE.md` here is
actually the `CLAUDE.md` of this repo), sub agents, custom slash commands and workflows

## Repository Structure

This repository is organized into specialized Claude Code configuration directories:

### dotclaude/

General-purpose Claude Code configurations mounted as `~/.claude`.

### job-hunting.claude/

Job hunting specific configurations including:

1. Cover letter evaluation agents
2. Resume tailoring tools
3. Job search automation commands
4. Interview preparation workflows

### personal-projects.claude/

Placeholder for personal project configurations.

### learning.claude/

Placeholder for learning project configurations.

### external-resources/

Git submodules containing community resources:

1. super-claude
2. awesome-claude-prompts
3. awesome-claude-code-agents
4. awesome-claude-code-subagents
5. awesome-claude-code
6. dynamic-sub-agents

### .claude-plugin/

Claude Code marketplace with 14 curated plugin collections.

See [Marketplace Documentation](#claude-code-marketplace) below for details.

## Claude Code Marketplace

This repository provides a comprehensive curated marketplace of Claude Code plugins, combining original tools with best-of-breed selections from across the community ecosystem.

### Installation

Add this marketplace to Claude Code:

```bash
/plugin marketplace add jaodsilv/claude
```

Then install any plugin:

```bash
/plugin install [plugin-name]
```

### Plugin Catalog

**14 plugins | 100+ tools | 7 sources curated**

#### Original Plugins (3)

1. **tdd-pro** - Professional TDD workflow
   - 7-phase TDD process with multi-agent coordination
   - Conventional commits and branch management
   - Code quality and testing automation
   - Keywords: `tdd`, `testing`, `workflow`, `automation`

2. **docs-automation** - Documentation automation pipeline
   - Batch documentation download and conversion
   - Multi-agent coordination (4 agents)
   - Format verification and quality checks
   - Keywords: `documentation`, `download`, `conversion`, `automation`

3. **job-hunting-pro** - Career development automation
   - Cover letter evaluation and improvement (14 agents)
   - Interview preparation and company research
   - Resume tailoring and ATS optimization
   - Keywords: `job-hunting`, `career`, `cover-letter`, `interview`

#### Community Collections (6) - 86+ tools

4. **community-testing** (12 items)
   - TDD workflow and code quality skills
   - Test automation and QA agents
   - SuperClaude test and analyze commands
   - Keywords: `testing`, `qa`, `tdd`, `automation`

5. **community-documentation** (13 items)
   - Batch docs pipeline (unique)
   - PRD, Roadmap, JTBD frameworks
   - API documentation and changelog tools
   - Keywords: `documentation`, `docs`, `prd`, `api-docs`

6. **community-devops** (10 items)
   - CI/CD automation (release, husky, act)
   - Kubernetes and cloud architecture agents
   - Build and deployment tools
   - Keywords: `devops`, `ci-cd`, `kubernetes`, `cloud`

7. **community-prompts** (8 items)
   - Prompt-to-pipeline architect (unique)
   - Agent orchestration and evolution
   - 100+ prompt examples from community
   - Keywords: `prompts`, `ai`, `llm`, `agents`

8. **community-git-tools** (9 items)
   - Conventional commits and branch skills
   - PR workflows and automation
   - Git worktree and branch management
   - Keywords: `git`, `version-control`, `commits`, `pr`

9. **community-best-of** (25 items)
   - Top-rated tools across all categories
   - Unique innovations highlighted
   - Cross-category best practices
   - Keywords: `best-practices`, `curated`, `top-rated`

#### jaodsilv Featured Collections (3)

10. **jaodsilv-workflow** (8 items)
    - Complete development workflow system
    - TDD, conventional standards, multi-agent
    - Agent evolution and curation tools
    - Keywords: `tdd`, `workflow`, `conventional`, `multi-agent`

11. **jaodsilv-docs** (5 items)
    - **UNIQUE** batch documentation pipeline
    - Download, convert, verify automation
    - Multi-agent coordination
    - Keywords: `documentation`, `batch`, `automation`, `pipeline`

12. **jaodsilv-career** (1 skill - 593 lines)
    - **UNIQUE** - Only career tool in ecosystem
    - Cover letters, resumes, interviews
    - Negotiation and offer evaluation
    - Keywords: `career`, `job-hunting`, `unique`

#### Meta-Plugins (2)

13. **marketplace-curator**
    - Tools for curating your own marketplace
    - Discovery agent for 13+ sources
    - Analysis and categorization tools
    - Templates and documentation
    - Keywords: `curation`, `marketplace`, `discovery`, `meta`

14. **community-bundle**
    - Single-command install of all 6 community collections
    - 86+ tools across all categories
    - Easy ecosystem access
    - Keywords: `bundle`, `community`, `meta`, `collection`

### Quick Start

**Install Everything**:

```bash
/plugin marketplace add jaodsilv/claude
/plugin install community-bundle  # All 6 community collections
```

**Install by Category**:

```bash
/plugin install community-testing      # Testing & QA tools
/plugin install community-git-tools    # Git workflows
/plugin install community-devops       # CI/CD & infrastructure
```

**Install Featured Collections**:

```bash
/plugin install jaodsilv-workflow  # Complete TDD workflow
/plugin install jaodsilv-career    # Career development (UNIQUE)
```

### Unique Differentiators

1. **TDD Workflow** (jaodsilv-workflow)
   - 7-phase process with multi-agent coordination
   - Design → Review loops at each step
   - Context compaction strategy
   - Quality gates throughout

2. **Batch Docs Pipeline** (jaodsilv-docs)
   - Only batch documentation automation in ecosystem
   - Download → Convert → Verify pipeline
   - Multi-format support
   - 4 specialized agents

3. **Career Development** (jaodsilv-career)
   - **ONLY career/job-hunting tool** across 205+ items discovered
   - 593 lines of comprehensive guidance
   - Cover letters, resumes, interviews, negotiation
   - Auto-invoked for career tasks

4. **Marketplace Curation** (marketplace-curator)
   - Create your own curated marketplace
   - Automated discovery and analysis
   - Templates and methodology included

### Curation Methodology

This marketplace was built through systematic discovery and curation:

1. **Discovery**: Analyzed 205+ items from 7 sources (1 local + 6 submodules)
2. **Categorization**: 10 standard categories with quality scoring (1-5 stars)
3. **Deduplication**: Identified overlaps and selected best-of-breed
4. **Collection Assembly**: Curated 6 community + 3 featured collections

**Quality Distribution**:

- 88% production-ready (5 stars)
- 10% adequate (3 stars)
- 2% high quality (4 stars)

**Documentation**:

- `curation/analysis/discovery-summary.md` - Discovery statistics and findings
- `curation/analysis/deduplication-analysis.md` - Overlap analysis and selections
- `curation/inventory/` - Structured JSON inventories for all sources

**Future Work**:

- 6 external marketplaces identified for future curation
- Ongoing community contributions welcome
- Quarterly maintenance and updates planned

### Contributing to Marketplace

Want to add your tools to this marketplace?

1. Create a plugin manifest (`plugin.json`) following our templates
2. Submit PR with your plugin in `.claude-plugin/plugins/[your-plugin]/`
3. Include quality documentation and examples
4. Follow conventional standards for commits/branches

See `marketplace-curator` plugin for complete curation toolkit.

## Motivation for Restructuring

The monolithic `dotclaude/` directory was causing:

1. Slow Claude Code startup
2. Missing slash commands in some sessions
3. Missing agents in some sessions

Splitting into specialized directories:

1. Improves startup performance
2. Reduces context loading
3. Makes configurations more maintainable
4. Allows for workflow-specific customization

<!-- TODO: Add instructions for Windows and MacOS -->
## How I suggest you to use this

1. git clone or fork into your src folder
2. Create a new branch for your own stuff, this will make it easier to merge with whatever I add later
3. Copy everything from your own ~/.claude into the .claude here
4. If needed add whatever file you have with secrets in the .gitignore, this .gitignore already includes .credentials.json
5. Further instructions for Linux and WSL users are below:
    1. Backup your *~/.claude*: `mv ~/.claude ~/.claude.bak`
    2. Mount or create symlink to *.claude* into your home:
        1. `export CLAUDE_USER_PATH=/path/to/your/src/folder/claude/.claude`
        2. Mount Alternative 1 (mount with `mount --bind`):
            1. Mount this *.claude* path into *~/.claude*: `sudo mount --bind $CLAUDE_USER_PATH ~/.claude`
            2. If you liked it and this to mount once you start your system, edit your *.bashrc* or *.zshrc*:
               `echo "sudo mount --bind \$CLAUDE_USER_PATH ~/.claude" >> ~/.bashrc`
        3. Mount Alternative 2 (Create symlink with `ln -s`):
            1. Create a symlink from your home to the .claude path in your src folder: `ln -s $CLAUDE_USER_PATH ~/.claude`
            2. This is the easiest way to mount, and it is persistent, as it creates a symlink in your home.
        4. Mount Alternative 3 (mount with `bindfs`):
            1. `sudo apt-get update && sudo apt-get install bindfs`
            2. `sudo bindfs --no-allow-other $CLAUDE_USER_PATH ~/.claude`
            3. If you liked it and want this path to mount once you start your shell, edit your *.bashrc* or *.zshrc*:
               `echo "sudo bindfs --no-allow-other \$CLAUDE_USER_PATH ~/.claude" >> ~/.bashrc`
        5. Mount Alternative 4 (mount with `/etc/fstab`):
            1. If you liked it and this to mount once you start your system, edit your `/etc/fstab`:
               `sudo echo "\$CLAUDE_USER_PATH /home/\$USER/.claude none bind" >> /etc/fstab && sudo systemctl daemon-reload`

## Contributing

If you feel you have anything relevant to share, commit and create a PR, I'll be happy to include anything I find useful ❤
