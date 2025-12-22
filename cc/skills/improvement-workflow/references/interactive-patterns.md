# Interactive Patterns

Detailed patterns for user interaction in improvement workflows.

## AskUserQuestion Patterns

### Severity Selection

Use when presenting multiple severity levels:

```
questions: [
  {
    question: "Which severity levels would you like to address?",
    header: "Severity",
    multiSelect: true,
    options: [
      { label: "CRITICAL (3 issues)", description: "Must fix - broken functionality or security risks" },
      { label: "HIGH (5 issues)", description: "Should fix - best practice violations" },
      { label: "MEDIUM (8 issues)", description: "Consider fixing - enhancement opportunities" },
      { label: "LOW (2 issues)", description: "Optional - polish and refinement" }
    ]
  }
]
```

### Individual Improvement Selection

Use when user wants fine-grained control:

```
questions: [
  {
    question: "Which improvements would you like to apply?",
    header: "Changes",
    multiSelect: true,
    options: [
      { label: "Fix frontmatter syntax", description: "CRITICAL: description field missing quotes" },
      { label: "Add trigger examples", description: "HIGH: agent needs 2-4 example blocks" },
      { label: "Improve description", description: "MEDIUM: make trigger phrases more specific" },
      { label: "Format code blocks", description: "LOW: standardize code block formatting" }
    ]
  }
]
```

### Confirmation Before Major Changes

Use for significant structural changes:

```
questions: [
  {
    question: "This will restructure the skill into SKILL.md + references/. Proceed?",
    header: "Confirm",
    multiSelect: false,
    options: [
      { label: "Yes, restructure", description: "Move detailed content to references/ directory" },
      { label: "No, keep as-is", description: "Leave current structure unchanged" },
      { label: "Show preview", description: "Display proposed structure before deciding" }
    ]
  }
]
```

### Skip Options

Always provide escape routes:

```
questions: [
  {
    question: "Apply all HIGH priority improvements?",
    header: "Batch",
    multiSelect: false,
    options: [
      { label: "Yes, apply all", description: "Apply all 5 HIGH priority improvements" },
      { label: "Select individually", description: "Choose specific improvements to apply" },
      { label: "Skip HIGH issues", description: "Move to MEDIUM priority improvements" }
    ]
  }
]
```

## Interaction Flow Patterns

### Progressive Disclosure Flow

1. Show summary first
2. Offer to expand details
3. Allow drill-down into specific issues

### Batch-Then-Individual Flow

1. Offer batch application by severity
2. If rejected, offer individual selection
3. Apply selected items
4. Confirm completion

### Preview-Then-Apply Flow

1. Show proposed changes
2. Get explicit approval
3. Apply changes
4. Show results

## Error Handling in Interactions

### When User Selects Nothing

```markdown
No improvements selected. Options:
1. Return to selection
2. View suggestions again
3. Exit without changes
```

### When Changes Conflict

```markdown
Improvements #2 and #5 conflict (both modify the same section).
Select which to apply:
1. Apply #2 only
2. Apply #5 only
3. Skip both
```

### When Changes Fail

```markdown
Failed to apply improvement #3: [error message]
Options:
1. Retry
2. Skip and continue
3. Abort remaining changes
```

## User Communication Guidelines

1. Be specific about what will change
2. Show before/after for significant changes
3. Provide clear escape routes
4. Confirm success after each change
5. Summarize all changes at the end
