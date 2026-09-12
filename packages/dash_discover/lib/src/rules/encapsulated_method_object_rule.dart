import 'dart:io';
import '../context.dart';
import '../models.dart';
import '../rule.dart';

/// Discovery rule for identifying oversized methods with deeply nested closures
/// and bloated shared state that should be extracted into dedicated method objects.
///
/// **Target Skill**:
/// - GitHub: https://github.com/kevmoo/dash_skills/tree/main/skills/encapsulated-method-object
final class EncapsulatedMethodObjectRule extends FileDiscoveryRule {
  const EncapsulatedMethodObjectRule();

  @override
  String get id => 'encapsulated-method-object';

  @override
  SkillTarget get target => const SkillTarget(
    org: 'kevmoo',
    repo: 'dash_skills',
    path: 'skills/encapsulated-method-object',
  );

  @override
  RuleCategory get category => RuleCategory.codeQuality;

  @override
  SkillLifecycle get lifecycle => SkillLifecycle.hygiene;

  @override
  String get description =>
      'Detects oversized methods with deeply nested closures.';

  @override
  Confidence get defaultConfidence => Confidence.high;

  @override
  String get diagnosisTemplate =>
      'Large methods with complex nested closures found in {count} file(s).';

  @override
  String get prescription =>
      'Apply Encapsulated Method Object pattern: extract bloated closure state into a dedicated private class with focused private methods.';

  @override
  String? checkFile(File file, String content, PackageContext context) {
    if (content.length > 2000 &&
        content.contains(' Function(') &&
        (content.contains('forEach(') || content.contains('where('))) {
      final lines = content.split('\n');
      if (lines.length > 250) {
        return 'Oversized method with complex closure state found';
      }
    }
    return null;
  }
}
