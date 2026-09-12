import 'dart:io';

import 'package:dash_discover/src/context.dart';
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

      expect(opportunities, hasLength(1));
      expect(opportunities.single.affectedCount, 1);
      expect(opportunities.single.evidence.single, contains('Shape'));
      expect(opportunities.single.evidence.single, contains('Circle'));
    });

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
  });
}
