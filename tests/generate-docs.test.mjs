import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  getTitle,
  getDescription,
  safeReadFile,
  generateCatalogEntry,
  generateAgentsCatalog,
  generateCommandsCatalog,
  generateSkillsCatalog,
  generatePluginsCatalog,
  generateIndexContent,
  generateDocs
} from '../scripts/generate-docs.mjs';

describe('generate-docs', () => {
  describe('getTitle', () => {
    it('should extract title from markdown with H1', () => {
      const content = '# My Title\n\nSome content';
      expect(getTitle(content)).toBe('My Title');
    });

    it('should return null if no H1 found', () => {
      const content = '## Not H1\n\nSome content';
      expect(getTitle(content)).toBeNull();
    });

    it('should extract first H1 if multiple exist', () => {
      const content = '# First Title\n\n# Second Title';
      expect(getTitle(content)).toBe('First Title');
    });

    it('should handle H1 with special characters', () => {
      const content = '# My `code` Title!';
      expect(getTitle(content)).toBe('My `code` Title!');
    });

    it('should handle empty content', () => {
      expect(getTitle('')).toBeNull();
    });

    it('should handle content with only whitespace before H1', () => {
      const content = '\n\n# Title\n';
      expect(getTitle(content)).toBe('Title');
    });
  });

  describe('getDescription', () => {
    it('should extract paragraph after H1', () => {
      const content = '# Title\n\nThis is the description.';
      expect(getDescription(content)).toBe('This is the description.');
    });

    it('should stop at next heading', () => {
      const content = '# Title\n\nFirst paragraph\n\n## Next Section';
      expect(getDescription(content)).toBe('First paragraph');
    });

    it('should handle empty description', () => {
      const content = '# Title\n\n## Next';
      expect(getDescription(content)).toBe('');
    });

    it('should truncate long descriptions', () => {
      const longText = 'A'.repeat(300);
      const content = `# Title\n\n${longText}`;
      expect(getDescription(content).length).toBe(200);
    });

    it('should handle custom max length', () => {
      const content = '# Title\n\nThis is a longer description';
      expect(getDescription(content, 10)).toBe('This is a ');
    });

    it('should join multi-line paragraphs', () => {
      const content = '# Title\n\nLine one\nLine two';
      expect(getDescription(content)).toBe('Line one Line two');
    });

    it('should skip empty lines before description', () => {
      const content = '# Title\n\n\n\nActual description';
      expect(getDescription(content)).toBe('Actual description');
    });

    it('should return empty string for no content after title', () => {
      const content = '# Title';
      expect(getDescription(content)).toBe('');
    });
  });

  describe('safeReadFile', () => {
    it('should read file successfully', () => {
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue('file content')
      };

      const result = safeReadFile('test.md', mockFs);
      expect(result).toBe('file content');
    });

    it('should return null on error', () => {
      const mockFs = {
        readFileSync: vi.fn().mockImplementation(() => {
          throw new Error('ENOENT');
        })
      };

      const result = safeReadFile('missing.md', mockFs);
      expect(result).toBeNull();
    });

    it('should log warning on error', () => {
      const consoleSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});
      const mockFs = {
        readFileSync: vi.fn().mockImplementation(() => {
          throw new Error('ENOENT');
        })
      };

      safeReadFile('missing.md', mockFs);
      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
    });
  });

  describe('generateCatalogEntry', () => {
    it('should generate entry with title from content', () => {
      const content = '# Agent Name\n\nDescription here';
      const entry = generateCatalogEntry('path/to/agent.md', content);

      expect(entry).toContain('## Agent Name');
      expect(entry).toContain('**File:** `path/to/agent.md`');
      expect(entry).toContain('Description here');
    });

    it('should use filename as fallback title', () => {
      const content = 'No title here';
      const entry = generateCatalogEntry('path/to/my-agent.md', content);

      expect(entry).toContain('## my-agent');
    });

    it('should use custom path label', () => {
      const content = '# Title';
      const entry = generateCatalogEntry('path/file.md', content, { pathLabel: 'Directory' });

      expect(entry).toContain('**Directory:**');
    });

    it('should handle empty description', () => {
      const content = '# Title\n\n## Next';
      const entry = generateCatalogEntry('file.md', content);

      expect(entry).toContain('## Title');
      expect(entry).not.toContain('undefined');
    });
  });

  describe('generateAgentsCatalog', () => {
    it('should generate catalog from agent files', async () => {
      const mockGlob = vi.fn().mockResolvedValue(['agents/test.md']);
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue('# Test Agent\n\nA test agent')
      };

      const result = await generateAgentsCatalog({ globFn: mockGlob, fs: mockFs });

      expect(result.count).toBe(1);
      expect(result.content).toContain('# Agent Catalog');
      expect(result.content).toContain('*1 agents available*');
      expect(result.content).toContain('## Test Agent');
    });

    it('should handle empty agent list', async () => {
      const mockGlob = vi.fn().mockResolvedValue([]);
      const mockFs = { readFileSync: vi.fn() };

      const result = await generateAgentsCatalog({ globFn: mockGlob, fs: mockFs });

      expect(result.count).toBe(0);
      expect(result.content).toContain('*0 agents available*');
    });

    it('should skip unreadable files', async () => {
      const mockGlob = vi.fn().mockResolvedValue(['agents/good.md', 'agents/bad.md']);
      const mockFs = {
        readFileSync: vi.fn().mockImplementation((path) => {
          if (path.includes('bad')) throw new Error('Cannot read');
          return '# Good Agent';
        })
      };

      const result = await generateAgentsCatalog({ globFn: mockGlob, fs: mockFs });

      expect(result.content).toContain('## Good Agent');
      expect(result.count).toBe(2); // Count is based on glob, not successful reads
    });

    it('should sort agents alphabetically', async () => {
      const mockGlob = vi.fn().mockResolvedValue(['agents/z.md', 'agents/a.md']);
      const mockFs = {
        readFileSync: vi.fn().mockImplementation((path) => {
          if (path.includes('z.md')) return '# Zebra Agent';
          return '# Alpha Agent';
        })
      };

      const result = await generateAgentsCatalog({ globFn: mockGlob, fs: mockFs });

      const alphaIndex = result.content.indexOf('Alpha Agent');
      const zebraIndex = result.content.indexOf('Zebra Agent');
      expect(alphaIndex).toBeLessThan(zebraIndex);
    });
  });

  describe('generateCommandsCatalog', () => {
    it('should generate catalog with command prefix', async () => {
      const mockGlob = vi.fn().mockResolvedValue(['commands/my-command.md']);
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue('# Command Title\n\nDoes something')
      };

      const result = await generateCommandsCatalog({ globFn: mockGlob, fs: mockFs });

      expect(result.content).toContain('## /my-command');
      expect(result.content).toContain('# Command Reference');
    });

    it('should handle nested command paths', async () => {
      const mockGlob = vi.fn().mockResolvedValue(['commands/git/commit.md']);
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue('# Git Commit')
      };

      const result = await generateCommandsCatalog({ globFn: mockGlob, fs: mockFs });

      expect(result.content).toContain('## /commit');
    });
  });

  describe('generateSkillsCatalog', () => {
    it('should generate skills from SKILL.md files', async () => {
      const mockGlob = vi.fn().mockResolvedValue(['skills/typescript/SKILL.md']);
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue('# TypeScript Skill\n\nTS expertise')
      };

      const result = await generateSkillsCatalog({ globFn: mockGlob, fs: mockFs });

      expect(result.content).toContain('# Skill Matrix');
      expect(result.content).toContain('## TypeScript Skill');
      expect(result.content).toContain('**Directory:**');
    });

    it('should use directory name as fallback', async () => {
      const mockGlob = vi.fn().mockResolvedValue(['skills/python/SKILL.md']);
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue('No title markdown')
      };

      const result = await generateSkillsCatalog({ globFn: mockGlob, fs: mockFs });

      expect(result.content).toContain('## python');
    });
  });

  describe('generatePluginsCatalog', () => {
    it('should generate plugin catalog from marketplace', async () => {
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue(JSON.stringify({
          name: 'Test Marketplace',
          version: '1.0.0',
          description: 'A test marketplace',
          plugins: [{
            name: 'test-plugin',
            version: '2.0.0',
            category: 'utility',
            description: 'Test plugin',
            keywords: ['test', 'demo']
          }]
        }))
      };

      const result = await generatePluginsCatalog({ fs: mockFs });

      expect(result.count).toBe(1);
      expect(result.content).toContain('# Plugin Marketplace');
      expect(result.content).toContain('**Marketplace:** Test Marketplace v1.0.0');
      expect(result.content).toContain('## test-plugin');
      expect(result.content).toContain('**Version:** 2.0.0');
      expect(result.content).toContain('**Tags:** test, demo');
    });

    it('should handle missing marketplace file', async () => {
      const mockFs = {
        readFileSync: vi.fn().mockImplementation(() => {
          throw new Error('ENOENT');
        })
      };

      const result = await generatePluginsCatalog({ fs: mockFs });

      expect(result.count).toBe(0);
      expect(result.content).toBe('');
    });

    it('should handle invalid marketplace JSON', async () => {
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue('not json')
      };

      const result = await generatePluginsCatalog({ fs: mockFs });

      expect(result.count).toBe(0);
    });

    it('should handle plugins without keywords', async () => {
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue(JSON.stringify({
          name: 'Test',
          version: '1.0.0',
          description: 'Test',
          plugins: [{ name: 'no-keywords', version: '1.0.0', category: 'test', description: 'No keywords' }]
        }))
      };

      const result = await generatePluginsCatalog({ fs: mockFs });

      expect(result.content).not.toContain('**Tags:**');
    });

    it('should handle non-array plugins field', async () => {
      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue(JSON.stringify({
          name: 'Test',
          version: '1.0.0',
          description: 'Test',
          plugins: 'not-an-array'
        }))
      };

      const result = await generatePluginsCatalog({ fs: mockFs });

      expect(result.count).toBe(0);
      expect(result.content).toBe('');
      expect(consoleSpy).toHaveBeenCalledWith(expect.stringContaining('must contain a "plugins" array'));
      consoleSpy.mockRestore();
    });
  });

  describe('generateIndexContent', () => {
    it('should generate index with counts', () => {
      const counts = { agents: 5, commands: 10, skills: 3, plugins: 8 };
      const content = generateIndexContent(counts);

      expect(content).toContain('# Claudius Documentation');
      expect(content).toContain('5 custom agents');
      expect(content).toContain('10 slash commands');
      expect(content).toContain('3 skills');
      expect(content).toContain('8 marketplace plugins');
    });

    it('should handle zero counts', () => {
      const counts = { agents: 0, commands: 0, skills: 0, plugins: 0 };
      const content = generateIndexContent(counts);

      expect(content).toContain('0 custom agents');
    });

    it('should include links to all catalogs', () => {
      const counts = { agents: 1, commands: 1, skills: 1, plugins: 1 };
      const content = generateIndexContent(counts);

      expect(content).toContain('[Agents](agents.md)');
      expect(content).toContain('[Commands](commands.md)');
      expect(content).toContain('[Skills](skills.md)');
      expect(content).toContain('[Plugins](plugins.md)');
    });
  });

  describe('generateDocs (integration)', () => {
    it('should generate all documentation files', async () => {
      const writtenFiles = {};
      const mockFs = {
        readFileSync: vi.fn().mockImplementation((path) => {
          if (path.includes('marketplace')) {
            return JSON.stringify({
              name: 'Test', version: '1.0.0', description: 'Test',
              plugins: []
            });
          }
          return '# Test\n\nContent';
        }),
        writeFileSync: vi.fn().mockImplementation((path, content) => {
          writtenFiles[path] = content;
        }),
        mkdirSync: vi.fn()
      };
      const mockGlob = vi.fn().mockResolvedValue([]);

      const counts = await generateDocs({
        outDir: 'test-out',
        fs: mockFs,
        globFn: mockGlob
      });

      expect(mockFs.mkdirSync).toHaveBeenCalledWith('test-out', { recursive: true });
      expect(Object.keys(writtenFiles)).toHaveLength(5); // agents, commands, skills, plugins, index
      expect(counts.agents).toBe(0);
      expect(counts.commands).toBe(0);
      expect(counts.skills).toBe(0);
      expect(counts.plugins).toBe(0);
    });

    it('should write to correct file paths', async () => {
      const writtenPaths = [];
      const mockFs = {
        readFileSync: vi.fn().mockReturnValue(JSON.stringify({
          name: 'Test', version: '1.0.0', description: 'Test', plugins: []
        })),
        writeFileSync: vi.fn().mockImplementation((path) => {
          // Normalize paths for cross-platform testing
          writtenPaths.push(path.replace(/\\/g, '/'));
        }),
        mkdirSync: vi.fn()
      };
      const mockGlob = vi.fn().mockResolvedValue([]);

      await generateDocs({ outDir: 'docs/_site', fs: mockFs, globFn: mockGlob });

      expect(writtenPaths).toContain('docs/_site/agents.md');
      expect(writtenPaths).toContain('docs/_site/commands.md');
      expect(writtenPaths).toContain('docs/_site/skills.md');
      expect(writtenPaths).toContain('docs/_site/plugins.md');
      expect(writtenPaths).toContain('docs/_site/index.md');
    });
  });
});
