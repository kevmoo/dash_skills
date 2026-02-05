---
description: |- 
  Enforce best practices for Dart and Flutter testing.
---

## When to use this skill

In a Dart or Flutter project.
When a user asks to "enforce test best practices" or similar.

## A list of patterns to look for

### Use `hasLength` instead of matching against `length`

Prefer `expect(list, hasLength(n))` over `expect(list.length, n)`.

This applies to objects of type `Iterable`, `Map` and `String`.

### Use `isEmpty` and `isNotEmpty` instead of matching against `isEmpty` and `isNotEmpty` properties

Prefer `expect(list, isEmpty)` over `expect(list.isEmpty, true)` and `expect(list, isNotEmpty)` over `expect(list.isNotEmpty, true)`.

This provides more descriptive failure messages.

This applies to objects of type `Iterable`, `Map` and `String`.

### Use `isNotEmpty` instead of `isNot(isEmpty)`

Prefer `expect(list, isNotEmpty)` over `expect(list, isNot(isEmpty))`.

This is more readable and idiomatic.

### Use `isA<T>()` instead of checking `is T` against a boolean

Prefer `expect(obj, isA<T>())` over `expect(obj is T, isTrue)`.

This provides much more descriptive failure messages when the type does not match.

### Use `containsPair(key, value)` instead of indexing into a map

Prefer `expect(map, containsPair(key, value))` over `expect(map[key], value)`.

This provides much more descriptive failure messages when the key is missing or the value does not match.

> [!NOTE]
> If the intention is to verify that a key is **missing** (which `expect(map[key], isNull)` also covers), use `expect(map, isNot(contains(key)))`. `containsPair(key, isNull)` expects the key to be present with a `null` value.

## Strategies for finding patterns

Use the following grep regexes to find candidates:

- `.length`: `\.length,\s*equals\(` or `expect\(.*\.length`
- Boolean properties: `expect\(.*\.(is(Empty|NotEmpty)),\s*(isTrue|true|isFalse|false)`

## Critical Implementation Details

- **Verify Types**: BEFORE applying `hasLength` or `contains`, ensure the subject is an `Iterable`, `Map`, or `String`. Some custom collection-like classes (e.g. `PriorityQueue`) may have `.length` or `.contains` but do not strictly implement `Iterable`, causing matchers to fail or behave unexpectedly.
- **Handle Inverted Logic**: Watch out for `expect(x.isEmpty, isFalse)`. This should become `expect(x, isNotEmpty)`, NOT `expect(x, isEmpty)`.
