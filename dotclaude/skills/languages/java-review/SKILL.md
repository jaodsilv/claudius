---
name: dotclaude:java-review
description: >-
  Provides Java-specific code review guidelines covering design patterns,
  exception handling, streams, and enterprise best practices.
---

# Java Code Review Skill

## Overview

Expert Java code review focusing on naming conventions, modern Java features, SOLID principles, exception handling, design patterns,
and best practices.

## Naming Conventions and Style

### Java Code Style

1. **Naming conventions**
   - `camelCase` for variables, methods, parameters
   - `PascalCase` for classes, interfaces, enums
   - `UPPER_CASE` for constants
   - Package names: lowercase, reverse domain notation

2. **Braces and indentation**
   - Opening brace on same line (K&R style)
   - 4 spaces indentation
   - Consistent formatting throughout

3. **Import organization**
   - No wildcard imports (`import java.util.*`)
   - Group: Java SE → Third-party → Project
   - Remove unused imports

## Modern Java Features

### Java 8+ Features

1. **Streams API**
   - ❌ `List<String> result = new ArrayList<>(); for(User u : users) { result.add(u.getName()); }`
   - ✅ `List<String> result = users.stream().map(User::getName).collect(Collectors.toList());`

2. **Lambda expressions**
   - ❌ `Collections.sort(list, new Comparator<String>() { public int compare(String a, String b) { return a.compareTo(b); } });`
   - ✅ `list.sort((a, b) -> a.compareTo(b));` or `list.sort(String::compareTo);`

3. **Optional instead of null**
   - ❌ `public User findUser(String id) { return null; }`
   - ✅ `public Optional<User> findUser(String id) { return Optional.ofNullable(user); }`
   - Use `map()`, `flatMap()`, `orElse()`, `orElseThrow()` properly

4. **Method references**
   - ✅ `list.forEach(System.out::println);` instead of `list.forEach(x -> System.out.println(x));`

### Java 14+ Features

1. **Records (Java 14+)**

   ```java
   // ✅ Immutable data carriers
   public record User(String name, String email) {}
   ```

2. **Pattern matching for instanceof (Java 16+)**
   - ❌ `if (obj instanceof String) { String s = (String) obj; }`
   - ✅ `if (obj instanceof String s) { // use s directly }`

3. **Sealed classes (Java 17+)**

   ```java
   public sealed interface Shape permits Circle, Rectangle, Triangle {}
   ```

4. **Text blocks (Java 15+)**

   ```java
   String json = """
       {
           "name": "John",
           "age": 30
       }
       """;
   ```

## Exception Handling

### Best Practices

1. **Specific exceptions**
   - ❌ `catch (Exception e)`
   - ✅ `catch (IOException | SQLException e)`

2. **Never catch Throwable or Error**
   - System errors should propagate

3. **Custom exceptions**

   ```java
   public class ValidationException extends RuntimeException {
       public ValidationException(String message) {
           super(message);
       }
   }
   ```

4. **Try-with-resources**

   ```java
   // ✅ Automatic resource management
   try (BufferedReader br = new BufferedReader(new FileReader(file))) {
       return br.readLine();
   }
   ```

5. **Don't swallow exceptions**
   - ❌ `catch (Exception e) { /* empty */ }`
   - ✅ `catch (Exception e) { logger.error("Error processing", e); throw new ProcessingException(e); }`

## Collection Types and Usage

### Proper Collection Usage

1. **Interface over implementation**
   - ❌ `ArrayList<String> list = new ArrayList<>();`
   - ✅ `List<String> list = new ArrayList<>();`

2. **Immutable collections**

   ```java
   List<String> immutable = List.of("a", "b", "c");
   Map<String, Integer> immutableMap = Map.of("key", 1);
   ```

3. **Collection choice**
   - `ArrayList`: Random access, fast iteration
   - `LinkedList`: Fast insertion/deletion
   - `HashSet`: Fast lookup, no duplicates, no order
   - `LinkedHashSet`: Insertion order preserved
   - `TreeSet`: Sorted order
   - `HashMap`: Key-value pairs, fast lookup
   - `ConcurrentHashMap`: Thread-safe map

4. **Avoid premature capacity allocation**
   - ✅ `new ArrayList<>()` unless you know exact size

## SOLID Principles

### Java Context

1. **Single Responsibility Principle**
   - One class, one reason to change
   - ❌ `UserManagerAndEmailSender`
   - ✅ `UserManager` + `EmailService`

2. **Open/Closed Principle**
   - Open for extension, closed for modification
   - Use interfaces and abstract classes

3. **Liskov Substitution Principle**
   - Subclasses should be substitutable for base classes
   - Don't violate contracts in overrides

4. **Interface Segregation**
   - Many specific interfaces > one general interface
   - Clients shouldn't depend on unused methods

5. **Dependency Inversion**
   - Depend on abstractions, not concretions
   - ✅ `private final PaymentService paymentService;` (interface)
   - ❌ `private final StripePaymentService paymentService;` (concrete)

## Common Design Patterns

### Pattern Implementation

1. **Builder pattern**

   ```java
   User user = User.builder()
       .name("John")
       .email("john@example.com")
       .build();
   ```

2. **Factory pattern**

   ```java
   public interface ShapeFactory {
       Shape createShape(String type);
   }
   ```

3. **Strategy pattern**

   ```java
   public interface PaymentStrategy {
       void pay(BigDecimal amount);
   }
   ```

4. **Singleton (prefer enum)**

   ```java
   public enum Configuration {
       INSTANCE;
       public void init() { /* ... */ }
   }
   ```

## Memory Management and GC

### Memory Considerations

1. **Avoid memory leaks**
   - Clear collections when done
   - Remove listeners after use
   - Close resources in finally or try-with-resources

2. **String concatenation**
   - ❌ `String s = ""; for(int i=0; i<1000; i++) s += i;` (creates 1000 objects)
   - ✅ `StringBuilder sb = new StringBuilder(); for(int i=0; i<1000; i++) sb.append(i);`

3. **Object pooling**
   - Reuse expensive objects (connections, threads)
   - Use `ThreadLocal` carefully (memory leaks)

4. **WeakReference for caches**

   ```java
   Map<Key, WeakReference<Value>> cache = new WeakHashMap<>();
   ```

## Testing with JUnit 5 and Mockito

### Testing Best Practices

1. **JUnit 5 annotations**

   ```java
   @Test
   void shouldCalculateTotalWhenItemsProvided() {
       // given
       List<Item> items = List.of(new Item(10), new Item(20));
       // when
       BigDecimal total = calculator.calculate(items);
       // then
       assertEquals(new BigDecimal("30"), total);
   }
   ```

2. **Parametrized tests**

   ```java
   @ParameterizedTest
   @ValueSource(ints = {1, 2, 3})
   void shouldValidatePositiveNumbers(int number) {
       assertTrue(validator.isPositive(number));
   }
   ```

3. **Mockito usage**

   ```java
   @Mock
   private UserRepository userRepository;

   @InjectMocks
   private UserService userService;

   @Test
   void shouldFindUserById() {
       when(userRepository.findById(1L)).thenReturn(Optional.of(user));
       verify(userRepository, times(1)).findById(1L);
   }
   ```

## Common Anti-Patterns

### To Avoid

1. **God classes** (>500 lines, many responsibilities)
2. **Primitive obsession** (use value objects instead of primitives)
   - ❌ `String email` everywhere
   - ✅ `Email email` (value object with validation)
3. **Magic numbers** (use named constants)
4. **Excessive method parameters** (>3 parameters, use builder or object)
5. **Nested conditionals** (>3 levels, extract methods)
6. **Returning null** (use Optional)
7. **Using == for String comparison** (use `equals()`)
8. **Not overriding equals() and hashCode() together**
9. **Catching generic Exception in production code**
10. **Not using diamond operator** (`new ArrayList<String>()` → `new ArrayList<>()`)

## Review Output Format

Report findings using this structure:

```markdown
### Java Review Results

#### Critical Issues
- [file:line] Issue description
  - Why it's a problem
  - Suggested fix

#### Modern Java Features
- [file:line] Could use Java 17+ feature

#### Exception Handling Issues
- [file:line] Improper exception handling

#### SOLID Violations
- [file:line] Principle violation

#### Design Pattern Opportunities
- [file:line] Pattern suggestion

#### Memory Concerns
- [file:line] Potential memory issue

#### Testing Issues
- [file:line] Test improvement needed

#### Positive Observations
- Good use of Records for data carriers
- Excellent application of SOLID principles
```

## Context Variables

When invoked, expect:
- `files`: Array of Java file paths to review
- `pr_number`: GitHub PR number for context
- `focus`: Specific focus area (e.g., "modern_features", "solid_principles")
