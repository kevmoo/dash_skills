import 'dart:io';
import '../context.dart';
import '../models.dart';
import '../rule.dart';

/// Discovery rule for identifying raw string interpolation with hardcoded `/`
/// path separators that can cause Windows cross-platform bugs.
///
/// **Target Skill**:
/// - GitHub: https://github.com/dart-lang/skills/tree/26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e/skills/dart-use-path-package
class PathPackageRule extends FileDiscoveryRule {
  static final _pathInterpolationPattern = RegExp(
    r'''(?<!['"/])\$\{?[a-zA-Z0-9_]+\}?/(?:lib|test|bin|src|[a-zA-Z0-9_-]+\.dart)''',
  );

  @override
  String get id => 'use-path-package';

  @override
  SkillTarget get target => const SkillTarget(
    org: 'dart-lang',
    repo: 'skills',
    path: 'skills/dart-use-path-package',
    commitSha: '26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e',
  );

  @override
  String get category => 'Cross-Platform Robustness';

  @override
  Priority get defaultPriority => Priority.high;

  @override
  String get diagnosisTemplate =>
      'Raw string interpolation with hardcoded `/` path separators found in {count} file(s).';

  @override
  String get prescription =>
      'Adopt `package:path` (`p.join`, `p.normalize`) to ensure cross-platform Windows compatibility and prevent path traversal bugs.';

  @override
  String? checkFile(File file, String content, PackageContext context) {
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('//') || trimmed.startsWith('/*')) continue;
      if (_pathInterpolationPattern.hasMatch(trimmed) &&
          !trimmed.contains('http://') &&
          !trimmed.contains('https://')) {
        return 'Raw path string interpolation found';
      }
    }
    return null;
  }
}
