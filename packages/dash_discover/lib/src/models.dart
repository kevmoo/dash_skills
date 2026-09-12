/// Architectural category for organizing discovery rules.
enum RuleCategory {
  testing('Testing Architecture'),
  language('Dart 3 Language Idioms'),
  documentation('Documentation & Testing'),
  cli('CLI Architecture'),
  codeQuality('Refactoring & Code Quality'),
  platform('Cross-Platform Robustness');

  final String label;
  const RuleCategory(this.label);

  @override
  String toString() => label;
}

/// Lifecycle model of a skill recommendation.
enum SkillLifecycle {
  /// One-time migration to a modern API or pattern (finite goal).
  migration('One-Time Migration'),

  /// Architectural capability or scaffold triggered by contextual intent.
  architecture('Architectural Capability'),

  /// Recurring hygiene sweep or threshold-driven audit (continuous health).
  hygiene('Periodic Hygiene');

  final String label;
  const SkillLifecycle(this.label);

  @override
  String toString() => label;
}

/// Confidence level in the accuracy of a discovery match.
enum Confidence {
  high('High'),
  medium('Medium'),
  low('Low');

  final String label;
  const Confidence(this.label);

  @override
  String toString() => label;
}

/// Points unambiguously to the exact upstream GitHub skill that this discovery
/// rule aligns with and prescribes.
class SkillTarget {
  final String org;
  final String repo;
  final String path;
  final String? commitSha;

  const SkillTarget({
    required this.org,
    required this.repo,
    required this.path,
    this.commitSha,
  });

  /// The basename identifier of the skill (e.g. `dart-migrate-to-checks-package`).
  String get skillName => path.split('/').last;

  /// Full permalink or branch URL to the skill definition on GitHub.
  Uri get githubUrl {
    final ref = commitSha ?? 'main';
    return Uri.parse('https://github.com/$org/$repo/tree/$ref/$path');
  }

  Map<String, dynamic> toJson() => {
    'org': org,
    'repo': repo,
    'path': path,
    if (commitSha != null) 'commit_sha': commitSha,
    'github_url': githubUrl.toString(),
  };
}

/// A discovered latent modernization opportunity.
class Opportunity implements Comparable<Opportunity> {
  final SkillTarget target;
  final RuleCategory category;
  final SkillLifecycle lifecycle;
  final Confidence confidence;
  final int affectedCount;
  final String diagnosis;
  final String prescription;
  final List<String> evidence;

  const Opportunity({
    required this.target,
    required this.category,
    required this.lifecycle,
    this.confidence = Confidence.high,
    this.affectedCount = 1,
    required this.diagnosis,
    required this.prescription,
    required this.evidence,
  });

  String get skill => target.skillName;

  @override
  int compareTo(Opportunity other) {
    // 1. Lifecycle order: migration, architecture, hygiene
    final lifeComp = lifecycle.index.compareTo(other.lifecycle.index);
    if (lifeComp != 0) return lifeComp;

    // 2. Confidence order: high, medium, low
    final confComp = confidence.index.compareTo(other.confidence.index);
    if (confComp != 0) return confComp;

    // 3. Affected file count descending: larger scope first
    return other.affectedCount.compareTo(affectedCount);
  }

  Map<String, dynamic> toJson() => {
    'skill': skill,
    'target': target.toJson(),
    'category': category.name,
    'category_label': category.label,
    'lifecycle': lifecycle.name,
    'lifecycle_label': lifecycle.label,
    'confidence': confidence.name.toUpperCase(),
    'affected_count': affectedCount,
    'diagnosis': diagnosis,
    'prescription': prescription,
    'evidence': evidence,
  };
}
