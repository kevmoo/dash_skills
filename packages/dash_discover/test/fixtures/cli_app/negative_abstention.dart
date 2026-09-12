import 'dart:io';

// HTTP server entrypoint: out of scope for dart-build-cli-app
void main(List<String> args) async {
  final server = await HttpServer.bind('localhost', 8080);
  print('Listening on ${server.port}');
}
