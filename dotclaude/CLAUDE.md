# Base CLAUDE.md

> The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
> NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and
> "OPTIONAL" in this document and all document within this system
> are to be interpreted as described in [RFC 2119](/doc/html/rfc2119).

## Repository Overview

## Current Structure

- `README.md` - Basic project description
- `LICENSE` - MIT license file
- `.claude` - Project-specific Claude Code configuration

## Output Formatting Preferences

- Always use numbered lists instead of bullet points when listing items
- Use markdown extended formatting for lists and enumerations (see <https://www.markdownguide.org/extended-syntax/> if needed)
- Use numbers (1., 2., 3.) for all lists and enumerations
- Use tree structure for nested lists and enumerations

## Custom Slash Commands and Sub-Agents instructions

- Follow the slash command/agent instructions throughfully, do not skip any steps unless explicitly stated.
- Also, do not assume anything without reading the instructions
- Do not add any additional steps unless explicitly stated.

## Claude Code Issues

Due to current Claude Code limitations, prefer using python agents over markdown agents when integrating multiple agents.
Running multiple markdown agents in parallel was causing Claude Code to run out of heap memory and crash,
probably some leak, hopefully it is resolved soon

### Parameters and default values

#### Definitions

- Schemas live within the command and agent files in a YAML format code block in the subsection `Parameters Schema`
- Default values live within the command and agent files in a YAML format code block in the subsection `Default Parameters Values`

#### Parsing Arguments

- When Parsing Arguments assign values to variables where:
  - `$\<variable-name\>` is the name of the variable to assign the value to, e.g., `$urls` is the name of the variable to assign
    the value to the `urls` parameter
  - `$\<variable-name\>[\<array-index\>]` access the value of the array index, e.g., `$urls[0]` is the value of the first url in the `urls` parameter
  - `$\<variable-name\>.\<object-key\>` access inner values of the object, e.g., `$urls[0].url` is the value of the first url in the `urls` parameter
- `\<foreach $value in $\<variable-name\>\>` blocks loops over the array sequentially and assign the value to the variable `$value`, e.g.,

  ```text
  \<foreach $url in $urls\>
    Launch Task using the Task tool with sub-agent "@docs:batch-downloader"
      Download the urls: \<urls\>{{urls}}\</urls\>
  \</foreach\>
  ```

### Prompt Templates on Markdown Agents and Custom Slash Commands

- Template prompts live within the command and agent files in a markdown format code block in the subsection
  `Template Prompt for sub-agent Task tool` or `Template Prompts for sub-agent Task tool`
- Template outputs live within the command and agent files in a markdown format code block in the subsection `Output Template` or `Output Templates`
- Custom Slash Commands and sub-agents can fill a prompt template with the parsed arguments to fill the command prompt when
  initializing a sub-agent Task.
- In the template, the placeholder "{{\<variable-name\>}}" or "{{ \<variable-name\> }}" should be replaced with the value of the
  variable `$\<variable-name\>`.
- Similarly, the placeholder "{{\<variable-name\>.\<object-key\>}}" or "{{ \<variable-name\>.\<object-key\> }}" should be replaced with the
  value of the variable `$\<variable-name\>.\<object-key\>`.
- Within a template, placeholders surrounded by backquotes are treated as code blocks and are not replaced with the value of the
  variable, e.g., "`{{\<variable-name\>}}`" or "`{{ \<variable-name\> }}`" should NOT be replaced with the value of the variable
  `$\<variable-name\>`.

### Prompt Templates on Python Agents

<!-- TODO: Add python agent prompt templates -->

## Frequently Used Commands

### Bash Commands

**Always use native tools instead of bash tools when available**

#### Development

#### Git

- `git worktree add -b ../<branch-name> <branch-name>` - Add a worktree for a new branch
  - worktrees should be placed in D:\src\{{REPO_NAME}}\{{BRANCH_NAME}}, where REPO_NAME and BRANCH_NAME should contain only the name after the last / or \
- `git worktree list` - List all worktrees
- `git worktree remove <worktree-path>` - Remove a worktree

<!-- TODO: Add git commands. The below are just examples. -->

- `git add <file>` - Stage a file
- `git commit -m "<commit message>"` - Commit changes
- `git push` - Push changes to remote repository
- `git pull` - Pull changes from remote repository
- `git switch -c <branch-name>` - Create a new branch
- `git switch <branch-name>` - Switch to a branch
- `git branch --show-current` - Show current branch
- `git branch -d <branch-name>` - Delete a branch
- `git status` - List all branches (local and remote)
- `git diff HEAD` - Merge a branch into the current branch
- `git worktree add -b <branch-name> <path>` - Create a new branch and worktree for a task
- `git worktree list` - List all worktrees
- `git worktree remove <branch-name>` - Remove a worktree

#### Github

- `gh issue view <issue-number>` - View an issue
- `gh issue create --title "<title>" --body "<body>"` - Create an issue
- `gh issue list` - List all issues
- `gh issue comment <issue-number> --body "<body>"` - Comment on an issue
- `gh issue close <issue-number>` - Close an issue
- `gh pr create -a @me -l <labels> -T <template> --title "<title>" --body "<body>"` - Create a pull request
- `gh pr list` - List all pull requests
- `gh pr merge <pr-number>` - Merge a pull request
- `gh pr close <pr-number>` - Close a pull request
- Get the latest PR comment from Claude

  ```bash
  gh pr view <pr-number> -c --json "comments" --jq '.comments | map(select(.author.login == "claude")) | last | { id: .id, author: .author.login, body: .body, isMinimized: .isMinimized }'
  ```

- Mark a pull request comment as resolved. Do that once a PR comment is resolved.

  ```bash
  gh api --method PATCH /repos/jaodsilv/ai-message-writer-assistant/pulls/comments/<comment-id> -f "minimizedReason=RESOLVED" -f 'isMinimized=true'
  ```

#### Linting

- `markdownlint-cli2 --config config/readme.markdownlint-cli2.yaml --fix` - Fix markdownlint-cli2 issues in the README.md file
- `markdownlint-cli2 --config config/claude.markdownlint-cli2.yaml --fix` - Fix markdownlint-cli2 issues in sub-agents,
   custom slash commands and output styles markdown files
- `markdownlint-cli2 --config config/other.markdownlint-cli2.yaml --fix` - Fix markdownlint-cli2 issues in the other markdown files in the project

### Custom Slash Commands

<!-- TODO: Add custom slash commands. ->

## Project Management

<!-- TODO: Add project management -->
- **Development Plan**: See `.claude/shared/todo.md` of the project for high-level roadmap with issue links.
  Exists only in the main branch. Do not attempt to read from other branches or worktrees
- **Issue Creation**: Use GitHub issue templates for consistent reporting
- **Automation**: GitHub Actions automatically add labeled issues/PRs to project board.
  See `.github/workflows/add-issues-to-project.yml` for more details. <!-- TODO: Create that file -->

## Architecture Overview

### Security Considerations

- API keys loaded from environment variables only
- No hardcoded credentials in source code
- `.{{env-file-name}}` file excluded from version control
- **API Key Validation**: Verify API key format and test connectivity on startup
- **Error Handling**: Implement graceful handling of API failures and rate limits
- **API Key Rotation**: Update `.{{env-file-name}}` file when rotating keys, restart application to apply changes

### Testing and Linting

- **Test Coverage Target**: >90% coverage for production readiness when applicable
- **Testing Strategy**: TDD for any task associated to a GitHub issue. Unit tests for components/hooks, integration tests for workflows,
  E2E tests for critical paths.
- **Testing Running**: Prefer running single tests, and not the whole test suite, for performance

### Issue Tracking and Development Plan

- **Issue Tracking**: All features tracked as GitHub issues linked to development phases
- **Project Management**: Automated GitHub Actions workflow for issue/PR management
- **Phase-Based Development**: See @.claude/shared/todo.md for detailed implementation plan
- **Priority Levels**: Critical → High → Medium → Low (automatically set via issue labels)
- **Status Automation**: Issues/PRs automatically move through Todo → In Progress → Done states

### Development Workflow

**REQUIRED**: All coding tasks **MUST** follow the comprehensive workflow process defined in:

📋 **[@shared/coding-task-workflow.md](shared/coding-task-workflow.md)**

This workflow ensures:

1. **Test-Driven Development (TDD)**: Tests are written before implementation
2. **Multi-Agent Collaboration**: Each phase uses specialized agents via the Task tool
3. **Quality Assurance**: Multiple design and review cycles
4. **Systematic Process**: Sequential execution with clear handoffs
5. **Context Management**: Regular compaction and state preservation
6. **Integration**: Seamless Git, GitHub, and issue tracking integration

**Key Workflow Phases:**

1. Git worktree setup and test requirement evaluation
2. Unit and integration test design, planning, and implementation
3. Solution design, development planning, and implementation
4. Code review, refactoring evaluation, and quality validation
5. Commit management and pull request workflow
6. Review response handling and task closure

**Compliance**: Deviation from this workflow is only permitted with explicit approval and documented justification.

### Git Guidelines

#### Branch Naming

Read @~/.claude/instructions/conventional-branch.md for more details.

#### Commit Conventions

- **Basics**: Read @~/.claude/instructions/conventional-commits.md for more details.
- **Focused Commits**: Only commit files directly related to your current task or change
- **Staging Discipline**: Use `git add` selectively to stage only relevant files, not `git add .`
- **Unrelated Changes**: Keep unrelated changes (one-time testing files, config updates, etc.) in separate commits
- **Clean History**: If you accidentally stage unrelated files, use `git restore --staged <file>` to unstage them.
  Do not use `git restore --staged .` to unstage all files.
- **Commit Scope**: Each commit should represent a single, cohesive change that can be reviewed independently.
  Do not commit changes that are not related to the current task.
- **Authoring**: Do NOT add "Co-authors", "Co-Authored-By: Claude <noreply@anthropic.com>" or
  "🤖 Generated with [Claude Code](https://claude.ai/code)" to the commit message.

### Versioning

- **Basics**: Read @~/.claude/shared/docs/semver.md for more details.
- **Versioning Strategy**: Use semantic versioning (SemVer) for all new releases.
- **Version Management**: Use the `version` command to manage the version of the project.
- **Version File**: The version is stored in the `version.txt` file.
- **Version Tag**: The version is tagged with the `v` prefix.
- **Version History**: The version history is stored in the `version-history.md` file.
