import '../context.dart';
import '../models.dart';
import '../rule.dart';

/// Discovery rule for identifying CLI entrypoints in `bin/` that use monolithic
/// ad-hoc `main()` functions instead of structured `CommandRunner` architectures.
///
/// **Target Skill**:
/// - GitHub: https://github.com/dart-lang/skills/tree/26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e/skills/dart-build-cli-app
class CliAppRule extends DiscoveryRule {
  const CliAppRule();

  @override
  String get id => 'build-cli-app';

  @override
  SkillTarget get target => const SkillTarget(
    org: 'dart-lang',
    repo: 'skills',
    path: 'skills/dart-build-cli-app',
    commitSha: '26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e',
  );

  @override
  String get category => 'CLI Architecture';

  @override
  Priority get defaultPriority => Priority.high;

  @override
  bool appliesTo(PackageContext context) => context.binFiles.isNotEmpty;

  @override
  Iterable<Opportunity> evaluate(PackageContext context) sync* {
    if (!appliesTo(context)) return;

    final nonRunnerFiles = <String>[];
    for (final file in context.binFiles) {
      final content = context.readContent(file);
      if (!content.contains('CommandRunner') &&
          !content.contains('command_runner.dart')) {
        nonRunnerFiles.add(context.relativePath(file));
      }
    }

    if (nonRunnerFiles.isNotEmpty) {
      yield Opportunity(
        target: target,
        category: category,
        priority: defaultPriority,
        diagnosis:
            '${nonRunnerFiles.length} CLI entrypoint(s) in bin/ use ad-hoc main() without CommandRunner.',
        prescription:
            'Structure CLI with `package:args/command_runner.dart` for standardized command hierarchy, POSIX exit codes, and stdout/stderr separation.',
        evidence: nonRunnerFiles,
      );
    }
  }
}
