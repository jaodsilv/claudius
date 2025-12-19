import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  loadMarketplace,
  validatePluginFields,
  validateFileReferences,
  checkDuplicate,
  checkMarketplaceDeclaration,
  validateMarketplaceRefs,
  parsePluginFile,
  validatePlugins,
  runCli
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

    it('should strip ./ prefix from paths before resolution', () => {
      const plugin = { skills: ['./skills/test.md'] };
      const mockFs = { existsSync: vi.fn().mockReturnValue(true) };

      // File is at project/.claude-plugin/plugin.json
      // Plugin base dir should be project/ (dirname of dirname)
      // Reference ./skills/test.md should resolve to project/skills/test.md
      validateFileReferences(plugin, 'project/.claude-plugin/plugin.json', mockFs);
      // Use path.join expectation to handle cross-platform path separators
      const call = mockFs.existsSync.mock.calls[0][0];
      expect(call.replace(/\\/g, '/')).toBe('project/skills/test.md');
    });

    it('should resolve paths relative to plugin base directory (parent of .claude-plugin)', () => {
      const plugin = { agents: ['agents/my-agent.md'] };
      const mockFs = { existsSync: vi.fn().mockReturnValue(true) };

      // Plugin file at workspace/my-plugin/.claude-plugin/plugin.json
      // Base dir should be workspace/my-plugin (two levels up from plugin.json)
      validateFileReferences(plugin, 'workspace/my-plugin/.claude-plugin/plugin.json', mockFs);
      const call = mockFs.existsSync.mock.calls[0][0];
      expect(call.replace(/\\/g, '/')).toBe('workspace/my-plugin/agents/my-agent.md');
    });

    it('should correctly handle nested plugin directories', () => {
      const plugin = { commands: ['./commands/cmd.md'] };
      const mockFs = { existsSync: vi.fn().mockReturnValue(true) };

      validateFileReferences(plugin, 'root/plugins/feature/.claude-plugin/plugin.json', mockFs);
      const call = mockFs.existsSync.mock.calls[0][0];
      expect(call.replace(/\\/g, '/')).toBe('root/plugins/feature/commands/cmd.md');
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
      expect(result.error).toContain('failed to read file');
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

    it('should return error for plugin missing source field', async () => {
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue(JSON.stringify({
          plugins: [
            { name: 'plugin-without-source' }
          ]
        }))
      };

      const result = await validatePlugins({
        fs: mockFs
      });

      // Expect two errors: missing source field + marketplace references non-existent plugin
      expect(result.errors).toHaveLength(2);
      expect(result.errors[0]).toContain("missing 'source' field");
      expect(result.errors[1]).toContain("references non-existent plugin");
      expect(result.pluginCount).toBe(0);
    });

    it('should handle plugin with missing source and missing name', async () => {
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue(JSON.stringify({
          plugins: [
            { description: 'A plugin with no name or source' }
          ]
        }))
      };

      const result = await validatePlugins({
        fs: mockFs
      });

      // Expect two errors: missing source field + marketplace references non-existent plugin (undefined)
      expect(result.errors).toHaveLength(2);
      expect(result.errors[0]).toContain('(unnamed)');
      expect(result.errors[0]).toContain("missing 'source' field");
      expect(result.errors[1]).toContain("references non-existent plugin");
    });
  });

  describe('runCli', () => {
    it('should recognize --verbose flag', async () => {
      const mockConsole = { log: vi.fn(), warn: vi.fn(), error: vi.fn() };
      const mockExit = vi.fn();
      const mockValidate = vi.fn().mockResolvedValue({
        errors: [],
        pluginCount: 1,
        skippedRefs: [{ file: 'test.json', ref: 'data/ext.md' }]
      });

      await runCli({
        argv: ['node', 'script.js', '--verbose'],
        console: mockConsole,
        exit: mockExit,
        validateFn: mockValidate
      });

      expect(mockValidate).toHaveBeenCalledWith({ verbose: true });
      expect(mockConsole.log).toHaveBeenCalledWith(expect.stringContaining('Skipped 1 data/ references'));
    });

    it('should recognize -v flag', async () => {
      const mockConsole = { log: vi.fn(), warn: vi.fn(), error: vi.fn() };
      const mockExit = vi.fn();
      const mockValidate = vi.fn().mockResolvedValue({
        errors: [],
        pluginCount: 1,
        skippedRefs: []
      });

      await runCli({
        argv: ['node', 'script.js', '-v'],
        console: mockConsole,
        exit: mockExit,
        validateFn: mockValidate
      });

      expect(mockValidate).toHaveBeenCalledWith({ verbose: true });
    });

    it('should warn when no plugins found', async () => {
      const mockConsole = { log: vi.fn(), warn: vi.fn(), error: vi.fn() };
      const mockExit = vi.fn();
      const mockValidate = vi.fn().mockResolvedValue({
        errors: [],
        pluginCount: 0,
        skippedRefs: []
      });

      await runCli({
        argv: ['node', 'script.js'],
        console: mockConsole,
        exit: mockExit,
        validateFn: mockValidate
      });

      expect(mockConsole.warn).toHaveBeenCalledWith('Warning: No plugins found in marketplace.json');
    });

    it('should print errors to stderr and exit with code 1', async () => {
      const mockConsole = { log: vi.fn(), warn: vi.fn(), error: vi.fn() };
      const mockExit = vi.fn();
      const mockValidate = vi.fn().mockResolvedValue({
        errors: ['Error 1', 'Error 2'],
        pluginCount: 2,
        skippedRefs: []
      });

      const result = await runCli({
        argv: ['node', 'script.js'],
        console: mockConsole,
        exit: mockExit,
        validateFn: mockValidate
      });

      expect(mockConsole.error).toHaveBeenCalledWith('Validation errors:\n');
      expect(mockConsole.error).toHaveBeenCalledWith('  - Error 1');
      expect(mockConsole.error).toHaveBeenCalledWith('  - Error 2');
      expect(mockExit).toHaveBeenCalledWith(1);
      expect(result.exitCode).toBe(1);
    });

    it('should print success message with plugin count', async () => {
      const mockConsole = { log: vi.fn(), warn: vi.fn(), error: vi.fn() };
      const mockExit = vi.fn();
      const mockValidate = vi.fn().mockResolvedValue({
        errors: [],
        pluginCount: 5,
        skippedRefs: []
      });

      const result = await runCli({
        argv: ['node', 'script.js'],
        console: mockConsole,
        exit: mockExit,
        validateFn: mockValidate
      });

      expect(mockConsole.log).toHaveBeenCalledWith('All 5 plugins validated successfully');
      expect(result.exitCode).toBe(0);
    });

    it('should not log skipped refs when not in verbose mode', async () => {
      const mockConsole = { log: vi.fn(), warn: vi.fn(), error: vi.fn() };
      const mockExit = vi.fn();
      const mockValidate = vi.fn().mockResolvedValue({
        errors: [],
        pluginCount: 1,
        skippedRefs: [{ file: 'test.json', ref: 'data/ext.md' }]
      });

      await runCli({
        argv: ['node', 'script.js'],
        console: mockConsole,
        exit: mockExit,
        validateFn: mockValidate
      });

      // Should only have success message, not skipped refs
      expect(mockConsole.log).toHaveBeenCalledTimes(1);
      expect(mockConsole.log).toHaveBeenCalledWith('All 1 plugins validated successfully');
    });

    it('should handle unexpected errors', async () => {
      const mockConsole = { log: vi.fn(), warn: vi.fn(), error: vi.fn() };
      const mockExit = vi.fn();
      const mockValidate = vi.fn().mockRejectedValue(new Error('Unexpected failure'));

      const result = await runCli({
        argv: ['node', 'script.js'],
        console: mockConsole,
        exit: mockExit,
        env: {},
        validateFn: mockValidate
      });

      expect(mockConsole.error).toHaveBeenCalledWith('Validation failed with unexpected error: Unexpected failure');
      expect(mockExit).toHaveBeenCalledWith(1);
      expect(result.exitCode).toBe(1);
    });

    it('should print stack trace when DEBUG is set', async () => {
      const mockConsole = { log: vi.fn(), warn: vi.fn(), error: vi.fn() };
      const mockExit = vi.fn();
      const testError = new Error('Debug failure');
      const mockValidate = vi.fn().mockRejectedValue(testError);

      await runCli({
        argv: ['node', 'script.js'],
        console: mockConsole,
        exit: mockExit,
        env: { DEBUG: 'true' },
        validateFn: mockValidate
      });

      expect(mockConsole.error).toHaveBeenCalledWith(testError.stack);
    });

    it('should not print stack trace when DEBUG is not set', async () => {
      const mockConsole = { log: vi.fn(), warn: vi.fn(), error: vi.fn() };
      const mockExit = vi.fn();
      const testError = new Error('No debug failure');
      const mockValidate = vi.fn().mockRejectedValue(testError);

      await runCli({
        argv: ['node', 'script.js'],
        console: mockConsole,
        exit: mockExit,
        env: {},
        validateFn: mockValidate
      });

      // error should be called twice: once for message, but NOT for stack
      const errorCalls = mockConsole.error.mock.calls;
      const hasStackCall = errorCalls.some(call => call[0] && call[0].includes('at '));
      expect(hasStackCall).toBe(false);
    });
  });
});
