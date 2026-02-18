# Severity Levels

## Definitions

| Level | Description | Examples | Action |
|-------|-------------|----------|--------|
| **Critical** | Blocks functionality, causes data loss, or security vulnerability | Runtime crash, SQL injection, data corruption, authentication bypass | Must fix immediately |
| **High** | Significant functionality impact or reliability concern | Test failures, broken API contract, race condition, memory leak | Fix before merge/release |
| **Medium** | Moderate impact, degraded experience or maintainability | Performance regression, missing error handling, code smell, deprecated API usage | Should fix soon |
| **Low** | Minor issue, cosmetic, or improvement opportunity | Style inconsistency, missing documentation, minor refactoring opportunity | Fix when convenient |

## Effort Estimates

| Level | Description | Typical Scope |
|-------|-------------|---------------|
| **Trivial** | Simple one-line or config change | Typo fix, flag toggle, version bump |
| **Minor** | Small focused change in 1-2 files | Add validation, fix import, update test |
| **Moderate** | Multi-file change requiring understanding of component | Refactor function, add error handling path, update API contract |
| **Significant** | Large change spanning multiple components | Architecture change, new subsystem, major refactor |

## Assignment Guidelines

1. **Severity is about impact**, not about how hard it is to fix
2. **Effort is about scope**, not about developer skill level
3. A critical finding can be trivial effort (e.g., fixing an exposed secret)
4. A low finding can be significant effort (e.g., large-scale style cleanup)
5. When in doubt between two levels, choose the higher severity (err on side of caution)
