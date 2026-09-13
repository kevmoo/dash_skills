## 0.1.0-wip

- Introduce package-level AST fact analysis (`PackageFacts`) via
  `package:analyzer`.
- Add `SealedHierarchyRule` to detect unsealed closed algebraic type
  hierarchies.
- Rewrite `PathPackageRule` using AST string interpolation visitor.
- Add `dart-seal-type-hierarchies` skill with abstention guardrails.
- Resolve installed `SKILL.md` before remote GitHub URL, with multi-root catalog
  search (local repo, target package, and `~/.agents/skills`).
