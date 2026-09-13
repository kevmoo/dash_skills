## 0.1.0-wip

- Introduce package-level AST fact analysis (`PackageFacts`) via
  `package:analyzer`.
- Add `SealedHierarchyRule` to detect unsealed closed algebraic type
  hierarchies.
- Rewrite `PathPackageRule` using AST string interpolation visitor.
- Add `dart-seal-type-hierarchies` skill with abstention guardrails.
- Resolve installed `SKILL.md` before remote GitHub URL, with multi-root catalog
  search (local repo, target package, and `~/.agents/skills`).
- Refactor CLI architecture to follow `dart-build-cli-app` guidelines:
  - Convert `bin/dash_discover.dart` into a thin entrypoint trampoline.
  - Implement structured CLI execution, argument parsing, option validation, and
    POSIX `ExitCode` handling in `lib/src/cli.dart`.
  - Declare `executables: dash_discover:` in `pubspec.yaml`.
  - Add fast in-memory unit tests in `test/cli_test.dart`.
