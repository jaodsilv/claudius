# Constraint Taxonomies

Comprehensive classification of constraints that shape software solution design.

## 1. Technical Constraints

| Type | Description | Examples |
|------|-------------|----------|
| **Platform** | Operating systems, browsers, devices the solution must support | iOS/Android only, Windows 11+, Chrome/Safari/Firefox, specific device form factors |
| **Stack** | Required or prohibited technologies and frameworks | Must use React, cannot use third-party payment gateway, requires Node.js 18+ |
| **Integration** | External systems and services that must be connected | Salesforce integration required, SAP backend, legacy mainframe connectivity |
| **Performance** | Speed, latency, and throughput requirements | Page load < 2 seconds, API response < 100ms, 1000 requests/second capacity |
| **Security** | Authentication, authorization, and data protection standards | GDPR compliance, OAuth 2.0 required, end-to-end encryption, PCI-DSS |
| **Scalability** | Load capacity and growth requirements | Support 1M concurrent users, 100x traffic growth, multi-region deployment |
| **Availability** | Uptime and disaster recovery requirements | 99.99% SLA, RPO < 1 hour, RTO < 4 hours, multi-datacenter failover |

## 2. Business Constraints

| Type | Description | Examples |
|------|-------------|----------|
| **Budget** | Funding constraints for development and operations | Development budget $500K, operational budget $100K/month, cost per user < $5 |
| **Timeline** | Launch dates, milestones, and time-to-market requirements | MVP in 6 months, launch by Q4, market window closing in 8 weeks |
| **Compliance** | Regulatory and certification requirements | HIPAA compliance, SOC 2 Type II, FDA approval, industry certifications |
| **Brand** | Design guidelines, UX standards, and brand compliance | Design system must be used, specific color palette, accessibility WCAG AA minimum |
| **Legal** | Licensing, intellectual property, and contractual requirements | GPL-compatible only, must purchase commercial license, vendor contract restrictions |
| **Stakeholder** | Executive requirements, approval processes, and political constraints | CEO approval required, board reporting needs, investor visibility requirements |

## 3. Resource Constraints

| Type | Description | Examples |
|------|-------------|----------|
| **Team** | Team size, availability, and organizational structure | 8-person team, distributed across 4 time zones, embedded with customer |
| **Skills** | Expertise gaps and required specializations | No GraphQL experience, need DevOps expertise, learning curve on Go |
| **Infrastructure** | Hardware, cloud resources, and physical constraints | On-premise only, AWS-only deployment, limited cloud budget allocation |
| **Third-party** | Vendor limitations and SaaS constraints | Vendor API rate limits, Stripe payment processing fees, Twilio SMS pricing |
| **Support** | Maintenance capacity and ongoing support requirements | 1 person on-call, limited support hours, legacy code only maintained reactively |

## 4. Environmental Constraints

| Type | Description | Examples |
|------|-------------|----------|
| **Network** | Bandwidth, latency, and connectivity requirements | Low-bandwidth environments (< 1 Mbps), high-latency (satellite), offline-first needs |
| **Device** | Hardware capabilities and device diversity | Older devices (2GB RAM), mobile-only, no JavaScript support, accessibility needs |
| **Geographic** | Regional requirements and data locality needs | Data residency in EU, APAC-specific servers, timezone considerations |
| **User** | User skill levels, expectations, and constraints | Non-technical users, specific language requirements, accessibility requirements |

## Assessment Framework

For each constraint identified, evaluate these properties:

| Property | Description | Values |
|----------|-------------|--------|
| **Type** | Which category does it fall into | Technical / Business / Resource / Environmental |
| **Source** | Where did the constraint originate | Stakeholder statement / Technical requirement / Legal document / Market research |
| **Impact** | How much does it affect the solution | High / Medium / Low |
| **Negotiability** | Can it be relaxed or changed | Hard (non-negotiable) / Soft (can be negotiated) |
| **Validation** | How do we confirm it's real | Stakeholder interview / Documentation / Testing / Analysis |
| **Mitigation** | How can we work around or satisfy it | (Varies by constraint) |

## Examples of Assessed Constraints

### Example 1: Technical Performance Constraint

**Constraint**: API response time must be under 100ms for 99th percentile

| Property | Value |
|----------|-------|
| Type | Technical (Performance) |
| Source | Technical requirement from architecture review |
| Impact | High (affects user experience and SLA) |
| Negotiability | Soft (could negotiate to 150ms with stakeholders) |
| Validation | Load testing and production monitoring |
| Mitigation | Caching, CDN, database optimization, async processing |

### Example 2: Business Timeline Constraint

**Constraint**: MVP must launch by Q4 to capture holiday market

| Property | Value |
|----------|-------|
| Type | Business (Timeline) |
| Source | Executive stakeholder requirement |
| Impact | High (affects go-to-market) |
| Negotiability | Soft (could negotiate with stakeholders) |
| Validation | Stakeholder confirmation |
| Mitigation | MVP approach, phased rollout, parallel workstreams, cut low-priority features |

### Example 3: Resource Skills Constraint

**Constraint**: Team has no experience with GraphQL

| Property | Value |
|----------|-------|
| Type | Resource (Skills) |
| Source | Team assessment |
| Impact | Medium (affects development speed) |
| Negotiability | Soft (can be addressed with training or hiring) |
| Validation | Skills inventory review |
| Mitigation | Training program, hire contractor, use REST alternative |

### Example 4: Environmental Network Constraint

**Constraint**: Solution must work on low-bandwidth connections (< 1 Mbps)

| Property | Value |
|----------|-------|
| Type | Environmental (Network) |
| Source | User research in target market |
| Impact | High (core functionality affected) |
| Negotiability | Hard (user environment is fixed) |
| Validation | Network simulation testing |
| Mitigation | Offline-first architecture, progressive loading, compressed assets |

## Constraint Interaction Patterns

Constraints often interact and compound. Common patterns include:

### Conflicting Constraints

**Example**: "Fast launch" (Timeline) vs "High quality" (Technical)

**Resolution approaches**:
1. Prioritize one over the other
2. Find middle ground (MVP with quality core)
3. Renegotiate one constraint
4. Add resources to satisfy both

### Compounding Constraints

**Example**: "Limited budget" + "Short timeline" + "Small team"

**Impact**: Severely limits scope and quality
**Resolution**: Focus on absolute minimum viable scope

### Enabling Constraints

**Example**: "Must use cloud" enables "Easy scaling"

**Impact**: One constraint simplifies satisfying another
**Resolution**: Leverage positive interactions

## Related Documentation

- See `trade-off-patterns.md` for resolution strategies
- Reference technical architecture for feasibility assessment
- Consult stakeholder requirements for negotiability assessment
