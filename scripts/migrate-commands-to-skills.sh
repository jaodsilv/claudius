#!/bin/bash
# Migrates commands to skills directory with frontmatter transformation
# Usage: ./scripts/migrate-commands-to-skills.sh [--dry-run] [--plugin <name>]

set -e

DRY_RUN=false
TARGET_PLUGIN=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --plugin) TARGET_PLUGIN="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

cd "$(dirname "$0")/.."

# Track metadata for stub generation
STUB_DATA_FILE=$(mktemp)

migrate_command() {
    local cmd_file="$1"
    local plugin_dir=$(dirname "$(dirname "$cmd_file")")
    local plugin_name=$(basename "$plugin_dir")
    local cmd_name=$(basename "$cmd_file" .md)
    local skill_dir="$plugin_dir/skills/$cmd_name"
    local skill_file="$skill_dir/SKILL.md"

    echo "Migrating: $cmd_file -> $skill_file"

    # Extract frontmatter fields we need for stub
    local arg_hint=$(grep "^argument-hint:" "$cmd_file" | sed 's/^argument-hint: *//' | sed 's/^"//' | sed 's/"$//')
    local context_fork=$(grep "^context: fork" "$cmd_file" || true)
    local description=$(grep "^description:" "$cmd_file" | sed 's/^description: *//')

    # Save stub data
    echo "$plugin_name|$cmd_name|$arg_hint|$context_fork|$description" >> "$STUB_DATA_FILE"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  DRY RUN - would create $skill_file"
        return
    fi

    # Create skill directory
    mkdir -p "$skill_dir"

    # Transform frontmatter and create skill file
    awk '
    BEGIN { in_fm=0; fm_done=0; added_invocable=0 }

    /^---$/ && !in_fm { in_fm=1; print; next }
    /^---$/ && in_fm {
        if (!added_invocable) {
            print "user-invocable: true"
            added_invocable=1
        }
        in_fm=0; fm_done=1; print; next
    }

    in_fm {
        # Skip argument-hint and context: fork (goes to stub)
        if (/^argument-hint:/) { next }
        if (/^context: fork/) { next }

        # After description, add user-invocable: true
        if (/^description:/ && !/^description: [>|]/) {
            # Single-line description
            print
            print "user-invocable: true"
            added_invocable=1
            next
        }
        if (/^description: [>|]/) {
            # Multi-line description starts
            in_desc=1
            print
            next
        }
        if (in_desc && /^[a-z][-a-z0-9]*:/) {
            # End of multi-line description
            if (!added_invocable) {
                print "user-invocable: true"
                added_invocable=1
            }
            in_desc=0
        }
        print
        next
    }

    { print }
    ' "$cmd_file" > "$skill_file"

    # Verify the skill file was created and has content
    if [[ ! -s "$skill_file" ]]; then
        echo "  ERROR: Skill file is empty, restoring from command"
        cp "$cmd_file" "$skill_file"
    fi

    # Delete original command file
    rm "$cmd_file"
    echo "  Migrated successfully"
}

# Find plugins with commands directories
plugins=""
if [[ -n "$TARGET_PLUGIN" ]]; then
    plugins="$TARGET_PLUGIN"
else
    # Process in order from plan
    plugins="doc-understanding.claude review-loop brainstorm.claude job-hunting.claude planner.claude cc gitx"
fi

for plugin in $plugins; do
    if [[ ! -d "$plugin/commands" ]]; then
        echo "Skipping $plugin (no commands directory)"
        continue
    fi

    echo ""
    echo "=== Processing plugin: $plugin ==="

    for cmd_file in "$plugin"/commands/*.md; do
        if [[ -f "$cmd_file" ]]; then
            migrate_command "$cmd_file"
        fi
    done
done

echo ""
echo "Migration complete!"
echo "Stub data saved to: $STUB_DATA_FILE"

if [[ "$DRY_RUN" == "false" ]]; then
    # Show remaining commands
    remaining=$(find . -path "*/commands/*.md" -type f 2>/dev/null | wc -l)
    echo "Remaining command files: $remaining"
fi
