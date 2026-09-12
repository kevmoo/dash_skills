/// Abstention cases the Tier 2 rule handles structurally.
///
/// None of these slashes are filesystem path separators, and each is
/// excluded by a property of the string literal itself rather than by a
/// keyword search over the surrounding source line.
class AbstentionDemo {
  void handleRequests(String version, String pkg, int count, int total) {
    // Absolute URLs: the literal contains a `://` scheme separator.
    final url1 = 'http://api.example.com/$version/users';
    final url2 = 'https://api.example.com/$version/users';
    final fileUri = 'file:///workspace/$pkg';

    // A `package:` specifier, not a path.
    final uri = 'package:$pkg/lib/src/entry.dart';

    // Division inside an interpolation: there is no literal `/` adjacent to
    // the expression, so nothing structural to match.
    final ratio = '${count / total}';

    // Raw string: `$` does not interpolate, so this is not an interpolation
    // node at all.
    const rawPath = r'$dir/lib';

    print('$url1 $url2 $uri $fileUri $ratio $rawPath');
  }
}
