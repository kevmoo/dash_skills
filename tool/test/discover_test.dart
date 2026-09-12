import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import '../lib/src/discovery_engine.dart';
import '../lib/src/outline_generator.dart';
import '../lib/src/rules/checks_migration_rule.dart';
import '../lib/src/rules/cli_app_rule.dart';
import '../lib/src/rules/doc_examples_rule.dart';
import '../lib/src/rules/pattern_matching_rule.dart';
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

  group('Individual Discovery Rules', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('rule_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('ChecksMigrationRule declares unambiguous upstream GitHub target', () {
      final rule = ChecksMigrationRule();
      expect(rule.target.org, 'dart-lang');
      expect(rule.target.repo, 'skills');
      expect(rule.target.path, 'skills/dart-migrate-to-checks-package');
      expect(rule.target.commitSha, isNotNull);
      expect(
        rule.target.githubUrl.toString(),
        contains('github.com/dart-lang/skills/tree/${rule.target.commitSha}'),
      );
    });

    test('ChecksMigrationRule evaluates in-memory context', () {
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

      final context = PackageContext.load(tempDir.path);
      final rule = ChecksMigrationRule();

      expect(rule.appliesTo(context), isTrue);
      final opps = rule.evaluate(context).toList();
      expect(opps, hasLength(1));
      expect(opps.single.skill, 'dart-migrate-to-checks-package');
      expect(opps.single.target.org, 'dart-lang');
    });

    test('CliAppRule flags ad-hoc CLI entrypoints without CommandRunner', () {
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

      final context = PackageContext.load(tempDir.path);
      final rule = CliAppRule();

      expect(rule.appliesTo(context), isTrue);
      final opps = rule.evaluate(context).toList();
      expect(opps, hasLength(1));
      expect(opps.single.skill, 'dart-build-cli-app');
    });

    test(
      'PatternMatchingRule detects legacy type cascades in source files',
      () {
        final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
        File(p.join(libDir.path, 'source.dart')).writeAsStringSync('''
void parse(Object x) {
  if (x is int) {
    print("int");
  } else if (x is String) {
    print("string");
  }
}
''');

        final context = PackageContext.load(tempDir.path);
        final rule = PatternMatchingRule();
        final opps = rule.evaluate(context).toList();

        expect(opps, hasLength(1));
        expect(opps.single.skill, 'dart-use-pattern-matching');
      },
    );

    test('DocExamplesRule detects unverified inline doc examples', () {
      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
      File(p.join(libDir.path, 'source.dart')).writeAsStringSync('''
/// ```dart
/// var x = 1;
/// ```
void foo() {}
''');

      final context = PackageContext.load(tempDir.path);
      final rule = DocExamplesRule();
      final opps = rule.evaluate(context).toList();

      expect(opps, hasLength(1));
      expect(opps.single.skill, 'dart-use-doc-examples');
    });
  });

  group('DiscoveryEngine & Registry', () {
    test('defaultDiscoveryRules contains all 7 rules', () {
      expect(defaultDiscoveryRules, hasLength(7));
      final ids = defaultDiscoveryRules.map((r) => r.id).toSet();
      expect(ids, contains('checks-migration'));
      expect(ids, contains('pattern-matching'));
      expect(ids, contains('doc-examples'));
      expect(ids, contains('build-cli-app'));
      expect(ids, contains('use-path-package'));
      expect(ids, contains('generate-test-mocks'));
      expect(ids, contains('encapsulated-method-object'));
    });

    test('runs complete discovery report on package', () {
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
