# Resolution Options

User options for each conflict during guided resolution.

## AskUserQuestion Format

```text
Question: "Conflict in [file] at lines [X-Y]. How would you like to resolve?"
Options:
1. "Apply suggested resolution (Recommended)" - Use AI-suggested resolution
2. "Keep ours" - Keep current branch version
3. "Keep theirs" - Keep base/incoming branch version
4. "Resolve manually" - Open for manual editing
5. "Abort operation" - Cancel entire merge/rebase
```

## Resolution Actions

| Option | Command | Notes |
|--------|---------|-------|
| Apply suggested | Apply suggester code | Use resolution from Phase 2 |
| Keep ours | `git checkout --ours <file>` | Current branch wins |
| Keep theirs | `git checkout --theirs <file>` | Base branch wins |
| Manual | Show conflict markers | Wait for user edit |
| Abort | `git merge --abort` or `git rebase --abort` | Cancel operation |
