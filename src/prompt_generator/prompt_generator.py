'''
This script is used to generate a prompt for a given task.
Copied and converted from anthropic's prompt generator https://colab.research.google.com/drive/1SoAajN8CBYTl79VyTwxtxncfCWlHlyy9

Updated to use Claude Code SDK instead of direct Anthropic SDK.

Usage:
    python3 prompt_generator.py "Your task description" [variable1] [variable2] ...

Example:
    python3 prompt_generator.py "Act as a customer service agent" "FAQ" "QUESTION"

If no arguments provided, uses default example task.
'''

import sys
sys.path.append('../prompts')

from claude_code_sdk import query, ClaudeCodeOptions
import re
import asyncio

from prompts import prompts

async def generate_prompt(task: str, variables: list[str]) -> str:
    """
    Generate a prompt for a given task.
    """
    variable_string = ""
    for variable in variables:
        variable_string += "\n{$" + variable.upper() + "}"
    print(variable_string)

    prompt = prompts.GENERATE_PROMPT_PROMPT.replace("{{TASK}}", task)
    assistant_partial = "<Inputs>"
    if variable_string:
        assistant_partial += variable_string + "\n</Inputs>\n<Instructions Structure>"

    # Create the full prompt with assistant partial
    full_prompt = f"{prompt}\n\nAssistant: {assistant_partial}"
    
    response_text = ""
    async for message in query(
        prompt=full_prompt,
        options=ClaudeCodeOptions(
            max_turns=1
        )
    ):
        if message.type == "result":
            response_text = message.result
            break
    
    # Combine assistant_partial with the response
    message = assistant_partial + response_text

    pretty_print(message)

def pretty_print(message):
    print('\n\n'.join('\n'.join(line.strip() for line in re.findall(r'.{1,100}(?:\s+|$)', paragraph.strip('\n'))) for paragraph in re.split(r'\n\n+', message)))

def extract_between_tags(tag: str, string: str, strip: bool = False) -> list[str]:
    ext_list = re.findall(f"<{tag}>(.+?)</{tag}>", string, re.DOTALL)
    if strip:
        ext_list = [e.strip() for e in ext_list]
    return ext_list

def remove_empty_tags(text):
    return re.sub(r'\n<(\w+)>\s*</\1>\n', '', text, flags=re.DOTALL)

def strip_last_sentence(text):
    sentences = text.split('. ')
    if sentences[-1].startswith("Let me know"):
        sentences = sentences[:-1]
        result = '. '.join(sentences)
        if result and not result.endswith('.'):
            result += '.'
        return result
    else:
        return text

def extract_prompt(metaprompt_response):
    between_tags = extract_between_tags("Instructions", metaprompt_response)[0]
    return between_tags[:1000] + strip_last_sentence(remove_empty_tags(remove_empty_tags(between_tags[1000:]).strip()).strip())

def extract_variables(prompt):
    pattern = r'{([^}]+)}'
    variables = re.findall(pattern, prompt)
    return set(variables)

# This will be called in main() function

async def remove_inapt_floating_variables(prompt):
    full_prompt = prompts.REMOVE_FLOATING_VARIABLES_PROMPT.replace("{$PROMPT}", prompt)
    
    response_text = ""
    async for message in query(
        prompt=full_prompt,
        options=ClaudeCodeOptions(
            max_turns=1
        )
    ):
        if message.type == "result":
            response_text = message.result
            break
    
    return extract_between_tags("rewritten_prompt", response_text)[0]

def find_free_floating_variables(prompt):
    variable_usages = re.findall(r'\{\$[A-Z0-9_]+\}', prompt)

    free_floating_variables = []
    for variable in variable_usages:
        preceding_text = prompt[:prompt.index(variable)]
        open_tags = set()

        i = 0
        while i < len(preceding_text):
            if preceding_text[i] == '<':
                if i + 1 < len(preceding_text) and preceding_text[i + 1] == '/':
                    closing_tag = preceding_text[i + 2:].split('>', 1)[0]
                    open_tags.discard(closing_tag)
                    i += len(closing_tag) + 3
                else:
                    opening_tag = preceding_text[i + 1:].split('>', 1)[0]
                    open_tags.add(opening_tag)
                    i += len(opening_tag) + 2
            else:
                i += 1

        if not open_tags:
            free_floating_variables.append(variable)

    return free_floating_variables

async def main():
    # Get task and variables from command line args or use defaults
    if len(sys.argv) > 1:
        task = sys.argv[1]
        variables = sys.argv[2:] if len(sys.argv) > 2 else []
    else:
        # Default example for testing
        task = "Act as a polite customer success agent for Acme Dynamics. Use FAQ to answer questions."
        variables = ["FAQ", "QUESTION"]
    
    # Generate the prompt
    message = await generate_prompt(task, variables)
    
    # Extract the prompt template and variables
    extracted_prompt_template = extract_prompt(message)
    extracted_variables = extract_variables(message)

    print("Variables:\n\n" + str(extracted_variables))
    print("\n************************\n")
    print("Prompt:")
    pretty_print(extracted_prompt_template)

    # Check for floating variables and fix them if needed
    floating_variables = find_free_floating_variables(extracted_prompt_template)
    if len(floating_variables) > 0:
        extracted_prompt_template_old = extracted_prompt_template
        extracted_prompt_template = await remove_inapt_floating_variables(extracted_prompt_template)
        print("New prompt template:\n")
        pretty_print(extracted_prompt_template)

if __name__ == "__main__":
    asyncio.run(main())
