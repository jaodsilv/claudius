#!/bin/bash
# Handler for /gitx:ignore command
# Create empty .gitignore if missing

log_section "Ignore Handler"

GITIGNORE="$WORKTREE/.gitignore"
log_debug "GITIGNORE_PATH" "$GITIGNORE"

if [[ ! -f "$GITIGNORE" ]]; then
  log_info "Creating empty .gitignore"
  touch "$GITIGNORE"
  echo "Created empty .gitignore file"
else
  log_info ".gitignore already exists"
fi

log_exit 0 "proceed"
exit 0
