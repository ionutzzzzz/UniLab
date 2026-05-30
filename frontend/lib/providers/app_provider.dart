import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:watcher/watcher.dart';
import '../models/models.dart';
import '../utils/backend_client.dart';
import '../utils/file_manager.dart';

class AppProvider with ChangeNotifier {
  final BackendClient _client = BackendClient();

  final List<UniLabFile> _openFiles = [];
  int _activeFileIndex = -1;
  List<File> _availableSamples = [];
  List<FileSystemEntity> _projectFiles = [];
  late String _projectRoot;
  
  String _consoleOutput = '';

  Map<String, dynamic> _workspaceVariables = {};
  List<Map<String, dynamic>> _generatedPlots = [];
  bool _isExecuting = false;

  StreamSubscription<WatchEvent>? _watcherSubscription;

  List<UniLabFile> get openFiles => _openFiles;
  int get activeFileIndex => _activeFileIndex;
  UniLabFile? get activeFile =>
      _activeFileIndex >= 0 ? _openFiles[_activeFileIndex] : null;
  String get consoleOutput => _consoleOutput;
  Map<String, dynamic> get workspaceVariables => _workspaceVariables;
  List<Map<String, dynamic>> get generatedPlots => _generatedPlots;
  bool get isExecuting => _isExecuting;
  List<File> get availableSamples => _availableSamples;
  List<FileSystemEntity> get projectFiles => _projectFiles;
  String get projectRoot => _projectRoot;

  AppProvider() {
    _projectRoot = _discoverProjectRoot();
    _loadAvailableSamples();
    refreshProjectFiles();
    _initWatcher();
  }

  String _discoverProjectRoot() {
    // Start from current working directory
    Directory current = Directory.current;
    
    // Strategy: Look for 'sample' directory in current or parent directories
    // This handles running from project root or from frontend/ subfolder
    for (int i = 0; i < 3; i++) {
      final samplePath = p.join(current.path, 'sample');
      if (Directory(samplePath).existsSync()) {
        return samplePath;
      }
      // If we are in 'frontend', the 'sample' is likely in the parent
      final parentSamplePath = p.join(current.parent.path, 'sample');
      if (Directory(parentSamplePath).existsSync()) {
        return parentSamplePath;
      }
      current = current.parent;
    }
    
    // Fallback to current directory if not found
    return p.join(Directory.current.path, 'sample');
  }

  @override
  void dispose() {
    _watcherSubscription?.cancel();
    super.dispose();
  }

  void _initWatcher() {
    _watcherSubscription?.cancel();
    final watcher = DirectoryWatcher(_projectRoot);
    _watcherSubscription = watcher.events.listen((event) {
      refreshProjectFiles();
    });
  }

  Future<void> _loadAvailableSamples() async {
    _availableSamples = await UniLabFileManager.getSamples();
    notifyListeners();
  }

  Future<void> refreshProjectFiles() async {
    final dir = Directory(_projectRoot);
    if (await dir.exists()) {
      _projectFiles = await UniLabFileManager.listDirectory(_projectRoot);
      // Sort directories first, then files
      _projectFiles.sort((a, b) {
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;
        return p.basename(a.path).compareTo(p.basename(b.path));
      });
    } else {
      _projectFiles = [];
    }
    notifyListeners();
  }

  void setProjectRoot(String path) {
    _projectRoot = path;
    _initWatcher();
    refreshProjectFiles();
  }

  void addNewFile() {
    final newFile = UniLabFile(
      name: 'Untitled${_openFiles.length + 1}.m',
      path: '',
      content: '',
    );
    _openFiles.add(newFile);
    _activeFileIndex = _openFiles.length - 1;
    notifyListeners();
  }

  void loadSample(String name, String content) {
    // Check if file is already open
    final existingIndex = _openFiles.indexWhere((f) => f.name == name);
    if (existingIndex != -1) {
      _activeFileIndex = existingIndex;
    } else {
      final newFile = UniLabFile(
        name: name,
        path: 'sample/$name',
        content: content,
      );
      _openFiles.add(newFile);
      _activeFileIndex = _openFiles.length - 1;
    }
    notifyListeners();
  }

  Future<void> openSample(File file) async {
    final name = p.basename(file.path);
    final content = await UniLabFileManager.readFile(file);
    loadSample(name, content);
  }

  Future<void> openFile(File file) async {
    final path = file.path;
    final name = p.basename(path);

    // Check if file is already open
    final existingIndex = _openFiles.indexWhere(
      (f) => f.path == path || (f.path == '' && f.name == name),
    );
    if (existingIndex != -1) {
      _activeFileIndex = existingIndex;
    } else {
      final content = await UniLabFileManager.readFile(file);
      final newFile = UniLabFile(name: name, path: path, content: content);
      _openFiles.add(newFile);
      _activeFileIndex = _openFiles.length - 1;
    }
    notifyListeners();
  }

  void closeFile(int index) {
    _openFiles.removeAt(index);
    if (_activeFileIndex >= _openFiles.length) {
      _activeFileIndex = _openFiles.length - 1;
    }
    notifyListeners();
  }

  void setActiveFile(int index) {
    _activeFileIndex = index;
    notifyListeners();
  }

  void updateActiveFileContent(String content) {
    if (activeFile != null) {
      _openFiles[_activeFileIndex] = activeFile!.copyWith(
        content: content,
        isModified: true,
      );
      notifyListeners();
    }
  }

  Future<void> saveActiveFile() async {
    if (activeFile == null) return;

    String savePath = activeFile!.path;

    if (savePath.isEmpty) {
      final directory = Directory(_projectRoot);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      savePath = p.join(_projectRoot, activeFile!.name);
    }

    try {
      final file = File(savePath);
      await file.writeAsString(activeFile!.content);

      _openFiles[_activeFileIndex] = activeFile!.copyWith(
        path: savePath,
        isModified: false,
      );

      await refreshProjectFiles();
    } catch (e) {
      _consoleOutput += '\nError saving file: $e\n';
      notifyListeners();
    }
  }

  Future<void> deleteFile(FileSystemEntity entity) async {
    try {
      if (await entity.exists()) {
        await entity.delete(recursive: true);

        // If it was an open file, close it
        final openIndex = _openFiles.indexWhere((f) => f.path == entity.path);
        if (openIndex != -1) {
          closeFile(openIndex);
        }

        await refreshProjectFiles();
      }
    } catch (e) {
      _consoleOutput += '\nError deleting: $e\n';
      notifyListeners();
    }
  }

  Future<void> runActiveFile() async {
    if (activeFile == null) return;

    _isExecuting = true;
    _consoleOutput += '\n>> Running ${activeFile!.name}...\n';
    notifyListeners();

    try {
      final result = await _client.runCode(activeFile!.content);
      _consoleOutput += result.stdout;
      if (result.stderr.isNotEmpty) {
        _consoleOutput += '\nError: ${result.stderr}';
      }
      _workspaceVariables = result.variables;

      // Simulate plot generation if the code suggests it or just for demo
      if (activeFile!.content.contains('plot') ||
          activeFile!.content.contains('surf')) {
        _generatedPlots.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': 'Figure ${_generatedPlots.length + 1}',
          'data': [
            {'x': 0.0, 'y': 1.0},
            {'x': 1.0, 'y': 3.0},
            {'x': 2.0, 'y': 2.0},
            {'x': 3.0, 'y': 5.0},
          ],
        });
      }
    } catch (e) {
      _consoleOutput += '\nExecution Error: $e';
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  void clearConsole() {
    _consoleOutput = '';
    notifyListeners();
  }

  Future<void> openFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m', 'txt', 'csv', 'json'],
    );
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      await openFile(file);
    }
  }

  void clearWorkspace() {
    _workspaceVariables.clear();
    notifyListeners();
  }

  void clearPlots() {
    _generatedPlots.clear();
    notifyListeners();
  }

  void stopExecution() {
    _isExecuting = false;
    _consoleOutput += '\n>> Execution stopped by user.\n';
    notifyListeners();
  }
}
