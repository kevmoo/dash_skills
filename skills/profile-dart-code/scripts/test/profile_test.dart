import 'dart:io';
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

void main() {
  test('profile script prints usage on --help', () async {
    final process = await TestProcess.start(Platform.resolvedExecutable, [
      'profile.dart',
      '--help',
    ]);
    await process.shouldExit(0);
  });

  test('profile script profiles a simple dummy target', () async {
    final tempDir = await Directory.systemTemp.createTemp('profile_test_');
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
      'profile.dart',
      '--out',
      outJson,
      '--',
      dummyScript.path,
    ]);
    await process.shouldExit(0);
    expect(File(outJson).existsSync(), isTrue);
    await tempDir.delete(recursive: true);
  }, timeout: const Timeout(Duration(minutes: 1)));
}
