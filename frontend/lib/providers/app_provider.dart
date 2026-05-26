import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/models.dart';
import '../utils/backend_client.dart';
import '../utils/file_manager.dart';

class AppProvider with ChangeNotifier {
  final BackendClient _client = BackendClient();
  
  final List<UniLabFile> _openFiles = [];
  int _activeFileIndex = -1;
  List<File> _availableSamples = [];
  List<FileSystemEntity> _projectFiles = [];
  String _projectRoot = 'sample';
  
  String _consoleOutput = '';
  Map<String, dynamic> _workspaceVariables = {};
  List<Map<String, dynamic>> _generatedPlots = [];
  bool _isExecuting = false;

  List<UniLabFile> get openFiles => _openFiles;
  int get activeFileIndex => _activeFileIndex;
  UniLabFile? get activeFile => _activeFileIndex >= 0 ? _openFiles[_activeFileIndex] : null;
  String get consoleOutput => _consoleOutput;
  Map<String, dynamic> get workspaceVariables => _workspaceVariables;
  List<Map<String, dynamic>> get generatedPlots => _generatedPlots;
  bool get isExecuting => _isExecuting;
  List<File> get availableSamples => _availableSamples;
  List<FileSystemEntity> get projectFiles => _projectFiles;
  String get projectRoot => _projectRoot;

  AppProvider() {
    _loadAvailableSamples();
    refreshProjectFiles();
  }

  Future<void> _loadAvailableSamples() async {
    _availableSamples = await UniLabFileManager.getSamples();
    notifyListeners();
  }

  Future<void> refreshProjectFiles() async {
    _projectFiles = await UniLabFileManager.listDirectory(_projectRoot);
    // Sort directories first, then files
    _projectFiles.sort((a, b) {
      if (a is Directory && b is! Directory) return -1;
      if (a is! Directory && b is Directory) return 1;
      return p.basename(a.path).compareTo(p.basename(b.path));
    });
    notifyListeners();
  }

  void setProjectRoot(String path) {
    _projectRoot = path;
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
    final existingIndex = _openFiles.indexWhere((f) => f.path == path || (f.path == '' && f.name == name));
    if (existingIndex != -1) {
      _activeFileIndex = existingIndex;
    } else {
      final content = await UniLabFileManager.readFile(file);
      final newFile = UniLabFile(
        name: name,
        path: path,
        content: content,
      );
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
      if (activeFile!.content.contains('plot') || activeFile!.content.contains('surf')) {
        _generatedPlots.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': 'Figure ${_generatedPlots.length + 1}',
          'data': [
             {'x': 0.0, 'y': 1.0},
             {'x': 1.0, 'y': 3.0},
             {'x': 2.0, 'y': 2.0},
             {'x': 3.0, 'y': 5.0},
          ]
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
}
