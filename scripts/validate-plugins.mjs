/**
 * Plugin Validation Script for Claude Code Marketplace
 *
 * This script validates plugin configurations against the marketplace.json manifest.
 *
 * BREAKING CHANGES (v1.1.0):
 * - Removed `pluginGlob` parameter: Plugin paths are now derived from marketplace.json `source` field
 * - Removed `globFn` parameter: No longer needed since we don't glob for plugins
 * - Added `verbose` parameter: Enable with --verbose or -v flag to see skipped data/ references
 *
 * @module validate-plugins
 */

import { readFileSync, existsSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

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
 * @param {object} options - Additional options
 * @param {string[]} [options.skippedRefs] - Array to collect skipped data/ references (for logging)
 * @returns {string[]} Array of error messages
 */
export function validateFileReferences(plugin, file, fs = { existsSync }, options = {}) {
  const errors = [];
  const { skippedRefs } = options;
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
    if (ref.startsWith('data/')) {
      if (skippedRefs) {
        skippedRefs.push({ file, ref });
      }
      continue;
    }

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
  let content;
  try {
    content = fs.readFileSync(file, 'utf-8');
  } catch (e) {
    return { plugin: null, error: `${file}: failed to read file - ${e.message}` };
  }

  try {
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
 * @param {boolean} options.verbose - Enable verbose output for skipped files
 * @returns {Promise<{ errors: string[], pluginCount: number, skippedRefs: Array }>}
 */
export async function validatePlugins(options = {}) {
  const {
    marketplacePath = '.claude-plugin/marketplace.json',
    fs = { readFileSync, existsSync },
    verbose = false
  } = options;

  const errors = [];
  const skippedRefs = [];

  // 1. Load marketplace.json
  const { marketplace, error: marketplaceError } = loadMarketplace(marketplacePath, fs);
  if (marketplaceError) {
    return { errors: [marketplaceError], pluginCount: 0, skippedRefs: [] };
  }

  const declaredPlugins = new Set(marketplace.plugins.map(p => p.name));

  // 2. Validate marketplace entries have required fields and build plugin file paths
  const pluginFiles = [];
  for (const p of marketplace.plugins) {
    if (!p.source) {
      errors.push(`marketplace.json: plugin '${p.name || '(unnamed)'}' missing 'source' field`);
      continue;
    }
    pluginFiles.push(`${p.source}/.claude-plugin/plugin.json`);
  }
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

    // Check referenced files exist (collect skipped refs for logging)
    errors.push(...validateFileReferences(plugin, file, fs, { skippedRefs: verbose ? skippedRefs : undefined }));
  }

  // 4. Check marketplace references valid plugins
  errors.push(...validateMarketplaceRefs(marketplace.plugins, foundPlugins));

  return { errors, pluginCount: pluginFiles.length, skippedRefs };
}

// Run when executed directly
// Use fileURLToPath for cross-platform compatibility (handles Windows/Unix path differences)
const currentFilePath = fileURLToPath(import.meta.url);
const isMainModule = process.argv[1] && currentFilePath === process.argv[1];
if (isMainModule) {
  try {
    const verbose = process.argv.includes('--verbose') || process.argv.includes('-v');
    const { errors, pluginCount, skippedRefs } = await validatePlugins({ verbose });

    if (pluginCount === 0) {
      console.warn('Warning: No plugins found in marketplace.json');
    }

    if (errors.length > 0) {
      console.error('Validation errors:\n');
      errors.forEach(e => console.error(`  - ${e}`));
      process.exit(1);
    }

    console.log(`All ${pluginCount} plugins validated successfully`);

    // Log skipped data/ references in verbose mode
    if (verbose && skippedRefs.length > 0) {
      console.log(`\nSkipped ${skippedRefs.length} data/ references (external submodules):`);
      skippedRefs.forEach(({ file, ref }) => console.log(`  - ${file}: ${ref}`));
    }
  } catch (e) {
    console.error(`Validation failed with unexpected error: ${e.message}`);
    if (process.env.DEBUG) {
      console.error(e.stack);
    }
    process.exit(1);
  }
}
