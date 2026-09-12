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

  // Matches type cascades where at least two branches perform `is` checks:
  // Either `if (x is A) ... else if (x is B)`
  // Or `else if (x is A) ... else if (x is B)`
  static final _typeCascadePattern = RegExp(
    r'(?:\bif\s*\([^)]+\s+is\s+[^)]+\)[^{}]*\{[^{}]*\}\s*else\s+if\s*\([^)]+\s+is\s+[^)]+\)|else\s+if\s*\([^)]+\s+is\s+[^)]+\)[\s\S]*?else\s+if\s*\([^)]+\s+is\s+[^)]+\))',
  );

  // Switch statement where cases return values or throw (candidates for switch expressions):
  static final _returningSwitchPattern = RegExp(
    r'switch\s*\([^)]+\)\s*\{(?:[^{}]*?(?:case\s+[^:]+|default)\s*:\s*)+(?:return\s+[^;]+;|throw\s+[^;]+;)',
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
    if (_typeCascadePattern.hasMatch(content)) {
      return 'Legacy type cascade found';
    }
    if (_returningSwitchPattern.hasMatch(content)) {
      return 'Legacy returning switch statement found';
    }
    return null;
  }
}
