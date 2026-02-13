---
name: dart-test-fundamentals
description: |-
  Core concepts and best practices for `package:test`.
  Covers `test`, `group`, lifecycle methods (`setUp`, `tearDown`), and configuration (`dart_test.yaml`).
license: Apache-2.0
---

# Dart Test Fundamentals

## When to use this skill
Use this skill when:
- Writing new test files.
- structuring test suites with `group`.
- Configuring test execution via `dart_test.yaml`.
- Understanding test lifecycle methods.

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

### 2. Lifecycle Methods (`setUp`, `tearDown`)

- **`setUp`**: Runs *before* every `test` in the current `group` (and nested
  groups).
- **`tearDown`**: Runs *after* every `test` in the current `group`.
- **`setUpAll`**: Runs *once* before any test in the group.
- **`tearDownAll`**: Runs *once* after all tests in the group.

**Best Practice:**
- Use `setUp` for resetting state to ensure test isolation.
- Avoid sharing mutable state between tests without resetting it.

### 3. Configuration (`dart_test.yaml`)

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

Running tags:
`dart test --tags integration`

#### Timeouts
Set default timeouts for tests.

```yaml
timeouts:
  2x # Double the default timeout
```

### 4. File Naming
- Test files **must** end in `_test.dart` to be picked up by the test runner.
- Place tests in the `test/` directory.

## Common commands

- `dart test`: Run all tests.
- `dart test test/path/to/file_test.dart`: Run a specific file.
- `dart test --name "substring"`: Run tests matching a description.
