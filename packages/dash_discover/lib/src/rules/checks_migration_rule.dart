import '../context.dart';
import '../models.dart';
import '../rule.dart';

/// Discovery rule for identifying test suites that still use legacy
/// `package:test` matchers instead of fluent `package:checks`.
///
/// **Target Skill**:
/// - GitHub: https://github.com/dart-lang/skills/tree/26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e/skills/dart-migrate-to-checks-package
class ChecksMigrationRule extends DiscoveryRule {
  const ChecksMigrationRule();

  @override
  String get id => 'checks-migration';

  @override
  SkillTarget get target => const SkillTarget(
    org: 'dart-lang',
    repo: 'skills',
    path: 'skills/dart-migrate-to-checks-package',
    commitSha: '26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e',
  );

  @override
  String get category => 'Testing Architecture';

  @override
  String get description =>
      'Detects test or flutter_test in dependencies when checks is absent.';

  @override
  Priority get defaultPriority => Priority.high;

  @override
  bool appliesTo(PackageContext context) {
    final hasTest =
        context.hasDependency('test') || context.hasDependency('flutter_test');
    final hasChecks = context.hasDependency('checks');
    return hasTest && !hasChecks && context.testFiles.isNotEmpty;
  }

  @override
  Iterable<Opportunity> evaluate(PackageContext context) sync* {
    if (!appliesTo(context)) return;

    yield Opportunity(
      target: target,
      category: category,
      priority: defaultPriority,
      diagnosis:
          'Repository depends on `package:test` but does not use `package:checks`.',
      prescription:
          'Migrate test assertions from legacy `expect(actual, matcher)` to fluent, strongly-typed `check(actual)...` chains.',
      evidence: [
        'pubspec.yaml lacks checks dependency',
        ...context.testFiles.take(3).map(context.relativePath),
      ],
    );
  }
}
