---
name: dart-test-coverage
description: |-
  Understand and improve test coverage in a Dart package.
  Helps agents run coverage, interpret results, and identify missed lines.
---

# Dart Test Coverage

Guidelines for running and interpreting test coverage in Dart packages.

## When to use this skill
- When asked to "check test coverage" or "improve coverage".
- When you need to identify which parts of a library are untested.

## How to use this skill (The Workflow)
1.  Ensure tests pass by running `dart test`.
2.  Collect coverage by running `dart test --coverage=.dart_tool/coverage`.
3.  Interpret the results using the provided script or standard tools.
4.  Add tests to cover missed lines.

## Running Coverage
Run the following command to collect coverage in JSON format:
```bash
dart test --coverage=.dart_tool/coverage
```

## Interpreting Results

### Option 1: Use the custom interpreter script
This repository includes a zero-dependency script that parses the raw JSON
output and provides a summary of covered percentage and missed lines.

Run it from the project root (adjust path to script as needed):
```bash
dart run .agent/skills/dart-test-coverage/scripts/interpret_coverage.dart .dart_tool/coverage <package_name>
```
Replace `<package_name>` with the name from `pubspec.yaml`.

Example Output:
```
package:my_pkg/src/file.dart: 50.0% (2/4 lines)
  Missed lines: 3, 4
```

### Option 2: Use package:coverage
If `package:test` is installed, `package:coverage` is likely available as a
transitive dependency. You can use its `format_coverage` tool.

To get a human-readable "pretty print" of the coverage:
```bash
dart run coverage:format_coverage --in=.dart_tool/coverage --out=stdout --pretty-print --report-on=lib
```
This will output the file content with hit counts on the left (e.g., `0|` for
missed lines).

## Constraints
- ALWAYS verify that tests pass before collecting coverage.
- DO NOT commit the `.dart_tool/coverage` directory.
- Focus coverage improvements on `lib/` files, not `test/` or generated files.
