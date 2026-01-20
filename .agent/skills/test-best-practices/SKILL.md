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
