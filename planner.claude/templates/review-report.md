# {{review_type}} Review Report

**Artifact Reviewed**: {{artifact_name}}
**Review Date**: {{date}}
**Reviewer**: Planner Plugin
**Goal/Context**: {{goal}}

---

## Executive Summary

**Overall Assessment**: {{overall_rating}} / 5

{{executive_summary}}

---

## Review Findings

### Strengths

1. **{{strength1_title}}**
   - {{strength1_detail}}
   - Impact: {{strength1_impact}}

2. **{{strength2_title}}**
   - {{strength2_detail}}
   - Impact: {{strength2_impact}}

### Areas for Improvement

1. **{{improvement1_title}}** ({{improvement1_severity}})
   - Issue: {{improvement1_issue}}
   - Suggestion: {{improvement1_suggestion}}
   - Impact if addressed: {{improvement1_impact}}

2. **{{improvement2_title}}** ({{improvement2_severity}})
   - Issue: {{improvement2_issue}}
   - Suggestion: {{improvement2_suggestion}}
   - Impact if addressed: {{improvement2_impact}}

### Critical Issues

{{#if has_critical_issues}}
1. **{{critical1_title}}**
   - Issue: {{critical1_issue}}
   - Why Critical: {{critical1_reason}}
   - Recommended Action: {{critical1_action}}
{{else}}
No critical issues identified.
{{/if}}

---

## Alignment Analysis

### Goal Alignment

| Aspect | Alignment Score | Notes |
|--------|-----------------|-------|
| Primary Goal | {{goal_alignment}}/5 | {{goal_notes}} |
| User Needs | {{user_alignment}}/5 | {{user_notes}} |
| Technical Feasibility | {{tech_alignment}}/5 | {{tech_notes}} |
| Resource Constraints | {{resource_alignment}}/5 | {{resource_notes}} |

### Gap Analysis

{{#if has_gaps}}
| Gap | Impact | Suggested Resolution |
|-----|--------|---------------------|
| {{gap1}} | {{gap1_impact}} | {{gap1_resolution}} |
| {{gap2}} | {{gap2_impact}} | {{gap2_resolution}} |
{{else}}
No significant gaps identified.
{{/if}}

---

## Completeness Check

| Element | Present | Quality | Notes |
|---------|---------|---------|-------|
| {{element1}} | {{element1_present}} | {{element1_quality}} | {{element1_notes}} |
| {{element2}} | {{element2_present}} | {{element2_quality}} | {{element2_notes}} |
| {{element3}} | {{element3_present}} | {{element3_quality}} | {{element3_notes}} |

**Completeness Score**: {{completeness_pct}}%

---

## Risk Assessment

### Identified Risks

| Risk | Probability | Impact | Current Mitigation | Adequate? |
|------|-------------|--------|-------------------|-----------|
| {{risk1}} | {{risk1_prob}} | {{risk1_impact}} | {{risk1_mitigation}} | {{risk1_adequate}} |
| {{risk2}} | {{risk2_prob}} | {{risk2_impact}} | {{risk2_mitigation}} | {{risk2_adequate}} |

### Risk Recommendations

1. {{risk_recommendation1}}
2. {{risk_recommendation2}}

---

## Feasibility Analysis

### Technical Feasibility

**Score**: {{tech_feasibility}}/5

{{tech_feasibility_analysis}}

### Resource Feasibility

**Score**: {{resource_feasibility}}/5

{{resource_feasibility_analysis}}

### Timeline Feasibility

**Score**: {{timeline_feasibility}}/5

{{timeline_feasibility_analysis}}

---

## Suggestions for Improvement

### High Priority

1. **{{high_priority1}}**
   - Current State: {{hp1_current}}
   - Recommended Change: {{hp1_change}}
   - Expected Benefit: {{hp1_benefit}}

2. **{{high_priority2}}**
   - Current State: {{hp2_current}}
   - Recommended Change: {{hp2_change}}
   - Expected Benefit: {{hp2_benefit}}

### Medium Priority

1. **{{medium_priority1}}**
   - Recommendation: {{mp1_recommendation}}

### Low Priority / Nice to Have

1. **{{low_priority1}}**
   - Recommendation: {{lp1_recommendation}}

---

## Questions for Discussion

1. {{question1}}
2. {{question2}}
3. {{question3}}

---

## Recommended Next Steps

### Immediate Actions

1. {{immediate1}}
2. {{immediate2}}

### Short-term Improvements

1. {{short_term1}}
2. {{short_term2}}

### Long-term Considerations

1. {{long_term1}}

---

## Review Methodology

This review was conducted using the following approach:

1. **Document Analysis**: Reviewed {{artifact_name}} for completeness and clarity
2. **Goal Alignment**: Compared artifact against stated goal: "{{goal}}"
3. **Best Practices Check**: Evaluated against industry best practices
4. **Risk Assessment**: Identified and evaluated potential risks
5. **Feasibility Analysis**: Assessed technical, resource, and timeline feasibility

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| {{date}} | 1.0 | Initial review | Planner Plugin |
