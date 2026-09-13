import 'dart:io';

import 'package:dash_discover/dash_discover.dart';

Future<void> main(List<String> args) async {
  exitCode = await runCli(args);
}
