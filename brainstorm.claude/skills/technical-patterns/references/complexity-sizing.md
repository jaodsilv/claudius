<!-- markdownlint-disable MD036 -->
# Complexity Sizing Methodology

T-shirt sizing framework for estimating implementation effort and identifying complexity drivers.

## T-shirt Sizing Scale

| Size | Effort Range | Description | Characteristics |
|------|--------------|-------------|-----------------|
| **XS** | < 1 week | Straightforward | No unknowns, single component, familiar tech, isolated change |
| **S** | 1-2 weeks | Minor complexities | Few dependencies, one complexity factor, mostly straightforward |
| **M** | 2-4 weeks | Moderate complexity | Multiple factors, 2-3 integration points, some unknowns |
| **L** | 1-2 months | Significant complexity | Major unknowns, 4+ integration points, multiple complexity factors |
| **XL** | 2+ months | High complexity | Fundamental unknowns, distributed systems aspects, significant risks |

## Complexity Factors

### Implementation Complexity

#### Algorithm Complexity

- **Low**: Standard algorithms (CRUD, simple calculations, basic validation)
- **Medium**: Moderate algorithms (sorting, searching, complex business logic)
- **High**: Complex algorithms (graph algorithms, ML models, optimization, cryptography)

#### Data Model Complexity

- **Low**: Simple entities with few relationships, straightforward schema
- **Medium**: Multiple entities with references, some constraints, moderate normalization
- **High**: Complex relationships, circular dependencies, temporal aspects, partitioning needed

#### Integration Complexity

- **Low**: No external systems, self-contained feature
- **Medium**: 1-2 external system integrations, well-documented APIs
- **High**: 3+ external systems, complex workflows, asynchronous coordination needed

#### UI/UX Complexity

- **Low**: Standard forms, straightforward workflows, no real-time updates
- **Medium**: Multiple screens, some interactivity, standard UI patterns
- **High**: Rich interactions, real-time updates, complex state management, animations

### Technology Fit Factors

#### Stack Compatibility

- **Good**: Using existing proven technologies in codebase
- **Acceptable**: Similar technologies with learning curve
- **Poor**: New technology, migration needed, rewrite required

#### Available Frameworks

- **Rich Ecosystem**: Mature frameworks, many libraries available
- **Basic**: Some libraries, but require custom implementation
- **Sparse**: Few options, significant custom work needed

#### Performance Requirements

- **Lenient**: Standard web performance acceptable (seconds range)
- **Moderate**: Millisecond-level response times needed
- **Strict**: Sub-millisecond requirements, specialized optimization

#### Scalability Needs

- **Single User**: Personal or small team usage
- **Modest**: Hundreds of users, standard database scaling
- **Massive**: Thousands+ concurrent users, distributed systems

### Resource Requirement Factors

#### Team Skill Fit

- **Excellent**: Team has deep expertise in all needed areas
- **Good**: Team has core expertise, minor learning needed
- **Poor**: Team needs significant upskilling or hiring

#### Infrastructure Complexity

- **Existing**: Uses standard infrastructure already in place
- **New**: New infrastructure needed, but standard (RDS, S3, etc.)
- **Complex**: Specialized infrastructure (Kafka, Elasticsearch, custom systems)

#### Third-party Dependencies

- **Few**: 0-1 critical dependencies
- **Moderate**: 2-3 critical dependencies with good support
- **Many**: 4+ dependencies or critical undocumented libraries

#### Maintenance Burden

- **Light**: Self-contained, minimal ongoing work
- **Moderate**: Regular updates needed, some monitoring
- **Heavy**: Constant tuning, frequent updates, complex troubleshooting

### Risk Factors

#### Technical Unknowns

- **None**: Approach fully understood, proven patterns exist
- **Minor**: Few unknowns, easily resolvable with research
- **Significant**: Major unknowns, technical spikes needed
- **Fundamental**: Core approach uncertain, prototyping required

#### Performance Risk

- **Low**: Expected performance easily achievable with known approach
- **Medium**: Performance uncertain, optimization needed, profiling required
- **High**: Performance critical, edge cases complex, benchmarking needed

#### Security/Compliance Risk

- **Low**: Standard security practices sufficient, no compliance concerns
- **Medium**: Special security considerations, moderate compliance needs
- **High**: Critical security requirements, strict compliance, auditing needed

#### Dependency Risk

- **Low**: Few dependencies, stable, good support, easy alternatives exist
- **Medium**: Some risk, vendor stability concerns, limited alternatives
- **High**: Critical path dependencies, single point of failure, vendor locked-in

## Assessment Approach

### Step 1: Evaluate Implementation Complexity

Score each dimension on 1-5 scale:

```text
Algorithm Complexity:  [ ] Low (1) [ ] Medium (2-3) [ ] High (4-5)
Data Model Complexity: [ ] Low (1) [ ] Medium (2-3) [ ] High (4-5)
Integration Complexity: [ ] Low (1) [ ] Medium (2-3) [ ] High (4-5)
UI/UX Complexity:      [ ] Low (1) [ ] Medium (2-3) [ ] High (4-5)

Implementation Score = Sum / 4
```

### Step 2: Evaluate Technology Fit

For each factor, assess feasibility:

```text
Stack Compatibility:   [ ] Good  [ ] Acceptable  [ ] Poor
Available Frameworks:  [ ] Rich  [ ] Basic       [ ] Sparse
Performance Fit:       [ ] Lenient [ ] Moderate  [ ] Strict
Scalability Fit:       [ ] Single [ ] Modest     [ ] Massive

Tech Fit Score = (# "Poor" x 2) + (# "Sparse" x 2) + (# "Strict" x 1)
```

### Step 3: Evaluate Resource Requirements

```text
Team Skill Fit:           [ ] Excellent [ ] Good  [ ] Poor
Infrastructure Needs:     [ ] Existing  [ ] New   [ ] Complex
Third-party Dependencies: [ ] Few       [ ] Moderate [ ] Many
Maintenance Burden:       [ ] Light     [ ] Moderate [ ] Heavy

Resource Score = (# "Poor/Complex/Many/Heavy" x 2)
```

### Step 4: Evaluate Risk Factors

```text
Technical Unknowns:    [ ] None  [ ] Minor  [ ] Significant [ ] Fundamental
Performance Risk:      [ ] Low   [ ] Medium [ ] High
Security/Compliance:   [ ] Low   [ ] Medium [ ] High
Dependency Risk:       [ ] Low   [ ] Medium [ ] High

Risk Score = (# "High" x 3) + (# "Medium" x 1) + (# "Significant/Fundamental" x 2)
```

### Step 5: Calculate T-shirt Size

```text
Total Score = Implementation (1-5) + Tech Fit (0-8) + Resources (0-8) + Risk (0-15)

Score Range → Size Mapping:
0-8    → XS (< 1 week)
9-14   → S (1-2 weeks)
15-22  → M (2-4 weeks)
23-32  → L (1-2 months)
33+    → XL (2+ months)
```

## Examples

### Example 1: User Authentication

Sizing: XS (< 1 week)

**Implementation**

- Algorithm: Low (1) - standard crypto
- Data Model: Low (1) - users, sessions
- Integration: Medium (2) - OAuth provider, email
- UI/UX: Low (1) - standard forms
- **Score: 1.25**

**Technology Fit**

- Stack: Good - frameworks have auth libraries
- Frameworks: Rich - many options (Passport, Auth0, etc.)
- Performance: Lenient - standard web response times
- Scalability: Modest - session storage
- **Score: 0**

**Resources**

- Skills: Good - team knows authentication (1)
- Infrastructure: Existing - standard database (0)
- Dependencies: Moderate (1) - OAuth library
- Maintenance: Light (0) - standard security updates
- **Score: 2**

**Risk**

- Unknowns: None (0) - well-established pattern
- Performance: Low (0) - not a bottleneck
- Security: High (3) - critical but well-understood mitigations
- Dependencies: Low (0) - major providers stable
- **Score: 3**

**Total: 1.25 + 0 + 2 + 3 = 6.25 → XS (< 1 week)**

---

### Example 2: Real-time Collaboration Editor

Sizing: L (1-2 months)

**Implementation**

- Algorithm: High (4) - operational transform, conflict resolution
- Data Model: High (4) - document structure, versions, deltas
- Integration: Medium (2) - authentication, persistence
- UI/UX: High (4) - rich editor, real-time cursor tracking
- **Score: 3.5**

**Technology Fit**

- Stack: Acceptable (1) - some websocket experience needed
- Frameworks: Basic (1) - limited frameworks, custom code needed
- Performance: Strict (3) - sub-second latency critical
- Scalability: Massive (2) - concurrent editors, distributed sync
- **Score: 7**

**Resources**

- Skills: Poor (2) - complex algorithms, few experienced devs
- Infrastructure: Complex (2) - WebSocket servers, persistence layer
- Dependencies: Many (2) - operational transform library, WebSocket lib
- Maintenance: Heavy (2) - constant optimization, bug fixes
- **Score: 8**

**Risk**

- Unknowns: Significant (2) - conflict resolution edge cases
- Performance: High (3) - latency critical, optimization complex
- Security: Medium (1) - access control, data consistency
- Dependencies: Medium (1) - third-party libraries, browser APIs
- **Score: 7**

**Total: 3.5 + 7 + 8 + 7 = 25.5 → L (1-2 months)**

---

### Example 3: Data Migration (SQL to NoSQL)

Sizing: M (2-4 weeks)

**Implementation**

- Algorithm: Medium (2) - data transformation, mapping
- Data Model: High (4) - schema change, denormalization
- Integration: High (4) - preserve existing APIs, transition period
- UI/UX: Low (1) - backend focused
- **Score: 2.75**

**Technology Fit**

- Stack: Poor (2) - new database technology
- Frameworks: Basic (1) - migration tools limited
- Performance: Moderate (2) - need performance parity
- Scalability: Modest (1) - horizontal scaling change
- **Score: 6**

**Resources**

- Skills: Poor (2) - NoSQL expertise limited
- Infrastructure: Complex (2) - new database, parallel systems
- Dependencies: Few (0) - minimal external libraries
- Maintenance: Heavy (2) - optimization, monitoring new system
- **Score: 6**

**Risk**

- Unknowns: Significant (2) - data modeling, performance surprises
- Performance: High (3) - must maintain or improve speed
- Security: Medium (1) - access control migration
- Dependencies: Medium (1) - database version compatibility
- **Score: 7**

**Total: 2.75 + 6 + 6 + 7 = 21.75 → M (2-4 weeks)**

## Complexity Drivers

When component score is **High** on any factor:

### High Implementation Complexity → Mitigations

- Prototype novel algorithms before full implementation
- Use TDD to incrementally build complex logic
- Break into smaller, independently testable pieces
- Consider library/framework solutions first

### High Technology Fit Risk → Mitigations

- Run technology spike (1-2 days) to prove viability
- Build small prototype with new technology
- Allocate time for team learning
- Plan for potential technology change

### High Resource Needs → Mitigations

- Hire specialists or contract expertise
- Allocate training budget for team learning
- Extend timeline for less experienced team
- Consider outsourcing specialized components

### High Risk Factors → Mitigations

- Identify and resolve unknowns via technical spikes
- Build proof-of-concept for risky aspects
- Add buffer time for unexpected challenges
- Plan contingency approaches

## Simplification Opportunities

Look for ways to reduce estimated size:

1. **Scope Reduction** - Can features be phased? Can MVP be simpler?
2. **Technology Leverage** - Existing libraries or frameworks reduce work?
3. **Reuse** - Similar code elsewhere? Can it be extracted and reused?
4. **Parallel Work** - Can different aspects be worked on independently?
5. **Team Augmentation** - Would additional expertise reduce timeline?
6. **Risk Reduction** - Can unknowns be eliminated via spikes?
7. **Architecture** - Different approach with lower complexity?
<!-- markdownlint-enable MD036 -->
