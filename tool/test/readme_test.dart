import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('validate README.md is up-to-date with the latest skills', () {
    final result = Process.runSync(
      'dart',
      ['bin/readme.dart', '--validate'],
    );
    expect(
      result.exitCode,
      0,
      reason:
          'README.md is out of date. Run `dart tool/bin/readme.dart --write` to update it.\n'
          'stdout:\n${result.stdout}\n'
          'stderr:\n${result.stderr}',
    );
  });
}
