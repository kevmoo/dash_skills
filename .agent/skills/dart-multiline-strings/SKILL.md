---
name: dart-multiline-strings
description: |-
  Guidelines and best practices for refactoring consecutive prints, single-line
  string concatenations, and complex output blocks into triple-quoted multi-line
  string literals (''' or """) in Dart.
license: Apache-2.0
---

# Dart Multi-line Strings

## 1. When to use this skill

Use this skill when:
-   Refactoring consecutive `print()` or `stdout.writeln()` statements into a
    single, cohesive output block.
-   Simplifying string literals that span multiple lines, contain embedded
    newlines (`\n`), or use nested indentations.
-   Formatting large user-facing text output (like CLI help menus, reports, or
    templated messages) to be readable, maintainable, and performant.

## Discovery

To find candidate code blocks for multi-line string refactoring:
-   Look for multiple back-to-back `print()` or `stdout.writeln()` calls inside
    a function, especially inside loops, console views, or CLI controllers.
-   Look for single-line strings heavily loaded with `\n` escape sequences.
-   Look for multiple string concatenations using the `+` operator or adjacent
    string literal splits that are meant to represent multi-line outputs.

## 2. Guidelines

### Combine Consecutive Outputs
Instead of calling `print()` repeatedly for a multi-line output, group the
contents into a single triple-quoted string literal: `print('''...''')`.

### Explicit and Clean Alignment
In a triple-quoted literal, the exact spacing and formatting inside the quotes
are preserved. Use this to specify indentation levels visually instead of using
manually padded space prefixes (e.g., `'    '`).

### Remove Empty Print Calls
If there are empty `print()` or `print('')` statements serving as vertical
separators between output segments, replace them by letting the trailing
newline of a multi-line string block handle the separation naturally.

### Handling the First Newline
If the opening triple-quote is immediately followed by a newline, the compiler
discards it.
-   If you do **not** want a leading blank line, start the string content on a
    fresh line in the source code for clean layout.
-   If you **do** want a leading blank line in the output, leave an extra empty
    line inside the triple-quoted block, or use `\n` explicitly at the
    beginning:
    ```dart
    print('''

    This starts with one blank line above it.''');
    ```

### 80-Character Line Limit Exemption
The `lines_longer_than_80_chars` lint rule **automatically ignores** lines inside
multiline string literals. You can write long lines inside triple-quotes without
triggering linter warnings or being forced to break them up.

### Dynamic Switch Expressions inside Interpolation
Leverage Dart 3 switch expressions directly inside string interpolations to
dynamically select and inject optional lines, conditional labels, or helper
instructions. This avoids cluttering the surrounding code with imperatively
constructed strings or multiple `if` statements:
```dart
print('''
Status: ${status.isSuccess ? 'PASS' : 'FAIL'}
${switch (status) {
  Status.failed => 'Error details: $errorMessage',
  _ => '',
}}''');
```

## 3. Examples

### Refactoring Consecutive Prints with Indentation

**Avoid:**
```dart
void printGerritView(String branch, String desc, bool hasConflicts) {
  print('Branch Details:');
  print('    Name:        ' + branch);
  print('    Description: ' + desc);
  print('');
  if (hasConflicts) {
    print('    WARNING: This branch has conflicts.');
    print('    Run `git merge origin/main` to resolve.');
  }
}
```

**Prefer:**
```dart
void printGerritView(String branch, String desc, bool hasConflicts) {
  print('''
Branch Details:
    Name:        $branch
    Description: $desc
${hasConflicts ? '''
    WARNING: This branch has conflicts.
    Run `git merge origin/main` to resolve.''' : ''}''');
}
```

