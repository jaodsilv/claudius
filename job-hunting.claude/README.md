# Job Hunting Claude Configuration

Specialized Claude Code configuration for job hunting workflows.

## Overview

This directory contains Claude Code configurations specifically for job hunting tasks:

1. Job application tracking
2. Resume tailoring
3. Cover letter generation and evaluation
4. Company research
5. Interview preparation
6. Networking assistance

## Structure

```text
job-hunting.claude/
├── agents/              # Job hunting specialized agents
│   ├── cover-letter-evaluator/    # 14 evaluation aspect agents
│   ├── jobs/                       # 4 job hunting workflow agents
│   └── interview-company-researcher.md
├── commands/            # Job hunting slash commands
│   └── jobs/                       # 4 job hunting commands
├── output-styles/       # Specialized output formatting
│   └── tech-cover-letter-specialist.md
├── shared/              # Job hunting shared resources
└── README.md
```

## Agents

### Cover Letter Evaluators (`agents/cover-letter-evaluator/`)

Multi-step cover letter analysis agents:

1. `false-assertion-cleaner.md` - Remove false claims from drafts
2. `ats.md` - Applicant Tracking System compatibility analysis
3. `impact.md` - Evaluate impact and accomplishment presentation
4. `keywords.md` - Keyword optimization analysis
5. `true-gaps.md` - Identify genuine skill gaps
6. `overlap.md` - Analyze overlap between qualifications and requirements
7. `relevance.md` - Assess relevance to position
8. `result-combiner.md` - Combine evaluation results
9. `skills.md` - Skills alignment evaluation
10. `tech-positioning.md` - Technical positioning analysis
11. `terminology.md` - Industry terminology assessment
12. `personalization.md` - Personalization and customization check
13. `communication.md` - Communication effectiveness evaluation
14. `presentation.md` - Overall presentation quality

### Job Hunting Agents (`agents/jobs/`)

Workflow agents for job hunting tasks:

1. `cover-letter-improver.md` - Iterative cover letter improvement
2. `Cover-Letter-improver-standalone.md` - Standalone cover letter improvement
3. `cover-letter-shortener.md` - Reduce cover letter length
4. `message-parser.md` - Parse and extract job posting information

### Interview Preparation

1. `interview-company-researcher.md` - Company research for interview prep

## Commands

### Job Hunting Commands (`commands/jobs/`)

1. `/jobs:overlap-analysis` - Analyze overlap between qualifications and job requirements
2. `/jobs:improve-cover-letter` - Improve existing cover letter drafts
3. `/jobs:eval-cover-letter` - Comprehensive cover letter evaluation
4. `/jobs:eval-cover-letterv2` - Enhanced cover letter evaluation (v2)

## Output Styles

### Tech Cover Letter Specialist

1. `tech-cover-letter-specialist.md` - Specialized formatting for technical cover letters

## Usage

This configuration is designed to be used alongside the general `dotclaude/` configuration.

To use these specialized agents and commands:

1. Ensure this `job-hunting.claude/` directory is properly linked or mounted
2. Reference agents using the appropriate path (e.g., `@jobs:cover-letter-improver`)
3. Invoke commands using slash notation (e.g., `/jobs:eval-cover-letter`)

## Related Repositories

1. **job-hunting-automation**: Python tools for job searching, scraping, and scoring
2. **job-applications** (private): Personal application materials and tracking
3. **latex-templates**: Resume/CV templates for professional formatting

## Data Repository Setup

This plugin requires a private data repository for personal information that should not be committed to the public configs repository.

### Purpose

The data repository separation ensures:

1. Personal compensation information stays private
2. Contact details and signatures are not exposed
3. Conversation history and input files remain confidential
4. Easy sharing of plugin configs without exposing personal data

### Prerequisites

1. Git installed
2. Windows (for junction support) or Linux/macOS (for symlinks)
3. Private GitHub repository for your data

### Setup Steps

1. **Create a private data repository**:

   ```bash
   gh repo create job-hunting-data --private
   ```

2. **Clone to your data location**:

   ```bash
   git clone https://github.com/yourusername/job-hunting-data D:\src\claudeforge\data
   ```

3. **Create the required directory structure**:

   ```bash
   cd D:\src\claudeforge\data
   mkdir job-hunting
   mkdir job-hunting\history
   mkdir job-hunting\input
   ```

4. **Create Windows junction** (run as Administrator):

   ```cmd
   mklink /J D:\src\claudeforge\job-hunting-configs\job-hunting.claude\data D:\src\claudeforge\data\job-hunting
   ```

   Or on Linux/macOS:

   ```bash
   ln -s /path/to/data/job-hunting /path/to/job-hunting-configs/job-hunting.claude/data
   ```

### Required Directory Structure

```text
job-hunting.claude/
├── data/                          # Junction to private data repo
│   ├── personal-info.yaml         # Personal data for template substitution
│   ├── resume.md                  # Extended resume in markdown format
│   ├── history/                   # Conversation history files
│   └── input/                     # Input files for processing
└── templates/                     # Example templates (committed to configs repo)
    └── personal-info.example.yaml
```

### Personal Info Schema

Create `data/personal-info.yaml` based on the template at `templates/personal-info.example.yaml`:

```yaml
# Compensation Information
compensation:
  hourly:
    display: "$75-95/hr"           # Your target hourly rate range
  yearly:
    display: "$155k-195k"          # Your target yearly salary range
  thresholds:
    hourly_minimum_display: "$70/hr"   # Minimum acceptable hourly
    yearly_minimum_display: "$150k"    # Minimum acceptable yearly

# Signature for LinkedIn/Email messages
signature:
  linkedin: |
    Best regards,
    Your Name
    Your Title
    email@example.com | (555) 123-4567
    GitHub: github.com/yourusername
```

### Files Using This Data

1. `output-styles/recruiter-response.md` - Uses compensation and signature for drafting responses
2. `agents/jobs/message-parser.md` - Uses compensation thresholds for fit calculations

## Integration

Commands in this directory can invoke Python tools from the `job-hunting-automation` repository for:

1. Job posting scraping and data extraction
2. Resume-to-job-description scoring and matching
3. Automated application tracking
4. Company research and analysis

The integration allows for seamless workflows between Claude Code's natural language processing capabilities and Python automation tools.

## Workflow Example

Typical job hunting workflow using this configuration:

1. Use `/jobs:overlap-analysis` to assess fit for a position
2. Generate cover letter draft using appropriate templates
3. Evaluate draft with `/jobs:eval-cover-letterv2`
4. Improve based on evaluation using `/jobs:improve-cover-letter`
5. Research company using `@interview-company-researcher` for interview prep
6. Track applications using integrated Python tools

## Contributing

This is a personal configuration repository. For suggestions or improvements:

1. Review existing agents and commands for patterns
2. Follow the naming conventions used in `dotclaude/`
3. Ensure compatibility with the base Claude Code configuration
4. Test new agents and commands thoroughly before committing

## License

See parent repository LICENSE file.
