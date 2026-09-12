---
name: dash-discover
description: |-
  Diagnoses latent architectural modernization opportunities across Dart and
  Flutter packages (language idioms, testing hygiene, CLI patterns, doc rot)
  and prescribes matching specialized skills.
key_features:
  - Architectural Gap Diagnosis
  - Latent Modernization Discovery
  - Two-Tier Prescriptions & Evidence
---

# Dash Discover (Meta-Skill)

The Meta-Skill Discovery Engine evaluates a Dart or Flutter project's
architecture, language idioms, testing patterns, and documentation health to
uncover latent modernization opportunities that standard static analysis passes
ignore.

---

## 1. When to use this skill

Use this skill when:
- Asked questions like: *"Am I doing this right?"*, *"Am I holding it right?"*,
  or *"What skills should I use on this repository?"*
- Entering a new or unfamiliar Dart/Flutter repository and determining where to
  focus modernization effort.
- `dart analyze` reports clean code (0 errors, 0 warnings), but the codebase may
  still harbor outdated pre-Dart 3 constructs, legacy matcher assertions,
  unstructured CLI entrypoints, or rotting doc examples.

---

## 2. Core Mental Model: The Analyzer Blindspot

Static analysis (`dart analyze`) verifies syntactic and semantic correctness,
not architectural quality or modern idiomatic design. A package can pass
`dart analyze --fatal-infos` with zero warnings while simultaneously:
- Using 7-branch polymorphic `else if (x is Y)` cascades instead of concise
  Dart 3 switch expressions with pattern destructuring.
- Relying on legacy `package:test` `expect(actual, matcher)` calls instead of
  fluent, type-safe `package:checks`.
- Storing rotting, unverified code snippets in `/// ``` ` doc comments instead of
  automated `{@example}` region testing.
- Building ad-hoc monolithic 300+ line `bin/main.dart` entrypoints without
  `package:args/command_runner.dart`.

Dash Discover systematically identifies these latent gaps and points directly to
the specialized skills equipped to remediate them.

---

## 3. Two-Tier Discovery Protocol

### Tier 1: Fast Static Heuristics (<50ms)

Run the discovery CLI from anywhere in the workspace:

```bash
dart run dash_discover <path-to-target-package>
```

Or for structured machine ingestion:

```bash
dart run dash_discover <path-to-target-package> --json
```

<!-- DISCOVERY_RULES_START -->
The static scanner performs rapid, zero-network checks across 6 built-in rules:
1. **Testing Architecture (`dart-migrate-to-checks-package`)**: Detects test or flutter_test in dependencies when checks is absent.
2. **Dart 3 Language Idioms (`dart-use-pattern-matching`)**: Detects legacy else if (... is ...) type cascades and returning switch statements.
3. **CLI Architecture (`dart-build-cli-app`)**: Detects ad-hoc bin/*.dart CLI entrypoints lacking structured argument parsing.
4. **Cross-Platform Robustness (`dart-use-path-package`)**: Detects manual path string concatenation without package:path.
5. **Testing Architecture (`dart-generate-test-mocks`)**: Detects handwritten fake or mock class definitions without mockito or mocktail.
6. **Testing Architecture (`dart-matcher-best-practices`)**: Detects unidiomatic expect() assertions (e.g. expect(x.length, ...) or expect(x.isEmpty, true)).
<!-- DISCOVERY_RULES_END -->

### Tier 2: Token-Efficient Outline Probing

To capture complex cross-cutting architectural patterns beyond regexes:
1. Generate the condensed repository outline (~1k tokens):
   ```bash
   dart run dash_discover <path-to-target-package> --outline-only
   ```
2. The outline captures:
   - `pubspec.yaml` (dependencies, dev-dependencies, SDK constraints).
   - Shallow directory structure (up to 3 levels deep).
   - Structural API signatures and class outlines (via `sem entities lib/ --signatures`).
3. Pass the generated prompt (`--prompt-only`) and outline to a fast model (such
   as Gemini Flash) along with the active skills catalog to evaluate semantic
   architectural fit with concrete file evidence.

---

## 4. Remediation Workflow

When `dash-discover` produces recommendations:
1. **Triage by Lifecycle & Confidence**:
   - Focus on finite migrations first (e.g. core language modernization and
     testing migrations), prioritized by confidence and affected file count.
   - Treat periodic hygiene audits (e.g. cognitive complexity, doc validation)
     as recurring sweeps rather than one-time migrations.
   - Throttle ubiquitous recommendations (e.g. at most one test framework
     migration at a time).
2. **Invoke Specialized Skills**:
   - For pattern matching: invoke `dart-modern-features` or `dart-use-pattern-matching`.
   - For test assertions: invoke `dart-migrate-to-checks-package`.
   - For doc rot: invoke `dart-doc-validation` or `dart-use-doc-examples`.
   - For CLI architecture: invoke `dart-build-cli-app`.
3. **Verify Empirically**:
   - Ensure tests continue to pass (`dart test`).
   - Ensure analysis remains clean (`dart analyze`).
