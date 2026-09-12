import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import '../lib/src/discovery_engine.dart';
import '../lib/src/outline_generator.dart';
import '../lib/src/skills_catalog.dart';
import '../lib/src/static_discovery.dart';

void main() {
  final repoRoot = Directory.current.path.endsWith('tool')
      ? Directory.current.parent
      : Directory.current;

  group('SkillsCatalog', () {
    test('discovers skills in repo root', () {
      final catalog = SkillsCatalog.discover();
      expect(catalog.skills, isNotEmpty);
      expect(
        catalog.skills.map((s) => s.name),
        contains('dart-modern-features'),
      );
      final modern = catalog.skills.firstWhere(
        (s) => s.name == 'dart-modern-features',
      );
      expect(modern.description, isNotEmpty);
      expect(modern.keyFeatures, isNotEmpty);
    });

    test('formats prompt text', () {
      final catalog = SkillsCatalog.discover();
      final text = catalog.formatForPrompt();
      expect(text, contains('AVAILABLE SKILLS CATALOG'));
      expect(text, contains('dart-modern-features'));
    });
  });

  group('OutlineGenerator', () {
    test('generates outline for package', () {
      final generator = OutlineGenerator(repoRoot.path);
      final outline = generator.generate();
      expect(outline, contains('REPOSITORY OUTLINE'));
      expect(outline, contains('1. pubspec.yaml'));
      expect(outline, contains('2. Directory Structure'));
    });
  });

  group('StaticDiscoveryEngine', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('static_discovery_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('flags missing package:checks when package:test is used', () {
      File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: sample_pkg
environment:
  sdk: ^3.0.0
dev_dependencies:
  test: ^1.24.0
''');
      final testDir = Directory(p.join(tempDir.path, 'test'))..createSync();
      File(
        p.join(testDir.path, 'sample_test.dart'),
      ).writeAsStringSync('void main() {}');

      final engine = StaticDiscoveryEngine(tempDir.path);
      final opps = engine.scan();

      expect(
        opps.map((o) => o.skill),
        contains('dart-migrate-to-checks-package'),
      );
    });

    test('flags ad-hoc CLI entrypoints without CommandRunner', () {
      File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: cli_pkg
environment:
  sdk: ^3.0.0
''');
      final binDir = Directory(p.join(tempDir.path, 'bin'))..createSync();
      File(p.join(binDir.path, 'main.dart')).writeAsStringSync('''
void main(List<String> args) {
  print("hello");
}
''');

      final engine = StaticDiscoveryEngine(tempDir.path);
      final opps = engine.scan();

      expect(opps.map((o) => o.skill), contains('dart-build-cli-app'));
    });
  });

  group('DiscoveryEngine', () {
    test('runs complete discovery report', () {
      final engine = DiscoveryEngine(repoRoot.path);
      final report = engine.run();

      expect(report.packageName, isNotEmpty);
      expect(report.outline, contains('REPOSITORY OUTLINE'));
      expect(report.probePrompt, contains('Meta Skill Discovery Engine'));
      expect(report.toMarkdown(), contains('Meta-Skill Discovery Report'));
      expect(report.toJson(), containsPair('package_name', report.packageName));
    });
  });
}
