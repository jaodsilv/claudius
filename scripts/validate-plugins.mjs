import { readFileSync, existsSync } from 'fs';
import { glob } from 'glob';

const errors = [];

// 1. Load marketplace.json
let marketplace;
try {
  marketplace = JSON.parse(readFileSync('.claude-plugin/marketplace.json'));
} catch (e) {
  console.error(`❌ Failed to read marketplace.json: ${e.message}`);
  process.exit(1);
}

if (!marketplace.plugins || !Array.isArray(marketplace.plugins)) {
  console.error('❌ marketplace.json must contain a "plugins" array');
  process.exit(1);
}

const declaredPlugins = new Set(marketplace.plugins.map(p => p.name));

// 2. Find all plugin.json files
const pluginFiles = await glob('.claude-plugin/plugins/*/plugin.json');
const foundPlugins = new Set();

if (pluginFiles.length === 0) {
  console.warn('⚠️  Warning: No plugin.json files found in .claude-plugin/plugins/');
}

// 3. Validate each plugin
for (const file of pluginFiles) {
  let plugin;
  try {
    plugin = JSON.parse(readFileSync(file));
  } catch (e) {
    errors.push(`${file}: invalid JSON - ${e.message}`);
    continue;
  }

  // Required fields
  if (!plugin.name) errors.push(`${file}: missing 'name'`);
  if (!plugin.version) errors.push(`${file}: missing 'version'`);
  if (!plugin.description) errors.push(`${file}: missing 'description'`);

  if (plugin.name) {
    // Check for duplicates
    if (foundPlugins.has(plugin.name)) {
      errors.push(`${file}: duplicate plugin name '${plugin.name}'`);
    }
    foundPlugins.add(plugin.name);

    // Check marketplace includes this plugin
    if (!declaredPlugins.has(plugin.name)) {
      errors.push(`${file}: plugin '${plugin.name}' not in marketplace.json`);
    }
  }

  // Check referenced files exist (skip data/ external refs)
  const refs = [
    ...(plugin.skills || []),
    ...(plugin.agents || []),
    ...(plugin.commands || []),
    ...(plugin.scripts || [])
  ].filter(ref => typeof ref === 'string');

  for (const ref of refs) {
    if (!ref.startsWith('data/') && !existsSync(ref)) {
      errors.push(`${file}: referenced file not found: ${ref}`);
    }
  }
}

// 4. Check marketplace references valid plugins
for (const p of marketplace.plugins) {
  if (!foundPlugins.has(p.name)) {
    errors.push(`marketplace.json: references non-existent plugin '${p.name}'`);
  }
}

// 5. Report results
if (errors.length > 0) {
  console.error('❌ Validation errors:\n');
  errors.forEach(e => console.error(`  - ${e}`));
  process.exit(1);
}

console.log(`✅ All ${pluginFiles.length} plugins validated successfully`);
