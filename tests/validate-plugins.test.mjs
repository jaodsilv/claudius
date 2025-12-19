import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  loadMarketplace,
  validatePluginFields,
  validateFileReferences,
  checkDuplicate,
  checkMarketplaceDeclaration,
  validateMarketplaceRefs,
  parsePluginFile,
  validatePlugins
} from '../scripts/validate-plugins.mjs';

describe('validate-plugins', () => {
  describe('loadMarketplace', () => {
    it('should load valid marketplace.json', () => {
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue(JSON.stringify({
          plugins: [{ name: 'test-plugin' }]
        }))
      };

      const result = loadMarketplace('test.json', mockFs);
      expect(result.error).toBeNull();
      expect(result.marketplace.plugins).toHaveLength(1);
    });

    it('should return error for missing file', () => {
      const mockFs = {
        readFileSync: vi.fn().mockImplementation(() => {
          throw new Error('ENOENT');
        })
      };

      const result = loadMarketplace('missing.json', mockFs);
      expect(result.error).toContain('Failed to read marketplace.json');
      expect(result.marketplace).toBeNull();
    });

    it('should return error for invalid JSON', () => {
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue('not valid json')
      };

      const result = loadMarketplace('invalid.json', mockFs);
      expect(result.error).toContain('Failed to read marketplace.json');
      expect(result.marketplace).toBeNull();
    });

    it('should return error for missing plugins array', () => {
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue(JSON.stringify({ name: 'test' }))
      };

      const result = loadMarketplace('no-plugins.json', mockFs);
      expect(result.error).toBe('marketplace.json must contain a "plugins" array');
      expect(result.marketplace).toBeNull();
    });

    it('should return error for non-array plugins', () => {
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue(JSON.stringify({ plugins: 'not-array' }))
      };

      const result = loadMarketplace('wrong-type.json', mockFs);
      expect(result.error).toBe('marketplace.json must contain a "plugins" array');
    });
  });

  describe('validatePluginFields', () => {
    it('should return no errors for valid plugin', () => {
      const plugin = { name: 'test', version: '1.0.0', description: 'A test plugin' };
      const errors = validatePluginFields(plugin, 'test.json');
      expect(errors).toHaveLength(0);
    });

    it('should return error for missing name', () => {
      const plugin = { version: '1.0.0', description: 'A test plugin' };
      const errors = validatePluginFields(plugin, 'test.json');
      expect(errors).toContain("test.json: missing 'name'");
    });

    it('should return error for missing version', () => {
      const plugin = { name: 'test', description: 'A test plugin' };
      const errors = validatePluginFields(plugin, 'test.json');
      expect(errors).toContain("test.json: missing 'version'");
    });

    it('should return error for missing description', () => {
      const plugin = { name: 'test', version: '1.0.0' };
      const errors = validatePluginFields(plugin, 'test.json');
      expect(errors).toContain("test.json: missing 'description'");
    });

    it('should return multiple errors for multiple missing fields', () => {
      const plugin = {};
      const errors = validatePluginFields(plugin, 'test.json');
      expect(errors).toHaveLength(3);
    });

    it('should handle null values', () => {
      const plugin = { name: null, version: null, description: null };
      const errors = validatePluginFields(plugin, 'test.json');
      expect(errors).toHaveLength(3);
    });
  });

  describe('validateFileReferences', () => {
    it('should return no errors when all files exist', () => {
      const plugin = { skills: ['skill1.md', 'skill2.md'] };
      const mockFs = { existsSync: vi.fn().mockReturnValue(true) };

      const errors = validateFileReferences(plugin, 'test.json', mockFs);
      expect(errors).toHaveLength(0);
    });

    it('should return error for missing file', () => {
      const plugin = { skills: ['missing.md'] };
      const mockFs = { existsSync: vi.fn().mockReturnValue(false) };

      const errors = validateFileReferences(plugin, 'test.json', mockFs);
      expect(errors).toContain('test.json: referenced file not found: missing.md');
    });

    it('should skip data/ prefix files', () => {
      const plugin = { skills: ['data/external/file.md'] };
      const mockFs = { existsSync: vi.fn().mockReturnValue(false) };

      const errors = validateFileReferences(plugin, 'test.json', mockFs);
      expect(errors).toHaveLength(0);
      expect(mockFs.existsSync).not.toHaveBeenCalled();
    });

    it('should check all reference types', () => {
      const plugin = {
        skills: ['skill.md'],
        agents: ['agent.md'],
        commands: ['command.md'],
        scripts: ['script.js']
      };
      const mockFs = { existsSync: vi.fn().mockReturnValue(true) };

      validateFileReferences(plugin, 'test.json', mockFs);
      expect(mockFs.existsSync).toHaveBeenCalledTimes(4);
    });

    it('should handle empty arrays', () => {
      const plugin = { skills: [], agents: [] };
      const mockFs = { existsSync: vi.fn() };

      const errors = validateFileReferences(plugin, 'test.json', mockFs);
      expect(errors).toHaveLength(0);
      expect(mockFs.existsSync).not.toHaveBeenCalled();
    });

    it('should filter out non-string references', () => {
      const plugin = { skills: ['valid.md', null, 123, { obj: true }] };
      const mockFs = { existsSync: vi.fn().mockReturnValue(true) };

      const errors = validateFileReferences(plugin, 'test.json', mockFs);
      expect(mockFs.existsSync).toHaveBeenCalledTimes(1);
    });
  });

  describe('checkDuplicate', () => {
    it('should return no error for unique plugin', () => {
      const foundPlugins = new Set(['other-plugin']);
      const result = checkDuplicate('test-plugin', foundPlugins, 'test.json');
      expect(result.error).toBeNull();
      expect(result.isDuplicate).toBe(false);
    });

    it('should return error for duplicate plugin', () => {
      const foundPlugins = new Set(['test-plugin']);
      const result = checkDuplicate('test-plugin', foundPlugins, 'test.json');
      expect(result.error).toContain("duplicate plugin name 'test-plugin'");
      expect(result.isDuplicate).toBe(true);
    });
  });

  describe('checkMarketplaceDeclaration', () => {
    it('should return null for declared plugin', () => {
      const declaredPlugins = new Set(['test-plugin']);
      const result = checkMarketplaceDeclaration('test-plugin', declaredPlugins, 'test.json');
      expect(result).toBeNull();
    });

    it('should return error for undeclared plugin', () => {
      const declaredPlugins = new Set(['other-plugin']);
      const result = checkMarketplaceDeclaration('test-plugin', declaredPlugins, 'test.json');
      expect(result).toContain("plugin 'test-plugin' not in marketplace.json");
    });
  });

  describe('validateMarketplaceRefs', () => {
    it('should return no errors when all refs are valid', () => {
      const marketplacePlugins = [{ name: 'plugin1' }, { name: 'plugin2' }];
      const foundPlugins = new Set(['plugin1', 'plugin2']);

      const errors = validateMarketplaceRefs(marketplacePlugins, foundPlugins);
      expect(errors).toHaveLength(0);
    });

    it('should return error for non-existent plugin reference', () => {
      const marketplacePlugins = [{ name: 'missing-plugin' }];
      const foundPlugins = new Set(['other-plugin']);

      const errors = validateMarketplaceRefs(marketplacePlugins, foundPlugins);
      expect(errors).toContain("marketplace.json: references non-existent plugin 'missing-plugin'");
    });

    it('should handle empty marketplace', () => {
      const errors = validateMarketplaceRefs([], new Set());
      expect(errors).toHaveLength(0);
    });
  });

  describe('parsePluginFile', () => {
    it('should parse valid plugin file', () => {
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue(JSON.stringify({ name: 'test' }))
      };

      const result = parsePluginFile('test.json', mockFs);
      expect(result.error).toBeNull();
      expect(result.plugin.name).toBe('test');
    });

    it('should return error for invalid JSON', () => {
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue('invalid json')
      };

      const result = parsePluginFile('test.json', mockFs);
      expect(result.error).toContain('invalid JSON');
      expect(result.plugin).toBeNull();
    });

    it('should return error for read failure', () => {
      const mockFs = {
        readFileSync: vi.fn().mockImplementation(() => {
          throw new Error('ENOENT');
        })
      };

      const result = parsePluginFile('missing.json', mockFs);
      expect(result.error).toContain('invalid JSON');
      expect(result.plugin).toBeNull();
    });
  });

  describe('validatePlugins (integration)', () => {
    it('should validate successfully with valid setup', async () => {
      const mockFs = {
        readFileSync: vi.fn().mockImplementation((path) => {
          if (path.includes('marketplace')) {
            return JSON.stringify({ plugins: [{ name: 'test-plugin', source: './test-plugin' }] });
          }
          return JSON.stringify({
            name: 'test-plugin',
            version: '1.0.0',
            description: 'Test'
          });
        }),
        existsSync: vi.fn().mockReturnValue(true)
      };

      const result = await validatePlugins({
        fs: mockFs
      });

      expect(result.errors).toHaveLength(0);
      expect(result.pluginCount).toBe(1);
    });

    it('should return error when marketplace fails to load', async () => {
      const mockFs = {
        readFileSync: vi.fn().mockImplementation(() => {
          throw new Error('File not found');
        })
      };

      const result = await validatePlugins({
        fs: mockFs
      });

      expect(result.errors).toHaveLength(1);
      expect(result.errors[0]).toContain('Failed to read marketplace.json');
    });

    it('should collect errors from multiple plugins', async () => {
      const mockFs = {
        readFileSync: vi.fn().mockImplementation((path) => {
          if (path.includes('marketplace')) {
            return JSON.stringify({
              plugins: [
                { name: 'plugin1', source: './plugin1' },
                { name: 'plugin2', source: './plugin2' }
              ]
            });
          }
          // Return invalid plugin (missing fields)
          return JSON.stringify({});
        }),
        existsSync: vi.fn().mockReturnValue(true)
      };

      const result = await validatePlugins({
        fs: mockFs
      });

      // Each plugin should have 3 errors (missing name, version, description)
      expect(result.errors.length).toBeGreaterThanOrEqual(6);
    });

    it('should handle no plugins found', async () => {
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue(JSON.stringify({ plugins: [] }))
      };

      const result = await validatePlugins({
        fs: mockFs
      });

      expect(result.errors).toHaveLength(0);
      expect(result.pluginCount).toBe(0);
    });
  });
});
