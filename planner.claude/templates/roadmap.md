# Project Roadmap: {{project_name}}

**Goal**: {{goal}}
**Horizon**: {{horizon}}
**Created**: {{date}}
**Status**: {{status}}

---

## Executive Summary

{{executive_summary}}

---

## Roadmap Visualization

```mermaid
gantt
    title {{project_name}} Roadmap
    dateFormat YYYY-MM-DD

    section Phase 1: {{phase1_name}}
    {{phase1_task1}}    :{{phase1_task1_id}}, {{phase1_start}}, {{phase1_task1_duration}}
    {{phase1_task2}}    :{{phase1_task2_id}}, after {{phase1_task1_id}}, {{phase1_task2_duration}}

    section Phase 2: {{phase2_name}}
    {{phase2_task1}}    :{{phase2_task1_id}}, after {{phase1_task2_id}}, {{phase2_task1_duration}}
    {{phase2_task2}}    :{{phase2_task2_id}}, after {{phase2_task1_id}}, {{phase2_task2_duration}}
```

---

## Phase Details

### Phase 1: {{phase1_name}}

**Duration**: {{phase1_duration}}
**Objective**: {{phase1_objective}}
**Prerequisites**: {{phase1_prerequisites}}

#### Milestones

| ID   | Milestone           | Target Date         | Success Criteria        | Status                |
| ---- | ------------------- | ------------------- | ----------------------- | --------------------- |
| M1.1 | {{milestone1_name}} | {{milestone1_date}} | {{milestone1_criteria}} | {{milestone1_status}} |
| M1.2 | {{milestone2_name}} | {{milestone2_date}} | {{milestone2_criteria}} | {{milestone2_status}} |

#### Deliverables

1. **{{deliverable1_name}}**
   - Description: {{deliverable1_description}}
   - Owner: {{deliverable1_owner}}

2. **{{deliverable2_name}}**
   - Description: {{deliverable2_description}}
   - Owner: {{deliverable2_owner}}

#### Dependencies

- **External**: {{phase1_external_deps}}
- **Internal**: {{phase1_internal_deps}}

#### Risks

| Risk           | Probability    | Impact           | Mitigation           |
| -------------- | -------------- | ---------------- | -------------------- |
| {{risk1_name}} | {{risk1_prob}} | {{risk1_impact}} | {{risk1_mitigation}} |
| {{risk2_name}} | {{risk2_prob}} | {{risk2_impact}} | {{risk2_mitigation}} |

---

### Phase 2: {{phase2_name}}

**Duration**: {{phase2_duration}}
**Objective**: {{phase2_objective}}
**Prerequisites**: Phase 1 complete

#### Phase 2 Milestones

| ID   | Milestone          | Target Date        | Success Criteria       | Status               |
| ---- | ------------------ | ------------------ | ---------------------- | -------------------- |
| M2.1 | {{milestone_name}} | {{milestone_date}} | {{milestone_criteria}} | {{milestone_status}} |

#### Phase 2 Deliverables

1. **{{deliverable_name}}**
   - Description: {{deliverable_description}}
   - Owner: {{deliverable_owner}}

#### Phase 2 Dependencies

- Depends on: Phase 1 milestones M1.1, M1.2

#### Phase 2 Risks

| Risk          | Probability   | Impact          | Mitigation          |
| ------------- | ------------- | --------------- | ------------------- |
| {{risk_name}} | {{risk_prob}} | {{risk_impact}} | {{risk_mitigation}} |

---

## Resource Considerations

### Team Requirements

| Phase   | Role      | Allocation      |
| ------- | --------- | --------------- |
| Phase 1 | {{role1}} | {{allocation1}} |
| Phase 2 | {{role2}} | {{allocation2}} |

### Key Resources

{{resource_notes}}

---

## Success Metrics

| Metric           | Target             | Measurement Method | Frequency        |
| ---------------- | ------------------ | ------------------ | ---------------- |
| {{metric1_name}} | {{metric1_target}} | {{metric1_method}} | {{metric1_freq}} |
| {{metric2_name}} | {{metric2_target}} | {{metric2_method}} | {{metric2_freq}} |

---

## OKR Alignment

### Aligned Objectives

| Phase   | Objective      | Key Results Impacted |
| ------- | -------------- | -------------------- |
| Phase 1 | {{objective1}} | {{kr1}}, {{kr2}}     |
| Phase 2 | {{objective2}} | {{kr3}}, {{kr4}}     |

---

## Open Questions

1. {{question1}}
2. {{question2}}
3. {{question3}}

---

## Next Steps

1. {{next_step1}}
2. {{next_step2}}
3. {{next_step3}}

---

## Revision History

| Date     | Version | Changes         | Author     |
| -------- | ------- | --------------- | ---------- |
| {{date}} | 1.0     | Initial roadmap | {{author}} |
