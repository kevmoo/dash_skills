import 'package:path/path.dart' as p;
import 'outline_generator.dart';
import 'skills_catalog.dart';
import 'static_discovery.dart';

class DiscoveryReport {
  final String packageName;
  final String packagePath;
  final List<Opportunity> staticOpportunities;
  final String outline;
  final String probePrompt;

  const DiscoveryReport({
    required this.packageName,
    required this.packagePath,
    required this.staticOpportunities,
    required this.outline,
    required this.probePrompt,
  });

  Map<String, dynamic> toJson() => {
    'package_name': packageName,
    'package_path': packagePath,
    'static_opportunities': staticOpportunities.map((o) => o.toJson()).toList(),
    'outline_length_chars': outline.length,
    'probe_prompt_length_chars': probePrompt.length,
  };

  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Meta-Skill Discovery Report: $packageName\n');
    buffer.writeln('Path: `$packagePath`\n');

    if (staticOpportunities.isEmpty) {
      buffer.writeln(
        'No immediate static modernization opportunities detected.\n',
      );
    } else {
      buffer.writeln(
        '## 🎯 Detected Opportunities (${staticOpportunities.length})\n',
      );
      for (final opp in staticOpportunities) {
        final badge = opp.priority == Priority.high ? '🔴 HIGH' : '🟡 MEDIUM';
        buffer.writeln('### $badge: `${opp.skill}` (${opp.category})\n');
        buffer.writeln('- **Diagnosis**: ${opp.diagnosis}');
        buffer.writeln('- **Prescription**: ${opp.prescription}');
        buffer.writeln('- **Evidence**:');
        for (final ev in opp.evidence) {
          buffer.writeln('  - $ev');
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}

class DiscoveryEngine {
  final String packagePath;
  final SkillsCatalog catalog;

  DiscoveryEngine(this.packagePath, {SkillsCatalog? catalog})
    : catalog = catalog ?? SkillsCatalog.discover();

  DiscoveryReport run() {
    final packageName = p.basename(packagePath);

    // Tier 1: Fast Static Heuristics (<50ms)
    final staticEngine = StaticDiscoveryEngine(packagePath);
    final staticOpportunities = staticEngine.scan();

    // Tier 2: Token-Efficient Outline Assembly
    final outlineGen = OutlineGenerator(packagePath);
    final outline = outlineGen.generate();

    // Assemble Prompt for LLM Probing
    final catalogText = catalog.formatForPrompt();
    final probePrompt =
        '''
You are an expert Dart software architect acting as the "Meta Skill Discovery Engine".
Your objective is to examine the following repository outline (which includes pubspec dependencies, directory structure, and high-level code signatures from `sem`) and recommend the top 2-3 most relevant, high-impact skills to run on this project.

Note:
- The package is ALREADY clean under `dart analyze`. Do NOT recommend skills to fix basic analyzer warnings or lint errors.
- Focus strictly on latent architectural modernization, code quality lift, modern language idiom adoption (Dart 3 patterns, records, sealed types), testing hygiene (pkg:checks, mock generation), documentation verification, and refactoring patterns.
- Do NOT hallucinate dependencies or files not in the outline.
- CITE SPECIFIC EVIDENCE: files, class names, methods, or dependency absences from the outline.

$catalogText

--------------------------------------------------------------------------------
$outline
--------------------------------------------------------------------------------

Please return your response in the following structured JSON format:
{
  "repository": "$packageName",
  "recommendations": [
    {
      "skill": "<skill-name>",
      "priority": "HIGH" | "MEDIUM",
      "diagnosis": "<1-2 sentence explanation of the latent gap or modernization opportunity>",
      "evidence": "<specific files, functions, or pubspec lines from the outline>",
      "prescription": "<concrete architectural or code modernization change to apply>"
    }
  ]
}
''';

    return DiscoveryReport(
      packageName: packageName,
      packagePath: packagePath,
      staticOpportunities: staticOpportunities,
      outline: outline,
      probePrompt: probePrompt,
    );
  }
}
