import 'dart:io';
import 'package:path/path.dart' as p;

class IdiomaticPathDemo {
  void process(String dir, String workspace, String root) {
    // Idiomatic: using package:path
    final p1 = p.join(dir, 'lib', 'src', 'foo.dart');
    final p2 = p.join(dir, 'test');

    final f = File(p.join(workspace, 'output.txt'));
    final d = Directory(p.join(root, 'temp'));

    print('$p1, $p2, $f, $d');
  }
}
