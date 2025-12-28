---
name: dotclaude:python-review
description: >-
  Provides Python-specific code review guidelines covering PEP compliance,
  type hints, testing, and Pythonic best practices.
---

# Python Code Review Skill

## Overview

Expert Python code review focusing on PEP 8 compliance, Pythonic idioms, type hints, modern Python 3.x features, and best practices.

## PEP 8 Style Compliance

### Formatting Standards

1. **Indentation**
   - Use 4 spaces (never tabs)
   - Consistent throughout

2. **Line length**
   - Maximum 88 characters (Black formatter standard) or 79 (PEP 8)
   - Break long lines at logical points

3. **Naming conventions**
   - `snake_case` for functions, variables, modules
   - `PascalCase` for classes
   - `UPPER_CASE` for constants
   - `_leading_underscore` for internal/private

4. **Imports**
   - Standard library → Third-party → Local
   - One import per line (except `from x import a, b`)
   - Absolute imports preferred over relative

5. **Whitespace**
   - 2 blank lines before top-level functions/classes
   - 1 blank line between methods
   - No trailing whitespace

## Type Hints (PEP 484)

### Modern Type Annotations

1. **Function signatures**
   - ❌ `def process(data):`
   - ✅ `def process(data: dict[str, Any]) -> Result:`

2. **Type hints for all public APIs**

   ```python
   def calculate_total(
       items: list[Item],
       discount: float = 0.0
   ) -> Decimal:
       ...
   ```

3. **Generic types**

   ```python
   from typing import TypeVar, Generic

   T = TypeVar('T')

   class Container(Generic[T]):
       def __init__(self, value: T) -> None:
           self.value = value
   ```

4. **Optional and Union**
   - Python 3.10+: `str | None` instead of `Optional[str]`
   - `Union[str, int]` or `str | int`

5. **Type checking**
   - Run mypy in strict mode
   - Fix all type errors before merge

## Pythonic Idioms

### Idiomatic Python

1. **List comprehensions**
   - ❌ `result = []; for x in items: result.append(x * 2)`
   - ✅ `result = [x * 2 for x in items]`

2. **Dictionary comprehensions**
   - ✅ `{k: v for k, v in pairs if v is not None}`

3. **Generator expressions**
   - ✅ `sum(x * x for x in range(1000))` (memory efficient)

4. **Enumerate instead of range(len())**
   - ❌ `for i in range(len(items)): print(i, items[i])`
   - ✅ `for i, item in enumerate(items): print(i, item)`

5. **zip for parallel iteration**
   - ✅ `for name, score in zip(names, scores):`

6. **Dictionary get() with default**
   - ❌ `value = d[key] if key in d else default`
   - ✅ `value = d.get(key, default)`

7. **String formatting**
   - Modern: f-strings
   - ✅ `f"Hello {name}, you are {age} years old"`

8. **Truthiness**
   - ❌ `if len(items) == 0:`
   - ✅ `if not items:`

## Context Managers

### Resource Management

1. **Always use context managers for resources**

   ```python
   # ✅ Good
   with open('file.txt') as f:
       data = f.read()

   # ❌ Bad (file might not close on exception)
   f = open('file.txt')
   data = f.read()
   f.close()
   ```

2. **Custom context managers**

   ```python
   from contextlib import contextmanager

   @contextmanager
   def managed_resource():
       resource = acquire()
       try:
           yield resource
       finally:
           release(resource)
   ```

3. **Multiple resources**

   ```python
   with open('in.txt') as infile, open('out.txt', 'w') as outfile:
       outfile.write(infile.read())
   ```

## Error Handling

### Exception Best Practices

1. **Specific exceptions**
   - ❌ `except Exception:`
   - ✅ `except (ValueError, KeyError) as e:`

2. **Never bare except**
   - ❌ `except:` (catches SystemExit, KeyboardInterrupt)
   - ✅ `except Exception:` (minimum)

3. **Custom exceptions**

   ```python
   class ValidationError(Exception):
       """Raised when validation fails"""
       pass
   ```

4. **Exception chaining**
   - ✅ `raise NewError(...) from original_error`

5. **EAFP over LBYL**
   - "Easier to Ask Forgiveness than Permission"
   - ✅ `try: return d[key] except KeyError: return default`
   - ❌ `if key in d: return d[key] else: return default`

## Modern Python Features

### Python 3.8+

1. **Walrus operator (3.8)**

   ```python
   # ✅ Avoid repeated computation
   if (n := len(data)) > 10:
       print(f"List is too long ({n} elements)")
   ```

2. **Positional-only and keyword-only arguments**

   ```python
   def func(pos_only, /, standard, *, kwd_only):
       pass
   ```

3. **Match statement (3.10)**

   ```python
   match status:
       case 200:
           return "OK"
       case 404:
           return "Not Found"
       case _:
           return "Unknown"
   ```

4. **Dataclasses**

   ```python
   from dataclasses import dataclass

   @dataclass
   class User:
       name: str
       email: str
       active: bool = True
   ```

5. **Type aliases (3.10+)**

   ```python
   Vector: TypeAlias = list[float]
   ```

## Performance Considerations

### Optimization Patterns

1. **Use built-in functions** (implemented in C)
   - `sum()`, `max()`, `min()`, `any()`, `all()`

2. **Avoid premature optimization**
   - Profile first: `python -m cProfile script.py`
   - Optimize hot paths only

3. **List vs generator**
   - Use generators for large datasets
   - `(x for x in range(1000000))` vs `[x for x in range(1000000)]`

4. **String concatenation**
   - ❌ `s = ''; for x in items: s += x` (O(n²))
   - ✅ `s = ''.join(items)` (O(n))

5. **Set membership**
   - Use `set` for `in` checks on large collections
   - O(1) vs O(n) for lists

## Testing Best Practices

### Pytest Conventions

1. **Test file naming**
   - `test_*.py` or `*_test.py`

2. **Test function naming**
   - `test_<functionality>_<scenario>_<expected_result>`
   - Example: `test_login_invalid_credentials_returns_error`

3. **Fixtures for setup**

   ```python
   @pytest.fixture
   def user():
       return User(name="Test", email="test@example.com")
   ```

4. **Parametrized tests**

   ```python
   @pytest.mark.parametrize("input,expected", [
       (1, 2),
       (2, 4),
       (3, 6),
   ])
   def test_double(input, expected):
       assert double(input) == expected
   ```

## Common Anti-Patterns

### To Avoid

1. **Mutable default arguments**
   - ❌ `def func(items=[]):`
   - ✅ `def func(items=None): items = items or []`

2. **Modifying list while iterating**
   - ❌ `for item in items: items.remove(item)`
   - ✅ `items = [item for item in items if condition]`

3. **Using `is` for value comparison**
   - ❌ `if x is True:`
   - ✅ `if x:` or `if x == True:`

4. **Not using `__name__ == "__main__"`**

   ```python
   # ✅ Good
   if __name__ == "__main__":
       main()
   ```

5. **Ignoring list/dict/set comprehensions**
   - More readable and often faster

6. **Using `eval()` or `exec()`**
   - Security risk, almost always avoidable

## Code Quality Checks

### Complexity Metrics

1. **Function length**
   - Target: <20 lines
   - Maximum: 50 lines

2. **Cyclomatic complexity**
   - Target: <5
   - Maximum: 10

3. **Class methods**
   - Keep classes focused
   - <10 methods per class ideal

### Documentation

1. **Docstrings for all public APIs**

   ```python
   def calculate(x: int, y: int) -> int:
       """Calculate the sum of two integers.

       Args:
           x: First integer
           y: Second integer

       Returns:
           Sum of x and y

       Raises:
           ValueError: If inputs are negative
       """
       if x < 0 or y < 0:
           raise ValueError("Inputs must be non-negative")
       return x + y
   ```

2. **Module docstrings**

   ```python
   """Module for user authentication.

   This module provides functions for user login, logout,
   and session management.
   """
   ```

## Review Output Format

Report findings using this structure:

```markdown
### Python Review Results

#### Critical Issues
- [file:line] Issue description
  - Why it's a problem
  - Suggested fix

#### PEP 8 Violations
- [file:line] Issue description

#### Type Hint Issues
- [file:line] Missing or incorrect type hints

#### Anti-Patterns Found
- [file:line] Anti-pattern description

#### Performance Concerns
- [file:line] Performance issue

#### Positive Observations
- Good use of context managers
- Excellent type hint coverage
```

## Context Variables

When invoked, expect:
- `files`: Array of Python file paths to review
- `pr_number`: GitHub PR number for context
- `focus`: Specific focus area (e.g., "type_hints", "pythonic_idioms")
