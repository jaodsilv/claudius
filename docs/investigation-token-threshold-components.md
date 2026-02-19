# Investigation: Components Affected by Token Threshold Changes for File Loading in Hooks

> **Date:** 2026-02-18
> **Status:** Verified
> **Branch:** `chore/review-skills-best-practices`

## Context

The `scripts/lib/count-tokens.py` estimates token usage. Thresholds in `inject_or_read()` determine when hooks **preload** file content inline (inject) vs. instruct the agent/skill to **read files itself** (explicit read). This affects hook behavior across the entire plugin ecosystem.

All plugin `lib/` directories are **symlinks** to `scripts/lib/`, confirmed:

```
analyzer/hooks/scripts/lib        -> ../../../scripts/lib
brainstorm.claude/hooks/scripts/lib -> ../../../scripts/lib
cc/hooks/scripts/lib               -> ../../../scripts/lib
gitx/hooks/scripts/lib             -> ../../../scripts/lib
planner.claude/hooks/scripts/lib   -> ../../../scripts/lib
review-loop/hooks/scripts/lib      -> ../../../scripts/lib
```

---

## Current Thresholds (in `inject_or_read`)

| Token Range | Haiku | Sonnet/Opus |
|---|---|---|
| < 500 | Inject inline | Inject inline |
| 500 - 9,999 | Inject inline | Explicit Read |
| 10,000+ | Explicit Read (with line-range hints) | Explicit Read |

**Source:** `scripts/lib/hook-output.sh` lines 119-127

```bash
if [[ "$tokens" -ge 10000 ]]; then
    strategy="read"
elif [[ "$tokens" -ge 500 ]]; then
    if [[ "$model" != "haiku" ]]; then
        strategy="read"
    fi
fi
```

---

## Central Files (Single Change Point)

| File | Role | Key Lines |
|---|---|---|
| `scripts/lib/hook-output.sh` | `inject_or_read()` -- the **only** function that applies token thresholds | 103-142 |
| `scripts/lib/count-tokens.py` | Token estimation engine (288 lines) called by `inject_or_read` | All |

---

## Hook Handler Scripts That Call `inject_or_read` (11 call sites)

### gitx plugin (8 call sites)

| Handler | Call Sites | Files Loaded | Consuming Agents |
|---|---|---|---|
| `gitx/hooks/scripts/handlers/ci-pre-tool.sh` | 6 calls (lines 63, 136, 137, 160, 182, 204) | CI failure logs, analysis files, task files, plan files from `.thoughts/pr/ci/` | `gitx:ci:failure-analyzer`, `gitx:ci:analysis-merger`, `gitx:ci:analysis-splitter`, `gitx:ci:fix-planner`, `gitx:ci:fixer` |
| `gitx/hooks/scripts/handlers/commit-push-inject-diff.sh` | 1 call (line 172) | `.claude/commit-conventions.yaml` | `gitx:commit:commit-writer` (via `gitx:committing-conventionally` skill) |
| `gitx/hooks/scripts/handlers/review.sh` | 1 call (line 57) | `.thoughts/pr/review-prompt.txt` | `gitx:review:reviewer` (via `gitx:review` skill) |

### analyzer plugin (3 call sites)

| Handler | Call Sites | Files Loaded | Consuming Agents |
|---|---|---|---|
| `analyzer/hooks/scripts/analyzer-pre-task.sh` | 3 calls (lines 75, 103, 118) | Analysis files, input files from `.thoughts/analyzer/` | `analyzer:analysis-splitter`, `analyzer:analyses-merger`, `analyzer:adversarial-critic` |

> **Note:** Line 103 is inside a `for` loop, so at runtime it may execute multiple times per invocation.

---

## Hook Handlers That Use `hook_output_context` WITHOUT `inject_or_read` (Always-Inject Pattern)

These handlers inject content directly -- they do NOT use token-based thresholds. If threshold coverage is needed here, they would require modification.

### gitx plugin

| Handler | Content Injected | Consuming Skill/Agent |
|---|---|---|
| `inject-pr-metadata.sh` (lines 67, 84, 101) | PR metadata fields from `.thoughts/pr/metadata.yaml` (parsed via `yq`) | `gitx:address-review:review-responder`, `gitx:address-review:ci-status-checker`, `gitx:pr:updater` |
| `commit-push-inject-diff.sh` (line 181) | Git diffs (raw `git diff` output, **unbounded size**) | `gitx:commit:commit-writer`, `gitx:commit:file-selector`, `gitx:commit:change-grouper` |
| `commit-push-pre.sh` (line 187) | File lists and status JSON | `gitx:commit-push` skill |
| `address-review.sh` (line 47) | `<worktree>` + Turn | `gitx:address-review` skill |
| `next-turn.sh` (line 40) | `<worktree>` + `--turn` | `gitx:next-turn` skill |
| `pr.sh` (line 20) | `<worktree>` | `gitx:pr` skill |
| `pre-update-pr.sh` (line 19) | `<worktree>` | `gitx:update-pr` skill |
| `comment-to-pr.sh` (line 114) | `<worktree>` + PR# + Turn | `gitx:comment-to-pr` skill |
| `address-ci.sh` (line 35) | CI failure count string | `gitx:address-ci` skill |

### analyzer plugin

| Handler | Content Injected | Consuming Skill |
|---|---|---|
| `analyze.sh` (line 9) | `<worktree>` | `analyzer:analyze` skill |
| `split-analysis.sh` (line 20) | `<worktree>` | `analyzer:split-analysis` skill (via command) |
| `merge-analyses.sh` (line 26) | `<worktree>` | `analyzer:merge-analyses` skill (via command) |
| `challenge.sh` (line 9) | `<worktree>` | `analyzer:challenge` skill (via command) |

### review-loop plugin

| Handler | Content Injected | Consuming Skill |
|---|---|---|
| `start-loop.sh` (line 22) | `<worktree>` | `review-loop:start-loop` skill |
| `resume-loop.sh` (lines 31, 44) | `<worktree>` + `<pr-metadata>` (review-loop state, turn, review count, approved) | `review-loop:resume-loop` skill |

---

## Agents Affected (Receive Hook-Injected Content)

### Agents receiving `inject_or_read` content (threshold-dependent)

| Agent | Plugin | Files Injected |
|---|---|---|
| `gitx:ci:failure-analyzer` | gitx | CI failure logs |
| `gitx:ci:analysis-merger` | gitx | Two analysis markdown files |
| `gitx:ci:analysis-splitter` | gitx | One analysis markdown file |
| `gitx:ci:fix-planner` | gitx | Task analysis file |
| `gitx:ci:fixer` | gitx | Fix plan file |
| `gitx:commit:commit-writer` | gitx | Commit conventions YAML (indirectly, via skill) |
| `gitx:review:reviewer` | gitx | Review prompt text |
| `analyzer:analysis-splitter` | analyzer | Full analysis markdown |
| `analyzer:analyses-merger` | analyzer | Multiple analysis files |
| `analyzer:adversarial-critic` | analyzer | Input content file |

### Agents receiving always-injected content (NOT threshold-gated today)

| Agent | Plugin | Content Injected |
|---|---|---|
| `gitx:address-review:review-responder` | gitx | PR metadata (PR#, branch, reviews JSON) |
| `gitx:address-review:ci-status-checker` | gitx | PR metadata (PR#, branch, CI status JSON) |
| `gitx:pr:updater` | gitx | PR metadata (PR#, branch, title, description) |
| `gitx:commit:commit-writer` | gitx | Git diffs (**unbounded**) |
| `gitx:commit:file-selector` | gitx | Git diffs (**unbounded**) |
| `gitx:commit:change-grouper` | gitx | Git diffs (**unbounded**) |

---

## Skills Affected (Receive Hook Additional Context)

### Skills consuming `inject_or_read` output

| Skill | Plugin | Content Received |
|---|---|---|
| `gitx:committing-conventionally` | gitx | Commit conventions YAML |
| `gitx:review` | gitx | Review prompt text |

### Skills consuming always-injected output

| Skill | Plugin | Content Received |
|---|---|---|
| `gitx:commit-push` | gitx | File lists/status |
| `gitx:address-review` | gitx | Worktree + turn |
| `gitx:next-turn` | gitx | Worktree + turn |
| `gitx:pr` | gitx | Worktree |
| `gitx:update-pr` | gitx | Worktree |
| `gitx:comment-to-pr` | gitx | Worktree + comment metadata |
| `gitx:address-ci` | gitx | CI failure count |
| `analyzer:analyze` | analyzer | Worktree |
| `analyzer:split-analysis` | analyzer | Worktree |
| `analyzer:merge-analyses` | analyzer | Worktree |
| `analyzer:challenge` | analyzer | Worktree |
| `review-loop:start-loop` | review-loop | Worktree |
| `review-loop:resume-loop` | review-loop | Worktree + PR metadata |

---

## Scripts Affected

| Script | Role | Impact |
|---|---|---|
| `scripts/lib/hook-output.sh` | Defines `inject_or_read()` | **Primary change target** -- threshold values live here (lines 119-127) |
| `scripts/lib/count-tokens.py` | Token estimation | May need updates if threshold logic moves here or new output modes are needed |
| `scripts/lib/args-validator.sh` | Sources `hook-output.sh` at line 24 | Indirectly affected -- any handler using `args-validator.sh` also gets `inject_or_read` |

---

## Key Observations

1. **Single change point**: Modifying thresholds in `inject_or_read()` (`hook-output.sh` lines 119-127) affects all 11 call sites across gitx and analyzer plugins automatically via symlinks.

2. **Git diffs are the biggest gap**: `commit-push-inject-diff.sh` injects raw git diffs (potentially very large) via `hook_output_context` WITHOUT any token-based gating. This is the highest-impact area for adding threshold control.

3. **PR metadata is always small**: `inject-pr-metadata.sh` extracts individual YAML fields -- these are consistently small and don't need threshold gating.

4. **Worktree-only injections are trivial**: Many handlers inject just `<worktree>path</worktree>` -- these are always under 100 tokens and need no threshold logic.

5. **review-loop resume metadata is moderate**: `resume-loop.sh` injects review-loop state from YAML which could grow with review history, but is typically small.

6. **Plugins using thresholds today**: Only **gitx** (ci-pre-tool.sh, commit-push-inject-diff.sh, review.sh) and **analyzer** (analyzer-pre-task.sh). Other plugins (review-loop, brainstorm, planner, cc) do not use `inject_or_read` at all.

---

## Verification Notes

During verification of the original plan, two discrepancies were found and corrected:

1. **Call site count corrected**: Original plan stated "13 call sites" -- actual verified count is **11 static call sites** (6 in ci-pre-tool.sh + 1 in commit-push-inject-diff.sh + 1 in review.sh + 3 in analyzer-pre-task.sh).

2. **Code comment fixed**: `hook-output.sh` line 93 originally said "Medium (500-8K tok)" but the actual code threshold at line 121 is `>= 10000` (10K). Comment was corrected to "Medium (500-10K tok)".
