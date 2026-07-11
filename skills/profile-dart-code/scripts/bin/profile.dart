import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'out',
      abbr: 'o',
      defaultsTo: 'cpu_profile.json',
      help: 'Path to save the JSON CPU profile output.',
    )
    ..addOption(
      'period',
      abbr: 'p',
      defaultsTo: '1000',
      help: 'Sampling period in microseconds (minimum 50).',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print usage instructions.',
    );

  final results = parser.parse(arguments);
  if (results['help'] as bool || results.rest.isEmpty) {
    print('Usage: dart profile.dart [options] -- <target.dart> [args...]');
    print(parser.usage);
    exit(results['help'] as bool ? 0 : 64);
  }

  final outPath = results['out'] as String;
  final period = int.tryParse(results['period'] as String) ?? 1000;
  final targetScript = results.rest.first;
  final targetArgs = results.rest.sublist(1);

  if (!File(targetScript).existsSync()) {
    print('Error: Target script not found at $targetScript');
    exit(66);
  }

  print('Launching target: $targetScript ${targetArgs.join(' ')}');

  final vmArgs = [
    '--observe=0',
    '--pause-isolates-on-exit',
    '--profile-period=$period',
    targetScript,
    ...targetArgs,
  ];

  final process = await Process.start(Platform.resolvedExecutable, vmArgs);

  final wsUriCompleter = Completer<Uri>();
  final uriRegex = RegExp(
    r'Observatory listening on ((http|ws)://[a-zA-Z0-9\.:]+[^\s]*)'
    r'|The Dart VM service is listening on ((http|ws)://[a-zA-Z0-9\.:]+[^\s]*)',
  );

  process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
    (line) {
      final match = uriRegex.firstMatch(line);
      if (match != null && !wsUriCompleter.isCompleted) {
        final rawUrl = match.group(1) ?? match.group(3);
        if (rawUrl != null) {
          var wsUrl = rawUrl.replaceFirst('http://', 'ws://');
          if (!wsUrl.endsWith('/ws')) {
            wsUrl = wsUrl.endsWith('/') ? '${wsUrl}ws' : '$wsUrl/ws';
          }
          wsUriCompleter.complete(Uri.parse(wsUrl));
        }
      } else {
        print(line);
      }
    },
  );

  process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(
    (line) {
      final match = uriRegex.firstMatch(line);
      if (match != null && !wsUriCompleter.isCompleted) {
        final rawUrl = match.group(1) ?? match.group(3);
        if (rawUrl != null) {
          var wsUrl = rawUrl.replaceFirst('http://', 'ws://');
          if (!wsUrl.endsWith('/ws')) {
            wsUrl = wsUrl.endsWith('/') ? '${wsUrl}ws' : '$wsUrl/ws';
          }
          wsUriCompleter.complete(Uri.parse(wsUrl));
        }
      } else {
        stderr.writeln(line);
      }
    },
  );

  final wsUri = await wsUriCompleter.future.timeout(
    const Duration(seconds: 15),
    onTimeout: () {
      print('Timeout waiting for VM service URI.');
      process.kill();
      exit(1);
    },
  );

  print('Connecting to VM service at $wsUri...');
  final service = await vmServiceConnectUri(wsUri.toString());

  final vm = await service.getVM();
  final isolates = vm.isolates ?? [];
  if (isolates.isEmpty) {
    print('Error: No isolates found.');
    process.kill();
    exit(1);
  }

  final isolateRef = isolates.first;
  final isolateId = isolateRef.id!;

  bool connectionLost = false;
  service.onDone.then((_) {
    connectionLost = true;
  });

  var isPausedAtExit = false;
  while (!isPausedAtExit && !connectionLost) {
    try {
      final isolate = await service.getIsolate(isolateId);
      final pauseKind = isolate.pauseEvent?.kind;
      if (pauseKind == EventKind.kPauseExit) {
        isPausedAtExit = true;
        break;
      }
      if (pauseKind == EventKind.kPauseException) {
        print('Target isolate paused on exception!');
        break;
      }
    } catch (e) {
      print('Error querying VM service: $e');
      break;
    }

    final exitCode = await process.exitCode.timeout(
      const Duration(milliseconds: 50),
      onTimeout: () => -1,
    );
    if (exitCode != -1) {
      print('Target process exited with code $exitCode');
      break;
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  if (!isPausedAtExit) {
    print(
      'Error: Target process did not pause at exit. Cannot retrieve CPU profile.',
    );
    await service.dispose();
    exit(1);
  }

  print('Target execution finished. Retrieving CPU profile samples...');
  final cpuSamples = await service.getCpuSamples(
    isolateId,
    0,
    0x7fffffffffffffff,
  );

  final sampleCount = cpuSamples.sampleCount ?? 0;
  print('Retrieved $sampleCount samples.');

  final functions = cpuSamples.functions ?? [];

  final sortedFunctions = List<ProfileFunction>.from(functions)
    ..sort((a, b) => (b.exclusiveTicks ?? 0).compareTo(a.exclusiveTicks ?? 0));

  print('\n=== Top 15 Functions by Self CPU Samples ===');
  print(
    '${'Self %'.padRight(8)} | ${'Self'.padRight(8)} | ${'Total %'.padRight(8)} | Function',
  );
  print(
    '-----------------------------------------------------------------------',
  );

  var displayed = 0;
  for (final func in sortedFunctions) {
    if (displayed >= 15) break;
    final count = func.exclusiveTicks ?? 0;
    if (count <= 0 && displayed > 0) break;
    final pct = sampleCount > 0 ? (count * 100.0 / sampleCount) : 0.0;
    final totalCount = func.inclusiveTicks ?? 0;
    final totalPct = sampleCount > 0 ? (totalCount * 100.0 / sampleCount) : 0.0;
    final name = func.function?.name ?? func.resolvedUrl ?? 'Unknown';
    print(
      '${pct.toStringAsFixed(1).padLeft(6)}% | ${count.toString().padLeft(8)} | ${totalPct.toStringAsFixed(1).padLeft(6)}% | $name',
    );
    displayed++;
  }

  final outFile = File(outPath);
  await outFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(cpuSamples.toJson()),
  );
  print('\nSaved complete JSON CPU profile to: $outPath');

  await service.resume(isolateId);
  await service.dispose();
  await process.exitCode;
}
