---
name: dart-modern-features
description: |-
  Guidelines for using modern Dart features (v3.0 - v3.10) such as Records,
  Extension Types, Class Modifiers, Wildcards, Digit Separators, Null-Aware
  Elements, and Dot Shorthands.
key_features:
  - Records & Extension Types
  - Class Modifiers & Wildcards
  - Null-aware elements & Dot shorthands
---

# Dart Modern Features

## 1. When to use this skill

Use this skill when:

- Writing or reviewing Dart code targeting Dart 3.0 or later.
- Refactoring legacy Dart code to use modern, concise, and zero-cost features
  such as records, extension types, class modifiers, null-aware collection
  elements, dot shorthands, and digit separators.
- Looking for idiomatic ways to handle multiple return values or zero-cost
  domain wrappers.

For pattern matching, switch expressions, and list/map/split destructuring, use
**[dart-use-pattern-matching]**. For converting closed class hierarchies into
exhaustive `sealed` types, use **[dart-seal-type-hierarchies]**.

### When NOT to use (Abstention Guardrails)

Do NOT apply modern features or refactor code when:

- **SDK Constraint < 3.0.0**: The package's `pubspec.yaml` specifies an SDK
  constraint that supports Dart 2.x (e.g., `sdk: '>=2.19.0 <4.0.0'`).
  Refactoring to Dart 3 features will introduce syntax errors for Dart 2 users.
- **Public API Records with > 3 Fields**: Records work well for 2–3 return
  values or internal tuples, but complex public API payloads are clearer and
  more extensible as dedicated classes or extension types.

## Discovery

To find candidates for modernization:

### Null-Aware Elements

Search for collection `if` statements checking for null:

- **Regex**: `if\s*\(\w+\s*!=\s*null\)\s*\w+`

### Digit Separators

Search for long numbers without separators:

- **Regex**: `\b\d{6,}\b` (Matches numbers with 6 or more digits).

## 2. Features

### Records

Use records as anonymous, immutable, aggregate structures to bundle multiple
objects without defining a custom class. Prefer them for returning multiple
values from a function or grouping related data temporarily.

**Avoid:** Creating a dedicated class for simple multiple-value returns.

```dart
class UserResult {
  final String name;
  final int age;
  UserResult(this.name, this.age);
}

UserResult fetchUser() {
  return UserResult('Alice', 42);
}
```

**Prefer:** Using records to bundle types seamlessly on the fly.

```dart
(String, int) fetchUser() {
  return ('Alice', 42);
}

void main() {
  var user = fetchUser();
  print(user.$1); // Alice
}
```

### Class Modifiers

Use class modifiers (`final`, `base`, `interface`, `sealed`) to restrict how
classes can be subtyped outside their defining library:

- `interface class`: External libraries may `implement`, but cannot `extend`.
- `base class`: External libraries may `extend`, but cannot `implement`
  (preserving private implementation invariants).
- `final class`: External libraries can neither `extend` nor `implement`.
- `sealed class`: Closed family of subtypes within the same library enabling
  exhaustive switching (see **[dart-seal-type-hierarchies]**).

**Avoid:** Leaving internal implementation classes open to arbitrary external
subclassing or interface implementation when invariants must be enforced.

```dart
class TokenStore {
  void save(String token) {}
}
```

**Prefer:** Declaring explicit subtyping capabilities with class modifiers.

```dart
final class TokenStore {
  void save(String token) {}
}
```

### Extension Types

Use extension types for a zero-cost wrapper around an existing type. Use them to
restrict operations or add custom behavior without runtime overhead.

**Avoid:** Allocating new wrapper objects just for domain-specific logic or type
safety.

```dart
class Id {
  final int value;
  Id(this.value);
  bool get isValid => value > 0;
}
```

**Prefer:** Using extension types which compile down to the underlying type at
runtime.

```dart
extension type Id(int value) {
  bool get isValid => value > 0;
}
```

### Digit Separators

Use underscores (`_`) in number literals strictly to improve visual readability
of large numeric values.

**Avoid:** Long number literals that are difficult to read at a glance.

```dart
const int oneMillion = 1000000;
```

**Prefer:** Using underscores to separate thousands or other groupings.

```dart
const int oneMillion = 1_000_000;
```

### Wildcard Variables

Use wildcards (`_`) as non-binding variables or parameters to explicitly signal
that a value is intentionally unused.

**Avoid:** Inventing clunky, distinct variable names to avoid "unused variable"
warnings.

```dart
void handleEvent(String ignoredName, int status) {
  print('Status: $status');
}
```

**Prefer:** Explicitly dropping the binding with an underscore.

```dart
void handleEvent(String _, int status) {
  print('Status: $status');
}
```

### Null-Aware Elements

Use null-aware elements (`?`) inside collection literals to conditionally
include items only if they evaluate to a non-null value.

**Avoid:** Using collection `if` statements for simple null checks.

```dart
var names = [
  'Alice',
  if (optionalName != null) optionalName,
  'Charlie'
];
```

**Prefer:** Using the `?` prefix inline.

```dart
var names = ['Alice', ?optionalName, 'Charlie'];
```

### Dot Shorthands

Use dot shorthands to omit the explicit type name when it can be confidently
inferred from context, such as with enums or static fields.

**Avoid:** Fully qualifying type names when the type is obvious from the
context.

```dart
LogLevel currentLevel = LogLevel.info;
```

**Prefer:** Reducing visual noise with inferred shorthand.

```dart
LogLevel currentLevel = .info;
```

## Related Skills

- **[dart-use-pattern-matching]**: Authoritative guide for Dart 3 pattern
  matching, switch expressions, and list/map/`String.split()` destructuring.
- **[dart-seal-type-hierarchies]**: Converting closed class hierarchies into
  `sealed` types for exhaustive switching.
- **[dart-best-practices]**: General code style and foundational Dart idioms
  that predate or complement the modern syntax features.

[dart-use-pattern-matching]:
  https://github.com/dart-lang/skills/blob/main/skills/dart-use-pattern-matching/SKILL.md
[dart-seal-type-hierarchies]:
  https://github.com/kevmoo/dash_skills/blob/main/skills/dart-seal-type-hierarchies/SKILL.md
[dart-best-practices]:
  https://github.com/kevmoo/dash_skills/blob/main/skills/dart-best-practices/SKILL.md
