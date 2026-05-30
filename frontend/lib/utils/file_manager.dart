import 'package:flutter/foundation.dart';
import 'dart:io' as io;

class UniLabFileManager {
  static Future<List<dynamic>> getSamples() async {
    if (kIsWeb) return [];

    try {
      final directory = io.Directory('sample'); 
      if (await directory.exists()) {
        return directory
            .listSync()
            .whereType<io.File>()
            .where((f) => f.path.endsWith('.m'))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading samples: $e');
    }
    return [];
  }

  static Future<String> readFile(dynamic file) async {
    if (kIsWeb) return '';
    if (file is io.File) {
      return await file.readAsString();
    }
    return '';
  }

  static Future<List<dynamic>> listDirectory(String path) async {
    if (kIsWeb) return [];
    
    try {
      final directory = io.Directory(path);
      if (await directory.exists()) {
        return directory.listSync().toList();
      }
    } catch (e) {
      debugPrint('Error listing directory: $e');
    }
    return [];
  }
}
