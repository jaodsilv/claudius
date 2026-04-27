---
description: Comprehensive PR review using specialized agents. Use this skill proactively when requested to review a PR. This skill requires the plugin pr-review-toolkit@claude-plugins-official and the plugin superpowers@claude-plugins-official to be installed
argument-hint: "[[--worktree] <worktree>] [--repo <owner/name>] [--pr <number>] [--ci-mode <job-name>] [--include-confidence] [--post]"
allowed-tools: Skill, Read, Bash(gh pr review), mcp__github_inline_comment__create_inline_comment, Agent, Write(.thoughts/pr/*), TaskCreate, TaskUpdate, TaskGet
context: fork
model: opus
---

For the task below use the TaskCreate, TaskUpdate and TaskGet tools to track the progress of each step.
Use the result to provide the final output.

Note: The PR branch is already checked out in the current working directory.

## Step 0: Input Parsing

### Step 0.1: Parse Arguments

<arguments>
$ARGUMENTS
</arguments>

From arguments find the following optional values:
- `--post`: set to `true` if present, `false` otherwise

### Step 0.2: Hook Additional Context Parsing

IGNORE other arguments. Instead, parse input from hook additional context looking for the XML tags:

- `worktree`: store its value in `$worktree`
- `pr-number`: store its value in `$PR_NUMBER`
- `repo`: store its value in `$REPO`
- `latest-reviewed-commit`: store its value in `$LATEST_REVIEWED_COMMIT`
- `ci-mode`: store its value in `$CI_MODE` (present when --ci-mode was used; names the CI job running this command)
- `review-prompt`: DEPRECATED, ignore it

## Step 1: Run reviews

For all substeps below:
- Review all changes from commit <commit>$LATEST_REVIEWED_COMMIT</commit> to tip of PR
- Also verify if all comments from the previous review round have been addressed wither by fixing them or by a justification.

### Step 1.1: `pr-review-toolkit` review

Use the Skill tool to execute the skill `/pr-review-toolkit:review-pr`:

```markdown
Skill(skill: 'pr-review-toolkit:review-pr', context: 'fork', args: 'all
  To all issues found, attribute a confidence score
  Rate each issue from 0-100:

  - **0-25**: Likely false positive or pre-existing issue
  - **26-50**: Minor nitpick not explicitly in CLAUDE.md
  - **51-75**: Valid but low-impact issue
  - **76-90**: Important issue requiring attention
  - **91-100**: Critical bug or explicit CLAUDE.md violation

  Review all changes from commit <commit>$LATEST_REVIEWED_COMMIT</commit> to tip of PR

  Also verify if all comments from the previous review round have been addressed either by fixing them or by a justification.')
```

### Step 1.2: Launch `superpowers:code-reviewer` Agent

Use the Agent tool to launch the `superpowers:code-reviewer` agent and ask it to review the pull request.
Also request that agent to attribute the same confidence score as in `## Issue Confidence Scoring` section.

### Step 1.3: Custom Review

These items below aim to fill gaps found in the reviews from the previous steps.
Use the Agent tool to launch a subagent to full review this pull request with a focus on all of the bellow that applies to the current PR:

#### Step 1.3.1: Code Quality

- [ ] No visible code smells or anti-patterns
- [ ] No commented-out code
- [ ] Meaningful variable names
- [ ] DRY principle followed
- [ ] KIS principle followed

#### Step 1.3.2: Testing

- [ ] Unit tests coverage for new functions
- [ ] Integration tests coverage for new endpoints

#### Step 1.3.3: Documentation

- [ ] Documentation for new features, if any
- [ ] README updated
- [ ] API docs updated

Also request this agent to attribute the same confidence score as in `## Issue Confidence Scoring` section.

**Not all items apply to all PRs, only comment on those that apply.**

### Step 1.4: Security Review

Use the Agent tool to launch a sub-agent focused on finding security issues focused in:

#### OWASP Top 10 Analysis

- [ ] SQL Injection vulnerabilities
- [ ] Cross-Site Scripting (XSS)
- [ ] Broken Authentication
- [ ] Sensitive Data Exposure
- [ ] XML External Entities (XXE)
- [ ] Broken Access Control
- [ ] Security Misconfiguration
- [ ] Cross-Site Request Forgery (CSRF)
- [ ] Using Components with Known Vulnerabilities
- [ ] Insufficient Logging & Monitoring

#### Additional Security Checks

- [ ] Hardcoded secrets or credentials
- [ ] Insecure cryptographic practices
- [ ] Unsafe deserialization
- [ ] Server-Side Request Forgery (SSRF)
- [ ] Race conditions or TOCTOU issues

Also request this agent to attribute the same confidence score as in `## Issue Confidence Scoring` section.

**Not all items apply to all PRs, only comment on those that apply.**

## Step 2: Aggregate comments

From step 1 you have a list of comments from different agents:
- Results from `pr-review-toolkit:review-pr`
- Results from `superpowers:code-reviewer` agent
- Results from custom review
- Results from security review

All of the comments with confidence scores.
Aggregate those comments in a single list.

## Step 3: Filter and locate comments on PR

Use the Agent tool to launch the agent `gitx:pr:review-criticizer` to review those comments.
This agent should received the following information wrapped in XML tags:

- <repo>
- <pr-number>
- <issue-number>
- <comments>

## Step 4: Post comments to PR

Use the result from step 3 to post the comments to the PR.

### Step 4.1: `--post` flag is not present

Parse the json output from step 3 and build a review report using the format of the results from `pr-review-toolkit:review-pr` skill

Write your output to `.thoughts/pr/review.md`

### Step 4.2: `--post` flag is present

Parse the json output from step 3 and build a review report using the format of the results from `pr-review-toolkit:review-pr` skill

Separate comments by their locations mapping the specific locations to the comment:
- top-level comments
- file-level, line-range, or specific-line comments

If `mcp__github_inline_comment__create_inline_comment` tool is available, use it to post file-level, line-range, and line-specific comments using that mcp tool (with `confirmed: true`) to highlight specific code issues.
If not available proceed as if ALL comments were top-level comments.

Post all top-level comments in a single review comment using the `gh pr review -R "$REPO" "$PR_NUMBER" --comment --body "..."` command.

## Issue Confidence Scoring

For each issue, rate it from 0-100:

- **0-25**: Likely false positive or pre-existing issue
- **26-50**: Minor nitpick not explicitly in CLAUDE.md
- **51-75**: Valid but low-impact issue
- **76-90**: Important issue requiring attention
- **91-100**: Critical bug or explicit CLAUDE.md violation
