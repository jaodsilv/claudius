# new Workflow process for coding Tasks

Create a Workflow process for coding Tasks
Create the empty file for the process

Reference it in the @dotclaude/CLAUDE.md, remeber to state that is required

<process>

The text should contain the process below that must be followed for coding Tasks. It should be followed sequentially, i.e., the upper level task should wait for the worker to finish before continuing with the next step.
First, Create a new agent for the task using the Task tool. It should follow the process below:

0. In the main agent, Create a new git worktree for the task. Memorize the name of the worktree.

1. Create a new agent for the task using the Task tool to evaluate the need for tests:
   1. If it is a refactoring, evaluate if it needs new tests
   2. If it is a cleanup or something that does not require new tests, consider it does not need new tests
   3. If it is a bug fix or a new feature, new tests are required

2. If tests are needed:
   1. Unit tests Design:
      1. In a new agent (using the Task tool to create this agent): design and document design of unit tests
      2. In a new agent (using the Task tool to create this agent): review Design, especially if it handles the task at hand and edge cases (Looping between 2.1.1 and 2.1.2 if needed, two new agents (Task tool) per loop round)
      3. run /compact to compact the context window, remember the task, the worktree name, the unit test design, and the step number you are working on
   2. Unit tests Plan:
      1. In a new agent (using the Task tool to create this agent): plan Unit tests for the task based on design
      2. In a new agent (using the Task tool to create this agent): review plan (Looping between 2.2.1 and 2.2.2 if needed, two new agents (Task tool) per loop round)
      3. run /compact to compact the context window, remember the task, the worktree name, the unit test plan, the unit test design, and the step number you are working on
   3. Tests Writing:
      1. In a new agent (using the Task tool to create this agent): write Unit tests, it is ok to be failing now
      2. In a new agent (using the Task tool to create this agent): review unit Tests, it is ok to be failing now (Looping between 2.3.1 and 2.3.2 if needed, two new agents (Task tool) per loop round)
      3. run /compact to compact the context window, remember the task, the worktree name, and the step number you are working on
   4. Integration tests Design:
      1. In a new agent (using the Task tool to create this agent): design and document design of integration tests
      2. In a new agent (using the Task tool to create this agent): review Design, especially if it handles the task at hand and edge cases (Looping between 2.4.1 and 2.4.2 if needed, two new agents (Task tool) per loop round)
      3. run /compact to compact the context window, remember the task, the worktree name, the integration test design, and the step number you are working on
   5. Integration tests Plan:
      1. In a new agent (using the Task tool to create this agent): plan integration tests based on design
      2. In a new agent (using the Task tool to create this agent): review plan (Looping between 2.5.1 and 2.5.2 if needed, two new agents (Task tool) per loop round)
      3. run /compact to compact the context window, remember the task, the worktree name, the integration test plan, the integration test design, and the step number you are working on
   6. Integration tests Writing:
      1. In a new agent (using the Task tool to create this agent): write integration tests, it is ok for them to be failing now
      2. In a new agent (using the Task tool to create this agent): review integration tests, it is ok to be failing now (Looping between 2.6.1 and 2.6.2 if needed, two new agents (Task tool) per loop round)
      3. run /compact to compact the context window, remember the task, the worktree name, and the step number you are working on

3. Solution:
   1. Solution Design:
      1. In a new agent (using the Task tool to create this agent): design and document design of the solution. Consider the tests written.
      2. In a new agent (using the Task tool to create this agent): review Design, especially if it handles the task at hand (Looping between 3.1 and 3.2 if needed, two new agents (Task tool) per loop round)
      3. run /compact to compact the context window, remember the task, the worktree name, the solution design, and the step number you are working on
   2. Development Plan:
      1. In a new agent (using the Task tool to create this agent): plan changes based on design
      2. In a new agent (using the Task tool to create this agent): review plan (Looping between 4.1 and 4.2 if needed, two new agents (Task tool) per loop round)
      3. run /compact to compact the context window, remember the task, the worktree name, the solution plan, the development design, and the step number you are working on
   3. Solution Writing:
      1. In a new agent (using the Task tool to create this agent): write solution and make the unit tests pass
      2. In a new agent (using the Task tool to create this agent): review solution and make the unit tests pass (Looping between 5.1 and 5.2 if needed, two new agents (Task tool) per loop round)
      3. run /compact to compact the context window, remember the task, the worktree name, the solution design, and the step number you are working on
   4. Fix code in the case of the integration tests are not passing yet
      1. In a new agent (using the Task tool to create this agent): fix code in the case of the integration tests are not passing yet
      2. In a new agent (using the Task tool to create this agent): review the code (Looping between 6.1 and 6.2 if needed, two new agents (Task tool) per loop round)
      3. run /compact to compact the context window, remember the task, the worktree name, the development design, and the step number you are working on
   5. Design x Code Review:
      1. In a new agent (using the Task tool to create this agent): review if code follows design
      2. If it does not follow the design:
         1. In a new agent (using the Task tool to create this agent): review if the design should be changed or the code should be refactored considering the task at hand
         2. If needed, looping back to 3.1 or to 5.1 as needed
      3. run /compact to compact the context window, remember the task, the worktree name, and the step number you are working on

4. Commit changes:
   1. In a new agent (using the Task tool to create this agent): write commit message
   2. In a new agent (using the Task tool to create this agent): review commit message (Looping between 8.1 and 8.2 if needed, two new agents (Task tool) per loop round)
   3. In this main agent, Commit changes using the message written by the agent in 8.1
   4. run /compact to compact the context window, remember the task, the worktree name, and the step number you are working on

5. Refactor:
   1. In a new agent (using the Task tool to create this agent): evaluate the code for refactoring needs. It is ok to not have anything to change
   2. run /compact to compact the context window, remember the task, the worktree name, the evaluation above, and the step number you are working on
   3. If the design should be changed, restart the process from step 1 with the refactoring as the new task
   4. run /compact to compact the context window, remember the task, the worktree name, and the step number you are working on

6. PR:
   1. If there is no PR created yet:
      1. In a new agent (using the Task tool to create this agent): write PR message
      2. In a new agent (using the Task tool to create this agent): review PR message (Looping between 10.1 and 10.2 if needed, two new agents (Task tool) per loop round)
      3. In this main agent, Create PR using the message written by the agent in 10.1
      4. run /compact to compact the context window, remember the task, the worktree name, and the step number you are working on
   2. Otherwise simply push the commits to the remote repository

   3. Wait 10 minutes for another agent on github to review the PR

   4. Acting on the review comments:
      1. In a new agent (using the Task tool to create this agent): check the latest comments on the PR
      2. If there is no comment, or if the latest Claude comment is that it failed to run, wait for user input and try again after user grants permission
      3. If there are comments:
         1. In a new agent (using the Task tool to create this agent): parse the latest Claude comment
         2. If there are issues to address:
            1. In a new agent (using the Task tool to create this agent): create two check lists:
               1. Issues to address NOW
               2. Issues to address LATER in a follow-up PR
            2. While the list of Issues to address LATER is not empty:
               1. Ask user if they want to create a github issue for the FIRST issue in the list of Issues to address LATER, if yes:
                  1. In a new agent (using the Task tool to create this agent): Write a Github issue text for the FIRST issue
                  2. In a new agent (using the Task tool to create this agent): Review the Github issue text
                  3. In this main agent, Create a github issue for this issue
               2. Remove the issue from the list of Issues to address LATER
               3. run /compact to compact the context window, remember the task, the worktree name, the two lists of issues, and the step number you are working on
            3. Mark the latest Claude comment as closed
            4. If the list of issues to address NOW is not empty:
               1. Ask user which they want to be addressed NOW, which should be ignored and which should be done later:
                  1. Replace the old list of issues to address NOW with the new list of issues to address NOW
                  2. If the new list of issues to address LATER is not empty go back to step 6.4.2.2.2
                  3. Ignore the list of ignored issues
               2. run /compact to compact the context window, remember the list of issues to address NOW, the worktree name, and the step number you are working on
               3. restart the process from step 1 with the list of issues to address NOW as the new task
         3. If there are no more issues to address:
            1. Merge the PR

7. Closing the Task
   1. If there is a github issue, mark it as complete
   2. In a new agent (using the Task tool to create this agent): Mark the task as complete if there is a roadmap document, task list, or similar for it
   3. exclude worktree from the git worktree list
   4. run /clear to clear the context window

</process>
