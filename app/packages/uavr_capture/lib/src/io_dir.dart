import 'dart:io';

Future<void> ensureDir(String path) async {
  await Directory(path).create(recursive: true);
}

Future<void> deleteFile(String path) async {
  final f = File(path);
  if (await f.exists()) await f.delete();
}
