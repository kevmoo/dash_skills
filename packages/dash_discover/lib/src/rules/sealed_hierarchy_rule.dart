import '../context.dart';
import '../models.dart';
import '../package_facts.dart';
import '../rule.dart';

/// Discovery rule for closed type hierarchies that are not declared `sealed`.
///
/// A hierarchy whose every subtype already lives in one library is closed in
/// practice but not in the type system: the compiler cannot check switch
/// exhaustiveness over it, so adding a subtype later silently falls through
/// existing switches instead of failing to compile.
///
/// This rule cannot be expressed at Tier 1. Deciding whether every subtype of
/// a type is declared in the same library is a question about the package's
/// type graph, not about any single file, so it needs the package-scoped
/// [PackageFacts] graph. It does *not* need element resolution.
///
/// **Target Skill**:
/// - GitHub: https://github.com/kevmoo/dash_skills/tree/main/skills/dart-seal-type-hierarchies
final class SealedHierarchyRule extends DiscoveryRule {
  const SealedHierarchyRule();

  /// Minimum number of subtypes before a hierarchy is worth sealing.
  ///
  /// A single subtype is usually specialization rather than an algebraic
  /// hierarchy, and exhaustiveness buys nothing.
  static const _minimumSubtypes = 2;

  @override
  String get id => 'seal-type-hierarchies';

  @override
  SkillTarget get target => const SkillTarget(
    org: 'kevmoo',
    repo: 'dash_skills',
    path: 'skills/dart-seal-type-hierarchies',
  );

  @override
  RuleCategory get category => RuleCategory.language;

  @override
  SkillLifecycle get lifecycle => SkillLifecycle.architecture;

  @override
  String get description =>
      'Detects closed type hierarchies that are not sealed, so the compiler '
      'cannot check switch exhaustiveness over them.';

  @override
  Confidence get defaultConfidence => Confidence.medium;

  @override
  Iterable<Opportunity> evaluate(PackageContext context) sync* {
    final facts = context.facts;
    final candidates = <TypeDeclarationFacts>[];
    final evidence = <String>[];

    for (final type in facts.typesByName.values) {
      if (!_isCandidate(type, facts)) continue;
      candidates.add(type);
      if (evidence.length < 4) {
        final subtypes = facts.subtypesOf[type.name]!;
        evidence.add(
          '${type.source.relativePath}:${type.source.lineOf(type.offset)} '
          '${type.name} (${subtypes.length} subtypes: '
          '${subtypes.map((s) => s.name).take(3).join(', ')})',
        );
      }
    }

    if (candidates.isEmpty) return;

    // Sealing a type that downstream packages can currently extend is a
    // breaking change. Types under `lib/src/` are package-private by
    // convention, so the change is safe; anything else needs a judgement call
    // that syntax alone cannot make.
    final allPrivate = candidates.every(
      (c) => c.source.isImplementation || c.isFinal,
    );

    yield Opportunity(
      target: target,
      category: category,
      lifecycle: lifecycle,
      confidence: allPrivate ? Confidence.high : Confidence.medium,
      affectedCount: candidates.length,
      diagnosis:
          '${candidates.length} abstract type(s) have all their subtypes '
          'declared in the same library but are not marked `sealed`, so '
          'switches over them are not exhaustiveness-checked.',
      prescription: allPrivate
          ? 'Mark these types `sealed` and replace `is` cascades over them '
                'with exhaustive switches. Adding a subtype then becomes a '
                'compile error at every switch instead of a silent fallthrough.'
          : 'Mark these types `sealed` and replace `is` cascades over them '
                'with exhaustive switches. Note that some are part of the '
                'public API, where sealing is a breaking change for packages '
                'that currently extend them -- confirm intent before applying.',
      evidence: evidence,
    );
  }

  bool _isCandidate(TypeDeclarationFacts type, PackageFacts facts) {
    if (type.isSealed || type.isEnum || type.isMixin) return false;

    // `sealed` implies `abstract`. Promoting a concrete, instantiable class
    // would also forbid constructing it, which is a much larger change than
    // this rule is entitled to suggest.
    if (!type.isAbstract) return false;

    final subtypes = facts.subtypesOf[type.name];
    if (subtypes == null || subtypes.length < _minimumSubtypes) return false;

    // `sealed` requires every direct subtype to be declared in the same
    // library. Subtypes scattered across files would simply not compile, so
    // this is a correctness gate rather than a heuristic.
    return subtypes.every(
      (s) => s.source.relativePath == type.source.relativePath,
    );
  }
}
