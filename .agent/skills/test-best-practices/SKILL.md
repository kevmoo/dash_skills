---
description: |-
  Enforce best practices for Dart and Flutter testing.
---

## When to use this skill

In a Dart or Flutter project.
When a user asks to "enforce test best practices" or similar.
When modifying or creating test files.

## Workflow

1.  **Search**: Use the grep commands below to identify candidates.
2.  **Analyze**: Check if the code violates the best practices defined below.
3.  **Apply**: Refactor the code to use the recommended matchers.
4.  **Verify**: Run tests (`dart test`) to ensure no regressions.

### Search Strategies

-   `.length`: `grep -r "\.length,\s*equals\(" test/`
-   Boolean properties:
    `grep -rE "expect\(.*\.(is(Empty|NotEmpty)),\s*(isTrue|true|isFalse|false)" test/`
-   Manual loops: `grep -r "for (var .* in .*)" test/` (manual review required)

## Best Practice Patterns

### Collections

#### Use `hasLength`

Prefer `expect(list, hasLength(n))` over `expect(list.length, n)`.
*Applies to*: `Iterable`, `Map`, `String`.

#### Use `isEmpty` / `isNotEmpty`

Prefer `expect(list, isEmpty)` over `expect(list.isEmpty, true)`.
Prefer `expect(list, isNotEmpty)` over `expect(list.isNotEmpty, true)` or
`expect(list, isNot(isEmpty))`.
*Applies to*: `Iterable`, `Map`, `String`.

#### Declarative Verification

Prefer `expect(list, everyElement(matcher))` over manual loops with assertions.

### Maps

#### Use `containsPair`

Prefer `expect(map, containsPair(key, value))` over `expect(map[key], value)`.

*Note*: If verifying a key is missing, use `expect(map, isNot(contains(key)))`.

#### Strict Equality

Prefer `expect(map, {'k': 'v'})` over multiple `containsPair` calls when the
full map is known.

### Types & Objects

#### Declarative Type Checks

Prefer `expect(obj, isA<T>())` over `expect(obj is T, isTrue)`.

#### Grouped Assertions

Prefer chaining `having` on `isA<T>` for multiple property checks.

```dart
expect(obj, isA<MyType>()
  .having((o) => o.prop1, 'prop1', a)
  .having((o) => o.prop2, 'prop2', b));
```

## Constraints

-   **Verify Types**: Ensure subject is strictly `Iterable`/`Map` before
    applying collection matchers. Some custom classes (e.g. `PriorityQueue`)
    may have `.length` but don't implement `Iterable`.
-   **Do NOT migrate to package:checks**: Unless explicitly requested. This
    skill focuses on `package:test` matchers.
-   **Preserve Behavior**: Ensure refactorings do not change strictness.
