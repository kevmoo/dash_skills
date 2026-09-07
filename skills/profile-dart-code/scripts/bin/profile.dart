import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:cli_util/cli_util.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

Future<void> main(List<String> arguments) async {
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

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on ArgParserException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln(
      'Usage: dart profile.dart [options] -- <target.dart> [args...]',
    );
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  if (results['help'] as bool) {
    print('Usage: dart profile.dart [options] -- <target.dart> [args...]');
    print(parser.usage);
    return;
  }
  if (results.rest.isEmpty) {
    stderr.writeln(
      'Usage: dart profile.dart [options] -- <target.dart> [args...]',
    );
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final outPath = results['out'] as String;
  final period = int.tryParse(results['period'] as String);
  if (period == null || period < 50) {
    stderr.writeln(
      'Error: Invalid --period value "${results['period']}". Must be an integer >= 50.',
    );
    exitCode = 64;
    return;
  }

  final targetScript = results.rest.first;
  final targetArgs = results.rest.sublist(1);

  if (!File(targetScript).existsSync()) {
    stderr.writeln('Error: Target script not found at $targetScript');
    exitCode = 66;
    return;
  }

  print('Launching target: $targetScript ${targetArgs.join(' ')}');

  final vmArgs = [
    '--observe=0',
    '--pause-isolates-on-exit',
    '--profile-period=$period',
    targetScript,
    ...targetArgs,
  ];

  final dartExe = dartExecutable ?? 'dart';
  final Process process;
  try {
    process = await Process.start(dartExe, vmArgs);
  } on ProcessException catch (e) {
    stderr.writeln(
      'Error: Failed to launch Dart executable "$dartExe": ${e.message}',
    );
    exitCode = 69;
    return;
  }

  final wsUriCompleter = Completer<Uri>();
  final uriRegex = RegExp(
    r'Observatory listening on ((http|ws)://[a-zA-Z0-9\.:]+[^\s]*)'
    r'|The Dart VM service is listening on ((http|ws)://[a-zA-Z0-9\.:]+[^\s]*)',
  );

  final stdoutSub = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
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
      });

  final stderrSub = process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
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
      });

  VmService? service;
  try {
    Uri? wsUri;
    try {
      wsUri = await wsUriCompleter.future.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      stderr.writeln('Timeout waiting for VM service URI.');
      exitCode = 1;
      return;
    }

    print('Connecting to VM service at $wsUri...');
    service = await vmServiceConnectUri(wsUri.toString());

    final vm = await service.getVM();
    final isolates = vm.isolates ?? [];
    if (isolates.isEmpty) {
      stderr.writeln('Error: No isolates found.');
      exitCode = 1;
      return;
    }

    final isolateRef = isolates.first;
    final isolateId = isolateRef.id!;

    var connectionLost = false;
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

      final procExitCode = await process.exitCode.timeout(
        const Duration(milliseconds: 50),
        onTimeout: () => -1,
      );
      if (procExitCode != -1) {
        print('Target process exited with code $procExitCode');
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!isPausedAtExit) {
      stderr.writeln(
        'Error: Target process did not pause at exit. Cannot retrieve CPU profile.',
      );
      exitCode = 1;
      return;
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

    final sortedFunctions = List<ProfileFunction>.from(
      functions,
    )..sort((a, b) => (b.exclusiveTicks ?? 0).compareTo(a.exclusiveTicks ?? 0));

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
      final totalPct = sampleCount > 0
          ? (totalCount * 100.0 / sampleCount)
          : 0.0;
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
    await process.exitCode;
  } finally {
    await service?.dispose();
    process.kill();
    await stdoutSub.cancel();
    await stderrSub.cancel();
  }
}
