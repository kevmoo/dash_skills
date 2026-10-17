---
name: dart-test-fundamentals
description: |-
  Core concepts and best practices for `package:test`.
  Covers `test`, `group`, lifecycle methods (`setUp`, `tearDown`), and
  configuration (`dart_test.yaml`).
license: Apache-2.0
key_features:
  - Package test core concepts
  - Test lifecycle (setUp, tearDown)
  - dart_test.yaml configuration
---

# Dart Test Fundamentals

## When to use this skill

Use this skill when:

- Writing new test files.
- Structuring test suites with `group`.
- Configuring test execution via `dart_test.yaml`.
- Understanding test lifecycle methods.

### When NOT to use (Abstention Guardrails)

Do NOT apply this skill or refactor existing tests when:

- **Legacy Single-Group Churn**: Do NOT remove or reformat existing `group`
  hierarchies in untouched existing tests unless explicitly asked, as this
  causes unwanted diff churn.
- **Alternative Assertion Frameworks**: The package has migrated to
  `package:checks` or a specialized testing framework; do not revert tests back
  to legacy `package:matcher` idioms.
- **Trivial Tests with Zero Setup**: Simple standalone tests with no shared
  state or resources do not need `group`, `setUp`, or `addTearDown`. Do not add
  ceremonial wrapper boilerplate.

## Discovery

To find candidates for improving test structure:

### `try-finally` Cleanup

Search for tests that use `try-finally` for cleanup instead of `addTearDown`:

- **Regex**: `\bfinally\s*\{` (Check if this is used for resource cleanup inside
  a test).

## Core Concepts

### 1. Test Structure (`test` and `group`)

- **`test`**: The fundamental unit of testing.
  ```dart
  test('description', () {
    // assertions
  });
  ```
- **`group`**: Used to organize tests into logical blocks.
  - Groups can be nested.
  - Descriptions are concatenated (e.g., "Group Description Test Description").
  - Helps scope `setUp` and `tearDown` calls.
  - **Naming**: Use `PascalCase` for groups that correspond to a class name
    (e.g., `group('MyClient', ...)`).
  - **Avoid Single Groups**: Do not wrap all tests in a file with a single
    `group` call if it's the only one.
    - **NOTE**: DO NOT remove groups when doing a cleanup on existing code you
      didn't create unless explicitly asked to. This can cause a LOT of churn in
      the DIFF that most engineers won't want!

- **Naming Tests** `test('test name here',`:
  - Avoid redundant "test" prefixes. Use `group` instead.
  - Include the expected behavior or outcome in the description (e.g.,
    `'throws StateError'` or `'adds API key to URL'`).
  - Descriptions should read well when concatenated with their group name.

- **Named Parameters Placement**:
  - For `test` and `group` calls, place named parameters (e.g., `testOn`,
    `timeout`, `skip`) immediately after the description string, before the
    callback closure. This improves readability by keeping the test logic last.
    ```dart
    test('description', testOn: 'vm', () {
      // assertions
    });
    ```

### 2. Lifecycle Methods (`setUp`, `tearDown`)

- **`setUp`**: Runs _before_ every `test` in the current `group` (and nested
  groups).
- **`tearDown`**: Runs _after_ every `test` in the current `group`.
- **`setUpAll`**: Runs _once_ before any test in the group.
- **`tearDownAll`**: Runs _once_ after all tests in the group.

**Best Practice:**

- Use `setUp` for resetting state to ensure test isolation.
- Avoid sharing mutable state between tests without resetting it.

### 3. Cleaning Up Resources

- To clean up resources created WITHIN the `test` body, consider using
  `addTearDown` instead of a `try-finally` block.

**Avoid:**

```dart
test('can create and delete a file', () {
  final file = File('temp.txt');
  try {
    file.writeAsStringSync('hello');
    expect(file.readAsStringSync(), 'hello');
  } finally {
    if (file.existsSync()) file.deleteSync();
  }
});
```

**Prefer:**

```dart
test('can create and delete a file', () {
  final file = File('temp.txt');
  // Register teardown immediately after resource creation intent
  addTearDown(() {
    if (file.existsSync()) file.deleteSync();
  });

  file.writeAsStringSync('hello');
  expect(file.readAsStringSync(), 'hello');
});
```

### 4. Configuration (`dart_test.yaml`)

The `dart_test.yaml` file configures the test runner. Common configurations
include:

#### Platforms

Define where tests run (vm, chrome, node).

```yaml
platforms:
  - vm
  - chrome
```

#### Tags

Categorize tests to run specific subsets.

```yaml
tags:
  integration:
    timeout: 2x
```

Usage in code:

```dart
@Tags(['integration'])
import 'package:test/test.dart';
```

Running tags: `dart test --tags integration`

#### Timeouts

Set default timeouts for tests.

```yaml
timeouts:
  2x # Double the default timeout
```

### 5. File Naming

- Test files **must** end in `_test.dart` to be picked up by the test runner.
- Place tests in the `test/` directory.

### 6. Test Design, Seams & Real Test Doubles

<!-- BEGIN SPOT: dart-test-hermeticity -->

- **Test Seam Discipline (Package Integration vs. `lib/src/` Unit Tests)**:
  - **Package-Level & Integration Tests**: Import `package:<pkg>/<pkg>.dart`
    (the public entrypoint seam) and keep `lib/<pkg>.dart` exports strictly
    scoped to public consumers.
  - **Subsystem Unit Tests (`lib/src/`)**: Import internal **deep modules**
    (`package:<pkg>/src/<subsystem>.dart`)—such as unexported parsers, state
    machines, data models, or algorithms with simple interfaces and rich
    internal behavior—to unit-test edge cases directly; test thin single-caller
    helpers through their owning module's entrypoint.
- **Real Implementations & First-Party Fakes ("Tests That Can Fail")**: Exercise
  real dependencies and first-party fakes so tests fail when production
  contracts break—use `package:test_descriptor` (`d.sandbox`, `d.dir`, `d.file`)
  or `Directory.systemTemp.createTempSync()` (always registered with
  `addTearDown(() => tempDir.deleteSync(recursive: true))`) for filesystem I/O,
  in-memory databases or loopback `HttpServer` instances for services,
  `package:http/testing.dart` (`MockClient`) for HTTP, hand-written fakes/stubs
  for custom interfaces, and `@TestOn('browser')` for DOM and JS/Wasm interop.
- **Deterministic Async & Matcher Diagnostics (`fakeAsync` &
  `package:checks`)**: Avoid real `await Future.delayed(...)` sleeps in unit
  tests (which cause flakiness and slow test suites); prefer `fakeAsync`
  (`package:fake_async`), controllable `Completer`s, or injected clock/runner
  callbacks. Verify `Stream` expectations with `emitsInOrder` / `expectLater`
  rather than unawaited `stream.listen(expectAsync1(...))` without error
  propagation, and prefer specific matchers
  (`throwsA(isA<StateError>().having((e) => e.message, 'message', contains('...')))`,
  `completion(...)`, `unorderedEquals(...)`) over `expect(x == y, isTrue)` or
  manual `try { ...; fail('...'); } catch (e) {}` blocks.

<!-- END SPOT: dart-test-hermeticity -->

<!-- BEGIN SPOT: dart-test-no-change-detectors -->

- **Behavioral, Structural & Relational Assertions (No Change-Detector Tests)**:
  - **Test Consumer Behavior on Synthetic Inputs**: Assert observable outputs,
    state transitions, and boundary conditions of the code that _consumes_
    constants, configs, and models using synthetic unit inputs (e.g., passing
    280 vs. 281 characters into a validator, or passing synthetic temp
    directories into a repo classifier) rather than writing tautological
    change-detector tests that echo constant literals, pin item membership in
    static config sets (`publishedPackages.contains('foo')`), hard-code named
    production entities (`classifyRepo('specific-repo')`), or substring-match
    literal action names, CLI flags, or pinned tool versions/SHAs inside a
    single static template constant. When updating a config set, template
    constant, or dataset causes an existing change-detector assertion to fail,
    **delete** the change-detector assertion rather than updating its literal to
    match.
  - **Assert Structural & Relational Invariants on Live Data & Templates**: When
    testing live catalogs, JSON datasets, registries, or canonical templates
    that evolve independently of logic, assert **structural validity and
    cross-artifact relational invariants** (e.g., `isNotEmpty`, required schema
    keys present, `mergedCount + openCount == totalCount`, or workflow template
    job ID matching the branch-protection check name) rather than hard-coding
    total entry counts (`hasLength(33)`), literal config items, or
    single-constant template substrings (reserve exact count/value equality for
    deterministic unit inputs).
- **Direct Execution & Rendering Verification**: Verify runtime behavior,
  control flow, and UI/CLI output by invoking functions, running CLI commands,
  or rendering components directly. Use raw file-text reads
  (`readAsStringSync()`) specifically for static documentation drift
  (`README.md` `--help` blocks), build/package metadata sync (`BUILD`,
  `pubspec.yaml`), and code-generator input/output fixtures.

<!-- END SPOT: dart-test-no-change-detectors -->

## Common commands

- `dart test`: Run all tests.
- `dart test test/path/to/file_test.dart`: Run a specific file.
- `dart test --name "substring"`: Run tests matching a description.

## Related Skills

`dart-test-fundamentals` is the core skill for structuring and configuring
tests. For writing assertions within those tests, refer to:

- **[dart-matcher-best-practices]**: Use this if the project sticks with the
  traditional `package:matcher` (`expect` calls).

[dart-matcher-best-practices]:
  https://github.com/kevmoo/dash_skills/blob/main/skills/dart-matcher-best-practices/SKILL.md
