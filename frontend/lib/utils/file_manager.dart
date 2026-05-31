import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:path/path.dart' as p;

class UniLabFileManager {
  static final Set<String> _textExtensions = {
    '.m', '.txt', '.csv', '.json', '.yaml', '.md', '.py', '.js', '.ts', '.html', 
    '.css', '.xml', '.log', '.bat', '.sh', '.sql', '.yml'
  };

  static final Set<String> _imageExtensions = {
    '.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp', '.tiff', '.ico'
  };

  static bool isTextFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return _textExtensions.contains(ext);
  }

  static bool isImageFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return _imageExtensions.contains(ext);
  }

  static bool isPdfFile(String path) {
    return p.extension(path).toLowerCase() == '.pdf';
  }

  static bool isAudioFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return {'.mp3', '.wav', '.m4a', '.ogg', '.flac'}.contains(ext);
  }

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
      // Only read as string if it's a known text format to avoid decoding errors
      if (isTextFile(file.path)) {
        try {
          return await file.readAsString();
        } catch (e) {
          debugPrint('Error decoding text file: $e');
          return '';
        }
      }
      // Return empty for binary files; viewers will use the path instead
      return '';
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