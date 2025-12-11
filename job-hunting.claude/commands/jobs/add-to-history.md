---

description: Updates a conversation history file in the @job-hunting/history directory.
argument-hint: Raw text copy-pasted from either email or linkedin
allowed-tools: Task, Read, TodoWrite, Write, LS, Grep, Glob, Edit
---

## Context

Arguments: $ARGUMENTS
Arguments is a raw text copy-pasted from either email or linkedin or an additional context from the user.

## Task

Your task is to update 1 file in the @job-hunting/history directory

### Steps

1. Parse the arguments to extract the desired information
2. analyze the arguments to determine the best template to use or if it is just additional context
3. analyze the arguments to extract non-obvious information, like the datetime of the message and company name, etc.
4. With the provided information identify the the filename of the history file to update.
5. Update the history file

### Arguments Parsing

You should parse the arguments to extract the following information:

- The company name, either from the person's title or from the message body
- The recruiting company name (for contract positions), either from the person's title or from the message body
- The recruiter's name
- The date and time of the message, if it is only a day of the week or a hours ago calculate the datetime it was received.
  Note that it is always presented in the -07:00 timezone, unless explicitly stated otherwise.
- Subject of the message (if available)
- The message body

#### Input format

Below are texts written in mixed of regex and text., like a regex using python's f-string format for variables.
If multiple messages arrived, they are separated by a triple dash `\n---\n`.
It comes in one of the following formats:

##### Format 1 - LinkedIn

- Note that, sometimes, the person includes their company in their title, like "Talent Partner@ Amazon Robotics".
- In that case, you should extract the company name from the title.
- Gender pronouns are optional
- "\nVerified recruiter" is optional
- ", #HIRING" is optional
- "\n👏\n👍\n😊\n+" is optional
- "{{subject}}\n" is optional
- "\n{2,}{{attachment_filename}}\n\n{{attachment_size}}\n\nDownload" is optional
- You should infer the desired variables from the text.

```text
{{full_name}}(\n\({{gender_pronouns}}\))?\n{{degree_connection}} degree connection\n· {{degree_connection}}\n{{person_title}}\n(\nVerified recruiter)?\n{{day_of_week_or_date}}\n{{full_name}} sent the following messages at {{time}}\nView {{first_name}}'s profile{{full_name}}(, #HIRING)?\n{{full_name}}( \({{gender_pronouns}}\))?  {{time}}(\n👏\n👍\n😊\n+)?\n+({{subject}}\n)?{{message_body}}(\n{2,}{{attachment_filename}}\n\n{{attachment_size}}\n\nDownload)?
```

##### Format 2 - Email

- "{{labels_names}}" is optional
- You should infer the desired variables from the text.

```text
{{subject}}\n({{labels_names}})?\n\n{{from}} <{{email_address}}>\n{{datetime_info}}\nto {{João}}\n\n{{message_body}}
```

### History File

Create a new history file in the @job-hunting/history directory.

#### History File Filename

The filename should be in the format of `<company_name>-<recruiter_first_name>.yaml` for full time positions
or `<recruiting_company_name>-<recruiter_first_name>-<company_name>.yaml` for contract positions.

If either the company name or the recruiting company name is unknown, use the word `unknown` in its place.

#### History File added or updated Content

The generated content should follow one of the templates below:

##### Template Group 1 - LinkedIn

- Note that `optional_subject` is optional
- `timestamp` should be printed in ISO format with the day of the week after it, e.g., `2025-08-20T15:21:00-07:00 Wednesday`
- Datetimes are always in -07:00 timezone

###### Template Group 1.1 - Reach-Out for contract positions

####### Template 1.1.1 - Without company name

```yaml
  - timestamp: {{timestamp}}
    from: {{from}}
    subject: {{optional_subject}}
    body: |
      {{message_body}}
```

###### Template 1.1.2 - With company name

```yaml
  - timestamp: {{timestamp}}
    from: {{from}}
    subject: {{optional_subject}}
    body: |
      {{message_body}}
```

###### Template Group 1.2 - Reach-out for Full Time positions

####### Template 1.2.1 - Without company name

```yaml
  - timestamp: {{timestamp}}
    from: {{from}}
    subject: {{optional_subject}}
    body: |
      {{message_body}}
```

####### Template 1.2.2 - With company name

```yaml
  - timestamp: {{timestamp}}
    from: {{from}}
    subject: {{optional_subject}}
    body: |
      {{message_body}}
```

###### Template Group 1.3 - Response to LinkedIn Applications

####### Template 1.3.1 - Response to LinkedIn Application

```yaml
  - timestamp: {{timestamp}}
    from: {{from}}
    subject: {{subject}}
    body: |
      {{message_body}}
```

##### Template Group 2 - Email

###### Template 2.1 - Recruiter Reach-Out for contract positions

```yaml
  - timestamp: {{timestamp}}
    from: {{from}}
    subject: {{subject}}
    body: |
      {{message_body}}
```

###### Template 2.2 - Recruiter Reach-Out for full time positions

```yaml
  - timestamp: {{timestamp}}
    from: {{from}}
    subject: {{subject}}
    body: |
      {{message_body}}
```

###### Template 2.3 - Application Response

####### Template 2.3.1 - Response to Email Application

```yaml
  - timestamp: {{timestamp}}
    from: {{from}}
    subject: {{subject}}
    body: |
      {{message_body}}
```

#### Template Group 3 - Additional Context

```yaml
context:
  - {{context}}
```

#### Template Group 4 - Update Process Status

```yaml
process_status: {{process_status}}
```
