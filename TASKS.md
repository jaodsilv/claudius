# Claude Repository - Restructuring Tasks

**Repository**: <https://github.com/jaodsilv/claude>
**Status**: Existing repository needs configuration restructuring
**Visibility**: PUBLIC

## Overview

Restructure the claude repository to split the monolithic `dotclaude/` directory into specialized Claude Code configuration directories to improve startup performance and reduce command/agent loading issues.

## Current Structure

```
claude/
├── dotclaude/                    # Currently mounted as ~/.claude
│   ├── agents/                  # All agents (general + job-specific)
│   ├── commands/                # All commands (general + job-specific)
│   ├── shared/                  # Shared resources
│   ├── instructions/            # Instructions
│   ├── scripts/                 # Scripts
│   └── [other directories]
├── external-resources/          # Git submodules (keep as-is)
├── job-hunting.claude/          # Currently empty placeholder
├── CLAUDE.base.md              # Base config template
├── CLAUDE.md                   # Project-specific CLAUDE.md
└── README.md
```

## Target Structure

```
claude/
├── dotclaude/                    # General configs only
│   ├── agents/                  # General-purpose agents only
│   ├── commands/                # General-purpose commands only
│   ├── shared/                  # Shared resources (stays)
│   ├── instructions/            # Instructions (stays)
│   ├── scripts/                 # Scripts (stays)
│   └── [other directories]
├── job-hunting.claude/          # Job hunting specific configs
│   ├── agents/                  # Job hunting agents
│   ├── commands/                # Job hunting slash commands
│   ├── shared/                  # Job hunting shared resources
│   └── README.md
├── personal-projects.claude/    # Placeholder for future
│   └── README.md
├── learning.claude/             # Placeholder for future
│   └── README.md
├── external-resources/          # Git submodules (no changes)
├── CLAUDE.base.md              # Base config template (stays)
├── CLAUDE.md                   # Update to document new structure
└── README.md                   # Update with restructuring info
```

## Tasks to Complete

### 1. Create New Directory Structure

```bash
cd D:/src/claude

# Create new specialized directories
mkdir -p job-hunting.claude/agents
mkdir -p job-hunting.claude/commands
mkdir -p job-hunting.claude/shared

# Create placeholder directories for future
mkdir -p personal-projects.claude
mkdir -p learning.claude
```

### 2. Identify and Migrate Job Hunting Content

**Search for job-related content in dotclaude:**

```bash
# Find job-related commands
find dotclaude/commands -name "*job*" -o -name "*jobs*"

# Find job-related agents
find dotclaude/agents -name "*job*" -o -name "*jobs*"

# Check for cover letter evaluators
find dotclaude -name "*cover-letter*"

# Check for resume-related configs
find dotclaude -name "*resume*"
```

**Content to migrate to job-hunting.claude:**

- Any commands with `jobs:*` prefix
- Any agents related to job hunting, cover letters, resumes
- Any job-hunting specific shared resources

**Migration commands:**

```bash
# Example: Move job-related commands
mv dotclaude/commands/jobs:* job-hunting.claude/commands/

# Example: Move job-related agents
mv dotclaude/agents/jobs:* job-hunting.claude/agents/

# Move cover letter evaluators
mv dotclaude/agents/cover-letter-evaluator:* job-hunting.claude/agents/

# Move job-related shared content if any
# Check dotclaude/shared for job-specific content
```

### 3. Create job-hunting.claude/README.md

```markdown
# Job Hunting Claude Configuration

Specialized Claude Code configuration for job hunting workflows.

## Overview

This directory contains Claude Code configurations specifically for job hunting tasks:
- Job application tracking
- Resume tailoring
- Cover letter generation and evaluation
- Company research
- Interview preparation
- Networking assistance

## Structure

\```
job-hunting.claude/
├── agents/              # Job hunting specialized agents
├── commands/            # Job hunting slash commands
├── shared/              # Job hunting shared resources
└── README.md
\```

## Agents

### Cover Letter Evaluators
- `cover-letter-evaluator:*` - Multi-step cover letter analysis agents
- `false-assertion-cleaner` - Remove false claims from drafts
- Various evaluation aspects (ATS, keywords, skills, etc.)

### Job Hunting Agents
- (List specific agents found during migration)

## Commands

### Job Hunting Commands
- `/jobs:*` - Job search and tracking commands
- (List specific commands found during migration)

## Usage

This configuration is designed to be used alongside the general `dotclaude/` configuration.

## Related Repositories

1. **job-hunting-automation**: Python tools for job searching
2. **job-applications** (private): Personal application materials
3. **latex-templates**: Resume/CV templates

## Integration

Commands in this directory can invoke Python tools from `job-hunting-automation` repository for scraping, scoring, and analysis tasks.
```

### 4. Create Placeholder READMEs

**personal-projects.claude/README.md:**

```markdown
# Personal Projects Claude Configuration

Placeholder for future personal project-specific Claude Code configurations.

## Purpose

This directory will contain Claude Code configurations for personal hobby projects:
- Sticker album layouts
- System design tools
- Web scraping projects
- Learning projects

## Status

Currently empty - configurations will be added as needed.
```

**learning.claude/README.md:**

```markdown
# Learning Claude Configuration

Placeholder for future learning-specific Claude Code configurations.

## Purpose

This directory will contain Claude Code configurations for educational projects:
- JavaScript exercises
- React learning
- Rust programming
- Algorithm practice
- Technical skill development

## Status

Currently empty - configurations will be added as needed.
```

### 5. Update Main CLAUDE.md

Update the project-specific CLAUDE.md to document the new structure:

```markdown
## Specialized Claude Configurations

This repository now uses specialized .claude directories for different workflows:

### dotclaude/
**Mount Location**: `~/.claude`
**Purpose**: General-purpose Claude Code configurations
**Contents**: General agents, commands, shared resources, instructions, scripts

### job-hunting.claude/
**Purpose**: Job hunting workflow configurations
**Contents**:
- Job hunting agents (cover letter evaluators, etc.)
- Job hunting slash commands (`/jobs:*`)
- Job hunting shared resources

**Related Repos**:
- job-hunting-automation (Python tools)
- job-applications (private materials)
- latex-templates (resume templates)

### personal-projects.claude/
**Purpose**: Personal project configurations (placeholder)
**Status**: To be populated as needed

### learning.claude/
**Purpose**: Learning and educational project configurations (placeholder)
**Status**: To be populated as needed

## Migration Notes

Content previously in `dotclaude/` has been split:
- General configs remain in `dotclaude/`
- Job hunting specific configs moved to `job-hunting.claude/`
- Future specialized configs will use similar pattern
```

### 6. Update Main README.md

Add section documenting the restructuring:

```markdown
## Repository Structure

This repository is organized into specialized Claude Code configuration directories:

### dotclaude/
General-purpose Claude Code configurations mounted as `~/.claude`.

### job-hunting.claude/
Job hunting specific configurations including:
- Cover letter evaluation agents
- Resume tailoring tools
- Job search automation commands
- Interview preparation workflows

### personal-projects.claude/
Placeholder for personal project configurations.

### learning.claude/
Placeholder for learning project configurations.

### external-resources/
Git submodules containing community resources:
- super-claude
- awesome-claude-prompts
- awesome-claude-code-agents
- awesome-claude-code-subagents
- awesome-claude-code
- dynamic-sub-agents

## Motivation for Restructuring

The monolithic `dotclaude/` directory was causing:
- Slow Claude Code startup
- Missing slash commands in some sessions
- Missing agents in some sessions

Splitting into specialized directories:
- Improves startup performance
- Reduces context loading
- Makes configurations more maintainable
- Allows for workflow-specific customization
```

### 7. Verify Migration

**Checklist:**

- [ ] All job-related commands moved to job-hunting.claude/commands/
- [ ] All job-related agents moved to job-hunting.claude/agents/
- [ ] No job-specific content remains in dotclaude/
- [ ] General agents remain in dotclaude/agents/
- [ ] General commands remain in dotclaude/commands/
- [ ] Shared resources properly organized
- [ ] All README files created

**Verification commands:**

```bash
# Check for remaining job-related content in dotclaude
grep -r "job" dotclaude/commands/
grep -r "job" dotclaude/agents/
grep -r "cover-letter" dotclaude/agents/

# Verify job-hunting.claude has content
ls -R job-hunting.claude/

# Check git status
git status
```

### 8. Commit and Push

```bash
cd D:/src/claude

git add .
git commit -m "feat: restructure into specialized Claude configurations

- Split dotclaude/ into specialized directories
- Create job-hunting.claude/ for job hunting workflows
- Move job-related commands and agents to job-hunting.claude/
- Create personal-projects.claude/ placeholder
- Create learning.claude/ placeholder
- Update CLAUDE.md with new structure documentation
- Update README.md with restructuring motivation
- Add comprehensive README files for each specialized directory

This restructuring improves Claude Code startup performance and
reduces command/agent loading issues by separating general configs
from specialized workflow configs."

git push origin main
```

## Verification Steps

1. Verify all job content migrated to job-hunting.claude/
2. Verify dotclaude/ contains only general configs
3. Verify placeholder directories created
4. Verify all READMEs are comprehensive
5. Verify CLAUDE.md and README.md updated
6. Test git push succeeds
7. Verify repository structure on GitHub

## Testing After Restructuring

After restructuring, test Claude Code:

1. Start Claude Code in a project using dotclaude/
2. Verify general commands still work
3. Verify general agents load correctly
4. Start Claude Code in job-hunting context
5. Verify job hunting commands work
6. Verify cover letter evaluator agents load

## Notes

- **Backwards Compatibility**: dotclaude/ remains functional for general use
- **Selective Loading**: Projects can choose which .claude directories to use
- **Future Expansion**: Easy to add more specialized directories (e.g., `web-dev.claude/`)
- **No Breaking Changes**: Existing dotclaude/ functionality preserved

## Success Criteria

- [ ] Directory structure created
- [ ] Job hunting content migrated
- [ ] Placeholder directories created
- [ ] All README files comprehensive
- [ ] CLAUDE.md updated
- [ ] Main README.md updated
- [ ] No job content remains in dotclaude/
- [ ] Migration verified
- [ ] Changes committed
- [ ] Pushed to GitHub successfully
- [ ] Claude Code tested with new structure

## Future Enhancements

After completing this restructuring, consider:

1. Creating web-dev.claude/ for web development projects
2. Creating data-science.claude/ for data analysis workflows
3. Documenting best practices for creating new specialized configs
4. Adding tooling to help switch between specialized configs
