import 'dart:io';
import '../context.dart';
import '../models.dart';
import '../rule.dart';

/// Discovery rule for identifying handwritten `Fake...` or `Mock...` classes
/// in test suites that should be automated via `@GenerateMocks` or `mocktail`.
///
/// **Target Skill**:
/// - GitHub: https://github.com/dart-lang/skills/tree/bf984f3ef223dd85e92036f934bbcb6bf301e4ce/skills/dart-generate-test-mocks
final class MockGenerationRule extends FileDiscoveryRule {
  const MockGenerationRule();

  static final _fakeClassPattern = RegExp(
    r'class\s+(?:Fake|Mock)[a-zA-Z0-9_]+\s+implements',
  );

  @override
  String get id => 'generate-test-mocks';

  @override
  SkillTarget get target => const SkillTarget(
    org: 'dart-lang',
    repo: 'skills',
    path: 'skills/dart-generate-test-mocks',
    commitSha: 'bf984f3ef223dd85e92036f934bbcb6bf301e4ce',
  );

  @override
  RuleCategory get category => RuleCategory.testing;

  @override
  SkillLifecycle get lifecycle => SkillLifecycle.architecture;

  @override
  RuleTrigger get trigger => RuleTrigger.capability;

  @override
  String get description =>
      'Detects handwritten fake or mock class definitions without mockito '
      'or mocktail.';

  @override
  Confidence get defaultConfidence => Confidence.medium;

  @override
  List<File> selectFiles(PackageContext context) => context.testFiles;

  @override
  String get diagnosisTemplate =>
      'Handwritten Fake/Mock class definitions found in {count} test file(s) without mockito or mocktail.';

  @override
  String get prescription =>
      'Automate test stubbing using `@GenerateMocks` or `mocktail` to avoid '
      'manual maintenance of interface stubs.';

  @override
  String? checkFile(File file, String content, PackageContext context) {
    if (_fakeClassPattern.hasMatch(content) &&
        !content.contains('package:mockito') &&
        !content.contains('package:mocktail')) {
      return 'Handwritten Fake/Mock stub found';
    }
    return null;
  }
}
