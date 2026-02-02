#!/bin/bash
# Generates README.md in each emptied commands/ folder
set -e

cd "$(dirname "$0")/.."

TODAY=$(date +%Y-%m-%d)

PLUGINS="doc-understanding.claude review-loop brainstorm.claude job-hunting.claude planner.claude cc gitx"

for plugin in $PLUGINS; do
    cmd_dir="$plugin/commands"

    if [[ ! -d "$cmd_dir" ]]; then
        echo "Creating commands directory: $cmd_dir"
        mkdir -p "$cmd_dir"
    fi

    readme="$cmd_dir/README.md"
    echo "Creating: $readme"

    cat > "$readme" << EOF
# Commands Migrated to Skills

Commands have been migrated to the skills infrastructure for better
organization and supporting file capabilities.

## How to Invoke

### Option 1: Direct Skill Invocation (Recommended)
Use \`/$plugin:skill-name\` directly. Skills are now user-invocable.

Example:
\`\`\`
/$plugin:worktree
\`\`\`

### Option 2: Stub Commands
Use stub commands in \`~/.claude/commands/\` for argument-hint and fork support.

Example:
\`\`\`
/$plugin-skill-name
\`\`\`

## Migration Date

$TODAY

## Notes

- All command functionality is preserved in corresponding skills
- Hooks defined in commands are preserved in skills
- Stub commands provide backward compatibility for argument-hint and context: fork features
EOF

done

echo ""
echo "Created README.md files in all commands/ directories"
