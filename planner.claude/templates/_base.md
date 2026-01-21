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

This file provides reusable template sections for other templates in `planner.claude/templates/`.

**How templates reference this base**:

1. Other templates (e.g., `review-report.md`, `roadmap.md`) include a comment at the top:
   `<!-- Base sections: See _base.md for metadata, revision history, open questions, next steps templates -->`

2. When generating documents, agents should:
   - Copy the Metadata Header section to document start
   - Copy Open Questions section before next steps
   - Copy Next Steps section near document end
   - Copy Revision History section at document end

**Section placement**:
- **Metadata Header**: Always first, after title
- **Open Questions**: Before recommendations or next steps
- **Next Steps**: Near end, after recommendations
- **Revision History**: Always last section
