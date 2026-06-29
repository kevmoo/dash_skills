import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('validate README.md is up-to-date with the latest skills', () async {
    final scriptPath = Directory.current.path.endsWith('tool')
        ? 'bin/readme.dart'
        : 'tool/bin/readme.dart';
    final result = await Process.run(Platform.resolvedExecutable, [
      scriptPath,
      '--validate',
    ]);
    expect(
      result.exitCode,
      0,
      reason:
          'README.md is out of date. Run dart tool/bin/readme.dart --write to update it.\n'
          'stdout:\n${result.stdout}\n'
          'stderr:\n${result.stderr}',
    );
  });
}
