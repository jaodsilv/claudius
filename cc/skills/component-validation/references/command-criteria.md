# Command Validation Criteria

Detailed validation rules for Claude Code slash commands.

## Frontmatter Validation

### Required Fields

| Field | Requirement | Severity if Missing |
|-------|-------------|---------------------|
| description | Present, under 60 characters | CRITICAL |

### Optional Fields

| Field | Best Practice | Severity if Violated |
|-------|---------------|----------------------|
| argument-hint | Document all expected arguments | HIGH |
| allowed-tools | Minimal necessary set (least privilege) | HIGH |
| model | Appropriate for command complexity | MEDIUM |
| disable-model-invocation | Set if non-LLM command | LOW |

## Content Validation

### Writing Style

| Criterion | Good | Bad | Severity |
|-----------|------|-----|----------|
| Perspective | "Read the file and analyze..." | "This command will read the file..." | HIGH |
| Voice | Imperative (action-oriented) | Descriptive (documentation-style) | HIGH |
| Clarity | Explicit step-by-step instructions | Vague or ambiguous guidance | MEDIUM |

### Argument Handling

| Criterion | Requirement | Severity |
|-----------|-------------|----------|
| $ARGUMENTS usage | Properly referenced in body | HIGH |
| Validation | Arguments validated before use | MEDIUM |
| Documentation | argument-hint describes all arguments | HIGH |

### Integration Patterns

| Pattern | Correct Syntax | Severity if Wrong |
|---------|----------------|-------------------|
| File references | `@path/to/file.md` | HIGH |
| Bash execution | `` !`command` `` | HIGH |
| Agent delegation | `Task @agent-name` | HIGH |
| Skill integration | `Use Skill tool to load skill-name`\* | MEDIUM |
| Plugin paths | `${CLAUDE_PLUGIN_ROOT}/path` | MEDIUM |

\* Skill integration in agents is also possible by adding the skills field to the
frontmatter: `skills: skill-name` or, if multiple skills are used:
`skills: skill-name1, skill-name2`

## Quality Criteria

### CRITICAL Issues

Must fix immediately:

- Invalid YAML frontmatter syntax
- Missing description field
- Security vulnerabilities (credential exposure, unsafe commands)
- Broken functionality (invalid references, syntax errors)

### HIGH Issues

Should fix for quality:

- Writing style violations (TO user instead of FOR Claude)
- Overly permissive tool access (allowing tools not needed)
- Missing argument handling or validation
- Poor error handling

### MEDIUM Issues

Consider fixing for improvement:

- Incomplete documentation in argument-hint
- Suboptimal organization or structure
- Missing edge case handling
- Redundant instructions

### LOW Issues

Nice to have polish:

- Style consistency with other commands
- Wording improvements
- Additional examples
- Formatting refinements

## Example Validation

```yaml
---
description: Create a git commit  # OK: Under 60 chars
argument-hint: "[message] - Optional commit message"  # OK: Documents args
allowed-tools: ["Bash"]  # OK: Minimal set
---
```

Content that passes validation:

```markdown
## Workflow

1. Run `git status` to check for changes
2. If no changes, report "Nothing to commit"
3. Stage all changes with `git add .`
4. Create commit with provided message or generate one
```

Content that fails validation:

```markdown
This command will help you create a git commit.  # BAD: Documentation style
You should first check for changes...  # BAD: Second person
```
