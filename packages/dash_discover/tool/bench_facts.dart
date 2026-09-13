// Measures the actual wall-clock cost of the Tier 2 parse, which is the
// claim the whole fact-base architecture rests on and which we have so far
// only asserted.
import 'dart:io';

import 'package:dash_discover/src/context.dart';

void main(List<String> args) {
  print('| package | lib files | parse ms | ms/file | types | edges |');
  print('| :--- | ---: | ---: | ---: | ---: | ---: |');

  var totalFiles = 0;
  var totalMs = 0;

  for (final root in args) {
    if (!File('$root/pubspec.yaml').existsSync()) continue;
    final context = PackageContext.load(root);
    if (context.libFiles.isEmpty) continue;

    final sw = Stopwatch()..start();
    final facts = context.facts;
    sw.stop();

    final edges = facts.subtypesOf.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    final ms = sw.elapsedMilliseconds;
    final n = context.libFiles.length;
    totalFiles += n;
    totalMs += ms;

    print(
      '| ${context.packageName} | $n | $ms | '
      '${(ms / n).toStringAsFixed(2)} | ${facts.typesByName.length} | $edges |',
    );
  }

  print(
    '\ntotal: $totalFiles files in ${totalMs}ms '
    '(${(totalMs / totalFiles).toStringAsFixed(2)} ms/file)',
  );
}
