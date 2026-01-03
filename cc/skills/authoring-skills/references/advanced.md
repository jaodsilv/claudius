# Advanced: Skills with Executable Code

Guidelines for skills that include scripts and dependencies.

## Scripts Philosophy

### Solve, Don't Punt

Handle errors explicitly rather than failing to Claude:

**Good**:

```python
def process_file(path):
    try:
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        print(f"File {path} not found, creating default")
        with open(path, 'w') as f:
            f.write('')
        return ''
```

**Bad**:

```python
def process_file(path):
    return open(path).read()  # Just fails
```

### No Voodoo Constants

Justify all configuration values:

**Good**:

```python
# HTTP requests typically complete within 30 seconds
REQUEST_TIMEOUT = 30

# Three retries balances reliability vs speed
MAX_RETRIES = 3
```

**Bad**:

```python
TIMEOUT = 47  # Why 47?
RETRIES = 5   # Why 5?
```

## Utility Scripts

Pre-made scripts offer advantages over generated code:

1. **More reliable** than Claude-generated code
2. **Save tokens** - no code in context
3. **Save time** - no generation required
4. **Ensure consistency** across uses

### Execute vs Read

Make intent clear in instructions:

- **Execute**: "Run `analyze_form.py` to extract fields"
- **Read as reference**: "See `analyze_form.py` for the algorithm"

Execution preferred for most utility scripts.

### Documentation Format

```markdown
## Utility scripts

**analyze_form.py**: Extract form fields from PDF

python scripts/analyze_form.py input.pdf > fields.json

Output format:
{"field_name": {"type": "text", "x": 100, "y": 200}}

**validate.py**: Check for issues

python scripts/validate.py fields.json
# Returns: "OK" or lists conflicts
```

## Visual Analysis

When inputs can be rendered as images:

```markdown
## Form layout analysis

1. Convert PDF to images:
   python scripts/pdf_to_images.py form.pdf

2. Analyze each page image to identify form fields
3. Claude sees field locations and types visually
```

Claude's vision helps understand layouts.

## Verifiable Intermediate Outputs

For complex tasks, use plan-validate-execute:

1. **Analyze** input
2. **Create plan file** (e.g., `changes.json`)
3. **Validate plan** with script
4. **Execute** approved plan
5. **Verify** output

**Why it works**:

- Catches errors before changes applied
- Machine-verifiable validation
- Reversible planning phase
- Clear debugging

**When to use**: Batch operations, destructive changes, high-stakes operations.

## Package Dependencies

List required packages in SKILL.md:

```markdown
## Dependencies

Install required packages:
pip install pypdf pdfplumber

Note: Verify packages are available in the target environment.
```

**Platform considerations**:

- claude.ai: Can install from npm, PyPI, pull from GitHub
- Anthropic API: No network access, no runtime installation

## MCP Tool References

Use fully qualified tool names: `ServerName:tool_name`

```markdown
Use the BigQuery:bigquery_schema tool to retrieve schemas.
Use the GitHub:create_issue tool to create issues.
```

Without server prefix, Claude may fail to locate tools.

## Anti-Patterns

### Windows Paths

Always use forward slashes:

- **Good**: `scripts/helper.py`, `reference/guide.md`
- **Bad**: `scripts\helper.py`, `reference\guide.md`

Unix-style paths work across all platforms.

### Too Many Options

Provide a default with escape hatch, not a menu of choices.
