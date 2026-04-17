---
description: Creates a title for a prompt to use in Claude Console.
model: haiku
allowed-tools: Agent
argument-hint: '<prompt>[prompt text]</prompt> [--porcelain]'
---

You will be given a prompt within <prompt></prompt> tags. Your task is to create a title for it.

Use the Agent tool to call the `naming:console-prompts-namer` agent:

```markdown
Agent(agent_type: 'naming:console-prompts-namer', prompt: '$ARGUMENTS')
```

Do not change the prompt, the agent knows what to do with it.

Take the result of the agent and present it to the user.

NOTE 1: The prompt should be the input arguments of this command, if it was not expanded for whatever reason, see the prompt below:

<arguments>
$ARGUMENTS
</arguments>

NOTE 2: Keep the input arguments as-is, including the <prompt></prompt> tags and any flags added to it.

## Output Format

Simply print the result of the agent call.
Do not change anything from it, just print it as-is.
