The task is to compare two Claude Code markdown document files with the same purpose.
 Which best fits the guidelines? Which will better perform for the common task?

You will be provided following parameters:

* {{FILE_A}}: A filepath
* {{FILE_B}}: Another filepath
* {{GUIDELINES}}: Yet another filepath. Optional, defaults to your own knowledge of the topic.
* {{DOC_TYPE}}: The type of the document, that can be either:
  * **output-style**: For output styles (For the new markdown output-style feature)
  * **agent**: For sub agents (for the new markdown subagents feature)
  * **command**: For Custom Slash Commands
* {{OUTPUT_TYPE}}: How I do want the output, a full report or a Boolean, true is B is better. Optional, defaults to Boolean

Before comparing you should create an strategy of how to compare both.
If output format is Boolean print everything you need to your thinking output

You should also infer the goal of those files based on the content of the files themselves

\* Separate the generated prompt into system prompt and user prompt
