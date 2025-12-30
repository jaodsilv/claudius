---
name: dotclaude:rust-review
description: >-
  Provides Rust-specific code review guidelines covering ownership, borrowing,
  lifetimes, error handling, and idiomatic Rust patterns.
---

# Rust Code Review Skill

## Overview

Expert Rust code review focusing on ownership, borrowing, lifetimes, memory safety, type safety, idiomatic patterns, and modern Rust best practices.

## Style and Conventions

### Rustfmt and Clippy

1. **Formatting standards**
   - Run `cargo fmt` before commit
   - Use default rustfmt settings unless project-specific config exists
   - 100 character line limit (default)

2. **Clippy lints**
   - Run `cargo clippy` and fix all warnings
   - ❌ Ignoring clippy lints without justification
   - ✅ `#[allow(clippy::lint_name)]` with comment explaining why

3. **Naming conventions**
   - `snake_case` for functions, variables, modules
   - `PascalCase` for types, traits, enums
   - `SCREAMING_SNAKE_CASE` for constants, statics
   - `'lowercase` for lifetimes

4. **Module structure**
   - One module per file preferred
   - Use `mod.rs` or `lib.rs` for public API
   - `pub use` for re-exports

## Ownership and Borrowing

### Memory Safety

1. **Prefer borrowing over ownership transfer**
   - ❌ `fn process(data: String) -> String`
   - ✅ `fn process(data: &str) -> String`
   - Take ownership only when necessary

2. **Minimize cloning**
   - ❌ `let copy = expensive_data.clone(); process(copy)`
   - ✅ `process(&expensive_data)`
   - Clone only when sharing ownership is required

3. **Borrow checker patterns**
   - Use references (`&T`) for read-only access
   - Use mutable references (`&mut T`) for exclusive write access
   - Never have aliasing mutable references

4. **Ownership transfer**

   ```rust
   // ✅ Clear ownership transfer
   fn take_ownership(s: String) { /* s is dropped here */ }

   // ✅ Return ownership
   fn transform(s: String) -> String { s.to_uppercase() }
   ```

5. **Reference validity**
   - Ensure references don't outlive data
   - Avoid returning references to local variables
   - Use lifetimes to express relationships

## Lifetimes

### Lifetime Annotations

1. **Explicit lifetimes when needed**

   ```rust
   // ✅ Clear lifetime relationship
   fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
       if x.len() > y.len() { x } else { y }
   }
   ```

2. **Struct lifetimes**

   ```rust
   // ✅ Struct holding references
   struct Config<'a> {
       name: &'a str,
       value: &'a str,
   }
   ```

3. **Lifetime elision rules**
   - Let compiler infer when possible
   - Only annotate when multiple references involved
   - Document non-obvious lifetime relationships

4. **Static lifetime**
   - ❌ `fn get() -> &'static str` (unless truly static)
   - ✅ Use `'static` for string literals, static data only

## Error Handling

### Result and Option

1. **Use Result for recoverable errors**
   - ❌ `panic!("Failed to open file")`
   - ✅ `File::open(path)?` with proper error propagation

2. **The ? operator**

   ```rust
   // ✅ Clean error propagation
   fn read_config(path: &Path) -> Result<Config, Error> {
       let content = fs::read_to_string(path)?;
       parse_config(&content)
   }
   ```

3. **Custom error types**

   ```rust
   // ✅ Use thiserror or implement Error trait
   #[derive(Debug, thiserror::Error)]
   enum AppError {
       #[error("IO error: {0}")]
       Io(#[from] std::io::Error),
       #[error("Parse error: {0}")]
       Parse(String),
   }
   ```

4. **Option handling**
   - Use `Option::map`, `and_then`, `unwrap_or` chains
   - ❌ `if let Some(x) = opt { ... } else { default }`
   - ✅ `opt.map(|x| ...).unwrap_or(default)`

5. **Avoid unwrap() in production**
   - ❌ `config.get("key").unwrap()`
   - ✅ `config.get("key").expect("key must exist")`
   - ✅ `config.get("key")?` in Result-returning functions

## Pattern Matching

### Enums and Match

1. **Exhaustive matching**

   ```rust
   // ✅ Handle all variants
   match result {
       Ok(val) => process(val),
       Err(e) => handle_error(e),
   }
   ```

2. **Match guards**

   ```rust
   // ✅ Clear conditional matching
   match value {
       x if x > 0 => println!("positive"),
       x if x < 0 => println!("negative"),
       _ => println!("zero"),
   }
   ```

3. **Destructuring**

   ```rust
   // ✅ Extract fields directly
   let Point { x, y } = point;
   match msg {
       Message::Write { text, .. } => println!("{}", text),
       _ => {}
   }
   ```

4. **Avoid unnecessary nesting**
   - Use `if let` for single pattern
   - Use early returns to reduce indentation

## Trait Design

### Idiomatic Traits

1. **Implement standard traits**
   - `Debug`, `Clone`, `PartialEq` for most types
   - `Display` for user-facing output
   - `Default` when sensible default exists
   - Use `#[derive(...)]` when possible

2. **Trait bounds**

   ```rust
   // ✅ Clear trait requirements
   fn process<T: Display + Clone>(item: T) -> String {
       format!("Item: {}", item)
   }

   // ✅ Where clauses for complex bounds
   fn complex<T, U>(t: T, u: U) -> String
   where
       T: Display + Clone,
       U: Debug + Default,
   {
       // ...
   }
   ```

3. **Associated types vs generics**
   - Use associated types for single implementation per type
   - Use generics for multiple implementations

4. **Trait objects**
   - `Box<dyn Trait>` for heap allocation
   - `&dyn Trait` for borrowed trait objects
   - Consider `enum` dispatch over trait objects for performance

## Unsafe Code

### Safety Guarantees

1. **Minimize unsafe usage**
   - Avoid unless absolutely necessary
   - Encapsulate in safe abstractions
   - Document invariants thoroughly

2. **Justification required**

   ```rust
   // ✅ Document why unsafe is needed
   /// SAFETY: Pointer is guaranteed valid because...
   unsafe {
       *ptr = value;
   }
   ```

3. **Common unsafe scenarios**
   - FFI boundaries
   - Low-level optimizations (profile first!)
   - Implementing safe abstractions over raw pointers

4. **Unsafe review checklist**
   - Are invariants documented?
   - Can this be avoided with safe Rust?
   - Are all safety conditions upheld?

## Concurrency and Thread Safety

### Send and Sync

1. **Thread safety markers**
   - `Send`: Safe to transfer between threads
   - `Sync`: Safe to share references between threads
   - Compiler enforces these automatically

2. **Arc and Mutex patterns**

   ```rust
   // ✅ Shared mutable state
   let data = Arc::new(Mutex::new(HashMap::new()));
   let data_clone = Arc::clone(&data);
   thread::spawn(move || {
       let mut map = data_clone.lock().unwrap();
       map.insert(key, value);
   });
   ```

3. **Avoid deadlocks**
   - Lock in consistent order
   - Keep lock guards short-lived
   - Consider `RwLock` for read-heavy workloads

4. **Message passing**
   - Prefer channels over shared state when possible
   - ✅ `mpsc::channel()` for producer-consumer patterns

5. **Rayon for data parallelism**
   - ✅ `vec.par_iter().map(|x| process(x))`
   - Easy parallel iteration

## Testing

### Rust Test Framework

1. **Unit tests**

   ```rust
   #[cfg(test)]
   mod tests {
       use super::*;

       #[test]
       fn test_addition() {
           assert_eq!(add(2, 2), 4);
       }

       #[test]
       #[should_panic(expected = "divide by zero")]
       fn test_panic() {
           divide(1, 0);
       }
   }
   ```

2. **Integration tests**
   - Place in `tests/` directory
   - Test public API only
   - One file per integration test suite

3. **Property-based testing**

   ```rust
   // ✅ Use proptest or quickcheck
   use proptest::prelude::*;

   proptest! {
       #[test]
       fn reversible(s in "\\PC*") {
           assert_eq!(reverse(&reverse(&s)), s);
       }
   }
   ```

4. **Benchmark tests**
   - Use `cargo bench` with criterion
   - Profile before optimizing

## Common Anti-Patterns

### To Avoid

1. **Unnecessary String allocation**
   - ❌ `fn process(s: String)` when `&str` suffices
   - ✅ Use `&str` for read-only string data

2. **Excessive cloning**
   - Don't clone to avoid borrow checker
   - Restructure code instead

3. **Panicking in libraries**
   - ❌ `unwrap()`, `expect()` in library code
   - ✅ Return `Result` and let caller handle errors

4. **Ignoring compiler warnings**
   - Treat warnings as errors in CI
   - `#![deny(warnings)]` or fix all warnings

5. **Not using iterators**
   - ❌ Manual indexing with loops
   - ✅ Iterator combinators (map, filter, collect)

6. **Stringly-typed APIs**
   - ❌ Passing `String` for structured data
   - ✅ Use enums or custom types

## Review Output Format

Report findings using this structure:

```markdown
### Rust Review Results

#### Critical Issues
- [file:line] Issue description
  - Why it's a problem
  - Suggested fix

#### Memory Safety Issues
- [file:line] Ownership/borrowing violation

#### Error Handling Issues
- [file:line] Improper error handling

#### Concurrency Issues
- [file:line] Thread safety concern

#### Performance Concerns
- [file:line] Unnecessary allocation/cloning

#### Style Violations
- [file:line] Rustfmt/Clippy warning

#### Positive Observations
- Excellent use of zero-cost abstractions
- Clean error handling with custom types
```

## Context Variables

When invoked, expect:
- `files`: Array of Rust file paths to review
- `pr_number`: GitHub PR number for context
- `focus`: Specific focus area (e.g., "ownership", "error_handling", "unsafe_code")
