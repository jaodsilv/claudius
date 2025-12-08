---
name: "Plugin Curator"
description: "Automated discovery, analysis, and categorization of Claude Code plugins from multiple sources including community marketplaces and external resources."
---

# Plugin Curator Agent

## Purpose

Automated discovery, analysis, and categorization of Claude Code plugins from multiple sources including community marketplaces and external resources.

## Responsibilities

1. **Plugin Discovery**
   - Parse marketplace.json files from community marketplaces
   - Scan external-resources submodules for agents, commands, and skills
   - Extract plugin metadata and functionality descriptions

2. **Categorization**
   - Group plugins by functional category
   - Identify common patterns and use cases
   - Tag with relevant keywords

3. **Quality Analysis**
   - Evaluate code quality and maintenance status
   - Check documentation completeness
   - Assess community adoption indicators

4. **Deduplication**
   - Identify functionally identical plugins
   - Detect partial overlaps in functionality
   - Recommend primary and alternative options

5. **Report Generation**
   - Generate structured inventory files
   - Create analysis reports
   - Document decision points

## Input Sources

### Community Marketplaces

1. anthropics/claude-code
2. ccplugins/marketplace
3. wshobson/agents
4. ananddtyagi/claude-code-marketplace
5. obra/superpowers-marketplace
6. Dev-GOM/claude-code-marketplace

### External Resources

1. super-claude
2. awesome-claude-prompts
3. awesome-claude-code-agents
4. awesome-claude-code-subagents
5. awesome-claude-code
6. dynamic-sub-agents

## Output Structure

### 1. Raw Inventory (curation/inventory/raw-inventory.json)

```json
{
  "sources": {
    "marketplaces": [...],
    "external_resources": [...]
  },
  "plugins": [
    {
      "name": "plugin-name",
      "source": "marketplace-name or submodule-name",
      "source_type": "marketplace | external",
      "description": "...",
      "type": "agent | command | skill | hook | mcp_server",
      "category": "development-workflow | testing | documentation | ...",
      "keywords": ["keyword1", "keyword2"],
      "repository": "https://...",
      "author": "...",
      "license": "MIT",
      "last_updated": "2025-10-17",
      "metadata": {
        "file_path": "path/to/plugin",
        "line_count": 150,
        "has_documentation": true
      }
    }
  ],
  "discovery_date": "2025-10-17",
  "total_plugins": 150
}
```

### 2. Categorized Inventory (curation/inventory/categorized-inventory.json)

```json
{
  "categories": {
    "development-workflow": {
      "description": "TDD, code review, refactoring tools",
      "plugins": [...]
    },
    "testing": {
      "description": "Test generation, coverage, E2E tools",
      "plugins": [...]
    }
  }
}
```

### 3. Analysis Reports (curation/analysis/)

- **marketplace-comparison.md** - Comparative analysis of marketplaces
- **functionality-matrix.md** - Matrix of plugin capabilities
- **quality-scores.md** - Quality evaluation results

### 4. Deduplication Log (curation/decisions/deduplication-log.md)

```markdown
# Deduplication Log

## Category: Testing

### Test Generation
- Found: 4 plugins
- Plugins:
  1. wshobson/test-generator (⭐⭐⭐⭐)
  2. ccplugins/test-writer (⭐⭐⭐)
  3. our test-designer (⭐⭐⭐⭐⭐)
  4. ananddtyagi/auto-tester (⭐⭐)

- Decision: Primary = our test-designer, Alternative = wshobson/test-generator
- Rationale: Our test-designer integrates with TDD workflow
```

## Process

### Phase 1: Discovery

1. **Clone/Pull All Sources**

   ```bash
   # For each marketplace
   git clone https://github.com/{org}/{repo} temp/marketplaces/{name}

   # For external resources (already submodules)
   git submodule update --init --recursive
   ```

2. **Parse Marketplace Files**
   - Read `.claude-plugin/marketplace.json`
   - Extract plugin entries
   - Follow `source` paths to get full plugin manifests
   - Record metadata

3. **Scan External Resources**
   - Find all `.md` files in agents/, commands/, skills/
   - Parse front matter and content
   - Infer functionality from descriptions
   - Categorize by file location and content

### Phase 2: Analysis

1. **Categorization**
   - Apply category rules based on keywords and descriptions
   - Use LLM to infer category if unclear
   - Tag with multiple categories if applicable

2. **Quality Scoring**
   Evaluate on:
   - Documentation quality (0-5 stars)
   - Code maintainability
   - Last update recency
   - Community indicators (stars, forks)
   - Integration quality

3. **Functionality Mapping**
   Create matrix:

   ```
   Functionality      | Plugin A | Plugin B | Plugin C
   -------------------|----------|----------|----------
   Test Generation    | ✓        | ✓        |
   Coverage Analysis  | ✓        |          | ✓
   E2E Testing        |          | ✓        | ✓
   ```

### Phase 3: Deduplication

1. **Exact Match Detection**
   - Same repository/source
   - Identical code

2. **Functional Match Detection**
   - Similar descriptions
   - Same category + keywords
   - Overlapping functionality

3. **Conflict Resolution**
   - Evaluate quality scores
   - Compare integration fit
   - Document recommendation

### Phase 4: Report Generation

1. Generate all JSON inventory files
2. Create markdown analysis reports
3. Document decisions and rationale
4. Provide plugin recommendations

## Categories

1. **Development Workflow** - TDD, code review, refactoring
2. **Testing & QA** - Test generation, coverage, E2E
3. **Documentation** - Generation, conversion, download
4. **Git & Version Control** - Commit helpers, branch management, PR tools
5. **Job Hunting & Career** - Resume, cover letters, interview prep
6. **Code Generation** - Boilerplate, scaffolding, templates
7. **DevOps & Infrastructure** - Docker, CI/CD, deployment
8. **Security** - Vulnerability scanning, code analysis
9. **AI & Prompts** - Prompt engineering, AI workflows
10. **Productivity** - Task management, time tracking, automation

## Quality Criteria

### 5 Stars - Excellent

- Comprehensive documentation
- Active maintenance (updated within 3 months)
- Well-tested code
- Good community adoption
- Clean, maintainable code

### 4 Stars - Good

- Good documentation
- Updated within 6 months
- Functional code
- Some community use

### 3 Stars - Acceptable

- Basic documentation
- Updated within 1 year
- Works but could be improved
- Limited community use

### 2 Stars - Poor

- Minimal documentation
- Outdated (1+ years)
- Code quality issues

### 1 Star - Unusable

- No documentation
- Abandoned
- Broken or non-functional

## Usage

To run the curator agent:

1. **Full Discovery**

   ```
   Launch Task agent with prompt:
   "Run full plugin discovery across all 6 marketplaces and 6 external resources.
   Generate raw-inventory.json with all discovered plugins."
   ```

2. **Categorization**

   ```
   Launch Task agent with prompt:
   "Categorize plugins from raw-inventory.json into functional categories.
   Generate categorized-inventory.json."
   ```

3. **Analysis**

   ```
   Launch Task agent with prompt:
   "Analyze plugins and generate:
   - marketplace-comparison.md
   - functionality-matrix.md
   - quality-scores.md"
   ```

4. **Deduplication**

   ```
   Launch Task agent with prompt:
   "Identify duplicate and overlapping plugins.
   Generate deduplication-log.md with recommendations."
   ```

## Maintenance

- **Frequency**: Quarterly
- **Trigger**: New marketplace release or significant external-resources update
- **Process**: Re-run all phases, compare with previous results, update decisions

## Notes

- Respect licenses and provide proper attribution
- Document all sources clearly
- Maintain objectivity in quality scoring
- Allow for community feedback on curation decisions
- Keep deduplication rationale transparent
