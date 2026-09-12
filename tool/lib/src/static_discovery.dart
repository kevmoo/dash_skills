import 'dart:io';
import 'package:path/path.dart' as p;

enum Priority { high, medium, low }

class Opportunity {
  final String skill;
  final String category;
  final Priority priority;
  final String diagnosis;
  final String prescription;
  final List<String> evidence;

  const Opportunity({
    required this.skill,
    required this.category,
    required this.priority,
    required this.diagnosis,
    required this.prescription,
    required this.evidence,
  });

  Map<String, dynamic> toJson() => {
    'skill': skill,
    'category': category,
    'priority': priority.name.toUpperCase(),
    'diagnosis': diagnosis,
    'prescription': prescription,
    'evidence': evidence,
  };
}

/// Fast static heuristic scanner (<50ms) for latent modernization opportunities.
class StaticDiscoveryEngine {
  final String packagePath;

  StaticDiscoveryEngine(this.packagePath);

  List<Opportunity> scan() {
    final opportunities = <Opportunity>[];

    final pubspecFile = File(p.join(packagePath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      return opportunities;
    }

    final pubspecContent = pubspecFile.readAsStringSync();
    final libDir = Directory(p.join(packagePath, 'lib'));
    final testDir = Directory(p.join(packagePath, 'test'));
    final binDir = Directory(p.join(packagePath, 'bin'));

    // 1. dart-migrate-to-checks-package
    final hasTest =
        pubspecContent.contains('test:') ||
        pubspecContent.contains('flutter_test:');
    final hasChecks = pubspecContent.contains('checks:');
    if (hasTest && !hasChecks && testDir.existsSync()) {
      final testFiles = testDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('_test.dart'))
          .take(3)
          .map((f) => p.relative(f.path, from: packagePath))
          .toList();
      opportunities.add(
        Opportunity(
          skill: 'dart-migrate-to-checks-package',
          category: 'Testing Architecture',
          priority: Priority.high,
          diagnosis:
              'Repository depends on `package:test` but does not use `package:checks`.',
          prescription:
              'Migrate test assertions from legacy `expect(actual, matcher)` to fluent, strongly-typed `check(actual)...` chains.',
          evidence: ['pubspec.yaml lacks checks dependency', ...testFiles],
        ),
      );
    }

    // 2. dart-build-cli-app
    if (binDir.existsSync()) {
      final binFiles = binDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      final nonRunnerBinFiles = <String>[];
      for (final binFile in binFiles) {
        final content = binFile.readAsStringSync();
        if (!content.contains('CommandRunner') &&
            !content.contains('command_runner.dart')) {
          nonRunnerBinFiles.add(p.relative(binFile.path, from: packagePath));
        }
      }
      if (nonRunnerBinFiles.isNotEmpty) {
        opportunities.add(
          Opportunity(
            skill: 'dart-build-cli-app',
            category: 'CLI Architecture',
            priority: Priority.high,
            diagnosis:
                'CLI entrypoint(s) in bin/ use ad-hoc main() without CommandRunner.',
            prescription:
                'Structure CLI with `package:args/command_runner.dart` for standardized command hierarchy, POSIX exit codes, and stdout/stderr separation.',
            evidence: nonRunnerBinFiles,
          ),
        );
      }
    }

    // 3. Scan lib/ files for patterns
    if (libDir.existsSync()) {
      final libFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      final docExampleFiles = <String>[];
      final patternMatchingFiles = <String>[];
      final pathPackageFiles = <String>[];
      final methodObjectFiles = <String>[];

      final typeCascadePattern = RegExp(r'else\s+if\s*\([^)]+\s+is\s+[^)]+\)');
      final docExamplePattern = RegExp(r'///\s*```dart');
      final pathInterpolationPattern = RegExp(
        r'''(?<!['"/])\$\{?[a-zA-Z0-9_]+\}?/(?:lib|test|bin|src|[a-zA-Z0-9_-]+\.dart)''',
      );

      for (final file in libFiles) {
        final relPath = p.relative(file.path, from: packagePath);
        final content = file.readAsStringSync();

        // Check doc examples lacking {@example}
        if (docExamplePattern.hasMatch(content) &&
            !content.contains('{@example')) {
          docExampleFiles.add(relPath);
        }

        // Check legacy type cascades
        if (typeCascadePattern.hasMatch(content)) {
          patternMatchingFiles.add(relPath);
        }

        // Check raw path concatenation (avoiding comment lines)
        for (final line in content.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.startsWith('//') || trimmed.startsWith('/*')) continue;
          if (pathInterpolationPattern.hasMatch(trimmed) &&
              !trimmed.contains('http://') &&
              !trimmed.contains('https://')) {
            pathPackageFiles.add(relPath);
            break;
          }
        }

        // Check large functions with nested closures (proxy for method object)
        if (content.length > 2000 &&
            content.contains(' Function(') &&
            (content.contains('forEach(') || content.contains('where('))) {
          final lines = content.split('\n');
          if (lines.length > 250) {
            methodObjectFiles.add(relPath);
          }
        }
      }

      if (docExampleFiles.isNotEmpty) {
        opportunities.add(
          Opportunity(
            skill: 'dart-use-doc-examples',
            category: 'Documentation & Testing',
            priority: Priority.medium,
            diagnosis:
                '${docExampleFiles.length} file(s) contain unverified inline `/// ``` ` doc examples without `{@example}` integration.',
            prescription:
                'Extract doc code snippets to verified example files with region tags ({@example ...}) to prevent documentation code rot.',
            evidence: docExampleFiles.take(4).toList(),
          ),
        );
      }

      if (patternMatchingFiles.isNotEmpty) {
        opportunities.add(
          Opportunity(
            skill: 'dart-use-pattern-matching',
            category: 'Dart 3 Language Idioms',
            priority: Priority.high,
            diagnosis:
                '${patternMatchingFiles.length} file(s) use legacy `else if (... is ...)` type cascades or returning switch statements.',
            prescription:
                'Refactor into concise Dart 3 switch expressions, sealed class exhaustiveness, and pattern destructuring.',
            evidence: patternMatchingFiles.take(4).toList(),
          ),
        );
      }

      if (pathPackageFiles.isNotEmpty) {
        opportunities.add(
          Opportunity(
            skill: 'dart-use-path-package',
            category: 'Cross-Platform Robustness',
            priority: Priority.high,
            diagnosis:
                'Raw string interpolation with hardcoded `/` path separators found in ${pathPackageFiles.length} file(s).',
            prescription:
                'Adopt `package:path` (`p.join`, `p.normalize`) to ensure cross-platform Windows compatibility and prevent path traversal bugs.',
            evidence: pathPackageFiles.take(4).toList(),
          ),
        );
      }

      if (methodObjectFiles.isNotEmpty) {
        opportunities.add(
          Opportunity(
            skill: 'encapsulated-method-object',
            category: 'Refactoring & Readability',
            priority: Priority.medium,
            diagnosis:
                'Large methods with complex closures found in ${methodObjectFiles.length} file(s).',
            prescription:
                'Apply Encapsulated Method Object pattern: extract bloated closure state into a dedicated private class with focused private methods.',
            evidence: methodObjectFiles.take(4).toList(),
          ),
        );
      }
    }

    // 4. Scan test/ for handwritten mocks
    if (testDir.existsSync()) {
      final testFiles = testDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('_test.dart'))
          .toList();
      final mockStubFiles = <String>[];
      final fakeClassPattern = RegExp(
        r'class\s+(?:Fake|Mock)[a-zA-Z0-9_]+\s+implements',
      );
      for (final testFile in testFiles) {
        final content = testFile.readAsStringSync();
        if (fakeClassPattern.hasMatch(content) &&
            !content.contains('package:mockito') &&
            !content.contains('package:mocktail')) {
          mockStubFiles.add(p.relative(testFile.path, from: packagePath));
        }
      }
      if (mockStubFiles.isNotEmpty) {
        opportunities.add(
          Opportunity(
            skill: 'dart-generate-test-mocks',
            category: 'Testing Architecture',
            priority: Priority.medium,
            diagnosis:
                'Handwritten Fake/Mock class definitions found in ${mockStubFiles.length} test file(s) without mockito or mocktail.',
            prescription:
                'Automate test stubbing using `@GenerateMocks` or `mocktail` to avoid manual maintenance of interface stubs.',
            evidence: mockStubFiles.take(4).toList(),
          ),
        );
      }
    }

    return opportunities;
  }
}
