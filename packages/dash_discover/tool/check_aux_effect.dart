// Verifies that the 3.7 change actually took effect: reports how many
// auxiliary (test/, bin/) sources were parsed, and which sealed-hierarchy
// candidates are rejected *because* a subtype lives outside lib/.
import 'dart:io';

import 'package:dash_discover/src/context.dart';

void main(List<String> args) {
  for (final root in args) {
    if (!File('$root/pubspec.yaml').existsSync()) continue;
    final context = PackageContext.load(root);
    final facts = context.facts;

    var rejectedByAux = 0;
    final details = <String>[];

    for (final type in facts.typesByName.values) {
      if (type.isSealed || type.isEnum || type.isMixin || !type.isAbstract) {
        continue;
      }
      final subtypes = facts.subtypesOf[type.name];
      if (subtypes == null || subtypes.length < 2) continue;

      final sameFile = subtypes.every(
        (s) => s.source.relativePath == type.source.relativePath,
      );
      if (sameFile) continue;

      // Would it have qualified if we had only looked at lib/?
      final libOnly = subtypes.where(
        (s) => s.source.relativePath.startsWith('lib/'),
      );
      final outsideLib = subtypes.where(
        (s) => !s.source.relativePath.startsWith('lib/'),
      );
      if (outsideLib.isEmpty) continue;
      if (libOnly.length < 2) continue;
      if (!libOnly.every(
        (s) => s.source.relativePath == type.source.relativePath,
      )) {
        continue;
      }

      rejectedByAux++;
      details.add(
        '    ${type.name} <- ${outsideLib.map((s) => '${s.name} (${s.source.relativePath})').join(', ')}',
      );
    }

    print(
      '${context.packageName}: lib=${facts.librarySources.length} '
      'aux=${facts.auxiliarySources.length} '
      'newly-rejected=$rejectedByAux',
    );
    details.forEach(print);
  }
}
