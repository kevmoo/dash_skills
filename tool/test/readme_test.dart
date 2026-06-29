import 'dart:io';
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

void main() {
  test('validate README.md is up-to-date with the latest skills', () async {
    final scriptPath = Directory.current.path.endsWith('tool')
        ? 'bin/readme.dart'
        : 'tool/bin/readme.dart';
    final process = await TestProcess.start(Platform.resolvedExecutable, [
      scriptPath,
      '--validate',
    ]);
    await process.shouldExit(0);
  });
}
