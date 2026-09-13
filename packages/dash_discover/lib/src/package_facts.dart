import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'context.dart';

/// A single parsed source file.
///
/// This is a purely *syntactic* parse: no element resolution, no type
/// inference, and no dependency graph. It therefore requires neither
/// `dart pub get` nor an SDK summary, and costs roughly a millisecond per
/// file, which is what makes it cheap enough to run on every discovery scan.
class ParsedSource {
  /// The file on disk.
  final File file;

  /// Path relative to the package root, e.g. `lib/src/foo.dart`.
  final String relativePath;

  /// Raw file contents.
  final String content;

  /// The parsed (unresolved) compilation unit.
  final CompilationUnit unit;

  ParsedSource({
    required this.file,
    required this.relativePath,
    required this.content,
    required this.unit,
  });

  /// Whether this file lives under `lib/src/`, which by convention means it is
  /// not part of the package's public API.
  bool get isImplementation =>
      relativePath.startsWith('lib/src/') ||
      relativePath.startsWith('lib\\src\\');

  /// 1-based line number for [offset], for human-readable evidence.
  int lineOf(int offset) {
    var line = 1;
    for (var i = 0; i < offset && i < content.length; i++) {
      if (content.codeUnitAt(i) == 0x0A) line++;
    }
    return line;
  }
}

/// Syntactic facts about one named type declaration.
class TypeDeclarationFacts {
  /// Simple name of the declared type.
  final String name;

  /// The source file that declares it.
  final ParsedSource source;

  /// Simple names of direct supertypes: `extends`, `implements`, `with`, and
  /// mixin `on` constraints, with any type arguments and import prefixes
  /// stripped.
  final List<String> directSupertypes;

  final bool isSealed;
  final bool isAbstract;
  final bool isFinal;
  final bool isBase;
  final bool isInterface;
  final bool isEnum;
  final bool isMixin;

  /// Character offset of the declaration, for line reporting.
  final int offset;

  TypeDeclarationFacts({
    required this.name,
    required this.source,
    required this.directSupertypes,
    required this.offset,
    this.isSealed = false,
    this.isAbstract = false,
    this.isFinal = false,
    this.isBase = false,
    this.isInterface = false,
    this.isEnum = false,
    this.isMixin = false,
  });
}

/// Package-scoped Tier 2 fact base.
///
/// Built once per scan and shared by every rule, so the parse cost is paid a
/// single time no matter how many rules query it. Package scope (rather than
/// file scope) is what makes cross-file questions -- such as "are all subtypes
/// of this class declared in the same library?" -- answerable at all.
class PackageFacts {
  final PackageContext context;

  /// Every parsed `.dart` file under `lib/`.
  ///
  /// Only these are eligible to produce findings.
  final List<ParsedSource> librarySources;

  /// Parsed `.dart` files outside `lib/` (`test/`, `bin/`).
  ///
  /// These never produce findings, but they do contribute subtype edges: a
  /// class in `test/` that extends a library type is enough to make sealing
  /// that type a compile error, so ignoring these files silently manufactures
  /// false positives.
  final List<ParsedSource> auxiliarySources;

  /// Named type declarations **in `lib/`**, keyed by simple name.
  ///
  /// Simple names collide in principle; on collision the first declaration
  /// wins and the duplicate is dropped, which is conservative: an ambiguous
  /// name simply produces no findings rather than a wrong one.
  final Map<String, TypeDeclarationFacts> typesByName;

  /// Reverse edges of [typesByName]: supertype name -> direct subtypes
  /// declared anywhere in this package, including outside `lib/`.
  final Map<String, List<TypeDeclarationFacts>> subtypesOf;

  PackageFacts._({
    required this.context,
    required this.librarySources,
    required this.auxiliarySources,
    required this.typesByName,
    required this.subtypesOf,
  });

  factory PackageFacts.build(PackageContext context) {
    final librarySources = _parseAll(context, context.libFiles);
    final auxiliarySources = _parseAll(context, [
      ...context.allTestFiles,
      ...context.binFiles,
    ]);

    // Only `lib/` declarations are candidates for findings.
    final typesByName = <String, TypeDeclarationFacts>{};
    final allLibraryDeclarations = <TypeDeclarationFacts>[];
    final duplicates = <String>{};
    for (final source in librarySources) {
      for (final facts in _declaredTypes(source)) {
        allLibraryDeclarations.add(facts);
        if (typesByName.containsKey(facts.name)) {
          duplicates.add(facts.name);
          continue;
        }
        typesByName[facts.name] = facts;
      }
    }
    for (final name in duplicates) {
      typesByName.remove(name);
    }

    // Edges come from everywhere, so that a subtype declared in `test/` is
    // visible even though it can never itself be a finding.
    final subtypesOf = <String, List<TypeDeclarationFacts>>{};
    void addEdges(Iterable<TypeDeclarationFacts> declarations) {
      for (final facts in declarations) {
        for (final supertype in facts.directSupertypes) {
          if (!typesByName.containsKey(supertype)) continue;
          (subtypesOf[supertype] ??= []).add(facts);
        }
      }
    }

    addEdges(allLibraryDeclarations);
    for (final source in auxiliarySources) {
      addEdges(_declaredTypes(source));
    }

    return PackageFacts._(
      context: context,
      librarySources: librarySources,
      auxiliarySources: auxiliarySources,
      typesByName: typesByName,
      subtypesOf: subtypesOf,
    );
  }

  /// Parses [files], skipping any that the analyzer cannot handle.
  static List<ParsedSource> _parseAll(
    PackageContext context,
    Iterable<File> files,
  ) {
    final sources = <ParsedSource>[];
    for (final file in files) {
      final content = context.readContent(file);
      final CompilationUnit unit;
      try {
        unit = parseString(
          content: content,
          path: file.path,
          throwIfDiagnostics: false,
        ).unit;
      } on ArgumentError {
        // Unparseable source (e.g. a future language feature this analyzer
        // does not know). Skipping is correct: no facts beats wrong facts.
        continue;
      }
      sources.add(
        ParsedSource(
          file: file,
          relativePath: context.relativePath(file).replaceAll(r'\', '/'),
          content: content,
          unit: unit,
        ),
      );
    }
    return sources;
  }

  static Iterable<TypeDeclarationFacts> _declaredTypes(
    ParsedSource source,
  ) sync* {
    for (final declaration in source.unit.declarations) {
      switch (declaration) {
        case ClassDeclaration():
          yield TypeDeclarationFacts(
            name: declaration.name.lexeme,
            source: source,
            offset: declaration.offset,
            directSupertypes: [
              if (declaration.extendsClause?.superclass case final s?)
                _simpleName(s),
              ...?declaration.implementsClause?.interfaces.map(_simpleName),
              ...?declaration.withClause?.mixinTypes.map(_simpleName),
            ],
            isSealed: declaration.sealedKeyword != null,
            isAbstract: declaration.abstractKeyword != null,
            isFinal: declaration.finalKeyword != null,
            isBase: declaration.baseKeyword != null,
            isInterface: declaration.interfaceKeyword != null,
          );
        case MixinDeclaration():
          yield TypeDeclarationFacts(
            name: declaration.name.lexeme,
            source: source,
            offset: declaration.offset,
            directSupertypes: [
              ...?declaration.onClause?.superclassConstraints.map(_simpleName),
              ...?declaration.implementsClause?.interfaces.map(_simpleName),
            ],
            // `sealed` is not a valid modifier on a mixin declaration.
            isBase: declaration.baseKeyword != null,
            isMixin: true,
          );
        case EnumDeclaration():
          yield TypeDeclarationFacts(
            name: declaration.name.lexeme,
            source: source,
            offset: declaration.offset,
            directSupertypes: [
              ...?declaration.implementsClause?.interfaces.map(_simpleName),
              ...?declaration.withClause?.mixinTypes.map(_simpleName),
            ],
            isEnum: true,
          );
        case ClassTypeAlias():
          yield TypeDeclarationFacts(
            name: declaration.name.lexeme,
            source: source,
            offset: declaration.offset,
            directSupertypes: [
              _simpleName(declaration.superclass),
              ...declaration.withClause.mixinTypes.map(_simpleName),
              ...?declaration.implementsClause?.interfaces.map(_simpleName),
            ],
            isSealed: declaration.sealedKeyword != null,
            isAbstract: declaration.abstractKeyword != null,
            isFinal: declaration.finalKeyword != null,
            isBase: declaration.baseKeyword != null,
            isInterface: declaration.interfaceKeyword != null,
          );
        default:
          continue;
      }
    }
  }

  /// Extracts the bare type name from a [NamedType], dropping type arguments
  /// and any import prefix.
  ///
  /// Uses `toSource()` rather than the AST accessors because those have been
  /// renamed across analyzer major versions; the source text has not.
  static String _simpleName(NamedType type) {
    var text = type.toSource();
    final generic = text.indexOf('<');
    if (generic != -1) text = text.substring(0, generic);
    if (text.endsWith('?')) text = text.substring(0, text.length - 1);
    final dot = text.lastIndexOf('.');
    if (dot != -1) text = text.substring(dot + 1);
    return text.trim();
  }
}
