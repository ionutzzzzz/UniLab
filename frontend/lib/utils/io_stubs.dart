// Mock/Stub classes for dart:io on Web
import 'dart:async';

abstract class FileSystemEntity {
  final String path;
  FileSystemEntity(this.path);
  
  Future<bool> exists() async => false;
  bool existsSync() => false;
  FileSystemEntity get absolute;
  Directory get parent => Directory(path.substring(0, path.lastIndexOf('/') == -1 ? 0 : path.lastIndexOf('/')));
  Future<FileSystemEntity> delete({bool recursive = false}) async => this;
  Future<FileSystemEntity> rename(String newPath) async => Directory(newPath); // Placeholder
  
  static bool isFileSync(String path) => false;
  static bool isDirectorySync(String path) => false;
}

class File extends FileSystemEntity {
  File(super.path);
  @override
  File get absolute => this;
  Future<void> writeAsString(String content) async {}
  Future<void> writeAsBytes(List<int> bytes) async {}
  Future<String> readAsString() async => '';
  Future<File> create({bool recursive = false}) async => this;
  @override
  Future<File> rename(String newPath) async => File(newPath);
}

class Directory extends FileSystemEntity {
  Directory(super.path);
  static Directory get current => Directory('/');
  @override
  Directory get absolute => this;
  List<FileSystemEntity> listSync({bool recursive = false, bool followLinks = true}) => [];
  Future<Directory> create({bool recursive = false}) async => this;
  @override
  Future<Directory> rename(String newPath) async => Directory(newPath);
}

class Platform {
  static bool get isLinux => false;
  static bool get isMacOS => false;
  static bool get isWindows => false;
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static String get resolvedExecutable => '';
  static Map<String, String> get environment => {};
}
