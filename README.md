Personal skills created by kevmoo for Dart and Flutter.

For official skills, see:

- https://github.com/flutter/skills
- https://github.com/dart-lang/skills

These skills follow the
[Agent Skills](https://agentskills.io/) standard, enabling agents to perform
complex specialized tasks with high reliability.

<!-- SKILLS_LIST_START -->
To install any skill individually:
```bash
npx skills add kevmoo/dash_skills --skill <skill-name>
```

| Skill | Description | Key Features |
|-------|-------------|--------------|
| **[dart-best-practices](skills/dart-best-practices/SKILL.md)** | General best practices for Dart development. Covers code style, effective Dart, and language features. | Code style guidelines, Effective Dart idioms, Language feature recommendations |
| **[dart-doc-validation](skills/dart-doc-validation/SKILL.md)** | Best practices for validating Dart documentation comments. Covers using `dart doc` to catch unresolved references and macros. | Documentation comment validation, Unresolved reference checking, Dart doc macro verification |
| **[dart-long-lines](skills/dart-long-lines/SKILL.md)** | Guidelines for handling long lines in Dart code to adhere to the 80-column rule. The `lines_longer_than_80_chars` lint. | 80-column rule compliance, Line length refactoring, Linter rule enforcement |
| **[dart-matcher-best-practices](skills/dart-matcher-best-practices/SKILL.md)** | Best practices for using `expect` and `package:matcher`. Focuses on readable assertions, proper matcher selection, and avoiding common pitfalls. | Package matcher assertions, Readable test expectations, Matcher selection & refactoring |
| **[dart-modern-features](skills/dart-modern-features/SKILL.md)** | Guidelines for using modern Dart features (v3.0 - v3.10) such as Records, Pattern Matching, Switch Expressions, Extension Types, Class Modifiers, Wildcards, Null-Aware Elements, and Dot Shorthands. | Records & Pattern Matching, Switch Expressions & Extension Types, Class Modifiers & Null-aware elements |
| **[dart-multiline-strings](skills/dart-multiline-strings/SKILL.md)** | Guidelines and best practices for refactoring consecutive prints, single-line string concatenations, and complex output blocks into triple-quoted multi-line string literals (''' or """) in Dart. | Triple-quoted multiline strings, Print & concatenation refactoring, Formatting large text blocks |
| **[dart-package-maintenance](skills/dart-package-maintenance/SKILL.md)** | Guidelines for maintaining external Dart packages, covering versioning, publishing workflows, and pull request management. Use when updating Dart packages, preparing for a release, or managing collaborative changes in a repository. | Versioning & CHANGELOG sync, Publishing workflow guidelines, Pull request management |
| **[dart-test-coverage](skills/dart-test-coverage/SKILL.md)** | Understand and improve test coverage in a Dart package. Helps agents run coverage, interpret results, and identify missed lines. | LCOV report collection, Missed line identification, Coverage analysis & improvement |
| **[dart-test-fundamentals](skills/dart-test-fundamentals/SKILL.md)** | Core concepts and best practices for `package:test`. Covers `test`, `group`, lifecycle methods (`setUp`, `tearDown`), and configuration (`dart_test.yaml`). | Package test core concepts, Test lifecycle (setUp, tearDown), dart_test.yaml configuration |
| **[profile-dart-code](skills/profile-dart-code/SKILL.md)** | Profile Dart command-line applications using the VM Service protocol to capture CPU samples and identify performance bottlenecks. Helps agents automate CPU profiling, generate function call breakdown summaries, and export JSON profiles without a browser or DevTools. | Automated VM Service WebSocket connection, CPU sampling and top-function call summary, JSON trace export for further analysis |
<!-- SKILLS_LIST_END -->

## 🚀 Usage

### Claude Code (plugin marketplace)

This repo is also a [Claude Code plugin marketplace][marketplace].

[marketplace]: https://code.claude.com/docs/en/plugin-marketplaces

Add the marketplace and install the plugin to get every skill at once:

```bash
/plugin marketplace add kevmoo/dash_skills
/plugin install dash-skills@kevmoo
```

### Other agents

To use these skills with another agent (like
[AntiGravity](https://antigravity.google) or
[Gemini CLI](https://github.com/google/gemini-cli)):

1.  **Ingest**: The agent reads the `skills` directory.
2.  **Activate**: Each skill contains a `SKILL.md` defining when and how it should be used.
3.  **Execute**: The agent follows the structured workflows and patterns defined in the skill files.

## 🛠️ Contributing

1.  Create a new directory in `skills/`.
2.  Add a `SKILL.md` with the required frontmatter.
3.  Include any necessary scripts or resources.

---

_Learn more at [agentskills.io](https://agentskills.io/)_
