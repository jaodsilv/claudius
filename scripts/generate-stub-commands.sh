#!/bin/bash
# Generates stub commands in ~/.claude/commands/ (flat structure)
# Reads original command metadata from git history
set -e

cd "$(dirname "$0")/.."

STUB_DIR="$HOME/.claude/commands"
mkdir -p "$STUB_DIR"

# List of plugins and their skills (former commands)
declare -A PLUGINS
PLUGINS["doc-understanding.claude"]="download"
PLUGINS["review-loop"]="config resume-loop start-loop"
PLUGINS["brainstorm.claude"]="continue export start"
PLUGINS["job-hunting.claude"]="add-to-history eval-cover-letter eval-cover-letterv2 improve-cover-letter new-history overlap-analysis"
PLUGINS["planner.claude"]="gather-requirements ideas prioritize review-architecture review-plan review-prioritization review-requirements review-roadmap roadmap"
PLUGINS["cc"]="bump-version create-command create-orchestration create-output-style create-skill improve-agent improve-command improve-orchestration improve-output-style improve-plugin improve-skill sync-configs"
PLUGINS["gitx"]="address-ci address-review comment-to-issue comment-to-pr commit-push create-issue fix-issue ignore merge merge-pr next-issue next-turn pr rebase refresh-metadata remove-branch remove-worktree review update-pr worktree"

count=0

for plugin in "${!PLUGINS[@]}"; do
    skills="${PLUGINS[$plugin]}"

    for skill in $skills; do
        cmd_path="$plugin/commands/$skill.md"
        stub_file="$STUB_DIR/${plugin}-${skill}.md"

        echo "Creating stub: $stub_file"

        # Try to get original command from git
        original=$(git show "HEAD:$cmd_path" 2>/dev/null || echo "")

        if [[ -z "$original" ]]; then
            # Command wasn't in HEAD, check if skill exists
            if [[ -f "$plugin/skills/$skill/SKILL.md" ]]; then
                desc=$(grep "^description:" "$plugin/skills/$skill/SKILL.md" | head -1 | sed 's/^description: *//' | sed 's/^>-$//')
                if [[ -z "$desc" || "$desc" == ">-" ]]; then
                    # Multi-line description, get first content line
                    desc=$(sed -n '/^description:/,/^[a-z]/p' "$plugin/skills/$skill/SKILL.md" | sed -n '2p' | sed 's/^  //')
                fi
                arg_hint=""
                has_fork=""
            else
                echo "  WARNING: Cannot find command or skill, skipping"
                continue
            fi
        else
            # Extract from original command
            desc=$(echo "$original" | grep "^description:" | sed 's/^description: *//')
            arg_hint=$(echo "$original" | grep "^argument-hint:" | sed 's/^argument-hint: *//' | sed 's/^"//' | sed 's/"$//')
            has_fork=$(echo "$original" | grep "^context: fork" || true)
        fi

        # Create stub file
        cat > "$stub_file" << EOF
---
description: ${desc:-Invokes $plugin:$skill skill}
EOF

        if [[ -n "$arg_hint" ]]; then
            echo "argument-hint: \"$arg_hint\"" >> "$stub_file"
        fi

        cat >> "$stub_file" << EOF
allowed-tools: Skill
EOF

        if [[ -n "$has_fork" ]]; then
            echo "context: fork" >> "$stub_file"
        fi

        cat >> "$stub_file" << EOF
model: haiku
---

Invoke the skill \`$plugin:$skill\` with the Skill tool, passing \$ARGUMENTS.
EOF

        count=$((count + 1))
    done
done

echo ""
echo "Created $count stub commands in $STUB_DIR"
