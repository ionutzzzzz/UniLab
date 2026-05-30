import 'dart:io';

class UniLabFileManager {
  static Future<List<File>> getSamples() async {
    // In development, the samples are in ../sample relative to the frontend directory
    final directory = Directory('../sample');
    if (await directory.exists()) {
      return directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.m'))
          .toList();
    }
    return [];
  }

  static Future<String> readFile(File file) async {
    return await file.readAsString();
  }

  static Future<List<FileSystemEntity>> listDirectory(String path) async {
    final directory = Directory(path);
    if (await directory.exists()) {
      return directory.listSync().toList();
    }
    return [];
  }
}
