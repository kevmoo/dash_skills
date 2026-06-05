import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _marketplaceName = 'kevmoo';
const _pluginName = 'dash-skills';

Map<String, dynamic> _readJson(File file) {
  expect(file.existsSync(), isTrue, reason: '${file.path} should exist');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  // CI runs `dart test` from the `tool/` package directory, so the repo root is
  // exactly one parent up. No need to walk the tree hunting for a marker.
  final repoRoot = Directory.current.parent;
  final marketplaceFile = File(
    p.join(repoRoot.path, '.claude-plugin', 'marketplace.json'),
  );
  final pluginLink = p.join(repoRoot.path, 'plugins', _pluginName, 'skills');
  // Skills live under a top-level `skills/` directory.
  final canonicalSkills = Directory(p.join(repoRoot.path, 'skills'));

  group('Claude plugin marketplace', () {
    test('marketplace.json declares the plugin', () {
      final marketplace = _readJson(marketplaceFile);

      expect(marketplace['name'], _marketplaceName);
      expect(marketplace['owner'], isA<Map<String, dynamic>>());

      final plugins = marketplace['plugins'] as List<dynamic>;
      expect(plugins, hasLength(1));

      final plugin = plugins.single as Map<String, dynamic>;
      expect(plugin['name'], _pluginName);

      // Guards against regressing to `source: "./"`, which would copy the
      // entire repo into every user's cache.
      expect(plugin['source'], './plugins/$_pluginName');
    });

    test('plugin source resolves to a directory with a plugin manifest', () {
      final marketplace = _readJson(marketplaceFile);
      final plugin = (marketplace['plugins'] as List<dynamic>).single
          as Map<String, dynamic>;
      final source = plugin['source'] as String;

      expect(source, startsWith('./'));
      expect(source, isNot(contains('..')));

      final pluginDir = Directory(p.join(repoRoot.path, source));
      expect(pluginDir.existsSync(), isTrue, reason: 'source "$source" exists');

      final manifest = _readJson(
        File(p.join(pluginDir.path, '.claude-plugin', 'plugin.json')),
      );
      expect(manifest['name'], plugin['name']);
    });

    test('skills symlink resolves to the top-level skills directory', () {
      expect(
        FileSystemEntity.isLinkSync(pluginLink),
        isTrue,
        reason:
            '"$pluginLink" must be a symlink. On Windows, ensure git checks '
            'out symlinks (core.symlinks=true / Developer Mode).',
      );

      final resolvedLink = Link(pluginLink).resolveSymbolicLinksSync();
      final expected = canonicalSkills.resolveSymbolicLinksSync();

      expect(
        p.equals(resolvedLink, expected),
        isTrue,
        reason: 'symlink should resolve to "$expected", got "$resolvedLink"',
      );
    });

    test('every skill is reachable through the plugin symlink', () {
      final skillNames = canonicalSkills
          .listSync()
          .whereType<Directory>()
          .map((entity) => p.basename(entity.path))
          .where(
            (name) => File(
              p.join(canonicalSkills.path, name, 'SKILL.md'),
            ).existsSync(),
          )
          .toList();

      expect(skillNames, isNotEmpty, reason: 'expected at least one skill');

      for (final name in skillNames) {
        final viaLink = File(p.join(pluginLink, name, 'SKILL.md'));
        expect(
          viaLink.existsSync(),
          isTrue,
          reason: 'skill "$name" should be reachable via the plugin symlink',
        );
      }
    });
  });
}
