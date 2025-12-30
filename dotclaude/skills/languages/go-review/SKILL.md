---
name: dotclaude:go-review
description: >-
  Provides Go-specific code review guidelines covering idiomatic patterns,
  error handling, concurrency, and standard library best practices.
---

# Go Code Review Skill

## Overview

Expert Go code review focusing on idiomatic Go patterns, effective error handling, concurrency safety, interface design, and
adherence to Effective Go principles.

## Go Formatting and Style

### Standard Conventions

1. **gofmt and goimports**
   - All code must be gofmt'd (automatic formatting)
   - Use goimports to manage import statements
   - No manual formatting decisions needed

2. **Naming conventions**
   - `MixedCaps` or `mixedCaps` (no underscores)
   - Exported: `UserService`, `GetUser`
   - Unexported: `userService`, `getUser`
   - Acronyms: `HTTPServer`, `URLPath` (not `HttpServer`, `UrlPath`)

3. **Package names**
   - Short, concise, lowercase, single-word
   - ✅ `package user`, `package http`
   - ❌ `package user_service`, `package UserService`

4. **Comment style**
   - Full sentences with proper punctuation
   - Start with name being documented
   - ✅ `// GetUser retrieves a user by ID.`
   - ❌ `// retrieves user`

## Error Handling

### Go Error Patterns

1. **Always check errors**
   - ❌ `result, _ := doSomething()`
   - ✅ `result, err := doSomething(); if err != nil { return err }`

2. **Error wrapping (Go 1.13+)**

   ```go
   // ✅ Good
   if err := validate(data); err != nil {
       return fmt.Errorf("validation failed: %w", err)
   }

   // ❌ Bad (loses stack trace)
   return errors.New("validation failed")
   ```

3. **Custom errors**

   ```go
   // ✅ Sentinel errors for expected conditions
   var ErrNotFound = errors.New("user not found")

   // ✅ Error types for rich context
   type ValidationError struct {
       Field string
       Issue string
   }

   func (e *ValidationError) Error() string {
       return fmt.Sprintf("%s: %s", e.Field, e.Issue)
   }
   ```

4. **Error checking in defer**

   ```go
   // ✅ Good
   defer func() {
       if err := f.Close(); err != nil {
           log.Printf("failed to close file: %v", err)
       }
   }()
   ```

5. **Don't panic in libraries**
   - Reserve panic for truly unrecoverable errors
   - Return errors instead
   - Let callers decide how to handle

## Concurrency and Goroutine Safety

### Safe Concurrent Patterns

1. **Mutex protection**

   ```go
   type SafeCounter struct {
       mu    sync.Mutex
       count int
   }

   func (c *SafeCounter) Inc() {
       c.mu.Lock()
       defer c.mu.Unlock()
       c.count++
   }
   ```

2. **Channel ownership**
   - Owner creates, writes, and closes
   - Consumers only read
   - ❌ Never close channel from reader side
   - ✅ Use context for cancellation

3. **Goroutine lifecycle**
   - ❌ `go func() { doWork() }()` (no control)
   - ✅ Use errgroup or WaitGroup for tracking
   - ✅ Always provide way to stop goroutines

4. **Context usage**

   ```go
   // ✅ Good - respect context cancellation
   func process(ctx context.Context, data []Item) error {
       for _, item := range data {
           select {
           case <-ctx.Done():
               return ctx.Err()
           default:
               if err := handle(item); err != nil {
                   return err
               }
           }
       }
       return nil
   }
   ```

5. **Race detector**
   - Run tests with `-race` flag
   - Fix all detected races before merge

## Interface Design

### Effective Interfaces

1. **Accept interfaces, return structs**
   - ❌ `func New() UserRepository`
   - ✅ `func New() *PostgresUserRepo`

2. **Small interfaces**

   ```go
   // ✅ Good - single method interface
   type Reader interface {
       Read(p []byte) (n int, err error)
   }

   // ❌ Bad - too many methods
   type Manager interface {
       Create()
       Read()
       Update()
       Delete()
       List()
       Count()
   }
   ```

3. **Interface segregation**
   - Define interfaces where they're used (consumer side)
   - ❌ Don't define all interfaces in one file
   - ✅ Define near the code that uses them

4. **Implicit implementation**

   ```go
   // ✅ No explicit "implements" needed
   type MyWriter struct{}

   func (w *MyWriter) Write(p []byte) (n int, err error) {
       // Implementation
   }
   // MyWriter now satisfies io.Writer
   ```

5. **Empty interface sparingly**
   - ❌ `func Process(data interface{})`
   - ✅ `func Process[T any](data T)` (Go 1.18+)
   - Use generics when appropriate

## Package Organization

### Structure Best Practices

1. **Package by domain, not type**
   - ✅ `user/`, `order/`, `payment/`
   - ❌ `models/`, `controllers/`, `services/`

2. **Internal packages**
   - Use `internal/` for non-exported packages
   - Prevents external imports

3. **Main package**
   - Keep `main()` small
   - Move logic to packages
   - Easy to test

4. **Cyclic dependencies**
   - Go prohibits import cycles
   - Redesign if cycles appear
   - Consider extracting shared interfaces

## Testing with Go's testing Package

### Test Conventions

1. **Table-driven tests**

   ```go
   func TestAdd(t *testing.T) {
       tests := []struct {
           name string
           a, b int
           want int
       }{
           {"positive", 1, 2, 3},
           {"negative", -1, -2, -3},
           {"zero", 0, 0, 0},
       }

       for _, tt := range tests {
           t.Run(tt.name, func(t *testing.T) {
               if got := Add(tt.a, tt.b); got != tt.want {
                   t.Errorf("Add() = %v, want %v", got, tt.want)
               }
           })
       }
   }
   ```

2. **Test helpers**
   - ❌ `assert.Equal(t, expected, actual)`
   - ✅ `if got != want { t.Errorf(...) }`
   - Use standard library when possible

3. **Parallel tests**

   ```go
   func TestSomething(t *testing.T) {
       t.Parallel() // Run concurrently with other parallel tests
       // Test code
   }
   ```

4. **Test coverage**
   - `go test -cover ./...`
   - Target: >80% coverage

## Performance Considerations

### Optimization Patterns

1. **Pointer vs value receivers**
   - Use pointers for large structs
   - Use pointers when mutating
   - Be consistent within a type

2. **Escape analysis**
   - `go build -gcflags='-m'` to see allocations
   - Avoid unnecessary heap allocations
   - Reuse buffers with `sync.Pool`

3. **String concatenation**
   - ❌ `s := ""; for _, x := range items { s += x }`
   - ✅ `var b strings.Builder; for _, x := range items { b.WriteString(x) }`

4. **Slice capacity**

   ```go
   // ✅ Pre-allocate if size known
   items := make([]Item, 0, expectedSize)

   // ✅ Avoid repeated append reallocations
   ```

5. **Benchmark tests**

   ```go
   func BenchmarkOperation(b *testing.B) {
       for i := 0; i < b.N; i++ {
           operation()
       }
   }
   ```

## Common Anti-Patterns

### To Avoid

1. **Goroutine leaks** (no cleanup/cancellation)
2. **Not closing resources** (defer is your friend)
3. **Ignoring errors** (silent failures)
4. **Using `init()` excessively** (hard to test)
5. **Global mutable state** (race conditions)
6. **Empty interface overuse** (`interface{}` everywhere)
7. **Premature optimization** (profile first)

## Review Output Format

Report findings using this structure:

```markdown
### Go Review Results

#### Critical Issues
- [file:line] Issue description
  - Why it's a problem
  - Suggested fix

#### Error Handling Issues
- [file:line] Unchecked error or improper handling

#### Concurrency Issues
- [file:line] Race condition or goroutine leak

#### Interface Design Issues
- [file:line] Non-idiomatic interface usage

#### Performance Concerns
- [file:line] Inefficient pattern detected

#### Positive Observations
- Excellent error wrapping
- Good use of table-driven tests
```

## Context Variables

When invoked, expect:
- `files`: Array of Go file paths to review
- `pr_number`: GitHub PR number for context
- `focus`: Specific focus area (e.g., "concurrency", "error_handling")
