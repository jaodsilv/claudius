# Loading Review Loop Configuration

Knowledge for finding, parsing, and merging review-loop configuration files.

## When to Use

Apply this skill when:
- Starting a new review loop (`/start-loop`)
- Resuming a paused loop (`/resume-loop`)
- Creating or editing configuration (`/config`)
- Need to find and parse config files
- Merging CLI args with config values

## Config File Locations

Search in priority order (first found wins):

| Priority | Location | Description |
|----------|----------|-------------|
| 1 | Explicit `--config` path | User-specified config file |
| 2 | `$worktree/.config/review-loop/config.yaml` | Project-level config |
| 3 | `~/.config/review-loop/config.yaml` | User-level config |
| 4 | Plugin `defaults/config.yaml` | Plugin default (fallback) |

## Config File Schema

```yaml
version: 1

# Required agents
reviewer: "plugin:agent-name"
developer: "plugin:agent-name"

# Optional CI agents
ciChecker: "plugin:agent-name"
ciFixer: "plugin:agent-name"

# Loop settings
maxRounds: 5
approvalThreshold: all  # all | critical | important

# Custom prompts (optional)
prompts:
  reviewer: |
    Custom instructions for reviewer...
  developer: |
    Custom instructions for developer...
  ciChecker: |
    Custom instructions for CI checker...
  ciFixer: |
    Custom instructions for CI fixer...

# Fetching strategies (optional)
fetchingStrategies:
  review: |
    How to fetch context for review phase...
  response: |
    How to fetch context for response phase...
```

## Loading Algorithm

### Step 1: Determine Config Path

```
IF --config provided:
  configPath = --config value
  IF file not exists: ERROR "Config file not found: $path"
ELSE:
  FOR path IN [project, user, plugin-default]:
    IF file exists at path:
      configPath = path
      BREAK
  IF no config found:
    configPath = null (use CLI args only)
```

### Step 2: Parse Config File

If configPath is set:
1. Read YAML file content
2. Parse into structured data
3. Validate version field (must be 1)

### Step 3: Merge with CLI Arguments

Precedence: CLI args > config file > hardcoded defaults

```
FOR each field IN [reviewer, developer, ciChecker, ciFixer, ...]:
  IF CLI arg provided for field:
    finalValue = CLI arg
  ELSE IF config has field:
    finalValue = config value
  ELSE:
    finalValue = hardcoded default (if any)
```

### Step 4: Validate Required Fields

After merge, ensure:
- `reviewer` is set (required)
- `developer` is set (required)
- `maxRounds` > 0 (default: 5)
- `approvalThreshold` ∈ {all, critical, important} (default: all)

If validation fails, prompt user for missing values.

## Hardcoded Defaults

| Field | Default Value |
|-------|---------------|
| `maxRounds` | 5 |
| `approvalThreshold` | all |
| `reviewer` | (none - required) |
| `developer` | (none - required) |
| `ciChecker` | null |
| `ciFixer` | null |

## Reading Config with Bash

```bash
# Check if project config exists
if [[ -f "$worktree/.config/review-loop/config.yaml" ]]; then
  config_path="$worktree/.config/review-loop/config.yaml"
elif [[ -f "$HOME/.config/review-loop/config.yaml" ]]; then
  config_path="$HOME/.config/review-loop/config.yaml"
fi

# If yq is available, parse YAML
if command -v yq &> /dev/null && [[ -n "$config_path" ]]; then
  reviewer=$(yq '.reviewer // ""' "$config_path")
  developer=$(yq '.developer // ""' "$config_path")
  maxRounds=$(yq '.maxRounds // 5' "$config_path")
fi
```

## Reading Config with Read Tool

Prefer using the Read tool to read config files, then parse YAML inline:

1. Try reading `$worktree/.config/review-loop/config.yaml`
2. If not found, try `~/.config/review-loop/config.yaml`
3. Parse YAML content to extract values

## Resume Behavior

When resuming a loop with `/resume-loop`:

1. Re-read config file (allows config changes between sessions)
2. Apply any CLI overrides (e.g., `--reviewer`, `--max-rounds`)
3. Update metadata with new config values
4. Continue from current turn state

**Preserved on resume** (cannot change):
- worktree location
- reviewCount (history)
- turn state

**Can change on resume**:
- reviewer / developer agents
- maxRounds
- approvalThreshold
- ciChecker / ciFixer
- Custom prompts

## Error Handling

| Error | Action |
|-------|--------|
| Explicit --config not found | Error and exit |
| Auto-detected config not found | Continue with CLI args only |
| Invalid YAML syntax | Error with parse message |
| Missing required field after merge | Prompt user with AskUserQuestion |
| Invalid approvalThreshold value | Default to "all" with warning |
