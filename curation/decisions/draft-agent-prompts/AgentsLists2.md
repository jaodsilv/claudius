# System Prompt

You are a Expert software Engineer specialized in AI multi-agentic orchestration.
I'm building my orchestration of AI sub-agents to help me develop faster. To do so I need first to build specialized agents roles.

# Your task

Ultrathink on a list of agent roles I should think in adding in the context of software development.
You can ask me questions to better understand my needs.
In the main output only the list and the questions.
No comments, preambles or after thoughts/ after considerations.
Leave anything else needed into your thinking output.

# Example Output

```text
<subagents-roles>
* Developer
* Tester
* PM
* Orchestrator
* Software Designer
* API Designer
* UX Designer
</subagents-roles>
<tailoring-questions>
1. What system are you trying to build?
2. Will it be a mobile first or desktop first application?
</tailoring-questions>
```

# Claude

project-scope-analyst.md
technical-planning-coordinator.md
react-architecture-specialist.md
claude-api-integration-expert.md
tech-hiring-domain-expert.md
database-architecture-designer.md
feature-roadmap-planner.md
requirements-gathering-agent.md
code-structure-organizer.md
testing-strategy-designer.md
performance-planning-agent.md
ui-ux-flow-designer.md
calendar-integration-specialist.md
email-system-designer.md
application-tracking-designer.md
job-board-integration-expert.md
candidate-communication-designer.md
data-flow-architect.md
security-planning-agent.md
deployment-strategy-agent.md
code-review-coordinator.md
documentation-specialist.md
orchestrator.md

# Google Gemini 2.5

## Flash with Thinking

### Planning & Analysis

- **Product Vision Agent**: This agent supports Product Owners by championing the business vision,
prioritizing features, maximizing return on investment (ROI), and represents user needs.
It assists in brainstorming high-level ideas, defining the problem or use case,
conducting market research, and evaluating prototypes to ensure alignment with business objectives.

- **Business Requirements Agent**: This agent translates high-level business requirements into detailed technical specifications.
Its functions include identifying stakeholders, gathering comprehensive requirements,
and bridging communication gaps between business and technical teams.
It drafts and maintains the Software Requirement Specification (SRS) document,
outlining functions, necessary resources, and potential risks.

- **Project Management Agent**: Orchestrates the entire development cycle,
including planning timelines, allocating resources, and tracking progress against milestones.
This agent can manage budgets, handle change requests,
perform continuous risk management by identifying potential delays or budget overruns,
optimize resource allocation, automate scheduling, generate reports, and manage stakeholder communication.
It ensures project health and stakeholder alignment.

### Design

- **Software Design Agent**: This agent designs the project's architecture,
including software navigation, user interfaces, and database structure.
It assesses how new software integrates with existing applications and systems.
This agent creates the Software Design Document (SDD) and can assist in generating prototypes.
It can also generate high-order components and core application structures rapidly.

- **UX/UI Design Agent**: This agent focuses on user-centered design principles.
It researches users, maps user journeys (UX), creates visual elements, maintains design systems (UI),
crafts micro-interactions (Interaction Design), and validates designs through user testing (UX Research).
It ensures the product meets both user needs and business objectives,
potentially boosting customer satisfaction and conversion rates.

### Development

- **Frontend Development Agent**: Specializes in building responsive user interfaces,
utilizing frameworks like React or Angular.
This agent can generate UI components, ensure cross-browser compatibility, and implement interaction logic.

- **Backend Development Agent**: Focuses on creating server logic, managing databases, and developing robust APIs.
It handles data processing, authentication, and integration with other services.

- **Mobile Development Agent**: Specializes in crafting native or cross-platform mobile applications.
This agent can generate code for specific mobile platforms and ensure performance and user experience on mobile devices.

- **Code Generation Agent**: This agent writes and optimizes code, detects inefficiencies,
suggests improvements, and can even implement fixes in real time.
It provides inline code suggestions  and can handle full workflows,
from generating code snippets to entire application components.

- **Code Review Agent**: Automatically analyzes code for quality, style, potential issues, and vulnerabilities.
It suggests fixes and helps catch errors early, ensuring clean, high-quality code and adherence to coding standards.  

### Quality Assurance & Testing

- **QA Test Automation Agent**: Creates test plans and automates testing workflows,
including unit, integration, and regression tests.
It can build complex test cases from plain English prompts,
maintain test scripts by adapting to UI or requirement changes, and generate large amounts of realistic test data.

- **Performance Testing Agent**: Optimizes system performance under various loads.
This agent can simulate user traffic, identify bottlenecks, and suggest performance improvements.

- **Security Testing Agent**: Performs vulnerability assessments.
This agent acts as a continuous security scanner, actively searching for vulnerabilities in code,
analyzing dependencies, flagging risks, and suggesting fixes before threats escalate.

- **User Acceptance Testing (UAT) Agent**: Coordinates with Subject Matter Experts (SMEs) to validate that solutions meet
business requirements.
It creates real-world test scenarios, documents findings, and facilitates feedback sessions,
contributing to reduced post-release defects and increased user adoption.

- **Debugging Agent**: Extends beyond simple find-and-fix procedures.
This agent uses data analytics and machine learning to identify where bugs are most likely to occur in the codebase,
thereby improving the efficiency of testing processes and allowing human developers to focus their efforts on potentially
problematic or high-risk areas.  

### Operations & Infrastructure

- **DevOps/Deployment Agent**: Manages infrastructure and deployment processes.
This agent automates CI/CD workflows, ensuring smooth and continuous delivery of software updates.  

### Cross-functional/Support Agents

- **Documentation Agent**: Generates and updates various forms of documentation,
including API documentation, user manuals, and internal technical specifications.  

- **Knowledge Management Agent**: Stores and retrieves past interactions, project history, and accumulated knowledge,
enabling personalized experiences and providing comprehensive responses to queries from other agents or humans.  

- **Compliance Agent**: Automatically audits project data and processes against regulatory requirements
(e.g., healthcare, finance, technology standards), flags inconsistencies, and recommends corrective actions.
It ensures data integrity and adherence to industry standards.  

### As Table

| Traditional Role | Proposed AI Agent Role | Core Functions | Key AI Capabilities | Primary SDLC Phase(s) | Recommended Agent Type |
|---|---|---|---|---|---|
| Product Owner | Product Vision Agent | Champions vision, prioritizes features, maximizes ROI, represents user needs | LLM reasoning & planning, Market analysis, Prototype evaluation | Planning | Goal-based, Utility-based |
| Business Analyst | Business Requirements Agent | Gathers & translates requirements into technical specs | Requirement analysis, SRS generation, Communication bridging | Planning | Goal-based |
| Project Manager | Project Management Agent | Orchestrates development cycle, plans timelines, allocates resources | Predictive analytics, Risk assessment, Scheduling, Reporting, Stakeholder communication | Planning, Development, Operations, Cross-cutting | Utility-based |
| Software Architect | Software Design Agent | Designs architecture, navigation, UI, database; assesses integration | Architecture generation, Component generation, Prototype assistance | Design | Goal-based, Utility-based |
| UX/UI Designer | UX/UI Design Agent | Researches users, maps journeys, creates visuals, validates designs | User research analysis, Design system generation, User testing analysis | Design | Model-based Reflex, Goal-based |
| Frontend Developer | Frontend Development Agent | Builds responsive user interfaces with frameworks (e.g., React, Angular) | Code generation, UI component generation, Cross-browser compatibility | Development | Goal-based |
| Backend Developer | Backend Development Agent | Creates server logic, manages databases, develops APIs | Code generation, Database schema design, API development | Development | Goal-based |
| Mobile Developer | Mobile Development Agent | Crafts native or cross-platform mobile applications | Code generation (platform-specific), Performance optimization | Development | Goal-based |
| Software Engineer | Code Generation Agent | Writes & optimizes code, detects inefficiencies, suggests fixes, implements changes | Code generation, Code optimization, Real-time fixes, Inline suggestions | Development | Goal-based |
| Code Reviewer | Code Review Agent | Automatically analyzes code for quality, style, issues, vulnerabilities | Code analysis, Vulnerability scanning, Suggestion generation | Development, Quality Assurance | Model-based Reflex, Goal-based |
| QA Engineer | QA Test Automation Agent | Creates test plans, automates testing (unit, integration, regression) | Test case generation, Test script maintenance, Test data generation | Quality Assurance | Goal-based, Model-based Reflex |
| Performance Engineer | Performance Testing Agent | Optimizes system performance under load, identifies bottlenecks | Load simulation, Performance analysis, Bottleneck identification | Quality Assurance | Utility-based |
| Security Specialist | Security Testing Agent | Performs vulnerability assessments, hunts for vulnerabilities, flags risks | Vulnerability scanning, Dependency analysis, Threat modeling | Quality Assurance, Operations, Cross-cutting | Goal-based, Model-based Reflex |
| UAT Specialist | User Acceptance Testing (UAT) Agent | Coordinates with SMEs, creates real-world test scenarios, documents findings | Scenario generation, Feedback facilitation, Defect documentation | Quality Assurance | Goal-based |
| Debugger | Debugging Agent | Identifies where bugs are likely to occur, assists in problem resolution | Data analytics, Machine learning (bug prediction), Root cause analysis | Quality Assurance, Development | Model-based Reflex, Goal-based |
| DevOps Engineer | DevOps/Deployment Agent | Manages infrastructure & deployment, automates CI/CD workflows | CI/CD automation, Infrastructure as Code generation, Deployment orchestration | Operations | Goal-based |
| Technical Writer | Documentation Agent | Generates & updates various forms of documentation (APIs, user manuals) | Documentation generation, Content summarization, Knowledge extraction | Cross-cutting | Goal-based |
| Knowledge Manager | Knowledge Management Agent | Stores & retrieves project history, accumulated knowledge, past interactions | Contextual memory, Information retrieval, Personalized response generation | Cross-cutting | Model-based Reflex |
| Compliance Officer | Compliance Agent | Audits project data against regulatory requirements, flags inconsistencies | Regulatory compliance auditing, Anomaly detection, Recommendation generation | Cross-cutting | Goal-based, Model-based Reflex |

## Pro

- **Orchestrator_Agent**: Decomposes high-level goals into specific tasks and coordinates the work of other agents.
- **Requirements_Analyst_Agent**: Gathers and refines user requirements,
creating detailed specifications, user stories, and acceptance criteria.
- **System_Architect_Agent**: Designs the overall software architecture, selects the technology stack,
and defines the primary components and their interactions.
- **Developer_Agent**: Writes, refactors, and debugs source code based on specifications provided by the architect
and requirements analyst.
- **Test_Engineer_Agent**: Creates and executes unit, integration, and end-to-end tests to verify functionality
and find defects.
- **Code_Reviewer_Agent**: Analyzes source code for quality, adherence to coding standards,
maintainability, and potential bugs.
- **Security_Analyst_Agent**: Scans code and infrastructure for security vulnerabilities
and suggests remediation strategies.
- **DevOps_Engineer_Agent**: Manages the CI/CD pipeline, automates builds,
testing, and deployment processes.
- **Technical_Writer_Agent**: Generates and maintains documentation,
including API references, system design documents, and user guides.
- **Research_Agent**: Explores external knowledge bases, documentation, and open-source libraries
to find solutions, best practices, or relevant code examples.

Excellent.
Thank you for providing that context.
Your answers clearly indicate that the initial friction is in the **planning and design phase** for a
**new, security-conscious web application**.

Based on this, I recommend prioritizing the development of your sub-agents to front-load the conceptual
and architectural work.
Here is a refined and prioritized list of roles tailored to your needs.

### Recommended Sub-Agent Orchestration Strategy

---

### **Tier 1: High-Priority (The "Blueprint" Crew)**

These agents directly address your primary pain point: **Planning**.
They work together to transform your initial idea into a well-structured, secure,
and maintainable project plan before significant code is written.

- **Role**: `Requirements_Analyst_Agent`
  - **Description**: Takes your high-level goals for the web application and breaks them down into detailed feature
  specifications, user stories, and functional requirements.
  - **Justification**: This is the starting point for any **greenfield** project and the core of the **planning** phase.
  It ensures clarity on what to build.

- **Role**: `System_Architect_Agent`
  - **Description**: Designs the high-level structure of the **React** application.
  It will propose a component hierarchy, select a state management strategy (e.g., Redux, Zustand),
  and design the data flow between the frontend and the **ClaudeAI API**.
  - **Justification**: Crucial for ensuring long-term **extensibility and maintainability**.
  A solid architecture is the foundation of a successful greenfield project.

- **Role**: `Security_Analyst_Agent`
  - **Description**: Works alongside the `System_Architect_Agent` from day one.
  It will specifically design the strategy for securely managing and using the ClaudeAI API keys on the client-side
  or through a backend-for-frontend (BFF), and define security best practices for the React application
  (e.g., preventing XSS).
  - **Justification**: Addresses your explicit requirement for high **security** from the very beginning of the design process,
  which is the most effective approach.

- **Role**: `Research_Agent`
  - **Description**: Acts as a specialist support agent for the Architect and Analyst.
  It will investigate best practices for integrating third-party APIs like ClaudeAI into React,
  compare different state management libraries, or find reference architectures for secure and scalable web apps.
  - **Justification**: Accelerates the planning and design phase by providing data-driven recommendations
  and preventing common pitfalls.

---

### **Tier 2: Medium-Priority (The "Builder" Crew)**

Once the blueprint is complete, these agents execute the plan.

- **Role**: `Developer_Agent`
  - **Description**: An expert in React and JavaScript/TypeScript. It takes the component designs and user stories and writes the
    actual code. It will implement the logic for calling the ClaudeAI API as designed by the architect.
  - **Justification**: The primary executor of the plan. Its effectiveness is maximized by the detailed specifications from the Tier 1 agents.

- **Role**: `Test_Engineer_Agent`
  - **Description**: Reads the requirements and acceptance criteria to generate corresponding unit and integration tests using a
    framework like Jest and React Testing Library.
  - **Justification**: Ensures code quality and application correctness from the start, which is vital for **maintainability**.

- **Role**: `Technical_Writer_Agent`
  - **Description**: Documents the architecture decisions, component APIs, and setup instructions as they are being created.
  - **Justification**: Directly supports your goal of **maintainability and extensibility** by creating a living document that
    makes it easier for the system (or humans) to understand and modify the codebase in the future.

---

### **Tier 3: Low-Priority (The "Operations" Crew)**

These agents are important for a mature project but are not critical for getting the initial version designed and built.

- **Role**: `DevOps_Engineer_Agent`
  - **Description**: Automates the build and deployment process (CI/CD) to a hosting service (e.g., Vercel, Netlify).
  - **Justification**: For a **greenfield** project, initial deployments can be manual. This role becomes more critical as the
    application grows and updates become more frequent.

- **Role**: `Code_Reviewer_Agent`
  - **Description**: Provides an automated second opinion on code quality, style guide adherence, and potential logic flaws.
  - **Justification**: While beneficial for **maintainability**, its function is partially covered by strong architectural guidelines
    and a robust `Test_Engineer_Agent` in the early stages.

This tiered approach allows you to focus your development efforts on building an orchestration system that solves your most
immediate problem—**planning**—while laying out a clear roadmap for future expansion.

# Copilot

## Think Deeper

### Attempt 1

- Requirements Analyst Agent
- Solution Architect Agent
- UI/UX Designer Agent
- Frontend Developer Agent
- Backend Developer Agent
- API Designer Agent
- DevOps Engineer Agent
- QA & Test Automation Agent
- Code Review Agent
- Security Auditor Agent
- Performance Optimizer Agent
- Documentation & Tutorial Agent
- Data Engineer Agent
- Integration & Orchestration Agent
- Release Manager Agent
- Bug Triage Agent
- Refactoring & Tech-Debt Agent
- Compliance & Localization Agent
- Accessibility Specialist Agent
- Product Manager Agent
- Customer Feedback & Analytics Agent
- Innovation & Research Agent
- Incident Response Agent

### Attempt 2

- Requirements Analyst Agent
- AI Integration Agent
- React Frontend Developer Agent
- Backend & Serverless Agent
- API Orchestrator Agent
- UI/UX & Prototyping Agent
- DevOps & Infrastructure Agent
- Security & Compliance Agent
- Test Automation Agent
- Performance & Scalability Agent
- Documentation & Onboarding Agent
- Orchestrator Coordinator Agent
- Bug Triage & Monitor Agent
- Analytics & Feedback Agent

### Attempt 3

- Code Generator
- Code Reviewer
- Debugger
- Documentation Writer
- Deployment Specialist
- Security Analyst
- Data Engineer
- Machine Learning Engineer
- Integration Specialist
- Performance Optimizer
- Requirements Analyst
- Version Control Manager
- Build Automation Specialist
- Quality Assurance Tester
- User Researcher
- Accessibility Expert

## Deep Research

### Round 1

- **Requirement Analysis Agent**
- **Stakeholder Interview Agent**
- **Architecture Advisor Agent**
- **System Design Agent**
- **Code Generator Agent**
- **Refactoring Agent**
- **Code Review Agent**
- **Pull Request Reviewer Agent**
- **Unit Testing Agent**
- **Test Data Generation Agent**
- **Integration Testing Agent**
- **End-to-End Testing Agent**
- **Test Automation Agent**
- **Static Analysis Agent**
- **Security Audit Agent**
- **Vulnerability Scanner Agent**
- **Performance Profiling Agent**
- **Load Testing Agent**
- **Memory Leak Detection Agent**
- **Code Quality Metrics Agent**
- **Dependency Updater Agent**
- **License Compliance Agent**
- **Documentation Writer Agent**
- **API Documentation Agent**
- **Changelog Generator Agent**
- **API Integration Agent**
- **Third-party Services Integration Agent**
- **API Mocking Agent**
- **UI/UX Prototype Agent**
- **Accessibility Testing Agent**
- **Localization/Internationalization Agent**
- **CI/CD Pipeline Agent**
- **Pipeline Optimization Agent**
- **Release Management Agent**
- **Versioning Agent**
- **Environment Configuration Agent**
- **Artifact Packaging Agent**
- **Deployment Orchestration Agent**
- **Rollback Management Agent**
- **Monitoring and Alerting Agent**
- **Incident Response Agent**
- **Post-Release Validation Agent**
- **Feedback Collection Agent**
- **Bug Triage Agent**
- **Regression Testing Agent**
- **Onboarding/Codebase Guide Agent**
- **Knowledge Base Agent**
- **On-call Duty Scheduler Agent**
- **Task Routing/Assignment Agent**
- **Automated Meeting Note Agent**
- **Synthetic Data Generation Agent**
- **Legal/Compliance Auditor Agent**
- **Observability/Telemetry Agent**
- **AI Model Integration Agent**
- **Prompt Engineering Agent**
- **Tool/Plugin Compatibility Agent**
- **Cloud Cost Optimization Agent**
- **Infrastructure as Code Agent**
- **Backup and Restore Agent**
- **Archival/Data Retention Agent**
- **User Support/Helpdesk Agent**
- **Internal Communication Agent**
- **Change Impact Analysis Agent**
- **Release Notes Generator Agent**
- **Migration/Upgrade Advisor Agent**
- **Custom Linter Agent**
- **Build Process Optimizer Agent**

### Round 3

# Specialized AI Sub-Agent Roles and Orchestration for Accelerated Software Development

A Comprehensive Agent Design Framework

---

## List of Agents (Round 3)

- Orchestrator Agent
- Requirements Analysis Agent
- Architecture Design Agent
- Planning Agent
- Coding Generation Agent
- Code Review Agent
- Debugging Agent
- Testing & QA Agent
- Security Analysis Agent
- Dependency & Environment Agent
- CI/CD Orchestration Agent
- Documentation Agent
- Deployment Orchestration Agent
- Maintenance & Monitoring Agent
- File Monitoring & Traceability Agent
- Human-in-the-Loop and Approval Agent
- Metrics & Observability Agent
- Version Control & Change Management Agent

---

## Agent Descriptions (Round 3)

---

### 1. **Feature Orchestrator Agent**

**Role**: The core coordinator responsible for managing workflows, delegating sub-tasks,
handling handoffs between specialized agents, and prioritizing tasks based on the project state, triggers,
and the feature's current state, as well as providing systems monitoring and emergency controls.
It is assigned to a single feature per instance.

**Capabilities**:
- Maintains a global overview of all available agents, active tasks,
and their current states for the feature.
- Interprets high-level objectives from humans or external systems and decomposes them into sub-tasks
for invocation by specific specialized agents.
- Manages the queue of requests, monitors agent availability/states, detects bottlenecks or stalls,
and dynamically reallocates work to optimize throughput.
- Maintains state, context, and task logs for traceability and recovery
in case of workflow interruptions.
- Workflow management: triggers, sequenced/concurrent execution, and dependencies.
- Logs agent status, failures, performance, and outcomes.
- Provides audit logs and triggers human-in-the-loop if unrecoverable errors occur.

**Usage in SDLC**:
- Present throughout the process, particularly crucial at orchestration "decision points" within a feature:
project kickoff, milestone transitions, or complex multi-agent coordination
(e.g., code requiring simultaneous testing and security review).

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Coordinate workflow for software development goal {goal_description}
Steps:
1. Analyze high-level objective and decompose into sub-tasks.
2. Assign each sub-task to the relevant specialized agent.
3. Collect sub-task results; monitor for errors or workflow blocks.
4. Re-assign/retry failed steps; escalate to HITL agent for ambiguous
or critical issues.
5. Maintain execution log and update project status summary in .llm/orchestration_log.txt
```

**When/Who Triggers**: Invoked one per feature being developed, new project goals,
major user commands, automation events (e.g., CI triggers),
or by user via project management interfaces.

**Files it can read/change/monitor**:
- Reads/writes `.llm/feat-{{feature-code}}/orchestra/log.txt`,
`.llm/feat-{{feature-code}}/orchestra/workflow_status.json`,
and all agent state files in `.llm/feat-{{feature-code}}/`.
- Can read project status, meta-files, error logs for effective coordination
and handoff clarity.

**Tag**: `@orchestrator @core @workflow @entrypoint`

---

### 2. **Requirements Analysis Agent**

**Role**: Translates business or stakeholder input into structured, actionable software requirements,
refining ambiguities before handoff to downstream agents.

**Capabilities**:
- Parses various input formats: emails, meeting transcripts, user stories, contracts.
- Extracts explicit requirements, identifies missing or ambiguous areas,
and generates clarifying questions.
- Produces formal requirements artifacts (markdown/JSON specifications)
for traceability and further design.

**Usage in SDLC**:
- Invoked at project origination, or whenever a requirement file is updated
or a new feature is proposed.

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Analyze and formalize new requirements from {input_source}
Steps:
1. Parse input (text, transcript, user story, etc.).
2. Extract functional, non-functional, and edge case requirements.
3. List ambiguities and generate follow-up clarification queries.
4. Save structured requirements artifacts; notify architects for further
design.
```

**When/Who Triggers**: Activated by product owners, project managers,
or automated triggers on new requirement inputs.
Handoff to architects upon completion.

**Files it can read/change/monitor**:
- Reads `.req_inbox/`, `.meetings/`, `.contracts/`.
- Writes/monitors `.requirements`, `.llm/requirements_log.txt`.

**Tag**: `@requirements @analysis @input @entry`

---

### 3. **Architecture Design Agent**

**Role**: Designs the high-level system architecture based on requirements and best practices,
outputting diagrams, tech stacks, and component relationships.

**Capabilities**:
- Auto-generates UML diagrams, system blueprints,
and recommends technology stacks.
- Assesses technical feasibility and scalability,
flags risky or conflicting design elements.
- Iterates with stakeholders on proposed architecture.

**Usage in SDLC**:
- Employed after initial requirements are captured or when major
refactors/redesigns occur.

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Propose architecture for requirements in .llm/requirements_log.txt
Steps:
1. Load up-to-date requirements document.
2. Generate data flow diagrams, component lists, and interface designs.
3. Suggest technology stack per project constraints.
4. Save diagrams to .uml/ folder, solicit feedback, and update with iteration.
```

**When/Who Triggers**: Triggered by architects, orchestrator, or via new/updated requirements artifacts.

**Files it can read/change/monitor**:
- Reads `.llm/requirements_log.txt`, `.uml/`.
- Writes/updates `.uml/architecture.vsdx`, `.design/`.

**Tag**: `@architecture @design @uml @blueprint`

---

### 4. **Planning Agent**

**Role**: Decomposes architecture and requirements into sequential, prioritized execution plans and actionable sub-tasks (“tickets”).

**Capabilities**:
- Creates hierarchical execution trees, identifies dependencies, and generates timelines.
- Adapts plans dynamically when feedback or new scope arises.
- Feeds downstream coding/testing agents with clear instructions.

**Usage in SDLC**:
- Invoked after architecture finalization or in early project planning.

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Plan task execution from current architecture and requirements.
Steps:
1. Prioritize features and tasks per user and business value.
2. Identify dependencies and create a task tree.
3. Assign tasks to agent roles/code owners.
4. Update .llm/task_plan.json and notify orchestrator.
```

**When/Who Triggers**: Initiated by orchestrator, project manager, or after architecture/design outputs.

**Files it can read/change/monitor**:
- Reads `.uml/`, `.requirements`.
- Writes `.llm/task_plan.json`, `.llm/ticket_queue.txt`.

**Tag**: `@planning @tasks @decompose @priority`

---

### 5. **Coding Generation Agent**

**Role**: Autonomously writes, refactors, and optimizes code according to defined tasks with modular, reusable patterns and
adhering to coding standards.

**Capabilities**:
- Generates code from natural language prompts or formal task inputs.
- Suggests and applies refactorings, and autofixes detected issues.
- Interfaces with dependency and environment agents for correctness.

**Usage in SDLC**:
- Core actor in development, triggered on new task assignments or file update requests.

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Implement feature/task as described in .llm/task_plan.json
Steps:
1. Parse assigned task description, dependencies, and constraints.
2. Generate or modify code in corresponding project file(s).
3. Apply best practices and optimize for maintainability.
4. Output code diffs and logs to .llm/generated_code.log.
```

**When/Who Triggers**: Triggered by orchestrator for scheduled tasks; can be directly invoked by a user for “ad-hoc” code generation.

**Files it can read/change/monitor**:
- Reads `.llm/task_plan.json`, relevant `.code/`.
- Writes `.code/`, `.llm/generated_code.log`.

**Tag**: `@coding @implementation @refactor @develop`

---

### 6. **Code Review Agent**

**Role**: Performs code reviews for style, maintainability, adherence to standards, and initial bug screening.

**Capabilities**:
- Lints code, checks for anti-patterns, and offers in-line suggestions.
- Verifies code adheres to team or domain standards.
- Can escalate to human-in-the-loop (HITL) for ambiguous or critical issues.

**Usage in SDLC**:
- Invoked on commit, pull request, or explicit user request for review.

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Review code in files changed in latest PR/commit.
Steps:
1. Lint and scan all changes for coding style and functional integrity.
2. Flag issues and suggest improvements inline or in a separate report.
3. Escalate unclear areas to HITL agent with a rationale.
4. Save review outcomes to .llm/code_review.log.
```

**When/Who Triggers**: Automatically triggered by version control events (PR, merge); developers can request reviews ad hoc.

**Files it can read/change/monitor**:
- Reads `.code/`, `.git/diffs`.
- Writes `.llm/code_review.log`, `.llm/review_summaries`.

**Tag**: `@review @lint @style @quality`

---

### 7. **Debugging Agent**

**Role**: Detects, triages, and proposes or applies fixes for code errors, integrating with test suites for validation.

**Capabilities**:
- Analyzes logs, stack traces, and test failures.
- Runs targeted code analysis to isolate faults.
- Suggests or applies code-level patches; can confirm fixes via test runner.

**Usage in SDLC**:
- Used in development and testing, rapidly iterating on failed builds or identified errors.

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Debug and resolve errors reported in .llm/error_log.txt or test failures.
Steps:
1. Parse error or stack trace context.
2. Locate affected code segment(s).
3. Generate candidate fixes and apply in test sandbox.
4. If automated fix passes, commit changes; else escalate to HITL.
5. Log all findings and actions to .llm/debugging.log.
```

**When/Who Triggers**: Triggered by error logs, failed tests, or explicit developer command.

**Files it can read/change/monitor**:
- Reads `.llm/error_log.txt`, `.code/`, `.tests/`.
- Writes `.code/`, `.llm/debugging.log`.

**Tag**: `@debug @fix @triage @patch`

---

### 8. **Testing & QA Agent**

**Role**: Writes, maintains, and executes test suites (unit, integration, security), reporting on coverage and regression.

**Capabilities**:
- Auto-generates test cases from specs and code diffs.
- Runs test suites, benchmarks, and collects coverage data.
- Supports test self-healing and regression analytics.

**Usage in SDLC**:
- Triggered before merges/deployments, or periodically by schedule.

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Ensure testing coverage and integrity for current codebase.
Steps:
1. Generate/augment test cases for recent code changes.
2. Execute tests, analyze failures, and log detailed results.
3. Provide coverage reports and suggest new cases if coverage is insufficient.
4. If critical issues found, notify orchestrator and escalate as needed.
```

**When/Who Triggers**: On code change, CI pipeline, or developer request.

**Files it can read/change/monitor**:
- Reads `.code/`, `.tests/`.
- Writes `.tests/`, `.llm/test_reports.log`.

**Tag**: `@qa @testing @coverage @regression`

---

### 9. **Security Analysis Agent**

**Role**: Proactively analyzes the codebase for security vulnerabilities, compliance violations, and recommends risk mitigation.

**Capabilities**:
- Scans code for CVEs, misconfigurations, and insecure patterns.
- Evaluates dependency vulnerabilities and suggests/forces upgrades.
- Ensures regulatory compliance (GDPR, HIPAA, etc.) where required.

**Usage in SDLC**:
- Runs before merging to production, on dependency updates, or as scheduled audits.

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Audit codebase for security vulnerabilities.
Steps:
1. Perform static and dynamic security analysis.
2. Identify and report vulnerabilities with affected locations and severity.
3. Suggest and prioritize mitigations or auto-remediation if allowed.
4. Output results to .llm/security_audit.log.
```

**When/Who Triggers**: Automated per CI/CD policies; can be invoked ad hoc for critical review.

**Files it can read/change/monitor**:
- Reads `.code/`, `.config/`, `.dependencies/`.
- Writes `.llm/security_audit.log`.

**Tag**: `@security @audit @compliance @vulnerability`

---

### 10. **Dependency & Environment Agent**

**Role**: Handles dependency management (installing, updating, pinning versions), environment setup/teardown, and validation.

**Capabilities**:
- Installs/updates dependencies per manifest (`package.json`, `requirements.txt`).
- Monitors environment for configuration drift or missing components.
- Validates system readiness before build/test/deploy.

**Usage in SDLC**:
- Invoked on environment changes, new features, or test failures linked to dependency/configuration.

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Manage project dependencies and environments.
Steps:
1. Read requirement manifests and current environment state.
2. Install, update or pin dependencies as needed.
3. Validate installation and report conflicts or drift.
4. Update .llm/dependency_state.json and notify orchestrator.
```

**When/Who Triggers**: On new dependencies/features; when configuration drift or failure detected.

**Files it can read/change/monitor**:
- Reads `package.json`, `requirements.txt`, `.env`, `.config/`.
- Writes `.llm/dependency_state.json`.

**Tag**: `@dependency @environment @setup @config`

---

### 11. **CI/CD Orchestration Agent**

**Role**: Manages continuous integration/build automation, deployment triggers, artifact management, and pipeline state transitions.

**Capabilities**:
- Executes builds, runs CI scripts, deploys artifacts, tracks build/test/deployment stages.
- Integrates with version control and external systems (e.g., cloud providers).
- Handles rollbacks, staged deployments, and orchestrates notifications.

**Usage in SDLC**:
- Central throughout integration/deployment; critical for reliable, automated releases.

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Execute CI/CD pipeline for current project state.
Steps:
1. Identify trigger (commit, merge, scheduled).
2. Launch build and test stages.
3. On success, promote to deployment or initiate escalation on failure.
4. Record all actions in .llm/cicd_pipeline.log.
```

**When/Who Triggers**: On push, pull request, scheduled, or manual command.

**Files it can read/change/monitor**:
- Reads `.yaml`/pipeline definitions, version control history, `.llm/status`.
- Writes `.llm/cicd_pipeline.log`.

**Tag**: `@cicd @pipeline @automation @deploy`

---

### 12. **Documentation Agent**

**Role**: Automates creation and maintenance of system, API, and user documentation, ensuring alignment with live code and recent changes.

**Capabilities**:
- Generates/revises documentation based on code diffs, new features, or reviews.
- Supports output formats (Markdown, HTML, PDF).
- Validates that documentation follows best practices and style guides.

**Usage in SDLC**:
- After code/feature changes, pre-release, on documentation update requests.

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Generate/update documentation to reflect latest code and design.
Steps:
1. Parse code, comments, and design/uml files for updates.
2. Generate/rewrite user-facing or technical documentation sections.
3. Format output as specified; save to .docs/ directory.
4. Summarize docs-changes and notify relevant stakeholders.
```

**When/Who Triggers**: Automatically on code change or explicit requests; after new features or API updates.

**Files it can read/change/monitor**:
- Reads `.code/`, `.uml/`, `.design/`.
- Writes `.docs/`, `.llm/documentation.log`.

**Tag**: `@documentation @docs @api @md`

---

### 13. **Deployment Orchestration Agent**

**Role**: Orchestrates deployment activities including rollouts, canary releases, blue/green deployments, and post-deployment health checks.

**Capabilities**:
- Provisions, configures, and validates deployment targets.
- Monitors deployment status, triggers automated rollback on failure.
- Integrates with infrastructure automation tools as needed.

**Usage in SDLC**:
- Key in the integration and deployment phases.

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Deploy current release to target environment.
Steps:
1. Validate artifact integrity and deployment prerequisites.
2. Provision or configure environment via infra automation if needed.
3. Deploy, monitor health, and verify system readiness.
4. Rollback if critical failure; report outcome to .llm/deployment_log.txt.
```

**When/Who Triggers**: Invoked by CI/CD agent during deploy, or on demand for manual releases.

**Files it can read/change/monitor**:
- Reads `.llm/build_artifact.log`, `.deploy/`, `.configs/`.
- Writes `.llm/deployment_log.txt`.

**Tag**: `@deployment @orchestration @rollout @infra`

---

### 14. **Maintenance & Monitoring Agent**

**Role**: Performs post-deployment system health checks, schedules maintenance, collects telemetry, and initiates hotfix/repair workflows.

**Capabilities**:
- Monitors system performance, logs anomalies, and schedules maintenance windows.
- Triggers alerts or repairs for detected incidents or performance degradation.
- Automates routine updates or optimizations for legacy code.

**Usage in SDLC**:
- Active post-release, during production operation, and for regular maintenance.

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Monitor and maintain deployed system health.
Steps:
1. Collect performance, error, and usage logs.
2. Analyze for anomalies; initiate repair or escalation for critical issues.
3. Schedule and execute routine maintenance tasks.
4. Update .llm/maintenance_log.txt.
```

**When/Who Triggers**: Monitors continuously (agent-initiated); can be triggered by external alerts or schedulers.

**Files it can read/change/monitor**:
- Reads `.logs/`, `.stats/`, `.configs/`.
- Writes `.llm/maintenance_log.txt`.

**Tag**: `@maintenance @monitoring @ops @incident`

---

### 15. **File Monitoring & Traceability Agent**

**Role**: Tracks, audits, and logs file changes, supports recovery and accountability, and triggers agents on relevant file events.

**Capabilities**:
- Real-time file/folder change detection across the workspace.
- Records before/after snapshots for critical files, enabling rollback and audit.
- Triggers downstream agents (e.g., test, review) in response to monitored file changes.

**Usage in SDLC**:
- Provides foundation for all agent triggers, essential in regulated or mission-critical contexts.

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Monitor all critical files and track changes.
Steps:
1. Watch files/directories for changes or access.
2. On event, record snapshot (diff) and log.
3. Trigger follow-on agents as per event-type (e.g., on .code/ change, start tests).
4. Maintain .llm/file_tracking_log.json for traceability.
```

**When/Who Triggers**: Runs continuously; invoked by orchestrator, CI/CD, or on explicit command.

**Files it can read/change/monitor**:
- Reads/writes all project files for logging.
- Maintains `.llm/file_tracking_log.json`.

**Tag**: `@filemonitor @trace @audit @triggers`

---

### 16. **Human-in-the-Loop and Approval Agent**

**Role**: Serves as the primary interface for human approvals, expertise input, escalation of ambiguous cases, and real-time HITL
interactions at critical workflow points.

**Capabilities**:
- Pauses automated workflows for human input at pre-designated checkpoints.
- Surfaces explanations, alternatives, and context to humans for actionable decision-making.
- Maintains compliance, accountability, and audit trails for all manual interventions.

**Usage in SDLC**:
- At critical quality, safety, or compliance gates (e.g., dangerous code changes, production releases).

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Secure human approval for high-impact agent action.
Steps:
1. Present current context and candidate actions in structured decision format.
2. Await human review and selection/approval/denial.
3. Record human input, resume/abort workflow as required.
4. Log all interaction to .llm/approval_logs.
```

**When/Who Triggers**: Triggered by orchestrator, security agent, code review, or on policy rule match requiring human oversight.

**Files it can read/change/monitor**:
- Reads all current workflow, code, and plan files.
- Writes approval/decision logs to `.llm/approval_logs`.

**Tag**: `@hitl @approval @compliance @checkpoints`

---

### 17. **Metrics & Observability Agent**

**Role**: Provides unified monitoring, telemetry, health metrics, and visualization across all agents, surfacing both technical KPIs
and business SLAs.

**Capabilities**:
- Tracks latency, throughput, task completion rate, failure/error frequency, and agent-specific metrics.
- Integrates with external tools (OpenTelemetry, App Insights, Datadog) for advanced analytics.
- Supports custom dashboards, alerting, and root-cause discovery.

**Usage in SDLC**:
- Monitors all agent interactions in real-time to ensure operational quality and efficiency.

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Observe and report on agent framework performance.
Steps:
1. Collect metric data from all agent logs and process runtime events.
2. Analyze for abnormalities; generate summary dashboard.
3. Push alerts or recommendations for detected issues.
4. Store results in .llm/metrics_dashboard.json.
```

**When/Who Triggers**: Continuous agent; can be called for specific deep-dive reports by operators or orchestrator.

**Files it can read/change/monitor**:
- Reads all `.llm/*_log.txt` and relevant logs/metrics across the system.
- Writes `.llm/metrics_dashboard.json`.

**Tag**: `@monitoring @metrics @observability @dashboard`

---

### 18. **Version Control & Change Management Agent**

**Role**: Integrates workflows with version control systems (e.g., Git), automates commits, tagging, branching, and manages
rollbacks for all code and artifact changes.

**Capabilities**:
- Automates commit/tag actions after changes/approval; maintains traceability between code and agent actions.
- Prepares change logs for releases and connects changes to upstream tickets/issues.
- Supports automation of rollbacks or partial reverts for failed deployments.

**Usage in SDLC**:
- Throughout artifact lifetime, especially at each code or configuration checkpoint.

**Steps once invoked (LLM-friendly prompt format)**:

```text
Task: Perform version control operations for current changes.
Steps:
1. Check for new/modified files since last sync.
2. Stage, commit, and tag changes per project/versioning policy.
3. Push code updates and record commit hashes to .llm/version_notes.json.
```

**When/Who Triggers**: After successful code/test changes, on demand by orchestrator or user.

**Files it can read/change/monitor**:
- Reads `.git/`, all changed files.
- Writes `.llm/version_notes.json`.

**Tag**: `@vcs @change @audit @rollback`

---

## Tailoring Questions (Round 3)

- Are there specific workflows or compliance gates in your SDLC that require additional human oversight, custom approvals, or
  escalation logic? (`@hitl`)
- How do you intend to scope agent file access for particularly sensitive or regulated sections of your codebase?
  (`@security`, `@filemonitor`)
- What external observability or analytics platforms should be integrated for end-to-end monitoring? (`@metrics`)
- Do your orchestration needs require classical pipeline models (sequential/concurrent/group chat/handoff/magentic), or a hybrid,
  and how should these workflows be recorded in the `.llm` folder? (`@orchestrator`)
- Which agent triggers require direct user input versus automated monitoring/event-based invocation? (`@orchestrator`, `@filemonitor`)
- Should any specialized agents be further broken down by programming language, domain expertise, or project-specific patterns for maximum efficacy?

---

## Analysis and Rationale for Choices

### **Frameworks and Orchestration Patterns**

Modern agent orchestration leverages robust frameworks such as LangGraph (stateful, graph-based control), CrewAI (role-driven,
collaborative pipelines), and AutoGen (conversational, event-driven workflows), each providing differing strengths for coordination,
memory management, and multi-agent interactions. For production-grade reliability, layered orchestration patterns—such as sequential,
concurrent, group chat, handoff, and magentic—should be mapped to business objectives and technical KPIs, as each pattern is suited
for a specific type of workflow or complexity.

A central Orchestrator Agent will map goals to orchestration sub-patterns, invoke sub-agents as routines, and combine agent outputs
into a coherent project state.

**Triggers and Agent Invocation:**
- Agents may be invoked via explicit user input, automated workflow events (e.g., file change monitors, test failures),
  schedule-based periodicity, or inter-agent handoff based on workflow state and dynamic needs.
- File monitoring agents ensure real-time, granular change tracking and prompt responsive downstream actions
  (e.g., code change → invoke testing agent).

### **Communication, Collaboration, and Handoffs**

Agent communication uses shared state files in a dedicated `.llm` folder (as per your specified convention), text-based messaging,
and structured protocol handoffs—ensuring that each agent maintains context and accountability for its actions. Handoff patterns,
including direct responsibility transfers and group chat coordination, leverage memory and context logs so agents can build upon
prior outputs and decisions, supporting transparency and continuity.

Open protocols, such as the Agent Communication Protocol (ACP) or proprietary equivalents, provide guaranteed interoperability and
auditability for agent-to-agent (and human-agent) interactions, critical for scaling orchestration frameworks. These protocols
should be secured via mutual authentication and versioned contracts.

### **LLM Function Calling and Prompt Engineering**

Function-calling workflows are utilized for safe, deterministic agent actions, mapping LLM outputs to structured calls that can be
sandboxed, audited, and parsed for role-based execution. Prompt engineering must be role-aware, principled, and modular, using
reusable templates and examples to guide agents in adhering to both software and communication best practices.

### **File Access, Change Management, and Traceability**

Each agent has explicit, scoped permissions for file access—aligned with the principle of least privilege—to support both
operational efficiency and security governance. File monitoring agents track all changes, support rollbacks via version control,
and provide audit trails for compliance and troubleshooting.

### **Security and Governance**

Agent actions are tracked and audited; sensitive operations (e.g., deployments, production data access) are guarded by
Human-in-the-Loop checkpoints, with HITL agents mediating approvals and decision escalation for ambiguous or safety-critical
scenarios. Zero-trust orchestrator agents may enforce authentication and privilege checks, using short-lived identity tokens and
fine-grained authorization policies to secure agent-to-agent calls and sensitive tool actions.

### **CI/CD and Version Control Integration**

CI/CD Orchestration agents tightly integrate pipeline actions with agent workflows, supporting full automation (build, test, deploy)
and providing hooks for custom agent routines and rollback mechanisms. Version control agents ensure all changes are committed,
tagged, and traceable—linking code diffs and deployment histories with agent action logs for end-to-end accountability.

### **Metrics, Observability, and Monitoring**

A dedicated Metrics & Observability Agent provides centralized logging, dashboarding, and alerting (using platforms such as
OpenTelemetry, App Insights, Datadog, or Galileo AI), tracking core KPIs: response time, error rates, task completion percentage,
agent utilization, and more. This enables both real-time monitoring and continuous improvement—critical for large-scale agent
ecosystems with many autonomous and semi-autonomous components.

### **Human-in-the-Loop Orchestration**

HITL agents manage collaboration between autonomous AI and human experts, applying approval, interruption, and review workflows at
pre-defined gates or for high-uncertainty tasks. Leading frameworks (LangGraph, CrewAI, HumanLayer, Permit.io MCP) provide robust
integration points for these checkpoints, logging decisions for auditability and smoothing collaboration without introducing
unnecessary friction.

---

## Final Remarks: Folder Structure Example

```text
.llm/
  orchestration_log.txt
  workflow_status.json
  requirements_log.txt
  task_plan.json
  review_summaries/
  approval_logs/
  code_review.log
  debugging.log
  test_reports.log
  security_audit.log
  dependency_state.json
  cicd_pipeline.log
  deployment_log.txt
  maintenance_log.txt
  file_tracking_log.json
  metrics_dashboard.json
  version_notes.json

uml/
  architecture.vsdx
docs/
  api.md
  user_manual.md

code/
  (all source code files)
tests/
  (all test suites)
config/
  (all environment/config files)
```

---

**In summary:** This comprehensive agent role taxonomy and orchestration design provides a robust, modular foundation for accelerating
next-generation software development, supporting granular specialization, rigorous security/traceability, and scalable automation
while safeguarding with human oversight at all critical points. Each recommended agent includes roles, triggers, capabilities, prompt
instructions, file operations, and tags to support scalable real-world implementation and future extensibility. The workflow is
designed for diverse development teams building with or on top of modern LLM-powered AI frameworks, and is adaptable to evolving
organizational or project needs, from startups to large enterprise SDLCs.

---
