---
name: matcher-to-checks
description: |-
  Replace the usage of `expect` and similar functions from `package:matcher` 
  to `package:checks` equivalents.
license: Apache-2.0
---

## When to use this skill

In a Dart or Flutter project.
When a user asks to migrate to `package:checks` or just "checks".

## The Workflow

1.  **Analysis**:
    - Use `grep` to identify files using `expect` or `package:matcher`.
    - Review custom matchers; these may require manual migration.
2.  **Tools & Dependencies**:
    - Ensure `dev_dependencies` includes `checks`.
    - Run `dart pub add --dev checks` if missing.
3.  **Discovery**:
    - Use the **Strategies for Discovery** below to find candidates.
4.  **Replacement**:
    - Add `import 'package:checks/checks.dart';`.
    - Apply the **Common Patterns** below.
    - **Final Step**: Replace `import 'package:test/test.dart';` with `import 'package:test/scaffold.dart';` (if available) ONLY after all `expect` calls are replaced. This ensures incremental progress.
5.  **Verification**:
    - Ensure the code analyzes cleanly.
    - Ensure tests pass.
    - Prefer using the Dart MCP server (vs the dart command line) if available.

## Strategies for Discovery

Use these commands to find migration candidates:

-   **Find usages of expect**:
    `grep -r "expect(" test/`
-   **Find usages of expectLater**:
    `grep -r "expectLater(" test/`
-   **Find specific matchers** (e.g. `isTrue`):
    `grep -r "isTrue" test/`

## Common Patterns

| Legacy `expect` | Modern `check` |
| :--- | :--- |
| `expect(a, equals(b))` | `check(a).equals(b)` |
| `expect(a, isTrue)` | `check(a).isTrue()` |
| `expect(a, isFalse)` | `check(a).isFalse()` |
| `expect(a, isNull)` | `check(a).isNull()` |
| `expect(a, isNotNull)` | `check(a).isNotNull()` |
| `expect(() => fn(), throwsA<T>())` | `check(() => fn()).throws<T>()` |
| `expect(list, hasLength(n))` | `check(list).length.equals(n)` |
| `expect(a, closeTo(b, delta))` | `check(a).isA<num>().isCloseTo(b, delta)` |
| `expect(a, greaterThan(b))` | `check(a).isGreaterThan(b)` |
| `expect(a, lessThan(b))` | `check(a).isLessThan(b)` |
| `expect(a, unorderedEquals(b))` | `check(a).isA<Iterable>().unorderedEquals(b)` |

**Complex Examples:**

*Deep Verification with `isA` and `having`:*

**Legacy:**
```dart
expect(() => foo(), throwsA(isA<ArgumentError>()
    .having((e) => e.message, 'message', contains('MSG'))));
```

**Modern:**
```dart
check(() => foo())
    .throws<ArgumentError>()
    .has((e) => e.message as String, 'message')
    .contains('MSG');
```

## Constraints

-   **Scope**: Only modify files in `test/` (and `pubspec.yaml`).
-   **Correctness**: One failing test is unacceptable. If a test fails after migration and you cannot fix it immediately, REVERT that specific change.
-   **Type Safety**: `package:checks` is stricter about types than `matcher`. You may need to add explicit `as T` casts or `isA<T>()` checks in the chain.
