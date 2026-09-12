import 'dart:io';
import '../context.dart';
import '../models.dart';
import '../rule.dart';

/// Discovery rule for identifying unverified inline markdown code examples in
/// doc comments that are vulnerable to code rot.
///
/// **Target Skill**:
/// - GitHub: https://github.com/dart-lang/skills/tree/26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e/skills/dart-use-doc-examples
final class DocExamplesRule extends FileDiscoveryRule {
  const DocExamplesRule();

  static final _docExamplePattern = RegExp(r'///\s*```dart');

  @override
  String get id => 'doc-examples';

  @override
  SkillTarget get target => const SkillTarget(
    org: 'dart-lang',
    repo: 'skills',
    path: 'skills/dart-use-doc-examples',
    commitSha: '26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e',
  );

  @override
  RuleCategory get category => RuleCategory.documentation;

  @override
  SkillLifecycle get lifecycle => SkillLifecycle.hygiene;

  @override
  String get description =>
      'Detects markdown code blocks in doc comments lacking {@example} integration.';

  @override
  Confidence get defaultConfidence => Confidence.medium;

  @override
  String get diagnosisTemplate =>
      '{count} file(s) contain unverified inline `/// ``` ` doc examples without `{@example}` integration.';

  @override
  String get prescription =>
      'Extract doc code snippets to verified example files with region tags ({@example ...}) to prevent documentation code rot.';

  @override
  String? checkFile(File file, String content, PackageContext context) {
    if (_docExamplePattern.hasMatch(content) &&
        !content.contains('{@example')) {
      return 'Unverified inline doc example found';
    }
    return null;
  }
}
