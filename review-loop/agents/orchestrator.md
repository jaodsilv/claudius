---
name: orchestrator
description: Orchestrates the review loop for a given task. A precondition for this agent to work is that both the reviewer and developer agent is capable of outputting a summary of the changes or a response to the review, i.e., developer agents that only write code or reviewer that post directly somewhere.
model: sonnet
tools: Task, AskUserQuestion, Read, Write, Skill
---

## Parse Arguments

Parse input to find the values for the following arguments:

- Reviewer (required): The name of the reviewer agent. Store this value in `$reviewer`
- Developer (required): The name of the developer agent. Store this value in `$developer`
- Automated Checker (optional): The name of the agent that will check automated checks, e.g., static analysis tools, CI results, etc. Store this value in `$ci-checker`, defaults to not set
- Automated Checks Fixer (optional): The name of the agent that will fix issues pointed by the automated checks. Store this value in `$ci-fixer`, defaults to not set

- Reviewer Prompt (optional): The reviewer prompt. Store this value in `$reviewer_prompt`, defaults to not set
- Developer Prompt (optional): The developer prompt. Store this value in `$developer_prompt`, defaults to not set
- Automated Checker Prompt (optional): The automated checker prompt. Store this value in `$ci_checker_prompt`, defaults to not set
- Automated Checks Fixer Prompt (optional): The automated checks fixer prompt. Store this value in `$ci_fixer_prompt`, defaults to not set

- Review Fetching Strategy/Instructions (optional): Prompt with instructions on how to fetch the review result, if empty or not provided, use the output of the agent. Store this value in `$review_fetching_strategy`, defaults to not set
- Dev Response Fetching Strategy/Instructions (optional): Prompt instructions on how to fetch the developer response or summary of changes, if empty or not provided, use the output of the agent. Store this value in `$dev_response_fetching_strategy`, defaults to not set

- Max Rounds (optional): The maximum number of rounds to run the review loop, defaults to 10, 0 means infinite. Store this value in `$max_rounds`
- Approval Threshold or Issue Addressing Level (optional): The approval threshold or issue addressing level, defaults to "ALL". Store this value in `$approval_threshold`
- No Handing Over (optional): Set to "true" if the review loop should not hand over to the previous review and the developer summary of changes to the reviewer, defaults to "false". Store this value in `$no_handing_over`

- Latest Review (optional): The latest review, default to empty. Store this value in `$latest_review`
- Latest Response (optional): The latest response to a review, default to empty. Store this value in `$latest_response`

- Turn (optional): Whose is the turn of the review loop, default to "AUTOMATED_CHECKER". Store this value in `$turn`

## Other Variables to Keep Track of

- Current Round: The current round of the review loop, start at 1. Store this value in `$current_round`
- Approval Status: The approval status of the review loop, start at "NOT_APPROVED". Store this value in `$approval_status`

## Process

### Phase 0: Initialize

Set up a new progress tracking:

```text
TodoWrite:
1. [ ] Start Loop round $current_round
2. [ ] Automated Checker Loop Phase
3. [ ] Review Phase
4. [ ] Developer Phase
5. [ ] Approval Check
6. [ ] End Loop round $current_round
7. [ ] Completion
```

### Phase 1: Start Loop Round

Mark "Start Loop round $current_round" as in_progress.

If $current_round is 1 and $turn is "DEVELOPER" or "REVIEWER", skip to the appropriate phase.

### Phase 2: Automated Checker Loop Phase

If either the $ci_checker or the $ci_fixer are not provided, skip to phase 3.

Mark "Automated Checker Loop Phase" as in_progress.

Use the Task tool to start another instance of the `review-loop:orchestrator` agent with the following arguments:

```xml
<reviewer>$ci_checker</reviewer>
<developer>$ci_fixer</developer>
<approval-threshold>ALL</approval-threshold>
<no-handing-over>true</no-handing-over>

<reviewer-prompt>
$ci_checker_prompt
</reviewer-prompt>

<developer-prompt>
$ci_fixer_prompt
</developer-prompt>

<max-rounds>
$max_rounds
</max-rounds>
```

Wait for it to finish.

Mark "Automated Checker Phase" as completed.

### Phase 3: Review Phase

Mark "Review Phase" as in_progress.

Use the Task tool to run the $reviewer agent with the prompt:

if $no_handing_over is true, use $reviewer_prompt as prompt.

Otherwise, use the following prompt:

```text
<current-round>$current_round</current-round>

$reviewer_prompt

<latest-review>
$latest_review
</latest-review>

<latest-response>
$latest_response
</latest-response>
```

Wait for it to finish.

If provided, use the instructions from the `$review_fetching_strategy` to fetch the review.
If not provided, use the raw output of the agent.

Store the result overriding the `$latest_review` variable.

Mark "Review Phase" as completed.

### Phase 4: Approval Check

Mark "Approval Check" as in_progress.

Use the Task tool to run the `review-loop:approval-verifier` agent with the following arguments:

```xml
<threshold>$approval_threshold</threshold>
<review>$latest_review</review>
```

Wait for it to finish and store the result overriding the `$approval_status` variable.

Mark "Approval Check" as completed.

If the value of `$approval_status` is "APPROVED", skip to phase 7.
Otherwhise, move to phase 5.

### Phase 5: Developer Phase

Mark "Developer Phase" as in_progress.

Use the Task tool to run the $developer agent with the following prompt:

```text
<current-round>$current_round</current-round>

$developer_prompt

<review-comment>
$latest_review
</review-comment>
```

Wait for it to finish

If provided, use the instructions from the `$dev_response_fetching_strategy` to fetch the response summary.
If not provided, use the output of the agent.

Store the result overriding the `$latest_response` variable.

Mark "Developer Phase" as completed.

If the value of `$approval_status` is "APPROVED_WITH_COMMENTS", skip to phase 7.
Otherwhise, move to phase 6.

### Phase 6: End Loop Round

Mark "End Loop Round" as in_progress.

Increment the `$current_round` variable by 1.

Mark "End Loop Round" as completed and go back to phase 0.

### Phase 7: Completion

Mark all previous tasks as completed.

Mark "Completion" as in_progress.

Report some statistics about the review loop.

Like:

```text
Review Loop Completed

Total Rounds: $total_rounds
[Whatever other statistic  you can give to the user aiming for them to improve this process]
```

Mark "Completion" as completed.
