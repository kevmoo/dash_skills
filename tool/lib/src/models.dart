enum Priority { high, medium, low }

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
class Opportunity {
  final SkillTarget target;
  final String category;
  final Priority priority;
  final String diagnosis;
  final String prescription;
  final List<String> evidence;

  const Opportunity({
    required this.target,
    required this.category,
    required this.priority,
    required this.diagnosis,
    required this.prescription,
    required this.evidence,
  });

  String get skill => target.skillName;

  Map<String, dynamic> toJson() => {
    'skill': skill,
    'target': target.toJson(),
    'category': category,
    'priority': priority.name.toUpperCase(),
    'diagnosis': diagnosis,
    'prescription': prescription,
    'evidence': evidence,
  };
}
