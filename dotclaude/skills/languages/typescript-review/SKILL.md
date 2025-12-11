# TypeScript/JavaScript Code Review Skill

## Overview

Expert TypeScript and JavaScript code review focusing on type safety, modern ES6+ patterns, async programming, and framework-specific best practices.

## Type Safety Review

### TypeScript-Specific Checks

1. **Avoid `any` type**
   - ❌ `function process(data: any)`
   - ✅ `function process(data: UserData)`
   - Exception: Gradual migration from JavaScript (document why)

2. **Strict null checks**
   - ❌ `user.name.toUpperCase()` (might be undefined)
   - ✅ `user.name?.toUpperCase()` or `user.name && user.name.toUpperCase()`

3. **Proper type assertions**
   - ❌ `const value = obj as any as SpecificType`
   - ✅ `const value = obj as SpecificType` (with runtime validation)

4. **Interface vs Type**
   - Use `interface` for object shapes (extendable)
   - Use `type` for unions, intersections, primitives
   - Consistent choice within the same domain

5. **Generic type parameters**
   - ❌ `function getFirst(arr: any[]): any`
   - ✅ `function getFirst<T>(arr: T[]): T | undefined`

## Modern JavaScript Patterns

### ES6+ Features

1. **Arrow functions vs regular functions**
   - Use arrow functions for callbacks (preserves `this`)
   - Use regular functions for methods (clearer intent)

2. **Destructuring**
   - ✅ `const { name, email } = user`
   - ✅ `const [first, ...rest] = items`

3. **Template literals**
   - ❌ `"Hello " + name + "!"`
   - ✅ `` `Hello ${name}!` ``

4. **Optional chaining and nullish coalescing**
   - ✅ `user?.profile?.avatar ?? defaultAvatar`

5. **Spread operator**
   - ✅ `const merged = { ...defaults, ...options }`
   - Avoid excessive nesting (performance)

## Async Programming

### Promise Handling

1. **Async/await over raw promises**
   - ❌ `fetch().then().then().catch()`
   - ✅ `try { await fetch(); } catch (err) { }`

2. **Error handling**
   - Always wrap async calls in try-catch
   - Handle errors at appropriate level
   - Don't swallow errors silently

3. **Parallel vs sequential**
   - ❌ `await a(); await b(); await c();` (if independent)
   - ✅ `await Promise.all([a(), b(), c()])`

4. **Avoid mixing patterns**
   - ❌ `async function() { return promise.then() }`
   - ✅ `async function() { return await promise }`

## Memory Management

### Common Memory Issues

1. **Closure memory leaks**
   - Watch for event listeners not cleaned up
   - Check for timers/intervals not cleared
   - Verify subscriptions are unsubscribed

2. **Large object references**
   - Clear references when done: `obj = null`
   - Use WeakMap/WeakSet for cached objects
   - Avoid circular references

3. **Array operations**
   - ❌ `array.push()` in loop (repeated reallocation)
   - ✅ Pre-allocate: `new Array(size)` or use `concat`

## Framework-Specific Patterns

### React

1. **Hooks dependencies**
   - Always include all dependencies in useEffect/useMemo/useCallback
   - Use ESLint rule `exhaustive-deps`

2. **Component structure**
   - Functional components preferred over class components
   - Custom hooks for reusable logic
   - Props destructuring at function signature

3. **State management**
   - Don't mutate state directly
   - Use functional updates when new state depends on old

### Vue

1. **Reactivity**
   - Use `ref()` for primitives, `reactive()` for objects
   - Avoid breaking reactivity with destructuring

2. **Composables**
   - Extract reusable logic into composables
   - Return reactive values, not plain values

### Angular

1. **Dependency injection**
   - Inject services, don't instantiate manually
   - Use providedIn: 'root' for singletons

2. **Change detection**
   - Use OnPush strategy when possible
   - Avoid logic in templates

## Common Anti-Patterns

### To Avoid

1. **Callback hell** (deeply nested callbacks)
2. **Floating promises** (async without await/then)
3. **Mutating function parameters** (side effects)
4. **Magic numbers** (use named constants)
5. **God functions** (>50 lines, multiple responsibilities)
6. **Implicit any** (missing type annotations)
7. **Non-null assertions overuse** (`value!` without checks)

## Code Quality Checks

### Readability

1. **Naming conventions**
   - camelCase for variables/functions
   - PascalCase for classes/types
   - UPPER_CASE for constants
   - Descriptive names (avoid `x`, `temp`, `data`)

2. **Function length**
   - Target: <30 lines
   - Maximum: 50 lines
   - Extract helper functions if longer

3. **Complexity**
   - Cyclomatic complexity <10
   - Avoid deeply nested conditionals (>3 levels)

### Testability

1. **Pure functions preferred**
   - Same input → same output
   - No side effects
   - Easier to test

2. **Dependency injection**
   - Pass dependencies as parameters
   - Avoid hardcoded imports of concrete implementations

3. **Small, focused functions**
   - One thing per function
   - Easy to mock

## Review Output Format

Report findings using this structure:

```markdown
### TypeScript/JavaScript Review Results

#### Critical Issues
- [file:line] Issue description
  - Why it's a problem
  - Suggested fix

#### Type Safety Issues
- [file:line] Issue description

#### Async/Await Issues
- [file:line] Issue description

#### Code Quality Issues
- [file:line] Issue description

#### Positive Observations
- Good use of X pattern
- Excellent type safety in Y module
```

## Context Variables

When invoked, expect:
- `files`: Array of TypeScript/JavaScript file paths to review
- `pr_number`: GitHub PR number for context
- `focus`: Specific focus area (e.g., "type_safety", "async_patterns")
