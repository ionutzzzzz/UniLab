import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:watcher/watcher.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../models/editor_models.dart';
import '../features/workspace/domain/workspace_variable.dart' as domain;
import '../bridge/unilab_bridge.dart';
import '../utils/file_manager.dart';

// Use a conditional import to handle dart:io
import 'dart:io' as io;

enum BackendStatus { connecting, connected, error }

class AppProvider with ChangeNotifier {
  final List<UniLabFile> _openFiles = [];
  int _activeFileIndex = -1;
  List<dynamic> _availableSamples = [];
  List<dynamic> _projectFiles = [];
  late String _projectRoot;

  // Console: structured messages instead of raw string
  final List<ConsoleMessage> _consoleMessages = [];

  Map<String, dynamic> _workspaceVariables = {};
  final List<PlotData> _generatedPlots = [];
  bool _isExecuting = false;
  final Set<String> _savingFileIds = {};

  BackendStatus _backendStatus = BackendStatus.connecting;

  StreamSubscription<WatchEvent>? _watcherSubscription;

  // Callbacks to push state into Riverpod (using domain WorkspaceVariable)
  final void Function(List<domain.WorkspaceVariable>)? onVariablesUpdated;
  final void Function(List<PlotData>)? onPlotsUpdated;

  List<UniLabFile> get openFiles => _openFiles;
  int get activeFileIndex => _activeFileIndex;
  UniLabFile? get activeFile =>
      _activeFileIndex >= 0 ? _openFiles[_activeFileIndex] : null;
  List<ConsoleMessage> get consoleMessages => List.unmodifiable(_consoleMessages);
  String get consoleOutput => _consoleMessages.map((m) => m.text).join('\n');
  Map<String, dynamic> get workspaceVariables => _workspaceVariables;
  List<PlotData> get generatedPlots => List.unmodifiable(_generatedPlots);
  bool get isExecuting => _isExecuting;
  List<dynamic> get availableSamples => _availableSamples;
  List<dynamic> get projectFiles => _projectFiles;
  String get projectRoot => _projectRoot;
  BackendStatus get backendStatus => _backendStatus;

  AppProvider({
    this.onVariablesUpdated,
    this.onPlotsUpdated,
  }) {
    _projectRoot = _discoverProjectRoot();
    _loadAvailableSamples();
    refreshProjectFiles();
    _initWatcher();
    _initBridge();
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

  /// Initialize the FFI bridge to the Rust backend.
  Future<void> _initBridge() async {
    try {
      final backendPath = await UniLabBridge.findBackendPath();
      await UniLabBridge.instance.initialize(backendPath);
      await UniLabBridge.instance.createSession('gui_user');
      _backendStatus = BackendStatus.connected;
      await fetchWorkspaceVariables();
      _addConsoleMessage('UniLab bridge initialized.', ConsoleMessageType.success);
    } catch (e) {
      _backendStatus = BackendStatus.error;
      _addConsoleMessage('Bridge initialization error: $e', ConsoleMessageType.error);
    }
    notifyListeners();
  }

  /// Add a message to the console.
  void _addConsoleMessage(String text, ConsoleMessageType type, {String? source}) {
    _consoleMessages.add(ConsoleMessage(
      text: text,
      type: type,
      source: source ?? 'System',
    ));
    notifyListeners();
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

  Future<void> createProjectFile(String fileName, String content) async {
    if (kIsWeb) {
      final newFile = UniLabFile(
        id: const Uuid().v4(),
        name: fileName,
        path: 'web/$fileName',
        content: content,
      );
      _openFiles.add(newFile);
      _activeFileIndex = _openFiles.length - 1;
      notifyListeners();
      return;
    }

    try {
      final path = p.join(_projectRoot, fileName);
      final file = io.File(path);
      await file.writeAsString(content);

      // Also sync to backend workspace
      try {
        await UniLabBridge.instance.createFile(fileName, content);
      } catch (e) {
        debugPrint('Failed to sync file to backend: $e');
      }

      await refreshProjectFiles();
      await openFile(file);
    } catch (e) {
      _addConsoleMessage('Error creating file: $e', ConsoleMessageType.error);
    }
  }

  void openImportDataTab() {
    final existingIndex = _openFiles.indexWhere((f) => f.path == 'unilab://import-data');
    if (existingIndex != -1) {
      _activeFileIndex = existingIndex;
    } else {
      final importFile = UniLabFile(
        id: 'import-data',
        name: 'Import Data',
        path: 'unilab://import-data',
        content: '',
      );
      _openFiles.add(importFile);
      _activeFileIndex = _openFiles.length - 1;
    }
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
    final path = (file as io.File).absolute.path;
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

  void updateFileContent(String id, String content) {
    final index = _openFiles.indexWhere((f) => f.id == id);
    if (index != -1 && _openFiles[index].content != content) {
      _openFiles[index] = _openFiles[index].copyWith(
        content: content,
        isModified: true,
      );
      notifyListeners();
    }
  }

  void updateActiveFileContent(String content) {
    if (activeFile != null) {
      updateFileContent(activeFile!.id, content);
    }
  }

  Future<void> saveActiveFile() async {
    if (_activeFileIndex < 0 || _activeFileIndex >= _openFiles.length || kIsWeb) return;

    final fileToSave = _openFiles[_activeFileIndex];
    final fileId = fileToSave.id;

    if (_savingFileIds.contains(fileId)) {
       debugPrint('AppProvider: Save already in progress for file: $fileId');
       return;
    }

    // Safeguard: Only save text files to prevent corruption of binary files
    if (fileToSave.path.isNotEmpty && !UniLabFileManager.isTextFile(fileToSave.path)) {
      debugPrint('AppProvider: Skipping save for binary file: ${fileToSave.path}');
      return;
    }

    String savePath = fileToSave.path;
    _savingFileIds.add(fileId);

    try {
      if (savePath.isEmpty) {
        final directory = io.Directory(_projectRoot);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        savePath = p.join(_projectRoot, fileToSave.name);
      }

      final file = io.File(savePath);
      await file.writeAsString(fileToSave.content);

      // Also sync to backend workspace
      try {
        await UniLabBridge.instance.createFile(fileToSave.name, fileToSave.content);
      } catch (e) {
        debugPrint('Failed to sync file to backend: $e');
      }

      // Re-verify the file is still open and find its current index (it might have moved)
      final currentIndex = _openFiles.indexWhere((f) => f.id == fileId);
      if (currentIndex != -1) {
        _openFiles[currentIndex] = _openFiles[currentIndex].copyWith(
          path: savePath,
          isModified: false,
        );
        notifyListeners();
      }

      await refreshProjectFiles();
    } catch (e) {
      _addConsoleMessage('Error saving file: $e', ConsoleMessageType.error);
    } finally {
      _savingFileIds.remove(fileId);
    }
  }

  Future<void> deleteFile(dynamic entity) async {
    if (kIsWeb) return;
    try {
      final ioEntity = entity as io.FileSystemEntity;
      if (await ioEntity.exists()) {
        final fileName = p.basename(ioEntity.path);
        await ioEntity.delete(recursive: true);

        // Also delete from backend
        try {
          await UniLabBridge.instance.createFile(fileName, ''); // Could add delete method later
        } catch (e) {
          debugPrint('Failed to sync file deletion to backend: $e');
        }

        // If it was an open file, close it
        final openIndex = _openFiles.indexWhere((f) => f.path == ioEntity.path);
        if (openIndex != -1) {
          closeFile(openIndex);
        }

        await refreshProjectFiles();
      }
    } catch (e) {
      _addConsoleMessage('Error deleting: $e', ConsoleMessageType.error);
    }
  }

  void updateMovedFilePaths(String oldPath, String newPath) {
    bool changed = false;
    for (int i = 0; i < _openFiles.length; i++) {
      final file = _openFiles[i];
      if (file.path == oldPath) {
        _openFiles[i] = file.copyWith(path: newPath);
        changed = true;
      } else if (file.path.startsWith(oldPath + '/')) {
        final remainingPath = file.path.substring(oldPath.length);
        _openFiles[i] = file.copyWith(path: newPath + remainingPath);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  Future<void> runActiveFile() async {
    if (activeFile == null) return;

    _isExecuting = true;
    _addConsoleMessage('>> Running ${activeFile!.name}...', ConsoleMessageType.output, source: 'System');

    try {
      final result = await UniLabBridge.instance.execute(activeFile!.content);

      if (result.stdout.isNotEmpty) {
        _addConsoleMessage(result.stdout, ConsoleMessageType.output, source: 'Script');
      }
      if (result.stderr.isNotEmpty) {
        _addConsoleMessage(result.stderr, ConsoleMessageType.error, source: 'Error');
      }

      // Update workspace variables from result
      _updateVariablesFromResult(result);

      // Parse plots from result.extra
      _updatePlotsFromResult(result);
    } catch (e) {
      _addConsoleMessage('Execution Error: $e', ConsoleMessageType.error, source: 'Error');
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  /// Convert ExecutionResult variables to WorkspaceVariable list and push to Riverpod.
  void _updateVariablesFromResult(ExecutionResult result) {
    final vars = result.variables.entries.map((e) {
      final info = e.value as Map<String, dynamic>;
      final shape = info['shape'] as List<dynamic>?;
      final sizeStr = shape != null ? shape.join('x') : '1x1';
      return domain.WorkspaceVariable(
        name: e.key,
        value: info['preview']?.toString() ?? '',
        size: sizeStr,
        typeClass: info['dtype']?.toString() ?? 'unknown',
      );
    }).toList();
    _workspaceVariables = result.variables;
    onVariablesUpdated?.call(vars);
  }

  /// Parse plots from result.extra and create PlotData objects.
  void _updatePlotsFromResult(ExecutionResult result) {
    _generatedPlots.clear();

    final b64List = result.extra['plot_data_b64'] as List<dynamic>? ?? [];
    final plot3dList = result.extra['plot_3d_data'] as List<dynamic>? ?? [];

    // Base64 PNG plots
    for (int i = 0; i < b64List.length; i++) {
      final dataUri = b64List[i] as String;
      _generatedPlots.add(PlotData(
        title: 'Figure ${i + 1}',
        type: 'image',
        xData: [],
        yData: [],
        imageDataUri: dataUri,
      ));
    }

    // 3D / structured data plots
    for (int i = 0; i < plot3dList.length; i++) {
      final raw = plot3dList[i] as Map<String, dynamic>;
      final xRaw = (raw['x'] as List<dynamic>?)
          ?.map((v) => (v as num).toDouble())
          .toList() ?? [];
      final yRaw = (raw['y'] as List<dynamic>?)
          ?.map((v) => (v as num).toDouble())
          .toList() ?? [];
      _generatedPlots.add(PlotData(
        title: 'Figure ${b64List.length + i + 1}',
        type: raw['type']?.toString() ?? 'line',
        xData: xRaw,
        yData: yRaw,
      ));
    }

    onPlotsUpdated?.call(_generatedPlots);
  }

  void clearConsole() {
    _consoleMessages.clear();
    notifyListeners();
  }

  /// Execute a command from the console REPL.
  Future<void> runConsoleCommand(String command) async {
    if (command.isEmpty) return;

    _addConsoleMessage('>> $command', ConsoleMessageType.output, source: 'System');

    try {
      final result = await UniLabBridge.instance.execute(command);

      if (result.stdout.isNotEmpty) {
        _addConsoleMessage(result.stdout, ConsoleMessageType.output, source: 'Script');
      }
      if (result.stderr.isNotEmpty) {
        _addConsoleMessage(result.stderr, ConsoleMessageType.error, source: 'Error');
      }

      _updateVariablesFromResult(result);
      _updatePlotsFromResult(result);
    } catch (e) {
      _addConsoleMessage('Error: $e', ConsoleMessageType.error, source: 'Error');
    }
  }

  /// Get autocomplete suggestions from the backend.
  Future<List<String>> getAutocomplete(String prefix) async {
    try {
      return await UniLabBridge.instance.getAutocomplete(prefix);
    } catch (e) {
      debugPrint('Autocomplete error: $e');
      return [];
    }
  }

  /// Fetch workspace variables from the backend.
  Future<void> fetchWorkspaceVariables() async {
    try {
      final workspace = await UniLabBridge.instance.getWorkspace();
      if (workspace.isEmpty) return;

      final vars = (workspace['variables'] as Map<String, dynamic>?)
          ?.entries
          .map((e) {
            final info = e.value as Map<String, dynamic>;
            final shape = info['shape'] as List<dynamic>?;
            final sizeStr = shape != null ? shape.join('x') : '1x1';
            return domain.WorkspaceVariable(
              name: e.key,
              value: info['preview']?.toString() ?? '',
              size: sizeStr,
              typeClass: info['dtype']?.toString() ?? 'unknown',
            );
          })
          .toList() ?? [];

      _workspaceVariables = workspace['variables'] ?? {};
      onVariablesUpdated?.call(vars);
      notifyListeners();
    } catch (e) {
      debugPrint('fetchWorkspaceVariables error: $e');
    }
  }

  Future<void> openFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'm', 'txt', 'csv', 'json', 'md', 'py', 'pdf',
        'png', 'jpg', 'jpeg', 'gif', 'webp',
        'mp3', 'wav', 'm4a', 'ogg'
      ],
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

  Future<void> openFolderPicker() async {
    if (kIsWeb) return;
    
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    
    if (selectedDirectory != null) {
      setProjectRoot(selectedDirectory);
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
    _addConsoleMessage('>> Execution stopped by user.', ConsoleMessageType.warning, source: 'System');
  }

  // Editor Actions
  final StreamController<String> _editorActionController = StreamController<String>.broadcast();
  Stream<String> get editorActions => _editorActionController.stream;

  void triggerEditorAction(String action) {
    debugPrint('AppProvider: Triggering editor action: $action');
    _editorActionController.add(action);
  }
}
