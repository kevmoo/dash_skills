import 'dart:io';

import 'package:dash_discover/src/context.dart';
import 'package:dash_discover/src/rules/matcher_best_practices_rule.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('MatcherBestPracticesRule Heuristic Evaluation', () {
    const rule = MatcherBestPracticesRule();
    final fixturesDir = Directory(
      p.join(Directory.current.path, 'test', 'fixtures', 'matcher'),
    );

    test('flagged on positive suboptimal fixture (Recall)', () {
      final file = File(
        p.join(fixturesDir.path, 'positive_suboptimal_test.dart'),
      );
      final context = PackageContext.load(Directory.current.path);
      final result = rule.checkFile(file, file.readAsStringSync(), context);
      expect(result, isNotNull, reason: 'Must detect suboptimal matchers');
    });

    test('abstains on negative idiomatic fixture (Precision)', () {
      final file = File(
        p.join(fixturesDir.path, 'negative_idiomatic_test.dart'),
      );
      final context = PackageContext.load(Directory.current.path);
      final result = rule.checkFile(file, file.readAsStringSync(), context);
      expect(
        result,
        isNull,
        reason: 'Must not flag already-idiomatic matchers',
      );
    });

    test('analyzes non-collection assertion fixture', () {
      final file = File(
        p.join(fixturesDir.path, 'negative_non_collection_test.dart'),
      );
      final context = PackageContext.load(Directory.current.path);
      final result = rule.checkFile(file, file.readAsStringSync(), context);
      // Let's observe the behavior:
      print('Heuristic result on negative_non_collection_test.dart: $result');
    });
  });
}
