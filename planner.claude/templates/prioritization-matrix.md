# Issue Prioritization

**Framework**: {{framework}}
**Issues Analyzed**: {{issue_count}}
**Date**: {{date}}
**Repository**: {{repository}}

---

## Summary

**Total Issues**: {{total_issues}}
**Ready to Work**: {{ready_count}}
**Blocked**: {{blocked_count}}
**High Priority (P0-P1)**: {{high_priority_count}}

---

## Priority Rankings

### P0 - Critical (Do Immediately)

| # | Title | Score | Effort | Status | Rationale |
|---|-------|-------|--------|--------|-----------|
| #{{issue_number}} | {{issue_title}} | {{score}} | {{effort}} | {{status}} | {{rationale}} |

### P1 - High Priority (Do This Sprint)

| # | Title | Score | Effort | Status | Rationale |
|---|-------|-------|--------|--------|-----------|
| #{{issue_number}} | {{issue_title}} | {{score}} | {{effort}} | {{status}} | {{rationale}} |

### P2 - Medium Priority (Plan for Next Sprint)

| # | Title | Score | Effort | Status | Rationale |
|---|-------|-------|--------|--------|-----------|
| #{{issue_number}} | {{issue_title}} | {{score}} | {{effort}} | {{status}} | {{rationale}} |

### P3 - Low Priority (Backlog)

| # | Title | Score | Effort | Status | Rationale |
|---|-------|-------|--------|--------|-----------|
| #{{issue_number}} | {{issue_title}} | {{score}} | {{effort}} | {{status}} | {{rationale}} |

---

## Dependency Graph

```mermaid
graph TD
    subgraph Ready
        {{ready_issues}}
    end

    subgraph Blocked
        {{blocked_issues}}
    end

    {{dependency_arrows}}
```

---

## Framework Breakdown

### {{framework}} Scoring Details

{{#if RICE}}

|---|-------|-------|--------|------------|--------|-------|
| #{{issue_number}} | {{issue_title}} | {{reach}} | {{impact}} | {{confidence}} | {{effort}} | {{score}} |
{{/if}}

{{#if MoSCoW}}
#### Must Have


#### Should Have
{{should_have_list}}

#### Could Have


#### Won't Have (This Release)
{{wont_have_list}}
{{/if}}

{{#if WeightedScoring}}
| # | Title | Value ({{value_weight}}%) | Feasibility ({{feasibility_weight}}%) | Alignment ({{alignment_weight}}%) | Risk ({{risk_weight}}%) | Total |
|---|-------|--------------------------|-------------------------------------|-----------------------------------|------------------------|-------|
| #{{issue_number}} | {{issue_title}} | {{value_score}} | {{feasibility_score}} | {{alignment_score}} | {{risk_score}} | {{total_score}} |
{{/if}}

---

## Issue Type Distribution

| Type | Count | % of Total |
|------|-------|------------|
| Bug | {{bug_count}} | {{bug_pct}}% |
| Feature | {{feature_count}} | {{feature_pct}}% |
| Enhancement | {{enhancement_count}} | {{enhancement_pct}}% |
| Tech Debt | {{tech_debt_count}} | {{tech_debt_pct}}% |
| Other | {{other_count}} | {{other_pct}}% |

---

## Effort Distribution

| Effort | Count | Total Person-Days |
|--------|-------|-------------------|
| XS | {{xs_count}} | {{xs_days}} |
| S | {{s_count}} | {{s_days}} |
| M | {{m_count}} | {{m_days}} |
| L | {{l_count}} | {{l_days}} |
| XL | {{xl_count}} | {{xl_days}} |

**Total Estimated Effort**: {{total_effort}} person-days

---

## Critical Path

The following issues are on the critical path and should be prioritized:

1. #{{critical_issue1}} → {{critical_issue1_title}}
2. #{{critical_issue2}} → {{critical_issue2_title}}
3. #{{critical_issue3}} → {{critical_issue3_title}}

**Critical Path Duration**: {{critical_path_duration}}

---

## Blocked Issues Analysis

| Issue | Blocked By | Estimated Unblock Date |
|-------|------------|------------------------|
| #{{blocked_issue}} | #{{blocker_issues}} | {{unblock_date}} |

---

## Recommendations

### Immediate Actions

1. {{recommendation1}}
2. {{recommendation2}}

### Sprint Planning Suggestions

- **Sprint Capacity**: {{sprint_capacity}} person-days
- **Recommended Issues**: {{recommended_issues}}
- **Expected Completion**: {{expected_issues_count}} issues

### Label Updates

```bash
# Apply priority labels
gh issue edit {{issue_number}} --add-label "{{priority_label}}"
```

---

## Notes

{{notes}}

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| {{date}} | 1.0 | Initial prioritization | {{author}} |
