import 'dart:io';
import '../context.dart';
import '../models.dart';
import '../rule.dart';

/// Discovery rule for identifying handwritten `Fake...` or `Mock...` classes
/// in test suites that should be automated via `@GenerateMocks` or `mocktail`.
///
/// **Target Skill**:
/// - GitHub: https://github.com/dart-lang/skills/tree/26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e/skills/dart-generate-test-mocks
class MockGenerationRule extends FileDiscoveryRule {
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
    commitSha: '26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e',
  );

  @override
  String get category => 'Testing Architecture';

  @override
  Priority get defaultPriority => Priority.medium;

  @override
  List<File> selectFiles(PackageContext context) => context.testFiles;

  @override
  String get diagnosisTemplate =>
      'Handwritten Fake/Mock class definitions found in {count} test file(s) without mockito or mocktail.';

  @override
  String get prescription =>
      'Automate test stubbing using `@GenerateMocks` or `mocktail` to avoid manual maintenance of interface stubs.';

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
