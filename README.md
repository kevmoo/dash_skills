Personal skills created by kevmoo for Dart and Flutter.

For official skills, see:

- https://github.com/flutter/skills
- https://github.com/dart-lang/skills

These skills follow the
[Agent Skills](https://agentskills.io/) standard, enabling agents to perform
complex specialized tasks with high reliability.

<!-- SKILLS_LIST_START -->
*   **[Dart Best Practices](skills/dart-best-practices/SKILL.md)** — General best practices for Dart development. Covers code style, effective Dart, and language features.
    ```bash
    npx skills add kevmoo/dash_skills --skill dart-best-practices
    ```
*   **[Dart Doc Validation](skills/dart-doc-validation/SKILL.md)** — Best practices for validating Dart documentation comments. Covers using `dart doc` to catch unresolved references and macros.
    ```bash
    npx skills add kevmoo/dash_skills --skill dart-doc-validation
    ```
*   **[Dart Long Lines](skills/dart-long-lines/SKILL.md)** — Guidelines for handling long lines in Dart code to adhere to the 80-column rule. The `lines_longer_than_80_chars` lint.
    ```bash
    npx skills add kevmoo/dash_skills --skill dart-long-lines
    ```
*   **[Dart Matcher Best Practices](skills/dart-matcher-best-practices/SKILL.md)** — Best practices for using `expect` and `package:matcher`. Focuses on readable assertions, proper matcher selection, and avoiding common pitfalls.
    ```bash
    npx skills add kevmoo/dash_skills --skill dart-matcher-best-practices
    ```
*   **[Dart Modern Features](skills/dart-modern-features/SKILL.md)** — Guidelines for using modern Dart features (v3.0 - v3.10) such as Records, Pattern Matching, Switch Expressions, Extension Types, Class Modifiers, Wildcards, Null-Aware Elements, and Dot Shorthands.
    ```bash
    npx skills add kevmoo/dash_skills --skill dart-modern-features
    ```
*   **[Dart Multi-line Strings](skills/dart-multiline-strings/SKILL.md)** — Guidelines and best practices for refactoring consecutive prints, single-line string concatenations, and complex output blocks into triple-quoted multi-line string literals (''' or """) in Dart.
    ```bash
    npx skills add kevmoo/dash_skills --skill dart-multiline-strings
    ```
*   **[Dart Package Maintenance](skills/dart-package-maintenance/SKILL.md)** — Guidelines for maintaining external Dart packages, covering versioning, publishing workflows, and pull request management. Use when updating Dart packages, preparing for a release, or managing collaborative changes in a repository.
    ```bash
    npx skills add kevmoo/dash_skills --skill dart-package-maintenance
    ```
*   **[Dart Test Coverage](skills/dart-test-coverage/SKILL.md)** — Understand and improve test coverage in a Dart package. Helps agents run coverage, interpret results, and identify missed lines.
    ```bash
    npx skills add kevmoo/dash_skills --skill dart-test-coverage
    ```
*   **[Dart Test Fundamentals](skills/dart-test-fundamentals/SKILL.md)** — Core concepts and best practices for `package:test`. Covers `test`, `group`, lifecycle methods (`setUp`, `tearDown`), and configuration (`dart_test.yaml`).
    ```bash
    npx skills add kevmoo/dash_skills --skill dart-test-fundamentals
    ```
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
