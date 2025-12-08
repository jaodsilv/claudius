---
description: Template for use with the tech-recruitment-followup-specialist system prompt
version: 1.0
system_prompt: tech-recruitment-followup-specialist
system_prompt_version: 1.0
---

<datetime_last_interaction>2025-0-T::00-07:00</datetime_last_interaction>

<datetime_now>2025-0-T::00-07:00</datetime_now>

<context>
[Provide context about the recruitment situation, such as:
- Application stage (applied, interviewed, offer received, etc.)
- Company and role details
- Previous interactions and outcomes
- Any specific concerns or questions to address
- Current status and next steps expected]
</context>

<platform>email linkedin</platform>

<resume_filename>
resume_with_excluded_parts.md
</resume_filename>

<conversation_history>
[Provide the conversation history in YAML format, including:
- Previous messages exchanged
- Key points discussed
- Decisions made or pending
- Any commitments or promises made
- Timeline of interactions]
</conversation_history>

<follow_up_type>application_status interview_followup networking offer_discussion post_rejection general_checkin custom</follow_up_type>
