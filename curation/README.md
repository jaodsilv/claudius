# Plugin Curation Directory

This directory tracks the curation process for community plugins integrated into this marketplace.

## Structure

1. **inventory/** - Plugin discovery and cataloging
   - `raw-inventory.json` - Automated discovery output from all sources
   - `categorized-inventory.json` - Plugins organized by category
   - `final-inventory.json` - After deduplication and quality filtering

2. **analysis/** - Comparative analysis of plugins
   - `marketplace-comparison.md` - Analysis of all 6 community marketplaces
   - `submodule-analysis.md` - Review of external-resources submodules
   - `functionality-matrix.md` - Matrix of all discovered functionality
   - `quality-scores.md` - Quality ratings and evaluation criteria

3. **decisions/** - Curation decision tracking
   - `deduplication-log.md` - Track how duplicate plugins were handled
   - `inclusion-criteria.md` - What makes a plugin worthy of inclusion
   - `exclusion-log.md` - Why specific plugins were excluded
   - `recommendations.md` - Suggested plugin combinations

4. **outputs/** - Final curated plugin manifests
   - Plugin configuration files for curated collections

## Curation Sources

### Community Marketplaces

1. anthropics/claude-code (official)
2. ccplugins/marketplace
3. wshobson/agents
4. ananddtyagi/claude-code-marketplace
5. obra/superpowers-marketplace
6. Dev-GOM/claude-code-marketplace

### External Resources (Submodules)

1. super-claude
2. awesome-claude-prompts
3. awesome-claude-code-agents
4. awesome-claude-code-subagents
5. awesome-claude-code
6. dynamic-sub-agents

## Curation Process

The curation workflow follows these steps:
1. Automated discovery using curator agent
2. Categorization by functionality
3. Quality evaluation
4. Deduplication and conflict resolution
5. Final selection and plugin manifest creation
6. Documentation and attribution

## Maintenance

This curation is reviewed quarterly to:
- Check for updates in source marketplaces
- Discover new valuable plugins
- Update quality scores
- Deprecate abandoned plugins
- Incorporate community feedback
