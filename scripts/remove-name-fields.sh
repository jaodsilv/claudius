#!/bin/bash
# Removes 'name:' field from YAML frontmatter in SKILL.md files
# Usage: ./scripts/remove-name-fields.sh [--dry-run]

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "DRY RUN MODE - no changes will be made"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

# Find all SKILL.md files with name: field in frontmatter (line 2 only)
count=0
for file in $(find . -name "SKILL.md" -type f); do
    # Check if line 2 starts with "name:"
    line2=$(sed -n '2p' "$file")
    if [[ "$line2" =~ ^name: ]]; then
        count=$((count + 1))
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "Would remove name: from $file"
        else
            echo "Removing name: from $file"
            # Delete line 2 (the name: line)
            sed -i '2d' "$file"
        fi
    fi
done

echo ""
echo "Total files processed: $count"
