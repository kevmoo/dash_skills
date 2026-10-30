import '../context.dart';
import '../models.dart';
import '../rule.dart';

/// Discovery rule for identifying test suites that still use legacy
/// `package:test` matchers instead of fluent `package:checks`.
///
/// **Target Skill**:
/// - GitHub: https://github.com/dart-lang/skills/tree/bf984f3ef223dd85e92036f934bbcb6bf301e4ce/skills/dart-migrate-to-checks-package
final class ChecksMigrationRule extends DiscoveryRule {
  const ChecksMigrationRule();

  @override
  String get id => 'checks-migration';

  @override
  SkillTarget get target => const SkillTarget(
    org: 'dart-lang',
    repo: 'skills',
    path: 'skills/dart-migrate-to-checks-package',
    commitSha: 'bf984f3ef223dd85e92036f934bbcb6bf301e4ce',
  );

  @override
  RuleCategory get category => RuleCategory.testing;

  @override
  SkillLifecycle get lifecycle => SkillLifecycle.migration;

  @override
  RuleTrigger get trigger => RuleTrigger.alternative;

  @override
  String get description =>
      'Detects test or flutter_test in dependencies when checks is absent.';

  @override
  Confidence get defaultConfidence => Confidence.high;

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
      lifecycle: lifecycle,
      trigger: trigger,
      confidence: defaultConfidence,
      affectedCount: context.testFiles.length,
      diagnosis:
          'Repository depends on `package:test` but does not use '
          '`package:checks`.',
      prescription:
          'Migrate test assertions from legacy `expect(actual, matcher)` to '
          'fluent, strongly-typed `check(actual)...` chains.',
      evidence: [
        'pubspec.yaml lacks checks dependency',
        ...context.testFiles.take(3).map(context.relativePath),
      ],
    );
  }
}
