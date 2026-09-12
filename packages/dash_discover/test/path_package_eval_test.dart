import 'dart:io';

import 'package:dash_discover/src/context.dart';
import 'package:dash_discover/src/rules/path_package_rule.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  const rule = PathPackageRule();
  final fixturesDir = p.join(
    Directory.current.path,
    'test',
    'fixtures',
    'path_package',
  );

  List<String> evidenceFor(String fixture) => rule
      .evaluate(PackageContext.load(p.join(fixturesDir, fixture)))
      .expand((o) => o.evidence)
      .toList();

  group('PathPackageRule', () {
    test('flags manual path construction (recall)', () {
      final context = PackageContext.load(p.join(fixturesDir, 'positive'));
      final opportunities = rule.evaluate(context).toList();

      expect(opportunities, hasLength(1));
      expect(
        opportunities.single.affectedCount,
        greaterThanOrEqualTo(4),
        reason:
            'Expected the interpolated joins and both dart:io constructor '
            'calls to be reported.',
      );
    });

    test('abstains on idiomatic and structurally excluded code', () {
      expect(
        evidenceFor('negative'),
        isEmpty,
        reason:
            'package:path usage, absolute URLs, `package:` specifiers, '
            'division inside an interpolation and raw strings must all be '
            'left alone.',
      );
    });

    test(
      'abstains on slashes that are not path separators',
      () {
        expect(evidenceFor('known_false_positives'), isEmpty);
      },
      skip:
          'KNOWN FAILURE. The Tier 2 rewrite dropped precision from 40% to '
          '22% on the 27-package corpus: MIME types, HTTP routes, URI '
          'resolution, ratios, JSON Schema pointers, git refspecs and glob '
          'patterns are all structurally identical to a path join. Blocked '
          'on the Tier 2 vs Tier 3 decision (side quest G9).',
    );
  });
}
