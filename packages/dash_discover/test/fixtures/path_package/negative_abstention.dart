class AbstentionDemo {
  void handleRequests(
    String version,
    String pkg,
    String subtype,
    int count,
    int total,
    String endpoint,
  ) {
    // URLs and URIs should NOT be flagged as file paths
    final url1 = 'http://api.example.com/$version/users';
    final url2 = 'https://api.example.com/$version/users';
    final uri = 'package:$pkg/lib/src/entry.dart';
    final fileUri = 'file:///workspace/$pkg';

    // MIME types
    final mime = 'application/$subtype';
    final textMime = 'text/$subtype';

    // Math division inside interpolation
    final ratio = '${count / total}';

    // API route path
    final route = '/api/$endpoint';

    // Raw string: $ is not an interpolation
    const rawPath = r'$dir/lib';

    print('$url1 $url2 $uri $fileUri $mime $textMime $ratio $route $rawPath');
  }
}
