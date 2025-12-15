import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { glob } from 'glob';
import { join, basename, dirname } from 'path';

const outDir = 'docs/_site';
mkdirSync(outDir, { recursive: true });

// Helper to extract title from markdown
function getTitle(content) {
  const match = content.match(/^#\s+(.+)/m);
  return match ? match[1] : null;
}

// Helper to extract description (first paragraph after title)
function getDescription(content) {
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
  return desc.join(' ').slice(0, 200);
}

// Helper to safely read file
function safeReadFile(file) {
  try {
    return readFileSync(file, 'utf-8');
  } catch (e) {
    console.warn(`⚠️  Warning: Could not read ${file}: ${e.message}`);
    return null;
  }
}

// Generate Agents catalog
async function generateAgentsCatalog() {
  const agents = await glob('dotclaude/agents/**/*.md');
  let content = '# Agent Catalog\n\n';
  content += `*${agents.length} agents available*\n\n`;

  for (const file of agents.sort()) {
    const md = safeReadFile(file);
    if (!md) continue;

    const name = basename(file, '.md');
    const title = getTitle(md) || name;
    const desc = getDescription(md);
    content += `## ${title}\n\n`;
    content += `**File:** \`${file}\`\n\n`;
    if (desc) content += `${desc}\n\n`;
    content += '---\n\n';
  }

  writeFileSync(join(outDir, 'agents.md'), content);
  return agents.length;
}

// Generate Commands catalog
async function generateCommandsCatalog() {
  const commands = await glob('dotclaude/commands/**/*.md');
  let content = '# Command Reference\n\n';
  content += `*${commands.length} commands available*\n\n`;

  for (const file of commands.sort()) {
    const md = safeReadFile(file);
    if (!md) continue;

    const name = basename(file, '.md');
    const title = getTitle(md) || name;
    const desc = getDescription(md);
    content += `## /${name}\n\n`;
    content += `**File:** \`${file}\`\n\n`;
    if (desc) content += `${desc}\n\n`;
    content += '---\n\n';
  }

  writeFileSync(join(outDir, 'commands.md'), content);
  return commands.length;
}

// Generate Skills catalog
async function generateSkillsCatalog() {
  const skills = await glob('dotclaude/skills/**/SKILL.md');
  let content = '# Skill Matrix\n\n';
  content += `*${skills.length} skills available*\n\n`;

  for (const file of skills.sort()) {
    const md = safeReadFile(file);
    if (!md) continue;

    const skillDir = dirname(file).split('/').pop();
    const title = getTitle(md) || skillDir;
    const desc = getDescription(md);
    content += `## ${title}\n\n`;
    content += `**Directory:** \`${dirname(file)}\`\n\n`;
    if (desc) content += `${desc}\n\n`;
    content += '---\n\n';
  }

  writeFileSync(join(outDir, 'skills.md'), content);
  return skills.length;
}

// Generate Plugin marketplace docs
async function generatePluginsCatalog() {
  let marketplace;
  try {
    marketplace = JSON.parse(readFileSync('.claude-plugin/marketplace.json'));
  } catch (e) {
    console.error(`❌ Failed to read marketplace.json: ${e.message}`);
    return 0;
  }

  if (!marketplace.plugins || !Array.isArray(marketplace.plugins)) {
    console.error('❌ marketplace.json must contain a "plugins" array');
    return 0;
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

  writeFileSync(join(outDir, 'plugins.md'), content);
  return marketplace.plugins.length;
}

// Generate index page
function generateIndex(counts) {
  const content = `# Claudius Documentation

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
  writeFileSync(join(outDir, 'index.md'), content);
}

// Main
const counts = {
  agents: await generateAgentsCatalog(),
  commands: await generateCommandsCatalog(),
  skills: await generateSkillsCatalog(),
  plugins: await generatePluginsCatalog()
};

generateIndex(counts);

console.log('✅ Documentation generated:');
console.log(`   - ${counts.agents} agents`);
console.log(`   - ${counts.commands} commands`);
console.log(`   - ${counts.skills} skills`);
console.log(`   - ${counts.plugins} plugins`);
