# MoSCoW Prioritization Guide

MoSCoW is a prioritization framework that categorizes requirements into four categories to manage scope and delivery expectations.

## Priority Levels

| Level | Name | Description | Example |
|-------|------|-------------|---------|
| P1 | Must Have | Essential for MVP or this release | User login functionality |
| P2 | Should Have | Important, high-value, but not critical | Password reset email |
| P3 | Could Have | Desirable if time and resources permit | Social login integration |
| P4 | Won't Have | Explicitly out of scope for this phase | Multi-language support (for v1) |

## Detailed Definitions

### P1: Must Have

**Characteristics**:
- Essential to product viability
- Required for MVP or release definition
- Blocking other work if incomplete
- High business/user impact if missing
- Non-negotiable with stakeholders

**Definition Process**:
1. Identify core user flows
2. Map to minimum viable product
3. Validate against business goals
4. Document acceptance criteria
5. Assess resource requirements

**Examples**:
- User authentication and authorization
- Core feature that solves primary user problem
- Critical security or compliance requirements
- Data persistence and backup
- Platform stability and performance baselines

**Questions to Ask**:
- Would users call this a deal-breaker if it's missing?
- Is this required for legal/compliance reasons?
- Does the product fail without this?
- Is this blocking other work?

### P2: Should Have

**Characteristics**:
- Important for user experience
- High value but not blocking
- Improves on MVP but not essential
- Medium-high business impact
- Worth doing if resources allow

**Definition Process**:
1. Identify valuable enhancement to core features
2. Assess user request frequency
3. Evaluate competitive advantage
4. Consider implementation complexity
5. Prioritize by impact and effort

**Examples**:
- Search and filtering capabilities
- Advanced user preferences
- Notification systems
- Reporting and analytics features
- UX improvements to common workflows

**Questions to Ask**:
- Would users significantly prefer this feature?
- Do competitors offer this?
- What's the impact on user satisfaction?
- How much effort is required?

### P3: Could Have

**Characteristics**:
- Nice-to-have features
- Lower priority/impact
- Improves but not essential
- Can be deferred to future releases
- Worth doing only if spare capacity

**Definition Process**:
1. Identify enhancement opportunities
2. Assess user request patterns
3. Consider differentiation value
4. Estimate implementation cost
5. Document for future consideration

**Examples**:
- Accessibility features beyond requirements
- Mobile app responsive design improvements
- Third-party integrations
- Advanced customization options
- Performance optimizations beyond baselines

**Questions to Ask**:
- Is this a nice-to-have or essential?
- How many users would benefit?
- Can this wait for a future release?
- What's the implementation complexity?

### P4: Won't Have

**Characteristics**:
- Explicitly out of scope
- Deferred to future versions
- May conflict with current priorities
- Not valuable for current release
- Documented for transparency

**Definition Process**:
1. Identify requested features
2. Assess against scope
3. Decide timing for future consideration
4. Document decision rationale
5. Communicate to stakeholders

**Examples**:
- Multi-language support (deferred to v2)
- Enterprise SSO integration (deferred to commercial tier)
- Desktop client (focus on web first)
- Advanced ML features (deferred to future)
- Full API customization (reserved for enterprise)

**Questions to Ask**:
- Why isn't this in scope?
- When might this become relevant?
- Is there a specific version/phase for this?
- How do we manage stakeholder expectations?

## Dependency Mapping

Requirements often depend on each other. Map dependencies to:
- Identify blocking relationships
- Sequence development activities
- Plan parallel workstreams

### Dependency Patterns

**Sequential Dependencies**:

```
P1: FR-001 (Database setup)
  ├── P1: FR-002 (User auth)
  ├── P2: FR-003 (Reporting)
  └── P3: FR-004 (Analytics)
```

### Dependency Assessment

For each dependency, document:
- **Requirement ID**: FR-001 depends on FR-002
- **Type**: Blocking / Enabling / Related
- **Risk**: Impact if dependency is not met
- **Sequence**: Must be completed before / in parallel with / after

### Gap Categories


**Information Gaps**:
- Unclear acceptance criteria
- Missing technical specifications
- Undefined performance targets
- Unknown user scenarios

**Scope Gaps**:
- Related requirements not yet identified
- Error handling not specified
- Integration points not defined

**Resource Gaps**:
- Skills not available
- Infrastructure not in place
- Tools not selected
- Knowledge gaps in team

**Validation Gaps**:
- Not verified with users
- Feasibility not confirmed
- Dependencies not mapped
- Constraints not identified

### Gap Documentation

For each gap, record:

```
GAP-001: [Missing Information]
- Impact: [How it affects progress]
- Owner: [Who should resolve]
- Resolution: [How to address]
- Needed by: [Target resolution date]
- Priority: [P1/P2/P3]
```

### Gap Resolution Priorities

- **Critical**: Blocking requirements (P1) without information
- **High**: Should Have requirements (P2) with significant impact
- **Medium**: Could Have requirements (P3) or minor clarifications
- **Low**: Future considerations or "nice-to-have" clarifications

## Prioritization Decision Framework

When prioritizing requirements, consider:

1. **User Impact**: How many users? How much value?
2. **Business Goals**: Alignment with strategic objectives
3. **Technical Feasibility**: Implementation complexity and risk
4. **Dependencies**: Blocking or blocked requirements
5. **Resource Constraints**: Team capacity and timeline
6. **Competitive Factors**: Market timing and differentiation
7. **Risk Mitigation**: Security, compliance, stability

## MoSCoW Assessment Checklist

Before finalizing prioritization:

**For P1 (Must Have)**:
- [ ] Essential to MVP or release definition
- [ ] Business/stakeholder agreement on inclusion
- [ ] Technical feasibility confirmed
- [ ] Resource requirements identified
- [ ] Dependencies mapped
- [ ] Acceptance criteria defined

**For P2 (Should Have)**:
- [ ] High-value enhancement to core features
- [ ] Resource estimates completed
- [ ] Dependency implications understood
- [ ] Deferred impact assessed if not included
- [ ] Priority vs. P1 items confirmed

**For P3 (Could Have)**:
- [ ] Non-critical feature or enhancement
- [ ] Documented for future consideration
- [ ] Impact if deferred is acceptable
- [ ] Resource estimates for future planning

**For P4 (Won't Have)**:
- [ ] Reason for deferral documented
- [ ] Stakeholder expectations managed
- [ ] Version/timeline for future consideration identified
- [ ] Clear exit criteria for reconsideration

## Examples

### Example 1: E-Commerce Application

**P1 - Must Have**:
- User registration and login
- Product catalog with search
- Shopping cart functionality
- Checkout and payment processing
- Order confirmation

**P2 - Should Have**:
- User profile and order history
- Product reviews and ratings
- Wish list / Save for later
- Email notifications
- Inventory management

**P3 - Could Have**:
- Product recommendations
- Social sharing
- Live chat support
- Mobile app
- Multi-language support

**P4 - Won't Have** (for v1):
- Subscription model
- B2B wholesale features
- Advanced analytics dashboard
- Custom product options

### Example 2: Project Management Tool

**P1 - Must Have**:
- User authentication
- Project creation and management
- Task creation, assignment, status tracking
- Team collaboration (comments, attachments)
- Basic reporting (status, completion)

**P2 - Should Have**:
- Kanban board view
- Timeline/Gantt chart
- File storage integration
- Activity feed
- Permission roles

**P3 - Could Have**:
- Time tracking
- Automated workflows
- Custom fields
- API for integrations
- Dark mode

**P4 - Won't Have** (for v1):
- Budget and resource forecasting
- Advanced custom reporting
- Enterprise SSO
- On-premise deployment
- Multi-tenancy

## Related Documentation

- See `smart-criteria.md` for requirement quality validation
- Reference project roadmap for version planning
- Consult technical architecture for feasibility assessment
- Review resource plan for capacity evaluati
