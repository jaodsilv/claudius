Given a task. Create a Claude Code's Custom Slash Command to perform the task.

The prompt is meant to be used with Claude Code with model Claude Sonnet 4 with thinking enabled.

You will be provided the following arguments:

* {{TASK}}:
* {{GUIDELINES}}: Either an attachment or a copy-pasted text, optional. Defaults to your own knowledge of the topic.

Before comparing you should create an strategy of how to perform the task.

Besides the prompt, you should also include the proper YAML frontmatter, including the values for:

* `allowed-tools`
* `description`
* `argument-hint`
* `model` if a model different from the default is needed

Do not forget, that the command may require arguments. Those arguments are passed as a single string in $ARGUMENTS,
the command should be able to parse that.
