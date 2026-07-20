import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

String _locateProfileScript() {
  final candidate1 = p.join(Directory.current.path, 'profile.dart');
  final candidate2 = p.join(Directory.current.path, 'bin', 'profile.dart');
  final candidate3 = p.join(
    Directory.current.path,
    'skills',
    'profile-dart-code',
    'scripts',
    'profile.dart',
  );
  final candidate4 = p.join(
    Directory.current.path,
    'skills',
    'profile-dart-code',
    'scripts',
    'bin',
    'profile.dart',
  );

  for (final candidate in [candidate1, candidate2, candidate3, candidate4]) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }
  throw StateError(
    'Could not locate profile.dart. Current directory: ${Directory.current.path}',
  );
}

void main() {
  test('profile script prints usage on --help', () async {
    final scriptPath = _locateProfileScript();
    final process = await TestProcess.start(Platform.resolvedExecutable, [
      scriptPath,
      '--help',
    ]);
    await process.shouldExit(0);
  });

  test(
    'profile script profiles a simple dummy target',
    () async {
      final scriptPath = _locateProfileScript();
      final tempDir = await Directory.systemTemp.createTemp('profile_test_');
      addTearDown(() => tempDir.delete(recursive: true));

      final dummyScript = File('${tempDir.path}/dummy.dart');
      await dummyScript.writeAsString('''
void main() {
  var sum = 0;
  for (var i = 0; i < 5000000; i++) {
    sum += i;
  }
}
''');

      final outJson = '${tempDir.path}/profile.json';
      final process = await TestProcess.start(Platform.resolvedExecutable, [
        scriptPath,
        '--out',
        outJson,
        '--',
        dummyScript.path,
      ]);
      await process.shouldExit(0);
      expect(File(outJson).existsSync(), isTrue);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
