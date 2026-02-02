# Commands Migrated to Skills

Commands have been migrated to the skills infrastructure for better
organization and supporting file capabilities.

## How to Invoke

### Option 1: Direct Skill Invocation (Recommended)
Use `/job-hunting.claude:skill-name` directly. Skills are now user-invocable.

Example:
```
/job-hunting.claude:worktree
```

### Option 2: Stub Commands
Use stub commands in `~/.claude/commands/` for argument-hint and fork support.

Example:
```
/job-hunting.claude-skill-name
```

## Migration Date

2026-01-30

## Notes

- All command functionality is preserved in corresponding skills
- Hooks defined in commands are preserved in skills
- Stub commands provide backward compatibility for argument-hint and context: fork features
