---
name: gitx:using-gh-cli-for-reviews
description: >-
  Tool still under developmt. DO NOT USE UNLESS EXPLICITLY TOLD TO DO SO
version: 1.0.0
allowed-tools: Bash(gh:*), AskUserQuestion
model: haiku
---

## Standard workflow actions

1. Create a PR
2. Review a PR
   1. Create PR Review
   2. Create PR Review Thread
   3. Create PR Review Approving PR
3. Fetch PR Review Comments and Review Threads
4. Respond to a PR Review or Thread Comment
   1. Create PR Comment to respond to a Review
   2. Reply to a PR Review Thread
5. Change status of a PR Review or Thread Comment
   1. Hide a PR Review with reason "RESOLVED"
   2. Marking a PR Review Thread as resolved
   3. Dismiss a PR Review Thread
   4. "Dismiss" a PR Review

First action would be testing if the user reviewing the PR is the owner of the PR
If that is the case you cannot mark a review event as "APPROVED", "CHANGES_REQUESTED" or "DISMISSED"
Only "COMMENTED" is available

## General Case Commands

1. Create a PR:

   ```bash
   gh pr create --title "Title" --body "Body" --assignee @me --label "label" --milestone "milestone" --reviewer "reviewer"
   ```

## gh PR Review Commands

Checking if the user reviewing the PR is the owner of the PR with the Bash tool:

```bash
owner=$(gh pr view <pr> --json author --jq '.author.login') &&
reviewer=$(gh auth status -a --json hosts --jq '.hosts."github.com"[0].login') &&
if [[ "$owner" = "$reviewer" ]]; then echo "true"; else echo "false"; fi
```

### Case 1: Reviewer is the owner of the PR

Context: It does make sense in solo projects with the aid of AI, or depending on the project/team structure

1. Create a PR Review Comment:

   ```bash
   gh pr review <pr> -c -b "Body"
   ```

2. Listing Open Reviews:

   ```bash
   gh api graphql -f query='
   query($owner: String!, $repo: String!, $number: Int!) {
     repository(owner: $owner, name: $repo) {
       pullRequest(number: $number) {
         reviews(first: 100) {
           nodes {
             id
             databaseId
             body
             submittedAt
             isMinimized
           }
         }
       }
     }
   }' -f owner=<repo-owner> -f repo=<repo-name> -F number=<pr-number>   | jq '.data.repository.pullRequest.reviews.nodes[] | select(.isMinimized == false) | {nodeid: .id,
   id: .databaseId, body, submitted_at: .submittedAt}'
   ```

3. Create a PR Comment to respond to a Review Comment:

   ```bash
   gh pr comment <pr-number> -b "<response-body>"
   ```

4. Getting the latest PR non-review comment:

   ```bash
   gh pr view <pr-number> --json comments --jq '.comments[-1] | {nodeid: .id, body: .body, createdAt: .createdAt}'
   ```

5. Marking a PR Review Comment or PR Comment as Resolved:

   ```bash
   gh api graphql -f query='
   mutation($commentId: ID!, $reason: ReportedContentClassifiers!) {
     minimizeComment(input: {subjectId: $commentId, classifier: $reason}) {
       minimizedComment {
         isMinimized
         minimizedReason
       }
     }
   }' -f commentId="$nodeId" -f reason="RESOLVED"
   ```

6. "Dismiss" a PR Review Comment or PR Comment as "OUTDATED":

   ```bash
   gh api graphql -f query='
   mutation($commentId: ID!, $reason: ReportedContentClassifiers!) {
     minimizeComment(input: {subjectId: $commentId, classifier: $reason}) {
       minimizedComment {
         isMinimized
         minimizedReason
       }
     }
   }' -f commentId="$nodeId" -f reason="OUTDATED"
   ```
