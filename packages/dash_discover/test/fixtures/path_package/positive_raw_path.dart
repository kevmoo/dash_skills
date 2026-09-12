import 'dart:io';

class PathDemo {
  void process(String dir, String workspace, String root) {
    // Suboptimal: raw string interpolation with hardcoded slash
    final p1 = '$dir/lib/src/foo.dart';
    final p2 = '${dir}/test';

    // Suboptimal: File / Directory constructor with raw interpolation
    final f = File('$workspace/output.txt');
    final d = Directory('$root/temp');

    print('$p1, $p2, $f, $d');
  }
}
