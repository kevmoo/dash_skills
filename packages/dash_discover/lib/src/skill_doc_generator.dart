import 'dart:io';
import 'package:path/path.dart' as p;
import 'rule.dart';
import 'rules_registry.dart';

const discoveryRulesStartTag = '<!-- DISCOVERY_RULES_START -->';
const discoveryRulesEndTag = '<!-- DISCOVERY_RULES_END -->';

/// Generates the Markdown list of discovery rules for inclusion in SKILL.md.
String generateDiscoveryRulesBlock([List<DiscoveryRule>? rules]) {
  final activeRules = rules ?? defaultDiscoveryRules;
  final buffer = StringBuffer();
  buffer.writeln(discoveryRulesStartTag);
  buffer.writeln();
  buffer.writeln(
    'The static scanner performs rapid, zero-network checks across '
    '${activeRules.length} built-in rules:',
  );
  buffer.writeln();
  buffer.writeln('<!-- prettier-ignore -->');
  for (var i = 0; i < activeRules.length; i++) {
    final rule = activeRules[i];
    final num = i + 1;
    buffer.writeln(
      '$num. **${rule.category.label} (`${rule.target.skillName}`)**: '
      '${rule.description}',
    );
  }
  buffer.writeln();
  buffer.write(discoveryRulesEndTag);
  return buffer.toString();
}

/// Updates the discovery rules section in [content] with the generated block.
String updateSkillContent(String content, [List<DiscoveryRule>? rules]) {
  final startIndex = content.indexOf(discoveryRulesStartTag);
  final endIndex = content.indexOf(discoveryRulesEndTag);
  if (startIndex == -1 || endIndex == -1) {
    throw StateError(
      'Could not find $discoveryRulesStartTag and $discoveryRulesEndTag in content',
    );
  }
  final generated = generateDiscoveryRulesBlock(rules);
  return content.replaceRange(
    startIndex,
    endIndex + discoveryRulesEndTag.length,
    generated,
  );
}

/// Locates the `skills/dash-discover/SKILL.md` file by walking up from [startDir].
File? findSkillFile([Directory? startDir]) {
  var dir = (startDir ?? Directory.current).absolute;
  while (dir.path != dir.parent.path) {
    final candidate = File(
      p.join(dir.path, 'skills', 'dash-discover', 'SKILL.md'),
    );
    if (candidate.existsSync()) {
      return candidate;
    }
    dir = dir.parent;
  }
  return null;
}
