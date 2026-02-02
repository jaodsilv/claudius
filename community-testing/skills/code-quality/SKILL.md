---

name: community-testing:code-quality
description: >-
  Provides code quality guidelines and best practices for maintaining
  high-quality, maintainable code
---

# Code Quality

## When to Use This Skill

This skill is automatically invoked when:

1. Reviewing code (self-review or peer review)
2. Evaluating code quality
3. Planning refactoring
4. Assessing technical debt
5. Preparing for code reviews

## Overview

Code quality guidelines ensure maintainable, readable, and robust software. This skill provides comprehensive checklists and best
practices for evaluating and improving code quality across multiple dimensions.

## Quality Dimensions

1. **Readability** - Easy to understand
2. **Maintainability** - Easy to modify
3. **Correctness** - Does what it should
4. **Efficiency** - Performs well
5. **Testability** - Easy to test
6. **Security** - Safe from vulnerabilities
7. **Consistency** - Follows conventions

## Quick Quality Checklist

Use this for rapid code review:

- [ ] Code is self-explanatory
- [ ] Functions/methods have single responsibility
- [ ] No code duplication
- [ ] Edge cases handled
- [ ] Tests are comprehensive
- [ ] No security vulnerabilities
- [ ] Performance is acceptable
- [ ] Follows project conventions
- [ ] Documentation is adequate
- [ ] Error handling is robust

## Detailed Quality Guidelines

### 1. Readability

**Purpose:** Code should be understandable by other developers (and your future self)

#### Naming

**DO:**
- Use descriptive, meaningful names
- Follow language conventions (camelCase, snake_case, etc.)
- Use pronounceable names
- Use searchable names
- Avoid abbreviations unless standard

```javascript
// Good
const userAuthenticationToken = generateToken(userId);
function calculateMonthlyPayment(principal, interestRate, months) { }

// Bad
const uat = genTkn(uid);
function calc(p, r, m) { }
```

**DON'T:**
- Use single-letter variables (except loop counters)
- Use misleading names
- Use magic numbers without constants

#### Function Size

**Target:** Functions should fit on one screen (20-40 lines)

**Indicators of too large:**
- Multiple levels of nested loops/conditionals
- Mixing abstraction levels
- Doing too many things

**Solution:** Extract helper functions

```javascript
// Good - Single responsibility
function validateUser(user) {
  validateEmail(user.email);
  validatePassword(user.password);
  validateAge(user.age);
}

// Bad - Too many responsibilities
function processUser(user) {
  // 100 lines of validation, database queries, email sending, logging...
}
```

#### Code Comments

**When to comment:**
- Complex algorithms
- Non-obvious business logic
- Workarounds for external issues
- TODO/FIXME items

**When NOT to comment:**
- Obvious code (let code speak for itself)
- Outdated information
- Commented-out code (use git instead)

```javascript
// Good - Explains WHY
// Use binary search because dataset can be >100k items
const index = binarySearch(items, target);

// Bad - Explains WHAT (code already shows this)
// Loop through users
for (const user of users) { }
```

### 2. Maintainability

**Purpose:** Code should be easy to modify and extend

#### Single Responsibility Principle

Each function/class should have one reason to change.

```javascript
// Good
class UserValidator {
  validate(user) { }
}

class UserRepository {
  save(user) { }
  find(id) { }
}

// Bad
class User {
  validate() { }
  save() { }
  sendEmail() { }
  generateReport() { }
}
```

#### DRY (Don't Repeat Yourself)

**Avoid code duplication:**

```javascript
// Good - Reusable function
function formatCurrency(amount, currency = 'USD') {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency
  }).format(amount);
}

const price = formatCurrency(100);
const tax = formatCurrency(15);

// Bad - Repeated logic
const price = `$${(100).toFixed(2)}`;
const tax = `$${(15).toFixed(2)}`;
```

#### Coupling and Cohesion

**Low coupling:** Minimize dependencies between modules
**High cohesion:** Related functionality together

```javascript
// Good - Low coupling
function calculateTotal(items) {
  return items.reduce((sum, item) => sum + item.price, 0);
}

// Bad - High coupling
function calculateTotal(database, userId, sessionId) {
  const user = database.getUser(userId);
  const session = validateSession(sessionId);
  // ... too many dependencies
}
```

### 3. Correctness

**Purpose:** Code does what it's supposed to do

#### Edge Cases

**Always consider:**
- Empty inputs (null, undefined, empty array/string)
- Boundary values (0, negative numbers, very large numbers)
- Invalid inputs
- Concurrent access
- Network failures
- Resource exhaustion

```javascript
// Good - Handles edge cases
function divide(a, b) {
  if (b === 0) {
    throw new Error('Division by zero');
  }
  if (!Number.isFinite(a) || !Number.isFinite(b)) {
    throw new Error('Invalid input');
  }
  return a / b;
}

// Bad - Assumes happy path
function divide(a, b) {
  return a / b;
}
```

#### Defensive Programming

**Validate inputs:**

```javascript
// Good
function processOrder(order) {
  if (!order || typeof order !== 'object') {
    throw new Error('Invalid order');
  }
  if (!order.items || !Array.isArray(order.items)) {
    throw new Error('Order must have items array');
  }
  if (order.items.length === 0) {
    throw new Error('Order cannot be empty');
  }
  // ... process
}

// Bad - Assumes valid input
function processOrder(order) {
  for (const item of order.items) { // May crash
    // ...
  }
}
```

#### Assertions and Invariants

**Document assumptions:**

```javascript
// Good
function calculateDiscount(price, discountPercent) {
  console.assert(price >= 0, 'Price must be non-negative');
  console.assert(discountPercent >= 0 && discountPercent <= 100,
    'Discount must be between 0 and 100');

  return price * (discountPercent / 100);
}
```

### 4. Efficiency

**Purpose:** Code performs adequately

#### Algorithm Complexity

**Know Big O notation:**
- O(1) - Constant
- O(log n) - Logarithmic
- O(n) - Linear
- O(n log n) - Linearithmic
- O(n²) - Quadratic
- O(2ⁿ) - Exponential

**Choose appropriate algorithms:**

```javascript
// Good - O(1) lookup
const users = new Map();
users.set(userId, userData);
const user = users.get(userId);

// Bad - O(n) lookup
const users = [];
users.push({ id: userId, ...userData });
const user = users.find(u => u.id === userId);
```

#### Premature Optimization

**"Premature optimization is the root of all evil"** - Donald Knuth

**DO:**
- Write clear code first
- Measure before optimizing
- Optimize bottlenecks only
- Document why optimization was needed

**DON'T:**
- Sacrifice readability for micro-optimizations
- Optimize without profiling
- Guess at performance issues

### 5. Testability

**Purpose:** Code should be easy to test

#### Pure Functions

**Prefer pure functions (no side effects):**

```javascript
// Good - Pure, testable
function calculateTax(amount, rate) {
  return amount * rate;
}

// Bad - Impure, harder to test
let totalTax = 0;
function calculateTax(amount, rate) {
  totalTax += amount * rate;
  logToDatabase(totalTax);
  sendEmail(totalTax);
}
```

#### Dependency Injection

**Make dependencies explicit:**

```javascript
// Good - Dependencies injected
class OrderService {
  constructor(database, emailService) {
    this.database = database;
    this.emailService = emailService;
  }

  async processOrder(order) {
    await this.database.save(order);
    await this.emailService.sendConfirmation(order);
  }
}

// Bad - Hard-coded dependencies
class OrderService {
  async processOrder(order) {
    await Database.getInstance().save(order);
    await EmailService.send(order);
  }
}
```

#### Small, Focused Units

**One test should test one thing:**

```javascript
// Good - Focused test
test('calculateTax returns correct amount', () => {
  expect(calculateTax(100, 0.1)).toBe(10);
});

test('calculateTax handles zero amount', () => {
  expect(calculateTax(0, 0.1)).toBe(0);
});

// Bad - Tests too much
test('order processing', () => {
  // Tests validation, calculation, database, email, logging...
});
```

### 6. Security

**Purpose:** Code is safe from vulnerabilities

#### Input Validation

**Never trust user input:**

```javascript
// Good - Validated and sanitized
function searchUsers(query) {
  const sanitized = sanitizeInput(query);
  const validated = validateSearchQuery(sanitized);
  return database.query('SELECT * FROM users WHERE name LIKE ?', [validated]);
}

// Bad - SQL injection vulnerability
function searchUsers(query) {
  return database.query(`SELECT * FROM users WHERE name LIKE '${query}'`);
}
```

#### Authentication & Authorization

**Check permissions:**

```javascript
// Good
async function deleteUser(userId, currentUser) {
  if (!currentUser.isAdmin()) {
    throw new Error('Unauthorized');
  }
  await database.deleteUser(userId);
}

// Bad
async function deleteUser(userId) {
  await database.deleteUser(userId); // Anyone can delete
}
```

#### Secrets Management

**NEVER:**
- Hard-code secrets
- Commit secrets to git
- Log secrets
- Send secrets in URLs

**DO:**
- Use environment variables
- Use secret management services
- Rotate secrets regularly

### 7. Consistency

**Purpose:** Code follows project conventions

#### Style Guides

**Follow project conventions:**
- Indentation (spaces vs tabs)
- Line length
- Brace style
- Import ordering
- File naming

**Use automated tools:**
- Prettier, ESLint (JavaScript)
- Black, Pylint (Python)
- RuboCop (Ruby)
- Checkstyle (Java)

#### Patterns

**Be consistent in:**
- Error handling approach
- Async patterns (callbacks, promises, async/await)
- State management
- API design
- Naming conventions

```javascript
// Good - Consistent async/await
async function getUser(id) {
  return await database.findUser(id);
}

async function getOrders(userId) {
  return await database.findOrders(userId);
}

// Bad - Mixing patterns
async function getUser(id) {
  return await database.findUser(id);
}

function getOrders(userId) {
  return new Promise((resolve, reject) => {
    database.findOrders(userId, (err, orders) => {
      if (err) reject(err);
      else resolve(orders);
    });
  });
}
```

## Code Review Checklist

### Functionality

- [ ] Code does what it's supposed to do
- [ ] Edge cases are handled
- [ ] Error cases are handled
- [ ] No obvious bugs

### Design

- [ ] Code follows SOLID principles
- [ ] Design patterns are appropriate
- [ ] Abstraction level is appropriate
- [ ] No over-engineering

### Readability

- [ ] Code is self-explanatory
- [ ] Naming is clear and consistent
- [ ] Comments explain "why" not "what"
- [ ] Code structure is logical

### Tests

- [ ] Tests are comprehensive
- [ ] Tests are maintainable
- [ ] Tests test the right things
- [ ] Edge cases are tested

### Performance

- [ ] No obvious performance issues
- [ ] Algorithm complexity is appropriate
- [ ] Resource usage is reasonable
- [ ] No memory leaks

### Security

- [ ] Input is validated
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities
- [ ] Authentication/authorization is correct
- [ ] No secrets in code

### Maintainability

- [ ] Code follows DRY
- [ ] Functions are small and focused
- [ ] Dependencies are minimal
- [ ] Code is easy to modify

### Consistency

- [ ] Follows project style guide
- [ ] Naming is consistent
- [ ] Patterns match existing code
- [ ] File structure matches conventions

## Refactoring Signals

**Consider refactoring when you see:**

1. **Long functions** (>50 lines)
2. **Deep nesting** (>3 levels)
3. **Code duplication** (copy-paste)
4. **Large classes** (>300 lines)
5. **Long parameter lists** (>4 parameters)
6. **Comments explaining code** (code should be clear)
7. **Complex conditionals** (extract to functions)
8. **God objects** (classes doing too much)
9. **Primitive obsession** (use domain objects)
10. **Feature envy** (method using another class's data)

## Code Smells

### Bloaters

- **Long Method:** Extract smaller methods
- **Large Class:** Split into multiple classes
- **Long Parameter List:** Create parameter object
- **Data Clumps:** Group related data into objects

### Object-Orientation Abusers

- **Switch Statements:** Use polymorphism
- **Temporary Field:** Extract to separate class
- **Refused Bequest:** Break inheritance hierarchy

### Change Preventers

- **Divergent Change:** Split class
- **Shotgun Surgery:** Move related code together
- **Parallel Inheritance:** Combine hierarchies

### Dispensables

- **Comments:** Make code self-explanatory
- **Duplicate Code:** Extract and reuse
- **Dead Code:** Delete it
- **Speculative Generality:** Remove unused abstraction

### Couplers

- **Feature Envy:** Move method to proper class
- **Inappropriate Intimacy:** Reduce coupling
- **Message Chains:** Hide delegation
- **Middle Man:** Remove unnecessary indirection

## Best Practices Summary

### DO

1. Write self-documenting code
2. Keep functions small and focused
3. Handle edge cases and errors
4. Write tests
5. Follow project conventions
6. Review your own code first
7. Refactor regularly
8. Validate all inputs
9. Use meaningful names
10. Keep it simple (KISS)

### DON'T

1. Write clever code (be clear instead)
2. Ignore edge cases
3. Leave commented-out code
4. Hard-code values
5. Mix abstraction levels
6. Create god classes
7. Duplicate code
8. Skip tests
9. Commit secrets
10. Premature optimize

## Quality Metrics

**Track these metrics:**

1. **Code Coverage:** Aim for >80%
2. **Cyclomatic Complexity:** Keep <10 per function
3. **Code Duplication:** Keep <3%
4. **Technical Debt:** Track and address
5. **Bug Rate:** Monitor and reduce
6. **Review Turnaround:** Keep <24 hours

## Integration with Development Workflow

**When to check quality:**

1. **During development:** Continuous self-review
2. **Before committing:** Final check
3. **In PR reviews:** Comprehensive review
4. **In refactoring phase:** Deep quality assessment
5. **In retrospectives:** Process improvement

## Reference

This skill provides guidelines for writing and reviewing high-quality code. Use it to:

- Perform systematic code reviews
- Identify refactoring opportunities
- Improve code maintainability
- Reduce technical debt
- Build better software

Quality is not a one-time activity but a continuous practice integrated into every phase of development.
