import 'dart:io';

import 'package:dash_discover/src/context.dart';
import 'package:dash_discover/src/rules/path_package_rule.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('PathPackageRule Heuristic Evaluation', () {
    const rule = PathPackageRule();
    final fixturesDir = Directory(
      p.join(Directory.current.path, 'test', 'fixtures', 'path_package'),
    );

    test('flagged on positive raw path fixture (Recall)', () {
      final file = File(p.join(fixturesDir.path, 'positive_raw_path.dart'));
      final context = PackageContext.load(Directory.current.path);
      final result = rule.checkFile(file, file.readAsStringSync(), context);
      expect(result, isNotNull, reason: 'Must detect raw path interpolation');
    });

    test('abstains on negative idiomatic fixture (Precision)', () {
      final file = File(p.join(fixturesDir.path, 'negative_idiomatic.dart'));
      final context = PackageContext.load(Directory.current.path);
      final result = rule.checkFile(file, file.readAsStringSync(), context);
      expect(
        result,
        isNull,
        reason: 'Must not flag code already using package:path',
      );
    });

    test('abstains on negative abstention fixture (URLs, MIME, math)', () {
      final file = File(p.join(fixturesDir.path, 'negative_abstention.dart'));
      final context = PackageContext.load(Directory.current.path);
      final result = rule.checkFile(file, file.readAsStringSync(), context);
      expect(
        result,
        isNull,
        reason: 'Must not flag URLs, URIs, MIME types, routes, or division',
      );
    });

    test('detects File/Directory interpolation directly', () {
      const content = '''
import 'dart:io';
void main() {
  final f = File('\$dir/output.txt');
}
''';
      final file = File('test/isolated_file_interp.dart');
      final context = PackageContext.load(Directory.current.path);
      expect(rule.checkFile(file, content, context), isNotNull);
    });
  });
}
