The task is to compare two pairs of Claude prompts, each pair is composed of a system prompt and a user prompt.
Which best fits the guidelines?

You will be provided the following required arguments:

* {{SYSTEM_PROMPT_A}}:
* {{USER_PROMPT_A}}
* {{SYSTEM_PROMPT_B}}
* {{USER_PROMPT_B}}
* {{GUIDELINES}}: Either an attachment or a copy-pasted text, optional. Defaults to your own knowledge of the topic.
* {{OUTPUT_TYPE}}: How I do want the output, a full report or a Boolean, true is B is better. Optional, defaults to Boolean

Before comparing you should create an strategy of how to compare both.
If output format is Boolean print everything you need to your thinking output

You should also infer the goal of those prompts based on the prompts themselves

\* Separate the generated prompt into system prompt and user prompt
