import 'dart:io';
import '../context.dart';
import '../models.dart';
import '../rule.dart';

/// Discovery rule for identifying unidiomatic `expect()` assertions in tests
/// (such as checking `.length`, `.isEmpty`, `.isNotEmpty`, or `.contains()`)
/// that should be migrated to first-class matchers.
///
/// **Target Skill**:
/// - GitHub: https://github.com/kevmoo/dash_skills/tree/main/skills/dart-matcher-best-practices
final class MatcherBestPracticesRule extends FileDiscoveryRule {
  const MatcherBestPracticesRule();

  static final _suboptimalMatcherPattern = RegExp(
    r'expect\(\s*[^,]+?\.(?:length\b|isEmpty\b|isNotEmpty\b|contains\([^)]*\))\s*,',
  );

  @override
  String get id => 'matcher-best-practices';

  @override
  SkillTarget get target => const SkillTarget(
    org: 'kevmoo',
    repo: 'dash_skills',
    path: 'skills/dart-matcher-best-practices',
  );

  @override
  RuleCategory get category => RuleCategory.testing;

  @override
  SkillLifecycle get lifecycle => SkillLifecycle.hygiene;

  @override
  String get description =>
      'Detects unidiomatic expect() assertions (e.g. expect(x.length, ...) or expect(x.isEmpty, true)).';

  @override
  Confidence get defaultConfidence => Confidence.high;

  @override
  bool appliesTo(PackageContext context) =>
      (context.hasDependency('test') ||
          context.hasDependency('flutter_test')) &&
      context.testFiles.isNotEmpty;

  @override
  List<File> selectFiles(PackageContext context) => context.testFiles;

  @override
  String get diagnosisTemplate =>
      '{count} test file(s) use suboptimal expect() assertions instead of dedicated matchers.';

  @override
  String get prescription =>
      'Migrate to first-class matchers (hasLength, isEmpty, isNotEmpty, contains) for clearer assertion failure messages.';

  @override
  String? checkFile(File file, String content, PackageContext context) {
    if (_suboptimalMatcherPattern.hasMatch(content)) {
      return 'Suboptimal expect() assertion found';
    }
    return null;
  }
}
