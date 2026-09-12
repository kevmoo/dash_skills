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

    test(
      'abstains on negative non-collection assertion fixture (Precision)',
      () {
        final file = File(
          p.join(fixturesDir.path, 'negative_non_collection_test.dart'),
        );
        final context = PackageContext.load(Directory.current.path);
        final result = rule.checkFile(file, file.readAsStringSync(), context);
        expect(
          result,
          isNull,
          reason: 'Must not flag floating-point length or scalar assertions',
        );
      },
    );

    test('flags isolated map string key indexing', () {
      const content = '''
import 'package:test/test.dart';
void main() {
  test('headers', () {
    expect(headers['content-type'], 'text/html');
  });
}
''';
      final file = File('test/isolated_map_test.dart');
      final context = PackageContext.load(Directory.current.path);
      expect(rule.checkFile(file, content, context), isNotNull);
    });

    test('abstains on valid list integer indexing', () {
      const content = '''
import 'package:test/test.dart';
void main() {
  test('first item', () {
    expect(items[0], 'apple');
  });
}
''';
      final file = File('test/isolated_list_test.dart');
      final context = PackageContext.load(Directory.current.path);
      expect(rule.checkFile(file, content, context), isNull);
    });

    test('flags isolated imperative try/catch with fail()', () {
      const content = '''
import 'package:test/test.dart';
void main() {
  test('throws', () {
    try {
      parse('invalid');
      fail('expected exception');
    } catch (e) {
      expect(e, isA<FormatException>());
    }
  });
}
''';
      final file = File('test/isolated_try_catch_test.dart');
      final context = PackageContext.load(Directory.current.path);
      expect(rule.checkFile(file, content, context), isNotNull);
    });
  });
}
