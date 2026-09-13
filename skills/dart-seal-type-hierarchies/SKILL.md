---
name: dart-seal-type-hierarchies
description: |-
  Identify closed type hierarchies that are not declared `sealed`, and seal
  them so the compiler can enforce switch exhaustiveness. Covers the same-library
  requirement, the public-API breaking-change tradeoff, and the migration from
  `is` cascades to exhaustive switches.
key_features:
  - Closed hierarchy detection
  - Exhaustiveness enforcement
  - Public API breaking-change analysis
---

# Seal Type Hierarchies

## 1. When to use this skill

Use this skill when:

- A package declares an abstract base type whose subtypes are all defined in the
  same library, but the base type is not marked `sealed`.
- Code branches over the members of such a hierarchy with `is` checks or a
  non-exhaustive `switch`, so adding a subtype later fails silently at runtime
  instead of loudly at compile time.
- Reviewing a new type hierarchy and deciding whether it should be open to
  external subtyping.

### When NOT to use (Abstention Guardrails)

Do NOT seal a type when:

- **Subtypes span multiple libraries**: `sealed` requires every direct subtype
  to be declared in the same library as the base type. If subtypes live in other
  files (and are not `part of` the same library), the code will not compile.
  Either move them or leave the hierarchy open.
- **The type is public API and external extension is intended**: Sealing a type
  exported from a published package is a **breaking change** for any downstream
  package that extends or implements it. Plugin interfaces, visitor bases, and
  extension points are meant to be open. Do not seal them to win exhaustiveness.
- **The base type is concrete and instantiated**: `sealed` implies `abstract`.
  If callers construct the base type directly, sealing it breaks them, and the
  fix is a larger refactor than this skill covers.
- **Fewer than two subtypes**: A single subtype is specialization, not an
  algebraic hierarchy. Exhaustiveness checking buys nothing.
- **SDK constraint below 3.0.0**: Class modifiers do not exist before Dart 3.
  Check `environment.sdk` in `pubspec.yaml` first.

## 2. Why sealing is the correctness move

The value is not switch syntax. It is that the compiler starts rejecting
incomplete branching:

```
seal the hierarchy -> exhaustiveness checking -> adding a subtype becomes
a compile error at every switch, instead of a silent fallthrough
```

An unsealed hierarchy with `is` cascades is not wrong today. It becomes wrong
the moment someone adds a subtype, and nothing tells them which call sites they
missed. Sealing is prophylactic: it converts a future runtime bug into a
present-day compile error.

This is a different concern from preferring pattern matching for readability.
Pattern matching over an unsealed hierarchy is a style choice. Sealing the
hierarchy is a correctness guarantee, and the ergonomic payoff is a consequence,
not the goal.

## 3. Detection

A type is a candidate when all of the following hold:

1. It is declared `abstract` and is not already `sealed`.
2. It has two or more direct subtypes.
3. Every direct subtype is declared in the **same library** as the base type.
4. Sealing it is not a breaking change: it lives under `lib/src/`, or is already
   marked `final`, or the package is an application rather than a published
   library.

Conditions 1 through 3 are decidable from the syntax tree. Condition 4 requires
knowing the author's intent about the public API and is the part a human or an
LLM must confirm.

This detection is **not expressible as a single-file regular expression**. It is
a question about the package-wide type graph: you must collect every type
declaration and every `extends`/`implements`/`with` edge before you can tell
whether a hierarchy is closed.

## 4. Applying the change

### Before

```dart
abstract class Shape {}

class Circle extends Shape {
  final double radius;
  Circle(this.radius);
}

class Square extends Shape {
  final double side;
  Square(this.side);
}

double area(Shape shape) {
  if (shape is Circle) {
    return 3.14159 * shape.radius * shape.radius;
  } else if (shape is Square) {
    return shape.side * shape.side;
  }
  // Silently reached when a new subtype is added.
  throw ArgumentError('Unknown shape: $shape');
}
```

### After

```dart
sealed class Shape {}

final class Circle extends Shape {
  final double radius;
  Circle(this.radius);
}

final class Square extends Shape {
  final double side;
  Square(this.side);
}

double area(Shape shape) => switch (shape) {
  Circle(:final radius) => 3.14159 * radius * radius,
  Square(:final side) => side * side,
};
```

Adding `class Triangle extends Shape` now produces a compile error at `area`,
naming the missing case. The `throw` and its unreachable-by-construction error
message are gone.

### Migration steps

1. Add `sealed` to the base type declaration.
2. Run `dart analyze`. Every non-exhaustive switch over the hierarchy now
   reports an error; every subtype declared outside the library reports one too.
3. Convert `is` cascades to `switch` expressions, removing the trailing
   `throw`/`default` that existed only to satisfy the return type.
4. Consider marking leaf subtypes `final` to prevent further extension.

## 5. Interaction with other skills

- **`dart-use-pattern-matching`** / **`dart-modern-features`**: apply _after_
  sealing. Rewriting an `is` cascade as a switch over an unsealed type is a
  readability change only; the same rewrite over a sealed type is checked by the
  compiler.
- Do not treat this skill as a reason to seal a hierarchy you do not own the
  evolution of.
