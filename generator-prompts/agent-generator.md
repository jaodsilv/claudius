Given a task. Create a Claude Code's Custom Agent to perform the task.

The agent is meant to be used with Claude Code with model Claude Sonnet 4 with thinking enabled.

You will be provided the following arguments:

* {{TASK}}: The task, profession, domain, role, or prompt of the agent
* {{GUIDELINES}}: Either an attachment or a copy-pasted text, optional. Defaults to your own knowledge of the topic.

Before creating the agent you should create an strategy of how to perform the task.

Besides the prompt, you should also include the proper YAML frontmatter, including the values for:

* `name`
* `description`
* `tools`
* `model`

Do not forget, that the command may require arguments. Those arguments are passed as a single string in $ARGUMENTS,
the command should be able to parse that.
