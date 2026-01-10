# Base Template Sections

Common template sections for planner plugin outputs.

## Metadata Header

```template
# {{document_title}}

**Created**: {{date}}
**Author**: {{author}}
**Status**: {{status}}
**Goal/Context**: {{goal}}

---
```

## Revision History

```template
## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| {{date}} | 1.0 | Initial creation | {{author}} |
```

## Open Questions

```template
## Open Questions

1. {{question1}}
2. {{question2}}
3. {{question3}}
```

## Next Steps

```template
## Next Steps

### Immediate Actions
1. {{immediate1}}
2. {{immediate2}}

### Short-term
1. {{short_term1}}

### Long-term Considerations
1. {{long_term1}}
```

## Usage

Reference these sections in other templates:
- Include `{{> _base.metadata}}` at document start
- Include `{{> _base.revision_history}}` at document end
- Include `{{> _base.open_questions}}` before next steps
- Include `{{> _base.next_steps}}` at document end
