---
name: dart-package-maintenance
description: |-
  Guidelines for maintaining external Dart packages, covering versioning,
  publishing workflows, and pull request management. Use when updating Dart
  packages, preparing for a release, or managing collaborative changes in a
  repository.
key_features:
  - Versioning & CHANGELOG sync
  - Publishing workflow guidelines
  - Pull request management
---

# Dart Package Maintenance

Guidelines for maintaining Dart packages in alignment with the canonical Dart
team
[External Package Maintenance](https://github.com/dart-lang/sdk/blob/main/docs/External-Package-Maintenance.md)
specification.

## When to use this skill

Use this skill when:

- Updating Dart packages, preparing for a release, or managing collaborative
  changes in a repository.
- Managing versioning, `CHANGELOG.md` synchronization, and publishing workflows.
- Ensuring published packages comply with Dart team conventions.

### When NOT to use (Abstention Guardrails)

Do NOT apply package maintenance version bumps or changelog updates when:

- **Internal / Private Packages**: Packages marked `publish_to: none` in
  `pubspec.yaml` that are not published to `pub.dev` (e.g., application root
  packages or internal monorepo tooling).
- **Repository-Root Files or Historical `CHANGELOG.md` Typos**: Pull requests
  that only modify repository-level files outside a published package (such as
  `.github/workflows/`, repo-root `SKILL.md`, or root docs in a monorepo) or
  that only fix typos/formatting in historical `CHANGELOG.md` sections.
- **In-Flight PR Commits**: Intermediate commits on an active feature branch
  where the version already carries an appropriate `-wip` suffix.

## Versioning

### Semantic Versioning

Dart packages use [semantic versioning](https://semver.org) with a
[pre-`1.0.0` variation](https://dart.dev/tools/pub/dependencies#caret-syntax)
where the version numbers are shifted to the right before a `1.0.0` release; see
also the
[`package:pub_semver` semantics](https://pub.dev/packages/pub_semver#semantics):

- **Packages at `1.0.0` or later**: `major.minor.patch`.
- **Packages not yet at `1.0.0`**: `0.major.minor`, where the second number is
  bumped for breaking changes, such as `0.4.2` to `0.5.0-wip`, and the third
  number is bumped for non-breaking features and bug fixes, such as `0.4.2` to
  `0.4.3-wip`. Avoid `+1` build suffixes (in `package:pub_semver`, `0.4.2+1-wip`
  parses `+1-wip` as build metadata rather than a `-wip` pre-release).
- **Recommendation**: Aim to publish `1.0.0` as soon as the package is stable.

Choose the version bump based on the impact of the change:

- **Major**: Breaking changes, including removing or renaming a `pubspec.yaml`
  `executables` entry.
- **Minor**: New features and non-breaking API changes, such as introducing a
  new class or adding a `pubspec.yaml` `executables` entry.
- **Patch**: Bug fixes, minimum `environment.sdk` or runtime `dependencies`
  constraint updates, or any other change that does not impact calling code.

### Updating the Version

Whenever the code in the repo differs from the latest version published on
`pub.dev`, both `pubspec.yaml` and `CHANGELOG.md` must use a `-wip` version. We
bump to `-wip` on the _first_ change after a release, even if we don't plan on
publishing the code in that state or if the change doesn't impact consumers.

When opening or merging a PR, check the current version in `pubspec.yaml` and
`CHANGELOG.md`:

- **Currently at a published version**, such as `1.2.3`: Perform the appropriate
  version bump, append `-wip` in `pubspec.yaml`, and add a matching
  `## <version>-wip` section at the top of `CHANGELOG.md`.
- **Already at a `-wip` version**, such as `1.2.4-wip`: Compare the existing
  `-wip` bump against the bump required for your change. If your change requires
  a larger bump, such as from a _patch_ bump to a _minor_ bump when adding a
  feature, update `pubspec.yaml` and rename the existing `## <version>-wip`
  heading in `CHANGELOG.md` in place.
- **Not yet published to `pub.dev`**, at `0.1.0-wip`: Keep `0.1.0-wip` and the
  `- Initial release.` entry without adding per-PR changelog entries until after
  the first release.

### Updating `CHANGELOG.md`

- **User-visible changes**: Add an entry under the top `-wip` section.
- **Internal or non-user-visible changes**, such as safe refactorings, lint
  cleanups, `test/`, `tool/`, or `README.md` updates, or `dev_dependencies` and
  `dependency_overrides` changes:
  - If your PR creates the new `-wip` section, add the `## <version>-wip`
    heading with no bullet items below it.
  - If the package is already at a `-wip` version, leave `CHANGELOG.md`
    untouched and apply the `skip-changelog-check` PR label.
- **Follow-up edits to unreleased work**: If a subsequent PR modifies or reverts
  an unreleased change in the current `-wip` section, such as bumping an SDK or
  dependency constraint again before publishing, update or remove the existing
  `-wip` bullet in place instead of adding a duplicate entry.
- **Already-published sections**: Never add new entries under an
  already-published version heading, especially after merging `main` when a
  release landed while your PR was open.

### Breaking Changes

- Evaluate the impact on dependent packages and internal projects.
- Consider running changes through internal presubmits if possible.
- Prefer incremental rollouts (e.g., new behavior as opt-in) to minimize
  downstream breakage.

## Publishing Process

1. **Preparation**: Remove the `-wip` suffix from `pubspec.yaml` and
   `CHANGELOG.md` in a dedicated pull request.
2. **Execution**: Run `dart pub publish` (or `flutter pub publish`) and resolve
   all warnings and errors.
3. **Tagging**: Create and push a git tag for the published version:
   - For single-package repos: `v1.2.3`
   - For monorepos: `package_name-v1.2.3`
   - Example: `git tag v1.2.3 && git push --tags`

## Pull Request Management

- **Commits**: Each PR should generally correspond to a single squashed commit
  upon merging.
- **Shared History**: Once a PR is open, avoid force pushing to the branch.
- **Conflict Resolution**: Prefer merging `main` into the PR branch rather than
  rebasing to resolve conflicts. This preserves the review history and comments.
- **Reviewing**: Add comments from the "Files changed" view to batch them.
- **Local Inspection**: Use `gh pr checkout <number>` to inspect changes locally
  in your IDE.
