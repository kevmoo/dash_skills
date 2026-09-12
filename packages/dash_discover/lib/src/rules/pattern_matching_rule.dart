import 'dart:io';
import '../context.dart';
import '../models.dart';
import '../rule.dart';

/// Discovery rule for identifying legacy type cascades and statements that can
/// be modernized with Dart 3 pattern matching, switch expressions, and destructuring.
///
/// **Target Skill**:
/// - GitHub: https://github.com/dart-lang/skills/tree/26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e/skills/dart-use-pattern-matching
final class PatternMatchingRule extends FileDiscoveryRule {
  const PatternMatchingRule();

  static final _typeCascadePattern = RegExp(
    r'else\s+if\s*\([^)]+\s+is\s+[^)]+\)',
  );

  @override
  String get id => 'pattern-matching';

  @override
  SkillTarget get target => const SkillTarget(
    org: 'dart-lang',
    repo: 'skills',
    path: 'skills/dart-use-pattern-matching',
    commitSha: '26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e',
  );

  @override
  RuleCategory get category => RuleCategory.language;

  @override
  SkillLifecycle get lifecycle => SkillLifecycle.migration;

  @override
  String get description =>
      'Detects legacy else if (... is ...) type cascades and returning switch statements.';

  @override
  Confidence get defaultConfidence => Confidence.high;

  @override
  String get diagnosisTemplate =>
      '{count} file(s) use legacy `else if (... is ...)` type cascades or returning switch statements.';

  @override
  String get prescription =>
      'Refactor into concise Dart 3 switch expressions, sealed class exhaustiveness, and pattern destructuring.';

  @override
  String? checkFile(File file, String content, PackageContext context) {
    return _typeCascadePattern.hasMatch(content)
        ? 'Legacy type cascade found'
        : null;
  }
}
