/// Slashes that are NOT filesystem path separators, but which the current
/// Tier 2 rule flags anyway.
///
/// Each case here was observed in a real package during the corpus scan. They
/// are all structurally identical to a genuine path join -- an interpolated
/// expression adjacent to a literal `/` -- and can only be distinguished by
/// knowing what the string *means*, which the syntax tree does not record.
///
/// Tracked as side quest G9: Tier 3 type resolution vs syntactic sink
/// restriction vs a semantic exclusion vocabulary.
library;

import 'dart:io';

class SemanticSlashes {
  // MIME types. Observed shape: `'application/' + subtype`.
  String mime(String subtype) => 'application/$subtype';

  String textMime(String subtype) => 'text/$subtype';

  // HTTP route patterns. Observed in shelf_router.
  String route(String endpoint) => '/api/$endpoint';

  // URI path resolution. Observed in webdriver.dart and webcrypto.dart.
  Uri session(Uri base, String id) => base.resolve('session/$id/');

  // A ratio rendered for humans, e.g. "3/5". Observed in melos.
  String progress(int attempt, int max) => '($attempt/$max) ';

  // A JSON Schema pointer. Observed in json_serializable.
  String schemaRef(String typeName) => '#/\$defs/$typeName';

  // A git refspec. Observed in melos.
  String refspec(String remote, String branch) => '$remote/$branch';

  // An HTTP Content-Range header value. Observed in shelf_static.
  String contentRange(int start, int end, int length) =>
      'bytes $start-$end/$length';

  // A glob pattern, which uses `/` on every platform by definition.
  String glob(String outDir) => '$outDir/**';

  // Suffix append with no separator at all: must never be flagged. This one
  // the Tier 2 rule already gets right, and the Tier 1 regex did not.
  File tempFile(String path) => File('$path.tmp');
}
