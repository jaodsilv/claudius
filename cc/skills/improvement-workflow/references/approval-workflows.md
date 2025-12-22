# Approval Workflows

Multi-step approval and batch processing patterns for improvement workflows.

## Approval Workflow Types

### Simple Approval

For single-item changes:

```text
1. Present change
2. Ask: "Apply this change?" (Yes/No)
3. Apply or skip based on response
```

### Batch Approval

For multiple related changes:

```text
1. Present all changes in category
2. Ask: "Apply all X changes?" (All/Select/Skip)
3. If "Select": present individual selection
4. Apply selected changes
```

### Cascading Approval

For changes with dependencies:

```text
1. Present change A
2. If approved, present dependent change B
3. Continue through dependency chain
4. Apply in correct order
```

### Deferred Approval

For changes that need review:

```text
1. Present all suggested changes
2. Ask: "Which to apply now?"
3. Save unapplied for later
4. Provide command to resume later
```

## Multi-Step Workflows

### Full Improvement Workflow

```text
Step 1: Analysis
├── Read component
├── Apply analysis framework
└── Generate suggestions

Step 2: Review
├── Present summary
├── Group by severity
└── Explain impacts

Step 3: Selection
├── Severity level selection
├── Individual item selection (if needed)
└── Confirmation of selections

Step 4: Application
├── Apply changes sequentially
├── Validate each change
└── Handle errors

Step 5: Summary
├── List applied changes
├── List skipped changes
└── Suggest next steps
```

### Quick Improvement Workflow

For time-sensitive improvements:

```text
Step 1: Quick Analysis
├── Focus on CRITICAL and HIGH only
└── Skip detailed assessment

Step 2: Batch Apply
├── Present changes
├── Apply all or none
└── Report results
```

## Batch Processing Patterns

### Severity-Based Batching

```text
Batch 1: CRITICAL (must fix)
├── Present all critical issues
├── Apply all (or abort)
└── Validate functionality

Batch 2: HIGH (should fix)
├── Present all high issues
├── Select which to apply
└── Apply selected

Batch 3: MEDIUM (optional)
├── Present all medium issues
├── Select which to apply
└── Apply selected

Batch 4: LOW (polish)
├── List all low issues
├── Offer bulk apply
└── Apply if requested
```

### File-Based Batching

For multi-file components (plugins, skills with references):

```text
Batch 1: Main file (SKILL.md, plugin.json)
├── Apply structural changes first
└── Validate main file

Batch 2: Reference files
├── Group by directory
├── Apply in parallel if independent
└── Validate each file

Batch 3: Cross-file changes
├── Apply interdependent changes
└── Validate all references
```

### Category-Based Batching

For mixed improvement types:

```text
Category 1: Structural changes
├── File moves, renames
├── Directory restructuring
└── Apply first

Category 2: Content changes
├── Text modifications
├── Code updates
└── Apply second

Category 3: Metadata changes
├── Frontmatter updates
├── Configuration changes
└── Apply third
```

## State Management

### Tracking Applied Changes

Maintain a list of applied changes for:
- Rollback capability
- Summary generation
- Conflict detection

```json
appliedChanges = [
  { file: "agent.md", line: 5, type: "edit", description: "Fixed frontmatter" },
  { file: "SKILL.md", line: 20, type: "edit", description: "Updated trigger" }
]
```

### Tracking Skipped Changes

Maintain for later reference:

```json
skippedChanges = [
  { severity: "MEDIUM", description: "Add more examples", reason: "User skipped" },
  { severity: "LOW", description: "Reformat tables", reason: "User skipped" }
]
```

## Recovery Patterns

### Partial Application Recovery

When some changes fail:

```text
1. Log successful changes
2. Report failed change with error
3. Ask: Continue with remaining changes?
4. Complete or abort based on response
5. Provide summary of partial state
```

### Rollback Pattern

If changes break functionality:

```text
1. Detect failure (test, validation)
2. Identify last known good state
3. Offer rollback option
4. Restore if requested
5. Report restored state
```
