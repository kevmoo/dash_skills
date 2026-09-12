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

  // Matches collection boolean and membership checks:
  // e.g. expect(x.isEmpty, true), expect(x.contains('a'), true)
  static final _booleanOrContainsPattern = RegExp(
    r'expect\(\s*[^,]+?\.(?:isEmpty\b|isNotEmpty\b|contains\([^)]*\))\s*,',
  );

  // Matches .length checks and captures the expected argument for inspection:
  // e.g. expect(x.length, 3) or expect(x.length, equals(3))
  static final _lengthPattern = RegExp(
    r'expect\(\s*[^,]+?\.length\b\s*,\s*([^,)]+)',
  );

  // Checks if the expected argument is a floating-point number (e.g. 25.0 or equals(25.0)):
  static final _floatPattern = RegExp(r'^(?:equals\(\s*)?\d+\.\d+');

  // Matches map string key lookups:
  // e.g. expect(map['key'], value)
  static final _mapStringLookupPattern = RegExp(
    r'''expect\(\s*[^,]+?\[\s*['"][^'"]+['"]\s*\]\s*,''',
  );

  // Matches imperative try/catch blocks that use fail():
  // e.g. try { fn(); fail('should throw'); } catch (e) { ... }
  static final _tryCatchFailPattern = RegExp(
    r'\btry\s*\{[\s\S]*?\bfail\s*\([^;]*\);[\s\S]*?\}\s*(?:on\s+\w+\s*)?catch\b',
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
    if (_booleanOrContainsPattern.hasMatch(content) ||
        _mapStringLookupPattern.hasMatch(content) ||
        _tryCatchFailPattern.hasMatch(content)) {
      return 'Suboptimal expect() assertion found';
    }

    for (final match in _lengthPattern.allMatches(content)) {
      final expectedArg = match.group(1)?.trim() ?? '';
      if (!_floatPattern.hasMatch(expectedArg)) {
        return 'Suboptimal expect() assertion found';
      }
    }

    return null;
  }
}
