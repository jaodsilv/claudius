#!/bin/bash
# Adds user-invocable: false to internal helper skills
set -e

cd "$(dirname "$0")/.."

# Define internal skill patterns per plugin
declare -A PATTERNS
PATTERNS["gitx"]="^(validating-|committing-|classifying-|categorizing-|generating-|parsing-|getting-|selecting-|naming-|managing-|syncing-|performing-|posting-|rebasing-|merging-|orchestrating-|using-)"
PATTERNS["cc"]="^(analyzing-|validating-|improving-|orchestrating-)"
PATTERNS["planner.claude"]="^(analyzing-|planning-|prioritizing-|reviewing-|roadmapping-|synthesizing-|orchestrating-)"
PATTERNS["brainstorm.claude"]="^(analyzing-|researching-|synthesizing-|validating-)"
PATTERNS["review-loop"]="^(extending-|loading-)"

count=0

add_user_invocable() {
    local file="$1"
    local tmp=$(mktemp)

    # Read file line by line
    local in_frontmatter=0
    local frontmatter_start=0
    local added=0
    local in_multiline_desc=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "---" && $frontmatter_start -eq 0 ]]; then
            frontmatter_start=1
            in_frontmatter=1
            echo "$line" >> "$tmp"
        elif [[ "$line" == "---" && $in_frontmatter -eq 1 ]]; then
            in_frontmatter=0
            echo "$line" >> "$tmp"
        elif [[ $in_frontmatter -eq 1 ]]; then
            echo "$line" >> "$tmp"
            # Check if this is end of description (single line or end of multiline)
            if [[ "$line" =~ ^description:\ [^\>\|] && $added -eq 0 ]]; then
                # Single-line description, add after
                echo "user-invocable: false" >> "$tmp"
                added=1
            elif [[ "$line" =~ ^description:\ [\>\|] ]]; then
                # Start of multi-line description
                in_multiline_desc=1
            elif [[ $in_multiline_desc -eq 1 && "$line" =~ ^[a-z][-a-z0-9]*: && $added -eq 0 ]]; then
                # End of multi-line description (new field started)
                # We need to insert BEFORE this line - rewrite
                # This approach won't work well, let's use sed instead
                :
            fi
        else
            echo "$line" >> "$tmp"
        fi
    done < "$file"

    mv "$tmp" "$file"
}

for plugin in "${!PATTERNS[@]}"; do
    pattern="${PATTERNS[$plugin]}"

    if [[ ! -d "$plugin/skills" ]]; then
        continue
    fi

    for skill_dir in "$plugin/skills"/*/; do
        skill_name=$(basename "$skill_dir")
        skill_file="${skill_dir}SKILL.md"

        if [[ ! -f "$skill_file" ]]; then
            continue
        fi

        # Check if skill name matches pattern
        if ! echo "$skill_name" | grep -qE "$pattern"; then
            continue
        fi

        # Check if already has user-invocable
        if grep -q "^user-invocable:" "$skill_file"; then
            echo "SKIP: $skill_file"
            continue
        fi

        echo "UPDATE: $skill_file"

        # Find the line number after description ends
        # For multi-line: find line after description block
        # For single-line: find the description line

        # Get line number of description
        desc_line=$(grep -n "^description:" "$skill_file" | head -1 | cut -d: -f1)

        if [[ -z "$desc_line" ]]; then
            echo "  WARNING: No description found, skipping"
            continue
        fi

        # Check if multi-line (starts with >- or | or >)
        desc_content=$(sed -n "${desc_line}p" "$skill_file")

        if echo "$desc_content" | grep -qE "^description: [>|]"; then
            # Multi-line description - find next field
            next_field_line=$(tail -n +$((desc_line + 1)) "$skill_file" | grep -n "^[a-z][-a-z0-9]*:" | head -1 | cut -d: -f1)
            if [[ -n "$next_field_line" ]]; then
                insert_line=$((desc_line + next_field_line))
            else
                # No next field, insert before closing ---
                insert_line=$(grep -n "^---$" "$skill_file" | tail -1 | cut -d: -f1)
            fi
        else
            # Single-line description
            insert_line=$((desc_line + 1))
        fi

        # Insert user-invocable: false at the line
        sed -i "${insert_line}i\\user-invocable: false" "$skill_file"
        count=$((count + 1))
    done
done

echo ""
echo "Updated $count skills with user-invocable: false"
