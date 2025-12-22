---
description: Analyze and improve an existing skill interactively
argument-hint: <skill-path> [--focus "<aspect>"]
allowed-tools: ["Read", "Glob", "Grep", "AskUserQuestion", "Skill", "Task", "Bash", "TodoWrite"]
---

# Improve Skill Workflow

Analyze an existing skill and suggest improvements interactively.

## Input Processing

Arguments: <arguments>$ARGUMENTS</arguments>

Parse:
1. `skill_path`: Path to skill directory or SKILL.md file (required)
   - If directory provided, look for SKILL.md within it
2. `focus`: Optional aspect to focus on (--focus "...")

If skill_path not provided, ask user to specify.
If focus provided, prioritize analysis of that aspect.

## Execution

Use TodoWrite to track progress:
- [ ] Phase 1: Analyze skill
- [ ] Phase 2: Present suggestions
- [ ] Phase 3: Select improvements
- [ ] Phase 4: Plan changes
- [ ] Phase 5: Apply changes
- [ ] Phase 6: Validate results

### Phase 1: Analysis

Load the improvement-workflow skill:


```
Use Skill tool to load cc:improvement-workflow
```

Use Task tool with @cc:skill-improver agent:

```
Analyze skill: [skill_path]
Focus area: [focus if provided, otherwise "general analysis"]

Evaluate:
1. SKILL.md frontmatter (name, description, version)
2. Description quality (third-person, trigger phrases)
3. Body structure (imperative form, not second-person)
4. Progressive disclosure:
   - SKILL.md length (1500-2000 words ideal, <5000 max)
   - References directory usage
   - Examples directory usage
   - Scripts directory usage
5. Resource references in SKILL.md
6. Trigger phrase specificity
7. Writing style consistency

Provide improvement suggestions with severity levels.
```

### Phase 2: Present Suggestions

Categorize suggestions:

1. Description improvements (triggers, third-person)
2. Content organization (progressive disclosure)
3. Writing style fixes (imperative form)
4. Resource additions/restructuring

Use AskUserQuestion:

```
Question: "Which categories would you like to address?"
Header: "Categories"
multiSelect: true
Options:
- Description (X issues) - Improve trigger phrases
- Organization (X issues) - Progressive disclosure
- Writing Style (X issues) - Imperative form
- Resources (X issues) - Add/restructure files
```

### Phase 3: Select Improvements

For each selected category, present specific improvements:

```
Question: "Which [category] improvements would you like to apply?"
Header: "Changes"
multiSelect: true
Options: [List improvements in category]
```

### Phase 4: Plan Changes

Mark todo: Phase 3 complete, Phase 4 in progress.

Use Task tool with @cc:change-planner agent:

```
Plan changes for skill: [skill_path]

Selected improvements:
[List of selected improvements with their details]

For content reorganization (SKILL.md → references/):
- Plan new file creation first
- Then plan content removal from SKILL.md
- Then plan reference pointer addition

Return a structured change plan with:
- Ordered steps
- Before/after content for each change
- Validation criteria
```

### Phase 5: Apply Changes

Mark todo: Phase 4 complete, Phase 5 in progress.

Use Task tool with @cc:component-writer agent:

```
Apply change plan to skill: [skill_path]

Change plan:
[Change plan from Phase 4]

For content reorganization:
- Create new reference files first
- Then modify SKILL.md

Apply each change in order.
Validate syntax after each edit.
Report success/failure for each step.
```

### Phase 6: Validation

Mark todo: Phase 5 complete, Phase 6 in progress.

1. Review the application report from component-writer
2. If any failures occurred, report them to user
3. Re-read the modified skill to verify
4. Validate SKILL.md structure and word count
5. Verify all referenced files exist
6. Present summary of all changes made
7. Suggest testing trigger phrases

Mark todo: Phase 6 complete.

## Special Operations

### Content Reorganization

If moving content from SKILL.md to references/:

1. Identify content to move
2. Create new file in references/ directory
3. Write content to new file
4. Replace content in SKILL.md with reference pointer
5. Validate both files

### Creating Missing Directories


If examples/ or scripts/ needed:

```bash
mkdir -p [skill-path]/examples
mkdir -p [skill-path]/scripts
```

## Error Handling

If skill not found:
- Report error clearly
- Suggest using Glob to find skills: `Glob pattern="**/skills/**/SKILL.md"`
- List any skill directories found without SKILL.md

If SKILL.md missing in directory:
- Report the issue
- Offer to create basic SKILL.md with frontmatter template

If analysis fails:
- Report partial results if available
- Suggest manual review with checklist:
  1. Check SKILL.md frontmatter has name, description, version
  2. Verify description uses third-person
  3. Check body uses imperative form
  4. Review word count (1500-2000 ideal)

If change planning fails:
- Report error from change-planner agent
- Show the selected improvements for manual review
- Suggest manual ordering if needed

If application fails:
- Review component-writer's application report
- Report which changes succeeded and which failed
- For failed changes, show intended modification for manual application
- Offer to retry failed changes or proceed with successful ones
