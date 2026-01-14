---
description: Starts a review loop for a given task.
argument-hint: --reviewer <reviewer-agent> --developer <developer-agent> --reviewer-prompt <reviewer-prompt> --developer-prompt <developer-prompt> [--review-fetching-strategy <review-fetching-strategy>] [--dev-response-fetching-strategy <dev-response-fetching-strategy>] [--max-rounds <max-rounds>] [--approval-threshold <approval-threshold>]
allowed-tools: Task
model: haiku
---

Use the Task tool to run the `review-loop:orchestrator` agent with the $ARGUMENTS as prompt.
