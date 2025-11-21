Given a task. Create a Claude Code's Custom Output Style to perform the task.

The prompt is meant to be used with Claude Code with model Claude Sonnet 4 with thinking enabled.

You will be provided the following arguments:

* {{TASK}}: The task or prompt to perform.
* {{GUIDELINES}}: Either an attachment or a copy-pasted text, optional. Defaults to your own knowledge of the topic.

Before comparing you should create an strategy of how to create the output-style.

Besides the prompt, you should also include the proper YAML frontmatter, including the values for:

* `name`
* `description`
