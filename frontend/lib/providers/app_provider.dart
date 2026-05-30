import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:watcher/watcher.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/backend_client.dart';
import '../utils/file_manager.dart';

// Use a conditional import to handle dart:io
import 'dart:io' as io;

class AppProvider with ChangeNotifier {
  final BackendClient _client = BackendClient();

  final List<UniLabFile> _openFiles = [];
  int _activeFileIndex = -1;
  List<dynamic> _availableSamples = [];
  List<dynamic> _projectFiles = [];
  late String _projectRoot;
  
  String _consoleOutput = '';

  Map<String, dynamic> _workspaceVariables = {};
  final List<Map<String, dynamic>> _generatedPlots = [];
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
  List<dynamic> get availableSamples => _availableSamples;
  List<dynamic> get projectFiles => _projectFiles;
  String get projectRoot => _projectRoot;

  AppProvider() {
    _projectRoot = _discoverProjectRoot();
    _loadAvailableSamples();
    refreshProjectFiles();
    _initWatcher();
  }

  String _discoverProjectRoot() {
    if (kIsWeb) return '/web-virtual-root';

    try {
      // Start from current working directory
      io.Directory current = io.Directory.current;
      
      // Strategy: Look for 'sample' directory in current or parent directories
      for (int i = 0; i < 3; i++) {
        final samplePath = p.join(current.path, 'sample');
        if (io.Directory(samplePath).existsSync()) {
          return samplePath;
        }
        // If we are in 'frontend', the 'sample' is likely in the parent
        final parentSamplePath = p.join(current.parent.path, 'sample');
        if (io.Directory(parentSamplePath).existsSync()) {
          return parentSamplePath;
        }
        current = current.parent;
      }
      return p.join(io.Directory.current.path, 'sample');
    } catch (e) {
      return 'sample';
    }
  }

  @override
  void dispose() {
    _watcherSubscription?.cancel();
    super.dispose();
  }

  void _initWatcher() {
    if (kIsWeb) return;

    _watcherSubscription?.cancel();
    try {
      final watcher = DirectoryWatcher(_projectRoot);
      _watcherSubscription = watcher.events.listen((event) {
        refreshProjectFiles();
      });
    } catch (e) {
      debugPrint('Watcher error: $e');
    }
  }

  Future<void> _loadAvailableSamples() async {
    _availableSamples = await UniLabFileManager.getSamples();
    notifyListeners();
  }

  Future<void> refreshProjectFiles() async {
    if (kIsWeb) return;

    try {
      final dir = io.Directory(_projectRoot);
      if (await dir.exists()) {
        _projectFiles = await UniLabFileManager.listDirectory(_projectRoot);
        // Sort directories first, then files
        _projectFiles.sort((a, b) {
          if (a is io.Directory && b is! io.Directory) return -1;
          if (a is! io.Directory && b is io.Directory) return 1;
          return p.basename(a.path).compareTo(p.basename(b.path));
        });
      } else {
        _projectFiles = [];
      }
    } catch (e) {
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
      id: const Uuid().v4(),
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
    final existingIndex = _openFiles.indexWhere((f) => f.name == name && f.path == 'sample/$name');
    if (existingIndex != -1) {
      _activeFileIndex = existingIndex;
    } else {
      final newFile = UniLabFile(
        id: const Uuid().v4(),
        name: name,
        path: 'sample/$name',
        content: content,
      );
      _openFiles.add(newFile);
      _activeFileIndex = _openFiles.length - 1;
    }
    notifyListeners();
  }

  Future<void> openSample(dynamic file) async {
    if (kIsWeb) return;
    final name = p.basename((file as io.File).path);
    final content = await UniLabFileManager.readFile(file);
    loadSample(name, content);
  }

  Future<void> openFile(dynamic file) async {
    if (kIsWeb) return;
    final path = (file as io.File).path;
    final name = p.basename(path);

    // Check if file is already open
    final existingIndex = _openFiles.indexWhere(
      (f) => f.path == path,
    );
    if (existingIndex != -1) {
      _activeFileIndex = existingIndex;
    } else {
      final content = await UniLabFileManager.readFile(file);
      final newFile = UniLabFile(id: const Uuid().v4(), name: name, path: path, content: content);
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
    debugPrint('AppProvider: Setting active file to index $index');
    _activeFileIndex = index;
    notifyListeners();
  }

  void reorderOpenFile(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final UniLabFile file = _openFiles.removeAt(oldIndex);
    _openFiles.insert(newIndex, file);

    // Keep active file index consistent
    if (_activeFileIndex == oldIndex) {
      _activeFileIndex = newIndex;
    } else if (oldIndex < _activeFileIndex && newIndex >= _activeFileIndex) {
      _activeFileIndex -= 1;
    } else if (oldIndex > _activeFileIndex && newIndex <= _activeFileIndex) {
      _activeFileIndex += 1;
    }
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
    if (activeFile == null || kIsWeb) return;

    String savePath = activeFile!.path;

    try {
      if (savePath.isEmpty) {
        final directory = io.Directory(_projectRoot);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        savePath = p.join(_projectRoot, activeFile!.name);
      }

      final file = io.File(savePath);
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

  Future<void> deleteFile(dynamic entity) async {
    if (kIsWeb) return;
    try {
      final ioEntity = entity as io.FileSystemEntity;
      if (await ioEntity.exists()) {
        await ioEntity.delete(recursive: true);

        // If it was an open file, close it
        final openIndex = _openFiles.indexWhere((f) => f.path == ioEntity.path);
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
    
    if (result != null) {
      if (kIsWeb) {
        // Handle web file selection
        final fileData = result.files.single;
        final name = fileData.name;
        final content = String.fromCharCodes(fileData.bytes!);
        
        final newFile = UniLabFile(id: const Uuid().v4(), name: name, path: 'web/$name', content: content);
        _openFiles.add(newFile);
        _activeFileIndex = _openFiles.length - 1;
        notifyListeners();
      } else if (result.files.single.path != null) {
        io.File file = io.File(result.files.single.path!);
        await openFile(file);
      }
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
