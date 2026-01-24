# Planner Session Start Hook

This file documents the SessionStart hook behavior. The actual hook is implemented
as a command hook in `hooks.json` that runs `scripts/check-dependencies.sh`.

## Purpose

Check for optional plugin dependencies and provide template paths at session start.
Early detection prevents cryptic failures mid-workflow, and template paths enable
agents to correctly locate templates.

## Implementation

The hook is defined in `hooks.json` as a command hook:

```json
{
  "type": "command",
  "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/scripts/check-dependencies.sh\"",
  "timeout": 10
}
```

The script returns JSON with:

- `systemMessage`: Warnings about missing dependencies
- `hookSpecificOutput.additionalContext`: Template paths for agents to use

## Checks Performed

### 1. GitHub CLI (gh)

- Checks if `gh` command is available
- Checks if `gh` is authenticated
- Warns if missing or not authenticated

### 2. Brainstorm Plugin

- Checks for `brainstorm.claude/.claude-plugin/plugin.json`
- Informs if available for enhanced requirements gathering

## Template Paths Provided

The hook provides paths to all templates via `additionalContext`:

| Template              | Path                                               | Location                                     |
| --------------------- | -------------------------------------------------- | -------------------------------------------- |
| Review Report         | `${PLUGIN_ROOT}/templates/review-report.md`        | planner.claude/templates/review-report.md    |
| Roadmap               | `${PLUGIN_ROOT}/templates/roadmap.md`              | planner.claude/templates/roadmap.md          |
| Prioritization        | `${PLUGIN_ROOT}/templates/prioritization-matrix.md`| planner.claude/templates/prioritization-matrix.md |
| Requirements Summary  | `${PLUGIN_ROOT}/templates/requirements-summary.md` | planner.claude/templates/requirements-summary.md |
| Ideas Synthesis       | `${PLUGIN_ROOT}/templates/ideas-synthesis.md`      | planner.claude/templates/ideas-synthesis.md  |
| Base Sections         | `${PLUGIN_ROOT}/templates/_base.md`                | planner.claude/templates/_base.md            |

All templates are located in `planner.claude/templates/` and are accessible via the paths above.

## How Agents Access Templates

Templates should be referenced in the following ways:

1. **In Commands**: Use the template path directly from hook context:


   ```
   Use the review-report template from ${PLUGIN_ROOT}/templates/review-report.md
   ```


2. **From Session Context**: Templates are provided in hook output, reference by name:

   ```
   Use the review-report template provided in session context
   ```


3. **Explicit Path**: For direct file operations, use the absolute path pattern:

   ```
   ${PLUGIN_ROOT}/templates/[template-name].md
   ```

The `_base.md` file provides shared template sections referenced by other templates and should be
consulted when understanding the full structure of any output template.
