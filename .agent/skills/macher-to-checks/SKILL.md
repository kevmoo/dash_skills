---
description: |-
  Replace the usage of `expect` and similar functions from `package:matcher` 
  to `package:checks` equivalents.
---

## When to use this skill

In a Dart or Flutter project.
When a user asks to migrate to `package:checks` or just "checks".

## How to use this skill
When asked to "migrate to checks", perform the following steps:

1.  **Analysis**:
    - Read through the Dart code in the `test/` directory looking for the usage of `expect` from `package:test`.
    - If there are many problems with a given file, go test by test, making sure the tests pass and the analyzer is happy.
    - If you cannot get a given test to pass, leave it as is with a `// TODO: Skipped migrating to package:checks, was too complex.` comment explaining why and continue.
    - If you are unsure about a conversion, err on the side of leaving the code as is.
    - Make special note of custom matchers. Tell the user to consider migrating these first before continuing.
2.  **Dependency Check**: Ensure `pubspec.yaml` has `package:checks` in `dev_dependencies`. Add it if missing using `dart pub add --dev checks`.
3.  **Import Management**: Add `import 'package:checks/checks.dart';` to Dart test files. Update the `package:test/test.dart` import to to `import 'package:test/scaffold.dart`. Ensure imports remain sorted.
4.  **Replacement**:
  - Replace `expect()` and `expectLater()` calls with `check()` equivalents. See common patterns below. 
5.  **Verification**: The code should analyze cleanly and the tests should pass.

## Common Conversion Patterns

-   `expect(a, equals(b));`  =>  `check(a).equals(b);`
-   `expect(a, isTrue);`  =>  `check(a).isTrue();`
-   `expect(a, isFalse);`  =>  `check(a).isFalse();`
-   `expect(a, isNull);`  =>  `check(a).isNull();`
-   `expect(a, isNotNull);`  =>  `check(a).isNotNull();`
-   `expect(() => foo(), throwsA<SomeException>());`  =>  `check(() => foo()).throws<SomeException>();`
-   `expect(a, unorderedEquals(b));`  =>  `check(a).isA<Iterable>().unorderedEquals(b);`
-   `expect(identical(a, b), isTrue);`  =>  `check(identical(a, b)).isTrue();`
-   `expect(identical(a, b), isFalse);`  =>  `check(identical(a, b)).isFalse();`
-   `expect(list, hasLength(n));`  =>  `check(list).length.equals(n);`
-   `expect(a, closeTo(b, delta));`  =>  `check(a).isA<num>().isCloseTo(b, delta);`
-   `expect(a, greaterThan(b));`  =>  `check(a).isGreaterThan(b);`
-   `expect(a, lessThan(b));`  =>  `check(a).isLessThan(b);`
-   `expect(a, orderedEquals(b));`  =>  `check(a).isA<Iterable>().deepEquals(b);`
-   `expect(() => foo(), throwsA(isA<ArgumentError>().having((e) => e.message, 'message', 'MSG')));`  =>  `check(() => foo()).throws<ArgumentError>().has((e) => e.message as String, (m) => m.contains('MSG'));`

## Constraints

-   NEVER modify files outside of `pubspec.yaml` and the `test/` directory.
-   The code should analyze cleanly and the tests should pass.
