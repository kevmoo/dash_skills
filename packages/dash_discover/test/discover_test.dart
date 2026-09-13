import 'dart:io';
import 'package:dash_discover/dash_discover.dart';
import 'package:dash_discover/src/outline_generator.dart';
import 'package:dash_discover/src/skills_catalog.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Directory _findRepoRoot(Directory start) {
  var dir = start.absolute;
  while (dir.path != dir.parent.path) {
    if (Directory(p.join(dir.path, 'skills')).existsSync()) {
      return dir;
    }
    dir = dir.parent;
  }
  return start;
}

void main() {
  final repoRoot = _findRepoRoot(Directory.current);

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

    test('finds skills by name', () {
      final catalog = SkillsCatalog.discover();
      expect(catalog.findByName('dart-modern-features'), isNotNull);
      expect(catalog.findByName('non-existent-skill-12345'), isNull);
    });

    test('formats prompt text', () {
      final catalog = SkillsCatalog.discover();
      final text = catalog.formatForPrompt();
      expect(text, contains('AVAILABLE SKILLS CATALOG'));
      expect(text, contains('dart-modern-features'));
    });
  });

  group('SkillTarget resolution', () {
    test('defaults to remote githubUrl when localPath is null', () {
      const target = SkillTarget(
        org: 'dart-lang',
        repo: 'skills',
        path: 'skills/dart-use-path-package',
        commitSha: '26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e',
      );

      expect(target.isLocal, isFalse);
      expect(target.localPath, isNull);
      expect(
        target.githubUrl.toString(),
        'https://github.com/dart-lang/skills/tree/26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e/skills/dart-use-path-package',
      );
      expect(target.resolvedUri, equals(target.githubUrl));

      final json = target.toJson();
      expect(json['is_local'], isFalse);
      expect(json['resolved_uri'], target.githubUrl.toString());
      expect(json.containsKey('local_path'), isFalse);
    });

    test('resolves to file:// URI when localPath is provided', () {
      const target = SkillTarget(
        org: 'kevmoo',
        repo: 'dash_skills',
        path: 'skills/dart-matcher-best-practices',
        localPath: '/path/to/SKILL.md',
      );

      expect(target.isLocal, isTrue);
      expect(target.localPath, '/path/to/SKILL.md');
      expect(target.resolvedUri.scheme, 'file');
      expect(target.resolvedUri.toFilePath(), '/path/to/SKILL.md');

      final json = target.toJson();
      expect(json['is_local'], isTrue);
      expect(json['local_path'], '/path/to/SKILL.md');
      expect(json['resolved_uri'], 'file:///path/to/SKILL.md');
    });

    test('withLocalPath creates updated target copy', () {
      const target = SkillTarget(
        org: 'dart-lang',
        repo: 'skills',
        path: 'skills/test',
      );
      final updated = target.withLocalPath('/local/test/SKILL.md');

      expect(target.isLocal, isFalse);
      expect(updated.isLocal, isTrue);
      expect(updated.localPath, '/local/test/SKILL.md');
      expect(updated.org, target.org);
      expect(updated.repo, target.repo);
      expect(updated.path, target.path);
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
      expect(opps.single.category, RuleCategory.testing);
      expect(opps.single.lifecycle, SkillLifecycle.migration);
      expect(opps.single.confidence, Confidence.high);
      expect(opps.single.affectedCount, 1);
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

    test(
      'MatcherBestPracticesRule detects suboptimal expect() calls in test files',
      () {
        File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: sample_test_pkg
environment:
  sdk: ^3.0.0
dev_dependencies:
  test: ^1.24.0
''');
        final testDir = Directory(p.join(tempDir.path, 'test'))..createSync();
        File(p.join(testDir.path, 'sample_test.dart')).writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('sample', () {
    final list = [1, 2, 3];
    expect(list.length, 3);
    expect(list.isEmpty, true);
  });
}
''');

        final context = PackageContext.load(tempDir.path);
        final rule = MatcherBestPracticesRule();

        expect(rule.appliesTo(context), isTrue);
        final opps = rule.evaluate(context).toList();

        expect(opps, hasLength(1));
        expect(opps.single.skill, 'dart-matcher-best-practices');
        expect(opps.single.target.org, 'kevmoo');
        expect(opps.single.category, RuleCategory.testing);
        expect(opps.single.lifecycle, SkillLifecycle.hygiene);
        expect(opps.single.confidence, Confidence.high);
      },
    );
  });

  group('DiscoveryEngine & Registry', () {
    test('defaultDiscoveryRules contains all 7 rules', () {
      expect(defaultDiscoveryRules, hasLength(7));
      final ids = defaultDiscoveryRules.map((r) => r.id).toSet();
      expect(ids, contains('checks-migration'));
      expect(ids, contains('pattern-matching'));
      expect(ids, contains('build-cli-app'));
      expect(ids, contains('use-path-package'));
      expect(ids, contains('generate-test-mocks'));
      expect(ids, contains('matcher-best-practices'));
      expect(ids, contains('seal-type-hierarchies'));
    });

    test('all rules define valid category and lifecycle metadata', () {
      for (final rule in defaultDiscoveryRules) {
        expect(rule.category, isA<RuleCategory>());
        expect(rule.lifecycle, isA<SkillLifecycle>());
        expect(rule.defaultConfidence, isA<Confidence>());
        expect(rule.description, isNotEmpty);
      }
    });

    test(
      'all rules can be instantiated as const with identity canonicalization',
      () {
        const rule1 = ChecksMigrationRule();
        const rule2 = ChecksMigrationRule();
        expect(identical(rule1, rule2), isTrue);

        const constSet = <DiscoveryRule>{
          ChecksMigrationRule(),
          PatternMatchingRule(),
          CliAppRule(),
          PathPackageRule(),
          MockGenerationRule(),
          MatcherBestPracticesRule(),
          SealedHierarchyRule(),
        };
        expect(constSet, hasLength(7));
      },
    );

    test('Opportunity sorts by lifecycle, confidence, and affectedCount', () {
      const target = SkillTarget(
        org: 'dart-lang',
        repo: 'skills',
        path: 'skills/test',
      );
      const oppMigrationHigh = Opportunity(
        target: target,
        category: RuleCategory.testing,
        lifecycle: SkillLifecycle.migration,
        confidence: Confidence.high,
        affectedCount: 5,
        diagnosis: 'd',
        prescription: 'p',
        evidence: [],
      );
      const oppMigrationLow = Opportunity(
        target: target,
        category: RuleCategory.testing,
        lifecycle: SkillLifecycle.migration,
        confidence: Confidence.low,
        affectedCount: 20,
        diagnosis: 'd',
        prescription: 'p',
        evidence: [],
      );
      const oppArchitectureHigh = Opportunity(
        target: target,
        category: RuleCategory.cli,
        lifecycle: SkillLifecycle.architecture,
        confidence: Confidence.high,
        affectedCount: 1,
        diagnosis: 'd',
        prescription: 'p',
        evidence: [],
      );
      const oppHygieneHighMany = Opportunity(
        target: target,
        category: RuleCategory.codeQuality,
        lifecycle: SkillLifecycle.hygiene,
        confidence: Confidence.high,
        affectedCount: 50,
        diagnosis: 'd',
        prescription: 'p',
        evidence: [],
      );
      const oppHygieneHighFew = Opportunity(
        target: target,
        category: RuleCategory.codeQuality,
        lifecycle: SkillLifecycle.hygiene,
        confidence: Confidence.high,
        affectedCount: 2,
        diagnosis: 'd',
        prescription: 'p',
        evidence: [],
      );

      final list = [
        oppHygieneHighFew,
        oppArchitectureHigh,
        oppHygieneHighMany,
        oppMigrationLow,
        oppMigrationHigh,
      ]..sort();

      expect(list, [
        oppMigrationHigh,
        oppMigrationLow,
        oppArchitectureHigh,
        oppHygieneHighMany,
        oppHygieneHighFew,
      ]);
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

    test('resolves local skill targets when installed in catalog', () {
      final temp = Directory.systemTemp.createTempSync('discovery_test_');
      addTearDown(() => temp.deleteSync(recursive: true));

      File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('''
name: mock_pkg
environment:
  sdk: ^3.5.0
dev_dependencies:
  test: ^1.25.0
''');
      final testDir = Directory(p.join(temp.path, 'test'))..createSync();
      File(p.join(testDir.path, 'foo_test.dart')).writeAsStringSync('''
import 'package:test/test.dart';
void main() {
  test('bad matcher', () {
    expect(items.length, 5);
  });
}
''');

      final catalog = SkillsCatalog.discover(workingDirectory: repoRoot);
      final engine = DiscoveryEngine(
        temp.path,
        catalog: catalog,
        rules: const [MatcherBestPracticesRule()],
      );
      final report = engine.run();

      expect(report.staticOpportunities, hasLength(1));
      final opp = report.staticOpportunities.first;
      expect(opp.skill, equals('dart-matcher-best-practices'));
      expect(opp.target.isLocal, isTrue);
      expect(opp.target.localPath, isNotNull);
      expect(opp.target.resolvedUri.scheme, equals('file'));
      expect(File(opp.target.localPath!).existsSync(), isTrue);
      expect(report.toMarkdown(), contains('Local file'));
    });

    test('falls back to remote githubUrl when skill is not in catalog', () {
      final temp = Directory.systemTemp.createTempSync(
        'discovery_fallback_test_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('''
name: mock_pkg
environment:
  sdk: ^3.5.0
dev_dependencies:
  test: ^1.25.0
''');
      final testDir = Directory(p.join(temp.path, 'test'))..createSync();
      File(p.join(testDir.path, 'foo_test.dart')).writeAsStringSync('''
import 'package:test/test.dart';
void main() {
  test('bad matcher', () {
    expect(items.length, 5);
  });
}
''');

      final emptyCatalog = SkillsCatalog(const []);
      final engine = DiscoveryEngine(
        temp.path,
        catalog: emptyCatalog,
        rules: const [MatcherBestPracticesRule()],
      );
      final report = engine.run();

      expect(report.staticOpportunities, hasLength(1));
      final opp = report.staticOpportunities.first;
      expect(opp.target.isLocal, isFalse);
      expect(opp.target.localPath, isNull);
      expect(opp.target.resolvedUri.scheme, equals('https'));
      expect(report.toMarkdown(), contains('Remote GitHub'));
    });
  });

  group('SKILL.md documentation synchronization', () {
    test('generateDiscoveryRulesBlock formats all rules and descriptions', () {
      final block = generateDiscoveryRulesBlock();
      expect(block, startsWith(discoveryRulesStartTag));
      expect(block, endsWith(discoveryRulesEndTag));
      expect(block, contains('across 7 built-in rules:'));
      for (final rule in defaultDiscoveryRules) {
        expect(block, contains(rule.category.label));
        expect(block, contains(rule.target.skillName));
        expect(block, contains(rule.description));
      }
    });

    test('skills/dash-discover/SKILL.md is in sync with defaultDiscoveryRules', () {
      final skillFile = findSkillFile(repoRoot);
      expect(
        skillFile,
        isNotNull,
        reason:
            'Could not find skills/dash-discover/SKILL.md in repo root: ${repoRoot.path}',
      );
      final content = skillFile!.readAsStringSync();
      final updated = updateSkillContent(content);
      expect(
        content,
        equals(updated),
        reason:
            'skills/dash-discover/SKILL.md is out of date with defaultDiscoveryRules.\n'
            'Run `dart run dash_discover --update-skill` to update it.',
      );
    });
  });
}
