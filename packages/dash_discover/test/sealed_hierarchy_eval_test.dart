import 'dart:io';

import 'package:dash_discover/src/context.dart';
import 'package:dash_discover/src/models.dart';
import 'package:dash_discover/src/rules/sealed_hierarchy_rule.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  const rule = SealedHierarchyRule();
  final fixturesDir = p.join(
    Directory.current.path,
    'test',
    'fixtures',
    'sealed_hierarchy',
  );

  group('SealedHierarchyRule', () {
    test('flags a closed hierarchy whose subtypes share a library', () {
      final context = PackageContext.load(
        p.join(fixturesDir, 'positive_closed'),
      );
      final opportunities = rule.evaluate(context).toList();

      expect(context.isUnpublished, isTrue);
      expect(opportunities, hasLength(1));
      expect(opportunities.single.affectedCount, 1);
      expect(opportunities.single.confidence, Confidence.high);
      expect(
        opportunities.single.prescription,
        isNot(contains('breaking change')),
      );
      expect(opportunities.single.evidence.single, contains('Shape'));
      expect(opportunities.single.evidence.single, contains('Circle'));
    });

    test(
      'distinguishes publish_to: none packages from published public APIs',
      () {
        final tempDir = Directory.systemTemp.createTempSync('sealed_pub_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        const hierarchySource = '''
abstract class Entity {}
class PackageEntity extends Entity {}
class RepoEntity extends Entity {}
''';
        final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
        File(
          p.join(libDir.path, 'api.dart'),
        ).writeAsStringSync(hierarchySource);

        File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: published_pkg
environment:
  sdk: ^3.5.0
''');
        final publishedCtx = PackageContext.load(tempDir.path);
        expect(publishedCtx.isUnpublished, isFalse);
        final publishedOpp = rule.evaluate(publishedCtx).single;
        expect(publishedOpp.confidence, Confidence.medium);
        expect(publishedOpp.prescription, contains('breaking change'));

        File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: internal_pkg
publish_to: none
environment:
  sdk: ^3.5.0
''');
        final unpublishedCtx = PackageContext.load(tempDir.path);
        expect(unpublishedCtx.isUnpublished, isTrue);
        final unpublishedOpp = rule.evaluate(unpublishedCtx).single;
        expect(unpublishedOpp.confidence, Confidence.high);
        expect(unpublishedOpp.prescription, isNot(contains('breaking change')));
      },
    );

    test('abstains on every negative case', () {
      final context = PackageContext.load(p.join(fixturesDir, 'negatives'));
      final opportunities = rule.evaluate(context).toList();

      expect(
        opportunities,
        isEmpty,
        reason:
            'Already-sealed, single-subtype, concrete-base, split-library and '
            'test-extended hierarchies must all be skipped. Reported: '
            '${opportunities.expand((o) => o.evidence).join('; ')}',
      );
    });
  });

  group('PackageFacts type graph', () {
    test('records subtype edges declared outside lib/', () {
      final context = PackageContext.load(p.join(fixturesDir, 'negatives'));
      final subtypes = context.facts.subtypesOf['Extended']!;

      expect(
        subtypes.map((s) => s.name),
        containsAll(<String>['ExtendedOne', 'ExtendedTwo', 'ExtendedThree']),
      );
      expect(
        subtypes
            .firstWhere((s) => s.name == 'ExtendedThree')
            .source
            .relativePath,
        startsWith('test/'),
        reason:
            'A subtype in test/ is what makes sealing a compile error, so it '
            'must appear in the graph even though it can never be a finding.',
      );
    });

    test('does not offer non-lib declarations as candidates', () {
      final context = PackageContext.load(p.join(fixturesDir, 'negatives'));

      expect(context.facts.typesByName.containsKey('ExtendedThree'), isFalse);
      expect(context.facts.auxiliarySources, isNotEmpty);
    });

    test('unitForFile reuses cached AST and parses modified strings', () {
      final context = PackageContext.load(
        p.join(fixturesDir, 'positive_closed'),
      );
      final onDiskFile = context.libFiles.single;
      final onDiskContent = onDiskFile.readAsStringSync();

      final cachedUnit = context.facts.unitForFile(onDiskFile, onDiskContent);
      expect(
        identical(cachedUnit, context.facts.librarySources.single.unit),
        isTrue,
      );

      final syntheticUnit = context.facts.unitForFile(
        File('test/synthetic_in_memory.dart'),
        'class SyntheticOnly {}',
      );
      expect(syntheticUnit.declarations, hasLength(1));
      expect(identical(syntheticUnit, cachedUnit), isFalse);
    });
  });
}
