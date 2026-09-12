import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../context.dart';
import '../models.dart';
import '../package_facts.dart';
import '../rule.dart';

/// Discovery rule for manual path construction that should use `package:path`.
///
/// This is a Tier 2 rule: it queries the parsed AST in [PackageFacts] rather
/// than matching regular expressions against raw lines. That removes an entire
/// class of lexical false positives -- a `/` inside a comment, a URL, a MIME
/// type, or a division expression is simply not a string-literal separator, so
/// no abstention heuristics are needed to exclude them.
///
/// **Target Skill**:
/// - GitHub: https://github.com/dart-lang/skills/tree/26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e/skills/dart-use-path-package
final class PathPackageRule extends DiscoveryRule {
  const PathPackageRule();

  @override
  String get id => 'use-path-package';

  @override
  SkillTarget get target => const SkillTarget(
    org: 'dart-lang',
    repo: 'skills',
    path: 'skills/dart-use-path-package',
    commitSha: '26b2dcc5654cbbc3b2ec56ea94719469bc8bae9e',
  );

  @override
  RuleCategory get category => RuleCategory.platform;

  @override
  SkillLifecycle get lifecycle => SkillLifecycle.migration;

  @override
  String get description =>
      'Detects manual path string concatenation without package:path.';

  @override
  Confidence get defaultConfidence => Confidence.medium;

  @override
  Iterable<Opportunity> evaluate(PackageContext context) sync* {
    final evidence = <String>[];
    var count = 0;

    for (final source in context.facts.librarySources) {
      final visitor = _PathJoinVisitor(source);
      source.unit.accept(visitor);
      for (final offset in visitor.findings) {
        count++;
        if (evidence.length < 4) {
          evidence.add('${source.relativePath}:${source.lineOf(offset)}');
        }
      }
    }

    if (count == 0) return;

    yield Opportunity(
      target: target,
      category: category,
      lifecycle: lifecycle,
      confidence: defaultConfidence,
      affectedCount: count,
      diagnosis:
          '$count string literal(s) join path segments with a hardcoded `/` '
          'separator, which breaks on Windows.',
      prescription:
          'Adopt `package:path` (`p.join`, `p.normalize`) to ensure '
          'cross-platform Windows compatibility and prevent path traversal '
          'bugs.',
      evidence: evidence,
    );
  }
}

/// Finds string literals that join a dynamic segment to a literal one using a
/// hardcoded `/` separator.
class _PathJoinVisitor extends RecursiveAstVisitor<void> {
  _PathJoinVisitor(this.source);

  final ParsedSource source;

  /// Offsets of offending string literals.
  final List<int> findings = [];

  @override
  void visitStringInterpolation(StringInterpolation node) {
    super.visitStringInterpolation(node);
    if (_isUriLike(node)) return;
    if (_isInsideUriConstruction(node)) return;

    final elements = node.elements;
    for (var i = 0; i < elements.length; i++) {
      final element = elements[i];
      if (element is! InterpolationExpression) continue;

      // `'$dir/lib/foo.dart'` -- the literal chunk *after* the expression
      // begins with a separator.
      if (i + 1 < elements.length) {
        final next = elements[i + 1];
        if (next is InterpolationString && next.value.startsWith('/')) {
          findings.add(node.offset);
          return;
        }
      }

      // `'lib/$name'` -- the literal chunk *before* the expression ends with
      // a separator.
      if (i > 0) {
        final previous = elements[i - 1];
        if (previous is InterpolationString && previous.value.endsWith('/')) {
          findings.add(node.offset);
          return;
        }
      }
    }
  }

  /// True when the literal is plainly a URI rather than a filesystem path.
  ///
  /// Checked against the literal's own text, not the surrounding source line,
  /// so an unrelated URL elsewhere on the line cannot suppress a real finding.
  bool _isUriLike(StringInterpolation node) {
    for (final element in node.elements) {
      if (element is! InterpolationString) continue;
      final value = element.value;
      if (value.contains('://') || value.startsWith('//')) return true;
    }
    final first = node.elements.first;
    if (first is InterpolationString) {
      final value = first.value;
      // Scheme-relative or absolute-URL-ish prefixes, and `package:`/`dart:`
      // style specifiers.
      if (value.startsWith('mailto:') ||
          value.startsWith('package:') ||
          value.startsWith('dart:')) {
        return true;
      }
    }
    return false;
  }

  /// True when the literal is an argument to a `Uri` constructor or factory,
  /// where `/` is a URI separator by definition.
  bool _isInsideUriConstruction(StringInterpolation node) {
    for (
      AstNode? current = node.parent;
      current != null;
      current = current.parent
    ) {
      switch (current) {
        case MethodInvocation(:final target, :final methodName):
          if (target?.toSource() == 'Uri') return true;
          if (methodName.name == 'parse' && target?.toSource() == 'Uri') {
            return true;
          }
        case InstanceCreationExpression(:final constructorName):
          if (constructorName.type.toSource() == 'Uri') return true;
        case FunctionBody():
          // Do not walk out of the enclosing function.
          return false;
        default:
          continue;
      }
    }
    return false;
  }
}
