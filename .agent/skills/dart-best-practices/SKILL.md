---
name: dart-best-practices
description: |-
  General best practices for Dart development.
  Covers code style, effective Dart, and language features.
license: Apache-2.0
---

# Dart Best Practices

## 1. When to use this skill
Use this skill when:
-   Writing or reviewing Dart code.
-   Looking for guidance on idiomatic Dart usage.

## 2. Best Practices

### Multi-line Strings
Prefer using multi-line strings (`'''`) over concatenating strings with `+` and `\n`, especially for large blocks of text like SQL queries, HTML, or PEM-encoded keys. This improves readability and avoids `lines_longer_than_80_chars` lint errors by allowing natural line breaks.

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

### Robust JSON Parsing with Switch Expressions
When implementing `fromJson` factory constructors or parsing untrusted `Map<String, dynamic>` input, use switch expressions for type validation and extraction. This is more readable than manual `is` checks and cleaner than unsafe casts (`as`).

**Avoid (Unsafe Access):**
```dart
final json = jsonDecode(stdout);
if (json is Map &&
    json['configuration'] is Map &&
    json['configuration']['properties'] is Map &&
    json['configuration']['properties']['core'] is Map) {
  return json['configuration']['properties']['core']['project'] as String?;
}
return null;
```

**Prefer (Deep Pattern Matching):**
```dart
return switch (jsonDecode(stdout)) {
  {
    'configuration': {
      'properties': {'core': {'project': final String project}},
    },
  } =>
    project,
  _ => null,
};
```

This pattern ensures that missing or incorrect types are caught with descriptive errors rather than opaque runtime exceptions.
