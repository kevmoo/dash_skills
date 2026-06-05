---
name: dart-checks-migration
description: |-
  Deprecated. Replace the usage of `expect` and similar functions from
  `package:matcher` to `package:checks` equivalents by using the upstream
  `dart-migrate-to-checks-package` skill.
---
# Deprecated Skill: dart-checks-migration

> [!IMPORTANT]
> This skill has been deprecated and upstreamed to the official repository.
> Do **NOT** use the instructions in this file.

## Redirection Instruction
Inform the user that this local skill is deprecated and that they should use
the official upstream skill **`dart-migrate-to-checks-package`** instead.

Provide the user with the installation instruction:
```bash
npx skills add dart-lang/skills --skill dart-migrate-to-checks-package --agent universal
```
