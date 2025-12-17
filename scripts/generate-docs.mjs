import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { glob } from 'glob';
import { join, basename, dirname } from 'path';

/**
 * Extract title from markdown content
 * @param {string} content - Markdown content
 * @returns {string|null} Title or null if not found
 */
export function getTitle(content) {
  const match = content.match(/^#\s+(.+)/m);
  return match ? match[1] : null;
}

/**
 * Extract description (first paragraph after title)
 * @param {string} content - Markdown content
 * @param {number} maxLength - Maximum description length
 * @returns {string} Description text
 */
export function getDescription(content, maxLength = 200) {
  const lines = content.split('\n');
  let started = false;
  let desc = [];
  for (const line of lines) {
    if (line.startsWith('# ')) { started = true; continue; }
    if (started && line.trim() === '') {
      if (desc.length > 0) break;
      continue;
    }
    if (started && !line.startsWith('#')) {
      desc.push(line);
    }
    if (started && line.startsWith('#')) break;
  }
  return desc.join(' ').slice(0, maxLength);
}

/**
 * Safely read a file
 * @param {string} file - File path
 * @param {object} fs - File system module (for testing)
 * @returns {string|null} File content or null on error
 */
export function safeReadFile(file, fs = { readFileSync }) {
  try {
    return fs.readFileSync(file, 'utf-8');
  } catch (e) {
    console.warn(`⚠️  Warning: Could not read ${file}: ${e.message}`);
    return null;
  }
}

/**
 * Generate catalog entry for a markdown file
 * @param {string} file - File path
 * @param {string} content - File content
 * @param {object} options - Generation options
 * @returns {string} Markdown entry
 */
export function generateCatalogEntry(file, content, options = {}) {
  const { nameExtractor = (f) => basename(f, '.md'), pathLabel = 'File' } = options;
  const name = nameExtractor(file);
  const title = getTitle(content) || name;
  const desc = getDescription(content);

  let entry = `## ${title}\n\n`;
  entry += `**${pathLabel}:** \`${file}\`\n\n`;
  if (desc) entry += `${desc}\n\n`;
  entry += '---\n\n';
  return entry;
}

/**
 * Generate Agents catalog
 * @param {object} deps - Dependencies for testing
 * @returns {Promise<{ content: string, count: number }>}
 */
export async function generateAgentsCatalog(deps = {}) {
  const { globFn = glob, fs = { readFileSync }, globPattern = 'dotclaude/agents/**/*.md' } = deps;

  const agents = await globFn(globPattern);
  let content = '# Agent Catalog\n\n';
  content += `*${agents.length} agents available*\n\n`;

  for (const file of agents.sort()) {
    const md = safeReadFile(file, fs);
    if (!md) continue;
    content += generateCatalogEntry(file, md);
  }

  return { content, count: agents.length };
}

/**
 * Generate Commands catalog
 * @param {object} deps - Dependencies for testing
 * @returns {Promise<{ content: string, count: number }>}
 */
export async function generateCommandsCatalog(deps = {}) {
  const { globFn = glob, fs = { readFileSync }, globPattern = 'dotclaude/commands/**/*.md' } = deps;

  const commands = await globFn(globPattern);
  let content = '# Command Reference\n\n';
  content += `*${commands.length} commands available*\n\n`;

  for (const file of commands.sort()) {
    const md = safeReadFile(file, fs);
    if (!md) continue;

    const name = basename(file, '.md');
    const title = getTitle(md) || name;
    const desc = getDescription(md);
    content += `## /${name}\n\n`;
    content += `**File:** \`${file}\`\n\n`;
    if (desc) content += `${desc}\n\n`;
    content += '---\n\n';
  }

  return { content, count: commands.length };
}

/**
 * Generate Skills catalog
 * @param {object} deps - Dependencies for testing
 * @returns {Promise<{ content: string, count: number }>}
 */
export async function generateSkillsCatalog(deps = {}) {
  const { globFn = glob, fs = { readFileSync }, globPattern = 'dotclaude/skills/**/SKILL.md' } = deps;

  const skills = await globFn(globPattern);
  let content = '# Skill Matrix\n\n';
  content += `*${skills.length} skills available*\n\n`;

  for (const file of skills.sort()) {
    const md = safeReadFile(file, fs);
    if (!md) continue;

    const skillDir = dirname(file).split('/').pop();
    const title = getTitle(md) || skillDir;
    const desc = getDescription(md);
    content += `## ${title}\n\n`;
    content += `**Directory:** \`${dirname(file)}\`\n\n`;
    if (desc) content += `${desc}\n\n`;
    content += '---\n\n';
  }

  return { content, count: skills.length };
}

/**
 * Generate Plugin marketplace docs
 * @param {object} deps - Dependencies for testing
 * @returns {Promise<{ content: string, count: number }>}
 */
export async function generatePluginsCatalog(deps = {}) {
  const { fs = { readFileSync }, marketplacePath = '.claude-plugin/marketplace.json' } = deps;

  let marketplace;
  try {
    marketplace = JSON.parse(fs.readFileSync(marketplacePath, 'utf-8'));
  } catch (e) {
    console.error(`❌ Failed to read marketplace.json: ${e.message}`);
    return { content: '', count: 0 };
  }

  if (!marketplace.plugins || !Array.isArray(marketplace.plugins)) {
    console.error('❌ marketplace.json must contain a "plugins" array');
    return { content: '', count: 0 };
  }

  let content = '# Plugin Marketplace\n\n';
  content += `*${marketplace.plugins.length} plugins available*\n\n`;
  content += `**Marketplace:** ${marketplace.name} v${marketplace.version}\n\n`;
  content += `${marketplace.description}\n\n`;
  content += '---\n\n';

  for (const plugin of marketplace.plugins) {
    content += `## ${plugin.name}\n\n`;
    content += `**Version:** ${plugin.version} | **Category:** ${plugin.category}\n\n`;
    content += `${plugin.description}\n\n`;
    if (plugin.keywords) {
      content += `**Tags:** ${plugin.keywords.join(', ')}\n\n`;
    }
    content += '---\n\n';
  }

  return { content, count: marketplace.plugins.length };
}

/**
 * Generate index page content
 * @param {object} counts - Count of each item type
 * @returns {string} Index page markdown content
 */
export function generateIndexContent(counts) {
  return `# Claudius Documentation

Welcome to the Claudius configuration documentation.

## Contents

- [Agents](agents.md) - ${counts.agents} custom agents
- [Commands](commands.md) - ${counts.commands} slash commands
- [Skills](skills.md) - ${counts.skills} skills
- [Plugins](plugins.md) - ${counts.plugins} marketplace plugins

## About

Claudius is a personal configuration repository for Claude Code, containing custom agents, commands, skills, and a curated plugin marketplace.

---

*Auto-generated documentation*
`;
}

/**
 * Main documentation generation function
 * @param {object} options - Configuration options
 * @returns {Promise<object>} Counts of generated items
 */
export async function generateDocs(options = {}) {
  const {
    outDir = 'docs/_site',
    fs = { readFileSync, writeFileSync, mkdirSync },
    globFn = glob
  } = options;

  // Ensure output directory exists
  fs.mkdirSync(outDir, { recursive: true });

  const deps = { fs, globFn };

  // Generate all catalogs
  const [agentsResult, commandsResult, skillsResult, pluginsResult] = await Promise.all([
    generateAgentsCatalog(deps),
    generateCommandsCatalog(deps),
    generateSkillsCatalog(deps),
    generatePluginsCatalog(deps)
  ]);

  // Write files
  fs.writeFileSync(join(outDir, 'agents.md'), agentsResult.content);
  fs.writeFileSync(join(outDir, 'commands.md'), commandsResult.content);
  fs.writeFileSync(join(outDir, 'skills.md'), skillsResult.content);
  fs.writeFileSync(join(outDir, 'plugins.md'), pluginsResult.content);

  const counts = {
    agents: agentsResult.count,
    commands: commandsResult.count,
    skills: skillsResult.count,
    plugins: pluginsResult.count
  };

  // Generate index
  const indexContent = generateIndexContent(counts);
  fs.writeFileSync(join(outDir, 'index.md'), indexContent);

  return counts;
}

// Run when executed directly
const isMainModule = import.meta.url === `file://${process.argv[1].replace(/\\/g, '/')}`;
if (isMainModule) {
  const counts = await generateDocs();

  console.log('✅ Documentation generated:');
  console.log(`   - ${counts.agents} agents`);
  console.log(`   - ${counts.commands} commands`);
  console.log(`   - ${counts.skills} skills`);
  console.log(`   - ${counts.plugins} plugins`);
}
