import { readFileSync, existsSync } from 'fs';
import { dirname, join } from 'path';

/**
 * Load and validate marketplace.json
 * @param {string} path - Path to marketplace.json
 * @param {object} fs - File system module (for testing)
 * @returns {{ marketplace: object, error: string|null }}
 */
export function loadMarketplace(path, fs = { readFileSync }) {
  try {
    const content = fs.readFileSync(path, 'utf-8');
    const marketplace = JSON.parse(content);

    if (!marketplace.plugins || !Array.isArray(marketplace.plugins)) {
      return { marketplace: null, error: 'marketplace.json must contain a "plugins" array' };
    }

    return { marketplace, error: null };
  } catch (e) {
    return { marketplace: null, error: `Failed to read marketplace.json: ${e.message}` };
  }
}

/**
 * Validate required fields in a plugin
 * @param {object} plugin - Plugin object
 * @param {string} file - Plugin file path
 * @returns {string[]} Array of error messages
 */
export function validatePluginFields(plugin, file) {
  const errors = [];
  if (!plugin.name) errors.push(`${file}: missing 'name'`);
  if (!plugin.version) errors.push(`${file}: missing 'version'`);
  if (!plugin.description) errors.push(`${file}: missing 'description'`);
  return errors;
}

/**
 * Validate file references in a plugin
 * @param {object} plugin - Plugin object
 * @param {string} file - Plugin file path
 * @param {object} fs - File system module (for testing)
 * @returns {string[]} Array of error messages
 */
export function validateFileReferences(plugin, file, fs = { existsSync }) {
  const errors = [];
  const refs = [
    ...(plugin.skills || []),
    ...(plugin.agents || []),
    ...(plugin.commands || []),
    ...(plugin.scripts || [])
  ].filter(ref => typeof ref === 'string');

  // Get the plugin's base directory (parent of .claude-plugin/)
  const pluginBaseDir = dirname(dirname(file));

  for (const ref of refs) {
    // Skip data/ references (external submodules)
    if (ref.startsWith('data/')) continue;

    // Resolve path relative to plugin's base directory
    const resolvedPath = join(pluginBaseDir, ref.replace(/^\.\//, ''));
    if (!fs.existsSync(resolvedPath)) {
      errors.push(`${file}: referenced file not found: ${ref}`);
    }
  }
  return errors;
}

/**
 * Check for duplicate plugin names
 * @param {string} pluginName - Plugin name to check
 * @param {Set<string>} foundPlugins - Set of already found plugin names
 * @param {string} file - Plugin file path
 * @returns {{ error: string|null, isDuplicate: boolean }}
 */
export function checkDuplicate(pluginName, foundPlugins, file) {
  if (foundPlugins.has(pluginName)) {
    return { error: `${file}: duplicate plugin name '${pluginName}'`, isDuplicate: true };
  }
  return { error: null, isDuplicate: false };
}

/**
 * Check if plugin is declared in marketplace
 * @param {string} pluginName - Plugin name to check
 * @param {Set<string>} declaredPlugins - Set of plugins declared in marketplace
 * @param {string} file - Plugin file path
 * @returns {string|null} Error message or null
 */
export function checkMarketplaceDeclaration(pluginName, declaredPlugins, file) {
  if (!declaredPlugins.has(pluginName)) {
    return `${file}: plugin '${pluginName}' not in marketplace.json`;
  }
  return null;
}

/**
 * Validate marketplace references point to existing plugins
 * @param {object[]} marketplacePlugins - Plugins array from marketplace.json
 * @param {Set<string>} foundPlugins - Set of plugins found in file system
 * @returns {string[]} Array of error messages
 */
export function validateMarketplaceRefs(marketplacePlugins, foundPlugins) {
  const errors = [];
  for (const p of marketplacePlugins) {
    if (!foundPlugins.has(p.name)) {
      errors.push(`marketplace.json: references non-existent plugin '${p.name}'`);
    }
  }
  return errors;
}

/**
 * Parse a plugin file
 * @param {string} file - Path to plugin.json file
 * @param {object} fs - File system module (for testing)
 * @returns {{ plugin: object|null, error: string|null }}
 */
export function parsePluginFile(file, fs = { readFileSync }) {
  try {
    const content = fs.readFileSync(file, 'utf-8');
    return { plugin: JSON.parse(content), error: null };
  } catch (e) {
    return { plugin: null, error: `${file}: invalid JSON - ${e.message}` };
  }
}

/**
 * Main validation function
 * @param {object} options - Configuration options
 * @param {string} options.marketplacePath - Path to marketplace.json
 * @param {object} options.fs - File system module (for testing)
 * @returns {Promise<{ errors: string[], pluginCount: number }>}
 */
export async function validatePlugins(options = {}) {
  const {
    marketplacePath = '.claude-plugin/marketplace.json',
    fs = { readFileSync, existsSync }
  } = options;

  const errors = [];

  // 1. Load marketplace.json
  const { marketplace, error: marketplaceError } = loadMarketplace(marketplacePath, fs);
  if (marketplaceError) {
    return { errors: [marketplaceError], pluginCount: 0 };
  }

  const declaredPlugins = new Set(marketplace.plugins.map(p => p.name));

  // 2. Build plugin file paths from marketplace sources
  const pluginFiles = marketplace.plugins.map(p => `${p.source}/.claude-plugin/plugin.json`);
  const foundPlugins = new Set();

  // 3. Validate each plugin
  for (const file of pluginFiles) {
    const { plugin, error: parseError } = parsePluginFile(file, fs);
    if (parseError) {
      errors.push(parseError);
      continue;
    }

    // Required fields
    errors.push(...validatePluginFields(plugin, file));

    if (plugin.name) {
      // Check for duplicates
      const { error: dupError, isDuplicate } = checkDuplicate(plugin.name, foundPlugins, file);
      if (dupError) errors.push(dupError);
      if (!isDuplicate) foundPlugins.add(plugin.name);

      // Check marketplace includes this plugin
      const declError = checkMarketplaceDeclaration(plugin.name, declaredPlugins, file);
      if (declError) errors.push(declError);
    }

    // Check referenced files exist
    errors.push(...validateFileReferences(plugin, file, fs));
  }

  // 4. Check marketplace references valid plugins
  errors.push(...validateMarketplaceRefs(marketplace.plugins, foundPlugins));

  return { errors, pluginCount: pluginFiles.length };
}

// Run when executed directly
// On Windows, import.meta.url is file:///C:/... (3 slashes), so we need file:///${path}
const isMainModule = process.argv[1] && import.meta.url === `file:///${process.argv[1].replace(/\\/g, '/')}`;
if (isMainModule) {
  const { errors, pluginCount } = await validatePlugins();

  if (pluginCount === 0) {
    console.warn('⚠️  Warning: No plugins found in marketplace.json');
  }

  if (errors.length > 0) {
    console.error('❌ Validation errors:\n');
    errors.forEach(e => console.error(`  - ${e}`));
    process.exit(1);
  }

  console.log(`✅ All ${pluginCount} plugins validated successfully`);
}
