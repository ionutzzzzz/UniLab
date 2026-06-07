import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:watcher/watcher.dart';
import 'package:highlight/highlight.dart' as hl;
import 'package:uuid/uuid.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart' as dmw;
import '../models/models.dart';
import '../models/editor_models.dart';
import '../features/workspace/domain/workspace_variable.dart' as domain;
import '../bridge/unilab_bridge.dart';
import '../utils/file_manager.dart';
import 'settings_provider.dart';
import 'dart:io' as io;

enum BackendStatus { connecting, connected, error }

class AppProvider with ChangeNotifier {
  final List<UniLabFile> _openFiles = [];
  int _activeFileIndex = -1;
  List<dynamic> _availableSamples = [];
  List<dynamic> _projectFiles = [];
  String? _projectRoot;
  bool _isWelcomeMode = true;

  final List<ConsoleMessage> _consoleMessages = [];
  final List<String> _commandHistory = [];
  Map<String, dynamic> _workspaceVariables = {};
  final List<PlotData> _generatedPlots = [];

  SettingsProvider? _settingsProvider;

  // Simulation State

  // Simulation State
  bool _isSimulationActive = false;
  String? _simulationModel;
  final List<Map<String, dynamic>> _simulationControls = [];
  final List<PlotData> _simulationPlots = [];
  String? _simWindowId;

  bool _isExecuting = false;
  final Set<String> _savingFileIds = {};
  final List<String> _recentFiles = [];
  final List<String> _recentProjects = [];
  Map<String, dynamic> _serverInfo = {};
  String _selectedConsoleTab = 'output';
  String _selectedWorkspaceSegment = 'Variables';

  String? _plotsWindowId;
  String? _simulationWindowId;

  BackendStatus _backendStatus = BackendStatus.connecting;

  StreamSubscription<WatchEvent>? _watcherSubscription;
  StreamSubscription? _bridgeEventSubscription;
  StreamSubscription<void>? _windowsChangedSubscription;

  final void Function(List<domain.WorkspaceVariable>)? onVariablesUpdated;
  final void Function(List<PlotData>)? onPlotsUpdated;

  List<UniLabFile> get openFiles => _openFiles;
  int get activeFileIndex => _activeFileIndex;
  UniLabFile? get activeFile =>
      _activeFileIndex >= 0 ? _openFiles[_activeFileIndex] : null;
  List<ConsoleMessage> get consoleMessages =>
      List.unmodifiable(_consoleMessages);
  List<String> get commandHistory => List.unmodifiable(_commandHistory);
  String get consoleOutput => _consoleMessages.map((m) => m.text).join('\n');
  Map<String, dynamic> get workspaceVariables => _workspaceVariables;

  bool get isSimulationActive => _isSimulationActive;
  String? get simulationModel => _simulationModel;
  List<Map<String, dynamic>> get simulationControls =>
      List.unmodifiable(_simulationControls);
  List<PlotData> get simulationPlots => List.unmodifiable(_simulationPlots);

  List<PlotData> get generatedPlots => List.unmodifiable(_generatedPlots);
  bool get isExecuting => _isExecuting;
  List<dynamic> get availableSamples => _availableSamples;
  List<dynamic> get projectFiles => _projectFiles;
  List<String> get recentFiles => List.unmodifiable(_recentFiles);
  List<String> get recentProjects => List.unmodifiable(_recentProjects);
  String? get projectRoot => _projectRoot;
  bool get isWelcomeMode => _isWelcomeMode;
  BackendStatus get backendStatus => _backendStatus;
  Map<String, dynamic> get serverInfo => _serverInfo;
  String get selectedConsoleTab => _selectedConsoleTab;
  String get selectedWorkspaceSegment => _selectedWorkspaceSegment;

  void setSelectedConsoleTab(String tab) {
    _selectedConsoleTab = tab;
    notifyListeners();
  }

  void setSelectedWorkspaceSegment(String segment) {
    _selectedWorkspaceSegment = segment;
    notifyListeners();
  }

  AppProvider({this.onVariablesUpdated, this.onPlotsUpdated}) {
    _initApp();
  }

  Future<void> _initApp() async {
    await _loadRecentFiles();
    await _loadRecentProjects();
    
    // Check if we should auto-open last project
    if (_recentProjects.isNotEmpty && !kIsWeb) {
      final lastProject = _recentProjects.first;
      if (await io.Directory(lastProject).exists()) {
        setProjectRoot(lastProject);
      }
    } else if (!kIsWeb) {
      setProjectRoot(await _discoverProjectRoot());
    }
    
    _loadAvailableSamples();
    _initBridge();
    _initWindowsListener();

    // Listen for control updates from simulation window
    dmw.WindowMethodChannel('simulation_channel').setMethodCallHandler((
      call,
    ) async {
      if (call.method == 'on_sim_control') {
        final data = jsonDecode(call.arguments);
        await sendSimControlUpdate(data['id'], data['value']);
      }
      return null;
    });
  }

  void updateSettings(SettingsProvider settings) {
    _settingsProvider = settings;
    notifyListeners();
  }

  Future<void> _loadRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recentFiles') ?? [];
    _recentFiles.clear();
    _recentFiles.addAll(list);
    notifyListeners();
  }

  Future<void> _loadRecentProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recentProjects') ?? [];
    _recentProjects.clear();
    _recentProjects.addAll(list);
    notifyListeners();
  }

  Future<void> _addToRecentProjects(String path) async {
    if (path.isEmpty || kIsWeb) return;
    _recentProjects.remove(path);
    _recentProjects.insert(0, path);
    if (_recentProjects.length > 10) _recentProjects.removeLast();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recentProjects', _recentProjects);
    notifyListeners();
  }

  Future<void> _addToRecentFiles(String path) async {
    if (path.isEmpty || path.startsWith('unilab://') || path.startsWith('web/'))
      return;
    _recentFiles.remove(path);
    _recentFiles.insert(0, path);
    if (_recentFiles.length > 20) _recentFiles.removeLast();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recentFiles', _recentFiles);
    notifyListeners();
  }

  Future<String> _discoverProjectRoot() async {
    if (kIsWeb) return '/web-virtual-root';
    try {
      final backendParent = await UniLabBridge.findBackendPath();
      final samples = p.join(backendParent, 'samples');
      if (await io.Directory(samples).exists()) return samples;
      
      // Fallback to what findSamplesPath returns
      return await UniLabBridge.findSamplesPath();
    } catch (e) {
       return await UniLabBridge.findSamplesPath();
    }
  }

  @override
  void dispose() {
    _watcherSubscription?.cancel();
    _bridgeEventSubscription?.cancel();
    _windowsChangedSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initBridge() async {
    try {
      if (UniLabBridge.instance.initialized &&
          UniLabBridge.instance.sessionId == null) {
        UniLabBridge.resetInstance();
      }
      final backendPath = await UniLabBridge.findBackendPath();
      // _addConsoleMessage('Connecting to backend at $backendPath...', ConsoleMessageType.output);

      await UniLabBridge.instance.initialize(backendPath);
      await UniLabBridge.instance.createSession('gui_user');
      _backendStatus = BackendStatus.connected;
      _serverInfo = await UniLabBridge.instance.getInfo();

      _bridgeEventSubscription?.cancel();
      _bridgeEventSubscription = UniLabBridge.instance.events.listen((event) {
        if (event['event'] == 'workspace_updated') {
          _handleWorkspaceUpdateEvent(event);
        } else if (event['type'] == 'sim_event') {
          _handleSimEvent(event);
        }
      });
      await fetchWorkspaceVariables();
    } catch (e) {
      _backendStatus = BackendStatus.error;
      _addConsoleMessage(
        'Backend initialization error: $e',
        ConsoleMessageType.error,
      );
      debugPrint('[AppProvider] Bridge initialization error: $e');
    }
    notifyListeners();
  }

  void _handleSimEvent(Map<String, dynamic> event) {
    final type = event['event'];
    final data = event['data'];

    if (type == 'SIM_START') {
      _isSimulationActive = true;
      _simulationModel = data['model'];
      _simulationControls.clear();
      _simulationPlots.clear();
      openDetachedSimWindow();
    } else if (type == 'CREATE_CONTROL') {
      _simulationControls.add(data);
      _syncSimWindow();
    } else if (type == 'GRAPHICAL_PLOT') {
      _handleSimPlot(data);
      _syncSimWindow();
    } else if (type == 'SIM_STOPPED') {
      _isSimulationActive = false;
    }
    notifyListeners();
  }

  void _handleSimPlot(Map<String, dynamic> data) {
    final figNum = data['fig'];
    final plotData = PlotData(
      title: 'Figure $figNum',
      type: 'image',
      xData: [],
      yData: [],
      imageDataUri: data['data'],
    );
    final index = _simulationPlots.indexWhere(
      (p) => p.title == 'Figure $figNum',
    );
    if (index != -1) {
      _simulationPlots[index] = plotData;
    } else {
      _simulationPlots.add(plotData);
    }
  }

  Future<void> sendSimControlUpdate(String id, dynamic value) async {
    await UniLabBridge.instance.sendSimEvent({'id': id, 'value': value});
  }

  Future<void> openDetachedSimWindow() async {
    if (_simWindowId != null || kIsWeb) return;
    try {
      final window = await dmw.WindowController.create(
        dmw.WindowConfiguration(
          arguments: jsonEncode({
            'type': 'simulation',
            'model': _simulationModel,
            'controls': _simulationControls,
            'plots': _simulationPlots.map((p) => p.toJson()).toList(),
          }),
          hiddenAtLaunch: false,
        ),
      );
      _simWindowId = window.windowId.toString();
      await window.show();
    } catch (e) {
      debugPrint('Error creating sim window: $e');
      _simWindowId = null;
    }
  }

  void _syncSimWindow() {
    if (_simWindowId == null) return;
    try {
      dmw.WindowController.fromWindowId(_simWindowId!).invokeMethod(
        'update_sim_state',
        jsonEncode({
          'model': _simulationModel,
          'controls': _simulationControls,
          'plots': _simulationPlots.map((p) => p.toJson()).toList(),
        }),
      );
    } catch (e) {
      debugPrint('Error syncing sim window: $e');
      _simWindowId = null;
    }
  }

  void _handleWorkspaceUpdateEvent(Map<String, dynamic> event) {
    final variables = event['variables'] as Map<String, dynamic>? ?? {};
    _updateVariablesFromMap(variables);
  }

  void _updateVariablesFromMap(Map<String, dynamic> variables) {
    // Check if variables actually changed to avoid flickering/excessive rebuilds
    if (mapEquals(_workspaceVariables, variables)) return;
    
    _workspaceVariables = variables;
    final vars = _workspaceVariables.entries.map((e) {
      final info = e.value as Map<String, dynamic>;
      final shape = info['shape'] as List<dynamic>?;
      final sizeStr = shape != null ? shape.join('x') : '1x1';
      return domain.WorkspaceVariable(
        name: e.key,
        value: info['preview']?.toString() ?? '',
        size: sizeStr,
        typeClass: info['dtype']?.toString() ?? 'unknown',
        min: info['min']?.toString() ?? '',
        max: info['max']?.toString() ?? '',
        mean: info['mean']?.toString() ?? '',
        median: info['median']?.toString() ?? '',
        sum: info['sum']?.toString() ?? '',
        variance: info['variance']?.toString() ?? '',
        std: info['std']?.toString() ?? '',
        range: info['range']?.toString() ?? '',
        mode: info['mode']?.toString() ?? '',
      );
    }).toList();
    onVariablesUpdated?.call(vars);
    notifyListeners();
  }

  void _addConsoleMessage(
    String text,
    ConsoleMessageType type, {
    String? source,
  }) {
    if (text.isEmpty) return;
    final lines = text.split('\n');
    for (var line in lines) {
      String trimmedLine = line.trim();
      if (trimmedLine.isEmpty && lines.length > 1 && line == lines.last) {
        continue;
      }
      if (trimmedLine.contains('::CLEAR_TERMINAL::')) {
        clearConsole();
        continue;
      }
      if (trimmedLine.contains('::CLEAR_WORKSPACE::')) {
        _workspaceVariables.clear();
        onVariablesUpdated?.call([]);
        notifyListeners();
        continue;
      }
      if (trimmedLine.contains('::CLEAR_VAR::')) {
        final parts = trimmedLine.split('::CLEAR_VAR::');
        if (parts.length > 1) _removeVariable(parts[1].trim());
        continue;
      }
      if (trimmedLine.contains('::OPEN_FILE::')) {
        final parts = trimmedLine.split('::OPEN_FILE::');
        if (parts.length > 1) _handleOpenFileCommand(parts[1].trim());
        continue;
      }
      _consoleMessages.add(
        ConsoleMessage(text: line, type: type, source: source ?? 'System'),
      );
    }
    notifyListeners();
  }

  Future<void> _handleOpenFileCommand(String filename) async {
    String fullPath;
    if (filename.startsWith('sample/')) {
      final samplesPath = await UniLabBridge.findSamplesPath();
      fullPath = p.join(p.dirname(samplesPath), filename);
    } else {
      if (_projectRoot == null) return;
      fullPath = p.join(_projectRoot!, filename);
    }
    final file = io.File(fullPath);
    if (await file.exists()) await openFile(file);
  }

  void _removeVariable(String name) {
    _workspaceVariables.remove(name);
    _updateVariablesFromMap(_workspaceVariables);
  }

  void _initWatcher() {
    if (kIsWeb || _projectRoot == null) return;
    _watcherSubscription?.cancel();
    try {
      final watcher = DirectoryWatcher(_projectRoot!);
      _watcherSubscription = watcher.events.listen(
        (event) => refreshProjectFiles(),
      );
    } catch (e) {
      debugPrint('Watcher error: $e');
    }
  }

  void _initWindowsListener() {
    if (kIsWeb) return;
    _windowsChangedSubscription?.cancel();
    try {
      _windowsChangedSubscription = dmw.onWindowsChanged.listen((_) {
        if (_plotsWindowId != null) _checkPlotsWindowExists();
        if (_simWindowId != null) _checkSimWindowExists();
      });
    } catch (e) {
      debugPrint('Windows listener error: $e');
    }
  }

  Future<void> _checkPlotsWindowExists() async {
    try {
      if (_plotsWindowId == null) return;
      final allWindows = await dmw.WindowController.getAll();
      if (!allWindows.any((w) => w.windowId.toString() == _plotsWindowId)) {
        _plotsWindowId = null;
        notifyListeners();
      }
    } catch (e) {
      _plotsWindowId = null;
    }
  }

  Future<void> _checkSimWindowExists() async {
    try {
      if (_simWindowId == null) return;
      final allWindows = await dmw.WindowController.getAll();
      if (!allWindows.any((w) => w.windowId.toString() == _simWindowId)) {
        _simWindowId = null;
        notifyListeners();
      }
    } catch (e) {
      _simWindowId = null;
    }
  }

  Future<void> _loadAvailableSamples() async {
    _availableSamples = await UniLabFileManager.getSamples();
    notifyListeners();
  }

  Future<void> refreshProjectFiles() async {
    if (kIsWeb || _projectRoot == null) return;
    try {
      final dir = io.Directory(_projectRoot!);
      if (await dir.exists()) {
        _projectFiles = await UniLabFileManager.listDirectory(_projectRoot!);
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
    _isWelcomeMode = false;
    _addToRecentProjects(path);
    _initWatcher();
    refreshProjectFiles();
    notifyListeners();
  }

  void resetToWelcome() {
    _isWelcomeMode = true;
    _projectRoot = null;
    _openFiles.clear();
    _activeFileIndex = -1;
    _watcherSubscription?.cancel();
    _projectFiles = [];
    notifyListeners();
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
      final path = 'web/$fileName';
      final existingIndex = _openFiles.indexWhere((f) => f.path == path);
      if (existingIndex != -1) {
        _activeFileIndex = existingIndex;
        // Optionally update content if it's a "create" call that should overwrite?
        // Usually creation should check if it exists first, but here we just prevent duplicate tab.
      } else {
        final newFile = UniLabFile(
          id: const Uuid().v4(),
          name: fileName,
          path: path,
          content: content,
        );
        _openFiles.add(newFile);
        _activeFileIndex = _openFiles.length - 1;
      }
      notifyListeners();
      return;
    }
    if (_projectRoot == null) return;
    try {
      final path = p.join(_projectRoot!, fileName);
      final file = io.File(path);
      await file.writeAsString(content);
      await UniLabBridge.instance.createFile(fileName, content);
      await refreshProjectFiles();
      await openFile(file);
    } catch (e) {
      _addConsoleMessage('Error creating file: $e', ConsoleMessageType.error);
    }
  }

  void openImportDataTab() {
    final existingIndex = _openFiles.indexWhere(
      (f) => f.path == 'unilab://import-data',
    );
    if (existingIndex != -1) {
      _activeFileIndex = existingIndex;
    } else {
      _openFiles.add(
        UniLabFile(
          id: 'import-data',
          name: 'Import Data',
          path: 'unilab://import-data',
          content: '',
        ),
      );
      _activeFileIndex = _openFiles.length - 1;
    }
    notifyListeners();
  }

  void loadSample(String name, String content, {String? path}) {
    final existingIndex = _openFiles.indexWhere(
      (f) => f.name == name && (path == null || f.path == path),
    );
    if (existingIndex != -1) {
      _activeFileIndex = existingIndex;
    } else {
      _openFiles.add(
        UniLabFile(
          id: const Uuid().v4(),
          name: name,
          path: path ?? 'sample/$name',
          content: content,
        ),
      );
      _activeFileIndex = _openFiles.length - 1;
    }
    notifyListeners();
  }

  Future<void> openSample(dynamic file) async {
    final content = await UniLabFileManager.readFile(file as io.File);
    loadSample(p.basename(file.path), content, path: file.path);
  }

  Future<void> refreshAvailableSamples() async {
    _availableSamples = await UniLabFileManager.getSamples();
    notifyListeners();
  }

  Future<void> openFile(dynamic file) async {
    if (file is! io.File) return;
    final path = p.canonicalize(file.absolute.path);
    final existingIndex = _openFiles.indexWhere((f) => f.path == path);
    if (existingIndex != -1) {
      _activeFileIndex = existingIndex;
      _addToRecentFiles(path);
      notifyListeners();
      return;
    }

    final content = await UniLabFileManager.readFile(file);

    // Check again after await to prevent race conditions (e.g. from double clicking)
    final reCheckIndex = _openFiles.indexWhere((f) => f.path == path);
    if (reCheckIndex != -1) {
      _activeFileIndex = reCheckIndex;
    } else {
      _openFiles.add(
        UniLabFile(
          id: const Uuid().v4(),
          name: p.basename(path),
          path: path,
          content: content,
        ),
      );
      _activeFileIndex = _openFiles.length - 1;
    }
    _addToRecentFiles(path);
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

  void reorderOpenFile(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final UniLabFile file = _openFiles.removeAt(oldIndex);
    _openFiles.insert(newIndex, file);
    if (_activeFileIndex == oldIndex) {
      _activeFileIndex = newIndex;
    } else if (oldIndex < _activeFileIndex && newIndex >= _activeFileIndex)
      _activeFileIndex -= 1;
    else if (oldIndex > _activeFileIndex && newIndex <= _activeFileIndex)
      _activeFileIndex += 1;
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
    if (activeFile != null) updateFileContent(activeFile!.id, content);
  }

  Future<void> saveActiveFile() async {
    if (_activeFileIndex < 0 || kIsWeb) return;
    final fileToSave = _openFiles[_activeFileIndex];
    if (_savingFileIds.contains(fileToSave.id)) return;

    // Check if path is empty or in a restricted/read-only location (like /usr/share or assets)
    bool isReadOnly = fileToSave.path.isEmpty;
    if (!isReadOnly && !kIsWeb) {
      try {
        final file = io.File(fileToSave.path);
        // Check if we can actually write to this file/directory
        if (await file.exists()) {
          // Try to open for appending just to check permissions
          final sink = file.openWrite(mode: io.FileMode.append);
          await sink.flush();
          await sink.close();
        } else {
          // If it doesn't exist, check if parent directory is writable
          final parent = file.parent;
          if (!await parent.exists()) {
             isReadOnly = true;
          }
        }
      } catch (e) {
        isReadOnly = true;
      }
    }

    if (isReadOnly) {
      await saveActiveFileAs();
      return;
    }

    _savingFileIds.add(fileToSave.id);
    try {
      final file = io.File(fileToSave.path);
      await file.writeAsString(fileToSave.content);
      await UniLabBridge.instance.createFile(
        fileToSave.name,
        fileToSave.content,
      );
      final idx = _openFiles.indexWhere((f) => f.id == fileToSave.id);
      if (idx != -1) {
        _openFiles[idx] = _openFiles[idx].copyWith(isModified: false);
      }
      _addToRecentFiles(fileToSave.path);
      await refreshProjectFiles();
    } catch (e) {
      _addConsoleMessage('Error saving file: $e', ConsoleMessageType.error);
    } finally {
      _savingFileIds.remove(fileToSave.id);
      notifyListeners();
    }
  }

  Future<void> saveActiveFileAs() async {
    if (_activeFileIndex < 0 || kIsWeb) return;
    final fileToSave = _openFiles[_activeFileIndex];

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save File As',
      fileName: fileToSave.name,
      type: FileType.custom,
      allowedExtensions: ['m', 'txt', 'csv', 'json', 'py'],
    );

    if (outputFile == null) return;

    // Ensure extension
    if (!outputFile.contains('.')) {
      outputFile += '.m';
    }

    try {
      final file = io.File(outputFile);
      await file.writeAsString(fileToSave.content);

      final idx = _openFiles.indexWhere((f) => f.id == fileToSave.id);
      if (idx != -1) {
        _openFiles[idx] = _openFiles[idx].copyWith(
          name: p.basename(outputFile),
          path: outputFile,
          isModified: false,
        );
      }
      _addToRecentFiles(outputFile);
      await refreshProjectFiles();
    } catch (e) {
      _addConsoleMessage('Error saving file as: $e', ConsoleMessageType.error);
    } finally {
      notifyListeners();
    }
  }

  Future<void> exportToPython() async {
    if (activeFile == null) return;
    try {
      final pythonCode = await UniLabBridge.instance.transpile(
        activeFile!.content,
      );

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export to Python',
        fileName: activeFile!.name.replaceAll('.m', '.py'),
        type: FileType.custom,
        allowedExtensions: ['py'],
      );

      if (outputFile == null) return;

      final file = io.File(outputFile);
      await file.writeAsString(pythonCode);
      _addConsoleMessage(
        'Successfully exported to $outputFile',
        ConsoleMessageType.output,
      );
    } catch (e) {
      _addConsoleMessage('Export failed: $e', ConsoleMessageType.error);
    }
  }

  Future<void> exportToPdf() async {
    if (activeFile == null) return;
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.robotoMonoRegular();
      final boldFont = await PdfGoogleFonts.robotoMonoBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Text(
              'UniLab Script: ${activeFile!.name}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ),
          footer: (pw.Context context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'UniLab Script Export: ${activeFile!.name}',
                  style: pw.TextStyle(font: boldFont, fontSize: 18),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  'Generated on ${DateTime.now().toString()}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 16),
              ..._highlightToPdfLines(activeFile!.content, font),
            ];
          },
        ),
      );

      final bytes = await pdf.save();

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export to PDF',
        fileName: activeFile!.name.replaceAll('.m', '.pdf'),
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final file = io.File(outputFile);
        await file.writeAsBytes(bytes);
        _addConsoleMessage(
          'Successfully exported to $outputFile',
          ConsoleMessageType.output,
        );
      }
    } catch (e) {
      _addConsoleMessage('Export to PDF failed: $e', ConsoleMessageType.error);
    }
  }

  Future<void> printActiveFile() async {
    if (activeFile == null) return;
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.robotoMonoRegular();
      final boldFont = await PdfGoogleFonts.robotoMonoBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Text(
              'UniLab Script: ${activeFile!.name}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'UniLab Script: ${activeFile!.name}',
                  style: pw.TextStyle(font: boldFont, fontSize: 18),
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 16),
              ..._highlightToPdfLines(activeFile!.content, font),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: activeFile!.name,
      );
    } catch (e) {
      _addConsoleMessage('Printing failed: $e', ConsoleMessageType.error);
    }
  }

  Future<void> deleteFile(dynamic entity) async {
    try {
      final ioEntity = entity as io.FileSystemEntity;
      if (await ioEntity.exists()) {
        await ioEntity.delete(recursive: true);
        final openIndex = _openFiles.indexWhere((f) => f.path == ioEntity.path);
        if (openIndex != -1) closeFile(openIndex);
        await refreshProjectFiles();
      }
    } catch (e) {
      _addConsoleMessage('Error deleting: $e', ConsoleMessageType.error);
    }
  }

  void updateMovedFilePaths(String oldPath, String newPath) {
    bool changed = false;
    for (int i = 0; i < _openFiles.length; i++) {
      if (_openFiles[i].path == oldPath) {
        _openFiles[i] = _openFiles[i].copyWith(path: newPath);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> runActiveFile() async {
    if (activeFile == null) return;

    // Ensure session is ready
    if (_backendStatus != BackendStatus.connected ||
        UniLabBridge.instance.sessionId == null) {
      _addConsoleMessage(
        'Backend not ready. Attempting to reconnect...',
        ConsoleMessageType.warning,
      );
      await _initBridge();
      if (_backendStatus != BackendStatus.connected ||
          UniLabBridge.instance.sessionId == null) {
        _addConsoleMessage(
          'Failed to connect to backend. Please check if the server is running.',
          ConsoleMessageType.error,
        );
        return;
      }
    }

    _isExecuting = true;
    _addConsoleMessage(
      '>> Running ${activeFile!.name}...',
      ConsoleMessageType.output,
      source: 'System',
    );
    try {
      final timeout =
          _settingsProvider?.settings.executionTimeout.toDouble() ?? 300.0;
      final result = await UniLabBridge.instance.execute(
        activeFile!.content,
        filename: activeFile!.path,
        timeout: timeout,
      );
      if (result.stdout.isNotEmpty) {
        _addConsoleMessage(
          result.stdout,
          ConsoleMessageType.output,
          source: 'Script',
        );
      }
      if (result.stderr.isNotEmpty) {
        _addConsoleMessage(
          result.stderr,
          ConsoleMessageType.error,
          source: 'Error',
        );
      }
      _updateVariablesFromResult(result);
      _updatePlotsFromResult(result);
    } catch (e) {
      _addConsoleMessage(
        'Execution Error: $e',
        ConsoleMessageType.error,
        source: 'Error',
      );
    } finally {
      _isExecuting = false;
      await fetchWorkspaceVariables();
      notifyListeners();
    }
  }

  void _updateVariablesFromResult(ExecutionResult result) =>
      _updateVariablesFromMap(result.variables);

  void _updatePlotsFromResult(ExecutionResult result) {
    // We no longer clear all plots every time to support Plot History
    // _generatedPlots.clear();

    final b64List = result.extra['plot_data_b64'] as List? ?? [];
    final scriptsList = result.extra['plot_scripts'] as List? ?? [];
    final figuresList = result.extra['plot_figures'] as List? ?? [];

    for (int i = 0; i < b64List.length; i++) {
      final scriptPath = i < scriptsList.length ? scriptsList[i] : null;
      final figNum = i < figuresList.length ? figuresList[i] : null;
      final imageDataUri = b64List[i];

      // If it's from a script, try to find an existing plot from that script and figure number to refresh
      int existingIndex = -1;
      if (scriptPath != null && figNum != null) {
        existingIndex = _generatedPlots.indexWhere(
          (p) => p.sourceScript == scriptPath && p.figNum == figNum,
        );
      } else if (scriptPath != null) {
        existingIndex = _generatedPlots.indexWhere(
          (p) => p.sourceScript == scriptPath,
        );
      } else if (figNum != null) {
        existingIndex = _generatedPlots.indexWhere(
          (p) => p.figNum == figNum && p.sourceScript == null,
        );
      }

      String title = 'Figure ${figNum ?? (_generatedPlots.length + 1)}';
      if (scriptPath != null) {
        title += ' (${p.basename(scriptPath)})';
      }

      final newPlot = PlotData(
        id: existingIndex != -1 ? _generatedPlots[existingIndex].id : null,
        title: title,
        type: 'image',
        xData: [],
        yData: [],
        imageDataUri: imageDataUri,
        sourceScript: scriptPath,
        figNum: figNum,
        createdAt: DateTime.now(),
      );

      if (existingIndex != -1) {
        // Refresh existing plot
        _generatedPlots[existingIndex] = newPlot;
      } else {
        // Add as new plot to history
        _generatedPlots.add(newPlot);
      }
    }

    onPlotsUpdated?.call(List.from(_generatedPlots));
    if (_plotsWindowId != null) {
      try {
        dmw.WindowController.fromWindowId(_plotsWindowId!).invokeMethod(
          'update_plots',
          jsonEncode(_generatedPlots.map((p) => p.toJson()).toList()),
        );
      } catch (e) {
        _plotsWindowId = null;
      }
    }
    if (_generatedPlots.isNotEmpty) {
      _selectedConsoleTab = 'plots';
      if (_plotsWindowId == null && !kIsWeb) openDetachedPlotsWindow();
    }
    notifyListeners();
  }

  // Future<void> openDetachedPlotsWindow() async {
  //   if (_plotsWindowId != null) {
  //     final controller = dmw.WindowController.fromWindowId(_plotsWindowId!);
  //     await controller.show();
  //   } else {
  //     final window = await dmw.WindowController.create(
  //       dmw.WindowConfiguration(arguments: jsonEncode({'type': 'plots'})),
  //     );

  //     _plotsWindowId = window.windowId.toString();

  //     await window.show();
  //   }
  // }

  Future<void> openDetachedPlotsWindow() async {
    if (_plotsWindowId != null) {
      final controller = dmw.WindowController.fromWindowId(_plotsWindowId!);
      await controller.show();
    }
  }

  Future<void> openDetachedSimulationWindow() async {
    if (_simulationWindowId != null) {
      final controller = dmw.WindowController.fromWindowId(
        _simulationWindowId!,
      );
      await controller.show();
    }
  }

  void clearConsole() {
    _consoleMessages.clear();
    notifyListeners();
  }

  void clearPlots() {
    _generatedPlots.clear();
    onPlotsUpdated?.call([]);
    notifyListeners();
  }

  Future<void> runConsoleCommand(String command) async {
    if (command.isEmpty) return;

    // Ensure session is ready
    if (_backendStatus != BackendStatus.connected ||
        UniLabBridge.instance.sessionId == null) {
      _addConsoleMessage(
        'Backend not ready. Attempting to reconnect...',
        ConsoleMessageType.warning,
      );
      await _initBridge();
      if (_backendStatus != BackendStatus.connected ||
          UniLabBridge.instance.sessionId == null) {
        _addConsoleMessage(
          'Failed to connect to backend.',
          ConsoleMessageType.error,
        );
        return;
      }
    }

    // Add to history
    _commandHistory.remove(command);
    _commandHistory.insert(0, command);
    if (_commandHistory.length > 100) _commandHistory.removeLast();

    _isExecuting = true;
    _addConsoleMessage(
      '>> $command',
      ConsoleMessageType.output,
      source: 'System',
    );
    try {
      final timeout =
          _settingsProvider?.settings.executionTimeout.toDouble() ?? 300.0;
      final result = await UniLabBridge.instance.execute(
        command,
        timeout: timeout,
      );
      if (result.stdout.isNotEmpty) {
        _addConsoleMessage(
          result.stdout,
          ConsoleMessageType.output,
          source: 'Script',
        );
      }
      if (result.stderr.isNotEmpty) {
        _addConsoleMessage(
          result.stderr,
          ConsoleMessageType.error,
          source: 'Error',
        );
      }
      _updateVariablesFromResult(result);
      _updatePlotsFromResult(result);
    } catch (e) {
      _addConsoleMessage(
        'Error: $e',
        ConsoleMessageType.error,
        source: 'Error',
      );
    } finally {
      _isExecuting = false;
      await fetchWorkspaceVariables();
      notifyListeners();
    }
  }

  Future<List<String>> getAutocomplete(
    String prefix, {
    String? fullLine,
  }) async {
    try {
      return await UniLabBridge.instance.getAutocomplete(
        prefix,
        fullLine: fullLine,
      );
    } catch (e) {
      return [];
    }
  }

  Future<String> fetchHelp(String topic) async {
    try {
      final result = await UniLabBridge.instance.execute('help $topic');
      return result.stdout;
    } catch (e) {
      return 'Error fetching help: $e';
    }
  }

  Future<void> fetchWorkspaceVariables() async {
    try {
      _updateVariablesFromMap(await UniLabBridge.instance.getWorkspace());
    } catch (e) {}
  }

  Future<void> openFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'm',
        'txt',
        'csv',
        'json',
        'md',
        'py',
        'pdf',
        'png',
        'jpg',
        'jpeg',
        'gif',
        'webp',
        'mp3',
        'wav',
        'm4a',
        'ogg',
      ],
    );
    if (result != null) {
      if (kIsWeb) {
        final fileData = result.files.single;
        final path = 'web/${fileData.name}';
        final existingIndex = _openFiles.indexWhere((f) => f.path == path);
        if (existingIndex != -1) {
          _activeFileIndex = existingIndex;
        } else {
          _openFiles.add(
            UniLabFile(
              id: const Uuid().v4(),
              name: fileData.name,
              path: path,
              content: String.fromCharCodes(fileData.bytes!),
            ),
          );
          _activeFileIndex = _openFiles.length - 1;
        }
      } else if (result.files.single.path != null)
        await openFile(io.File(result.files.single.path!));
      notifyListeners();
    }
  }

  Future<void> openFolderPicker() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) setProjectRoot(selectedDirectory);
  }

  Future<void> clearWorkspace() async {
    try {
      await UniLabBridge.instance.execute('clear all');
      _workspaceVariables.clear();
      onVariablesUpdated?.call([]);
      notifyListeners();
    } catch (e) {}
  }

  void stopExecution() {
    _isExecuting = false;
    UniLabBridge.instance.sendSimEvent({'type': 'STOP'});
    _addConsoleMessage(
      '>> Execution stopped by user.',
      ConsoleMessageType.warning,
      source: 'System',
    );
  }

  final StreamController<String> _editorActionController =
      StreamController<String>.broadcast();
  Stream<String> get editorActions => _editorActionController.stream;
  void triggerEditorAction(String action) =>
      _editorActionController.add(action);

  List<pw.Widget> _highlightToPdfLines(String code, pw.Font font) {
    final result = hl.highlight.parse(code, language: 'matlab');
    final List<List<pw.InlineSpan>> lines = [[]];

    // Map highlight categories to colors (Light theme style for PDF)
    final Map<String, PdfColor> colorMap = {
      'keyword': PdfColors.blue,
      'string': PdfColors.red900,
      'number': PdfColors.green900,
      'comment': PdfColors.green,
      'function': PdfColors.brown,
      'params': PdfColors.black,
      'meta': PdfColors.grey700,
      'built_in': PdfColors.cyan900,
    };

    void traverse(hl.Node node, PdfColor? parentColor) {
      final nodeColor =
          colorMap[node.className] ?? parentColor ?? PdfColors.black;

      if (node.value != null) {
        final parts = node.value!.split('\n');
        for (int i = 0; i < parts.length; i++) {
          if (parts[i].isNotEmpty) {
            lines.last.add(
              pw.TextSpan(
                text: parts[i],
                style: pw.TextStyle(font: font, color: nodeColor, fontSize: 9),
              ),
            );
          }

          if (i < parts.length - 1) {
            lines.add([]);
          }
        }
      }

      if (node.children != null) {
        for (final child in node.children!) {
          traverse(child, nodeColor);
        }
      }
    }

    if (result.nodes != null) {
      for (final node in result.nodes!) {
        traverse(node, null);
      }
    }

    return lines
        .map(
          (lineSpans) => pw.RichText(
            text: pw.TextSpan(
              children: lineSpans.isEmpty
                  ? [pw.TextSpan(text: ' ')]
                  : lineSpans,
            ),
          ),
        )
        .toList();
  }
}
