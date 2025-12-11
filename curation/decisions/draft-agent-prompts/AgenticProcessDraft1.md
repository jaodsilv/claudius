# TASK

Help me design a multi-agentic AI developer

## Output

- I want the output as diagrams on how it should work
- Feel free to output more than one artifact containing a diagram in each one
- You can choose the proper file format, e.g., svg, html+react, etc..

## Process

To achieve the final result follow the below steps:
1. Ultrathink on how to achieve the multi-agentic AI developer
2. Then write the design accordingly to the plan

## Files and Folders

- `.llm/` - Folder for the LLM to work on
- `.llm/todo.md` - List of features to be developed, ultra high-level, 1000 words or less per feature. Only exists in the main branch.
- `.llm/plans/` - Folder for the LLM to work on and add plans for each feature and update status. Exists in all branches.
- `.llm/plans/plan-<feature-id>.md` - List of steps to be developed for a feature, includes steps for planning, execution and
  testing. Each `step` here should be a single commitable unit. Each step may contain multiple items to be done, but they should
  sum up to a single commitable unit. The plan should include any interfaces that are needed to be implemented or changed, so tests
  and code should be written in parallel.
- `.llm/monitoring/` - Folder for the LLM to work on and add monitoring information for each agent. Exists in all branches.

## Requirements

Workflow should include specialized agents working in parallel

### Components

- Agentic Orchestrator (AO): the main agent, launches Feature orchestrators agents and edit a common .llm/todo.features.md file.
  Creates in .llm an empty file for each feature, this will let us know which features are still running.
<!-- * Agentic Result Listener (AL): periodically checks if files appeared or disapeared in .llm.Listens to the results of the
     subagents and updates the .llm/todo.md file. -->
- Feature Orchestrator (FO): Orchestrates subagents for a specific feature. Works on a separate branch from the main Orchestrator
  using git worktree. This should launch (PO) and (EO)
- Planning Orchestrator (PO): Orchestrates subagents for a specific feature. Works on a separate branch from the main Orchestrator
  using git worktree. This should launch (P) and (PRev)
- Execution Orchestrator (EO): Orchestrates subagents for a specific feature. Works on a separate branch from the main Orchestrator
  using git worktree. This should launch (T), (I) and (CR)
- Code Reviewer (CR): Review both the code and the tests
- Planner (P): Creates a plan and answer to (PRev) reviews
- Plan Reviewer (PRev): Alternates turns with (P). Review (P) work
- Tester (T): Write tests for the feature. Multiple agents of this type can be launched in parallel to write different types of tests
- IntegrationTester (IT): Write integration tests for the feature
- Implementer (I): Write the feature code
- Code Reviewer (CR): Review both the code and the tests

#### Agentic Orchestrator (AO)

This orchestrator should work with a pool of sub agents to not overload the system

**(AO) Operation**:
Let {{poolsize}} be the size of the sub-agents pool
1. Launches {{poolsize}} (PO) in parallel, each one with a different feature from .llm/todo.features.md
2. For each (PO) created, do concurrently:
    1. Wait for (PO) to complete
    2. Launch (FO) for this same feature
    3. Wait for (FO) to complete
    4. if there are still incomplete features in todo.md, launch a new (PO) for the next feature

#### Feature Orchestrator (FO)

#### Planning Orchestrator (PO)

#### Execution Orchestrator (EO)

- Input can be either a review or a task. Ends once plan is written
- (FO) should check if there is anything new to do from PRev review and loop inton Planner again until there is nothing from PRev
- (P) and (PRev) can be launched multiple times instead of ping ponging

Once (P) and (PRev) are done (FO) should launch to work concurrently on a single commitable unit:

It can launch 1 trio per commitable unit in the planned feature

(T) and (I) must work independtly, i.e., they must be agents independent from each other

(T) and (I) should work in parallel, while (CR) should start and stop at every complete change of either (T) or (I)

Once there is nothing more from (CR), ifa PR should be created. This will launch a third-part independent review

Once PR is created, (FO) should look for PR reviews and restart the planning duo with the review as input. Once plan is ready,
restart the coding trio. Loop until there is no new review relevant in the PR

(FO) Should end once the feature is complete and PR is merged
