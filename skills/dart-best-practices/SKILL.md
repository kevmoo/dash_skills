---
name: dart-best-practices
description: |-
  General best practices for Dart development.
  Covers code style, effective Dart, and language features.
license: Apache-2.0
key_features:
  - Code style guidelines
  - Effective Dart idioms
  - Language feature recommendations
---

# Dart Best Practices

## 1. When to use this skill

Use this skill when:

- Writing or reviewing Dart code.
- Looking for guidance on idiomatic Dart usage.

### When NOT to use (Abstention Guardrails)

Do NOT apply this skill or refactor code when:

- **Public API Breaking Changes**: Refactoring would alter public API contracts,
  return types, or parameter signatures in published packages without a
  coordinated major SemVer bump.
- **Dogmatic Micro-Optimizations**: Rewriting clear, readable code for
  negligible theoretical gains (e.g. replacing clear string concatenation in a
  simple one-line log message with multiline quotes).
- **Domain-Specific or Code-Generated Files**: Generated files (`*.g.dart`,
  `*.freezed.dart`, protobufs) or files where line lengths and string layouts
  are managed by code generators.
- **Explicit Type Annotations in Public Interfaces**: Replacing explicit type
  annotations with `var` or `final` where explicit types document the public API
  surface or disambiguate complex generics.

## 2. Best Practices

### Multi-line Strings

Prefer using multi-line strings (`'''`) over concatenating strings with `+` and
`\n`, especially for large blocks of text like SQL queries, HTML, or PEM-encoded
keys. This improves readability and avoids `lines_longer_than_80_chars` lint
errors by allowing natural line breaks.

**Avoid:**

```dart
final pem = '-----BEGIN RSA PRIVATE KEY-----\n' +
    base64Encode(fullBytes) +
    '\n-----END RSA PRIVATE KEY-----';
```

**Prefer:**

```dart
final pem = '''
-----BEGIN RSA PRIVATE KEY-----
${base64Encode(fullBytes)}
-----END RSA PRIVATE KEY-----''';
```

### Line Length

Avoid lines longer than 80 characters, even in Markdown files and comments. This
ensures code is readable in split-screen views and on smaller screens without
horizontal scrolling.

**Prefer:** Target 80 characters for wrapping text. Exceptions are allowed for
long URLs or identifiers that cannot be broken.

## Discovery

### Multi-line Strings

To find candidates for multi-line strings, search for string concatenation with
`+` involving newlines:

- **Regex**: `['"]\s*\+\s*['"]`
- **Regex**: `\+\s*['"].*\\n`

### Line Length

- Rely on the `lines_longer_than_80_chars` lint from the analyzer.

## Related Skills

- **[dart-modern-features]**: For idiomatic usage of modern Dart features like
  Pattern Matching (useful for deep JSON extraction), Records, and Switch
  Expressions.

[dart-modern-features]:
  https://github.com/kevmoo/dash_skills/blob/main/skills/dart-modern-features/SKILL.md
