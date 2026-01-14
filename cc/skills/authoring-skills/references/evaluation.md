# Skill Evaluation and Iteration

Guidelines for testing skills and improving them over time.

## Build Evaluations First

Create evaluations BEFORE extensive documentation.

### Evaluation-Driven Development

1. **Identify gaps**: Run Claude on tasks without skill. Document failures
2. **Create evaluations**: Build 3+ scenarios testing gaps
3. **Establish baseline**: Measure performance without skill
4. **Write minimal instructions**: Just enough to pass evaluations
5. **Iterate**: Execute, compare to baseline, refine

### Evaluation Structure

```json
{
  "skills": ["pdf-processing"],
  "query": "Extract all text from this PDF and save to output.txt",
  "files": ["test-files/document.pdf"],
  "expected_behavior": [
    "Successfully reads the PDF using appropriate library",
    "Extracts text from all pages without missing any",
    "Saves extracted text to output.txt in readable format"
  ]
}
```

## Iterative Development with Claude

Work with Claude A (author) to create skills for Claude B (tester).

### Creating New Skills

1. **Complete task without skill**: Work through problem, note what context you provide
2. **Identify reusable pattern**: What information helps similar future tasks?
3. **Ask Claude A to create skill**: "Create a skill capturing this pattern"
4. **Review for conciseness**: Remove unnecessary explanations
5. **Improve architecture**: Organize content, split to reference files
6. **Test with Claude B**: Use skill on related tasks
7. **Iterate**: Return to Claude A with observations

### Iterating Existing Skills

1. **Use skill in real workflows**: Give Claude B actual tasks
2. **Observe behavior**: Note struggles, successes, unexpected choices
3. **Return to Claude A**: Share observations, ask for improvements
4. **Review suggestions**: Consider reorganizing, stronger language
5. **Apply and test**: Update skill, test again
6. **Repeat**: Continue observe-refine-test cycle

## Navigation Observation

Watch how Claude actually uses skills:

| Observation | Indicates |
|-------------|-----------|
| Unexpected exploration paths | Structure not intuitive |
| Missed references | Links need prominence |
| Overreliance on one section | Content should be in SKILL.md |
| Ignored content | File unnecessary or poorly signaled |

## Team Feedback

1. Share skills with teammates
2. Ask: Does skill activate when expected? Clear instructions? What's missing?
3. Incorporate feedback to address blind spots

## Key Insight

Claude A understands agent needs. You provide domain expertise. Claude B reveals gaps
through usage. Iterative refinement improves skills based on observed behavior,
not assumptions.
