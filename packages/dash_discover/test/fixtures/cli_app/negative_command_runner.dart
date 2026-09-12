import 'dart:io';
import 'package:args/command_runner.dart';

Future<void> main(List<String> args) async {
  final runner = CommandRunner<int>('tool', 'A tool description');
  exitCode = (await runner.run(args)) ?? 0;
}
