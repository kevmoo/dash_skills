import 'dart:io';
import '../context.dart';
import '../models.dart';
import '../rule.dart';

/// Discovery rule for identifying raw string interpolation with hardcoded `/`
/// path separators that can cause Windows cross-platform bugs.
///
/// **Target Skill**:
/// - GitHub: https://github.com/dart-lang/skills/tree/26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e/skills/dart-use-path-package
final class PathPackageRule extends FileDiscoveryRule {
  const PathPackageRule();

  static final _pathInterpolationPattern = RegExp(
    r'''(?<![\w/])\$\{?[a-zA-Z0-9_.]+\}?/(?:lib|test|bin|src|[a-zA-Z0-9_-]+\.dart)''',
  );

  static final _fileOrDirInterpolationPattern = RegExp(
    r'''\b(?:File|Directory)\s*\(\s*['"][^'"]*?\$\{?[a-zA-Z0-9_.]+\}?''',
  );

  static final _mathDivisionInInterp = RegExp(r'\$\{[^}]*?\s/\s[^}]*?\}');

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
  RuleCategory get category => RuleCategory.platform;

  @override
  SkillLifecycle get lifecycle => SkillLifecycle.migration;

  @override
  String get description =>
      'Detects manual path string concatenation without package:path.';

  @override
  Confidence get defaultConfidence => Confidence.medium;

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
      if (trimmed.startsWith('//') ||
          trimmed.startsWith('/*') ||
          trimmed.startsWith('*')) {
        continue;
      }

      // Abstain on raw string literals (r'...' or r"...") where $ is not interpolated
      if (trimmed.contains("r'") || trimmed.contains('r"')) {
        continue;
      }

      // 1. Abstain on URLs, URIs, and schemes
      if (trimmed.contains('http://') ||
          trimmed.contains('https://') ||
          trimmed.contains('package:') ||
          trimmed.contains('file://') ||
          trimmed.contains('Uri.parse') ||
          trimmed.contains('Uri.http') ||
          trimmed.contains('Uri.https')) {
        continue;
      }

      // 2. Abstain on MIME headers
      if (trimmed.contains('application/') ||
          trimmed.contains('text/') ||
          trimmed.contains('multipart/')) {
        continue;
      }

      // 3. Abstain on math division inside interpolation: ${... / ...}
      if (_mathDivisionInInterp.hasMatch(trimmed)) {
        continue;
      }

      // 4. Abstain on API routes: '/api/...' or router.add('/...')
      if (trimmed.contains('/api/') || trimmed.contains('router.')) {
        continue;
      }

      // 5. Match positive path pattern
      if (_pathInterpolationPattern.hasMatch(trimmed)) {
        return 'Raw path string interpolation found';
      }

      // 6. Match explicit File/Directory constructors with string concatenation
      if (_fileOrDirInterpolationPattern.hasMatch(trimmed)) {
        return 'File or Directory instantiated with interpolated path string';
      }
    }
    return null;
  }
}
