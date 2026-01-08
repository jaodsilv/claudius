<!-- markdownlint-disable MD024 -->
# Architecture Patterns

Comprehensive reference for evaluating and comparing architectural approaches.

## 1. Monolithic Architecture

**Structure**: Single unified codebase with all components in one deployment unit.

### When to Use

- Early-stage startups with small teams
- Small to medium applications (<50 developers)
- Simple domain models with few integration points
- Performance-critical systems where latency matters
- Heavy coupling is acceptable or beneficial

### Advantages

- **Simplicity**: Single deployment, centralized testing, shared libraries
- **Performance**: No network calls, no serialization overhead
- **Debugging**: Stack traces, synchronized logs, simple debugging
- **Development**: Straightforward local development, simple debugging
- **Maintenance**: Consolidated monitoring, single database, unified logging

### Disadvantages

- **Scalability**: Must scale entire application, not individual components
- **Flexibility**: Deployment lock-step, shared resource contention
- **Technology Stack**: All components use same tech stack
- **Team Scaling**: Coordination overhead, merge conflicts, integration testing
- **Blast Radius**: Bug in one module affects entire system
- **Database**: Single database model, schema changes impact all features

### Technology Fit

- Simple data model (single database)
- Real-time requirements (in-process calls)
- Heavy inter-feature dependencies
- Synchronous workflows

### Complexity Assessment

**Data Model**: Any complexity handled internally
**Integration**: Fewer external systems preferred
**Deployment**: Single artifact to manage
**Scaling**: Vertical scaling primary

---

## 2. Microservices Architecture

**Structure**: Multiple independent services, each with own codebase, database, and deployment.

### When to Use

- Large teams (>20 developers) working independently
- Independent scaling requirements across features
- Technology diversity needed (different stacks per service)
- High availability and fault isolation critical
- Complex domain with clear service boundaries

### Advantages

- **Independent Scaling**: Scale individual services by demand
- **Technology Freedom**: Each service chooses optimal stack
- **Deployment Independence**: Deploy services without coordination
- **Team Autonomy**: Teams own full service lifecycle
- **Resilience**: Failure in one service isolates impact
- **Large Systems**: Natural fit for complex, large applications

### Disadvantages

- **Complexity**: Distributed system challenges (latency, consistency, failures)
- **Debugging**: Cross-service tracing, multiple logs, timing issues
- **Data Consistency**: Eventual consistency, saga patterns required
- **Network**: Network calls add latency, potential failure points
- **Deployment**: Many moving parts, coordination challenges
- **Operational Overhead**: Multiple databases, monitoring, scaling decisions
- **Testing**: Integration testing across service boundaries
- **Cost**: Infrastructure complexity, redundancy needs

### Technology Fit

- Independent scaling per feature
- Polyglot requirements (different languages/frameworks)
- API-driven interactions
- Asynchronous communication possible

### Complexity Assessment

**Data Model**: Distributed schemas, eventual consistency
**Integration**: Service-to-service APIs, complex workflows
**Deployment**: Coordinated multi-service deployments
**Monitoring**: Distributed tracing, multiple data sources

---

## 3. Event-Driven Architecture

**Structure**: Services communicate through events rather than direct calls, enabling loose coupling.

### When to Use

- Asynchronous workflows (email, notifications, reporting)
- Complex business processes with many steps
- Publishing domain events for other services to consume
- Real-time data propagation across systems
- Audit trail and event sourcing beneficial
- Decoupling is priority over strong consistency

### Advantages

- **Loose Coupling**: Services don't know about each other
- **Scalability**: Subscribers can scale independently
- **Resilience**: Subscriber failures don't block publishers
- **Auditability**: Event log provides complete history
- **Flexibility**: Add new subscribers without changing publisher
- **Real-time**: Fast event propagation for responsive systems

### Disadvantages

- **Debugging**: Event flows across services, timing sensitive
- **Consistency**: Eventual consistency, duplicate event handling
- **Ordering**: Event ordering guarantees complex to implement
- **Error Handling**: Failed event processing, retry logic needed
- **Testing**: Async testing, race conditions, timing issues
- **Infrastructure**: Message broker required, operational complexity
- **Latency**: Multiple hops through event system

### Technology Fit

- Asynchronous workflows
- Independent feature updates (notifications, reports)
- Event sourcing desired
- Publishing pattern (one-to-many)

### Complexity Assessment

**Data Model**: Event schema design, versioning
**Integration**: Message broker setup, routing rules
**Deployment**: Event system configuration, monitoring
**Consistency**: Handling eventual consistency, idempotency

---

## 4. Serverless Architecture

**Structure**: Functions deployed to cloud platform, platform manages infrastructure and scaling.

### When to Use

- Spiky, unpredictable workloads
- Short-running operations (API requests, transformations)
- Minimal operational overhead desired
- Cost-based on actual usage matters
- Integrating with cloud services (events, storage)
- Rapid prototyping and experimentation

### Advantages

- **Scalability**: Platform auto-scales functions per demand
- **Cost**: Pay per invocation, no idle costs
- **Operations**: Platform manages infrastructure, patching, scaling
- **Speed**: Deploy individual functions, rapid iteration
- **Integration**: Native cloud service integrations
- **Simplicity**: No server management, deployment simple

### Disadvantages

- **Cold Starts**: Latency spike on function startup
- **Limitations**: Execution time limits, memory constraints
- **Statelessness**: Functions must be stateless
- **Debugging**: Limited logging, distributed tracing needed
- **Local Development**: Simulation tools imperfect
- **Vendor Lock-in**: Cloud-specific APIs and services
- **Costs**: Unpredictable expenses with spiky usage
- **Testing**: Hard to reproduce production environment locally

### Technology Fit

- Stateless operations
- Short execution times
- Spiky, event-driven workloads
- Integration with cloud services

### Complexity Assessment

**Data Model**: External storage required (database, S3)
**Integration**: Cloud service integrations straightforward
**Deployment**: Simple but function-specific
**Monitoring**: Provider-based monitoring, limited visibility

---

## 5. Modular Monolith

**Structure**: Single codebase organized into clearly defined modules with enforced boundaries.

### When to Use

- Team wants monolith benefits but fears tight coupling
- Clear domain boundaries exist but not ready to split
- Needs flexibility to evolve toward microservices
- Shared transaction needs present
- Clear module ownership desired

### Advantages

- **Simplicity**: Single deployment like monolith
- **Boundaries**: Enforced module isolation without network overhead
- **Evolution**: Easier path to microservices if needed
- **Transactions**: Atomic transactions across related modules
- **Development**: Local development simpler than microservices
- **Performance**: In-process calls, no network latency
- **Flexibility**: Deploy as monolith or split modules to services

### Disadvantages

- **Discipline**: Requires enforced boundaries (often overlooked)
- **Deployment**: Still single deployment artifact
- **Scaling**: Vertical scaling like monolith
- **Technology Stack**: Shared across modules
- **Complexity**: More complex than true monolith but less than microservices
- **Monitoring**: Still single application view

### Technology Fit

- Clear domain boundaries
- Shared data needs
- Mixed transaction requirements
- Future growth into microservices

### Complexity Assessment

**Data Model**: Single database with modular schemas
**Integration**: Internal module APIs, clear boundaries
**Deployment**: Single artifact, coordinated releases
**Scaling**: Vertical scaling with module-level optimization

---

## Pattern Comparison Matrix

| Factor | Monolith | Modular | Microservices | Event-Driven | Serverless |
|--------|----------|---------|---------------|--------------|-----------|
| **Team Size** | <10 | 10-30 | 30+ | 10-50 | <20 |
| **Scalability** | Limited | Limited | Independent | Independent | Auto |
| **Complexity** | Low | Medium | High | High | Medium |
| **Performance** | High | High | Medium | Medium | Variable |
| **Consistency** | Strong | Strong | Eventual | Eventual | Variable |
| **Operational** | Low | Low | High | High | Low |
| **Testing** | Easy | Medium | Hard | Hard | Medium |
| **Cost** | Low | Low | Variable | Variable | Usage-based |

## Selection Criteria

### Start With

1. **Monolith** if:
   - Team <15 developers
   - Simple domain (few integrations)
   - Real-time consistency required
   - Local development important

2. **Modular Monolith** if:
   - Clear domains but shared transactions
   - Anticipate future growth
   - Want enforced boundaries without microservices complexity

### Evolve To

1. **Microservices** if:
   - Need independent scaling per domain
   - Team >20 developers
   - Different tech stacks needed
   - Can handle distributed system complexity

2. **Event-Driven** if:
   - Asynchronous workflows dominant
   - Decoupling is priority
   - Event history valuable
   - One-to-many communication patterns

3. **Serverless** if:
   - Spiky, unpredictable load
   - Want to minimize operations
   - Event-based interactions
   - Cost-sensitive to unused capacity

## Trade-offs Summary

| Architecture | Gain | Lose |
|--------------|------|------|
| Monolith → Modular | Boundaries | Still monolithic |
| Monolith → Microservices | Independent scaling | Distributed complexity |
| Monolith → Event-Driven | Loose coupling | Eventual consistency |
| Monolith → Serverless | Zero ops | Vendor lock-in, cold starts |
| Modular → Microservices | Full independence | Network latency, complexity |
| Microservices → Event-Driven | Decoupling | Message ordering, debugging |
