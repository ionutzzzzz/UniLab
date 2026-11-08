import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import '../theme/syntax_themes.dart';
import '../utils/platform_dmw.dart' as dmw;
import '../models/models.dart';
import '../models/editor_models.dart';
import '../features/workspace/domain/workspace_variable.dart' as domain;
import '../bridge/unilab_bridge.dart';
import '../utils/file_manager.dart';
import 'settings_provider.dart';
import '../utils/platform_io.dart' as io;

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
  int _executionRunId = 0;
  void Function()? _flushEditorCallback;

  void registerEditorFlushCallback(void Function()? callback) {
    _flushEditorCallback = callback;
  }
  final Set<String> _savingFileIds = {};
  final List<String> _recentFiles = [];
  final List<String> _recentProjects = [];
  Map<String, dynamic> _serverInfo = {};
  String _selectedConsoleTab = 'output';
  String _selectedWorkspaceSegment = 'Variables';
  bool _isSplitEditor = false;
  int _secondaryFileIndex = -1;
  String? _requestedHelpTopic;
  int _helpRequestVersion = 0;
  String _username = 'gui_user';

  String? _plotsWindowId;
  int _untitledCounter = 0;

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
  bool get isSplitEditor => _isSplitEditor;
  int get secondaryFileIndex => _secondaryFileIndex;
  UniLabFile? get secondaryFile {
    if (_openFiles.isEmpty) return null;
    if (_secondaryFileIndex >= 0 && _secondaryFileIndex < _openFiles.length) {
      return _openFiles[_secondaryFileIndex];
    }
    if (_openFiles.length > 1) {
      final altIndex = _activeFileIndex == 0 ? 1 : 0;
      return _openFiles[altIndex];
    }
    return activeFile;
  }
  String? get requestedHelpTopic => _requestedHelpTopic;
  int get helpRequestVersion => _helpRequestVersion;
  String get username => _username;

  void setSelectedConsoleTab(String tab) {
    _selectedConsoleTab = tab;
    notifyListeners();
  }

  void setSelectedWorkspaceSegment(String segment) {
    _selectedWorkspaceSegment = segment;
    notifyListeners();
  }

  void toggleSplitEditor() {
    _isSplitEditor = !_isSplitEditor;
    if (_isSplitEditor && (_secondaryFileIndex < 0 || _secondaryFileIndex >= _openFiles.length)) {
      if (_openFiles.length > 1) {
        _secondaryFileIndex = _activeFileIndex == 0 ? 1 : 0;
      } else {
        _secondaryFileIndex = _activeFileIndex;
      }
    }
    notifyListeners();
  }

  void setSecondaryFile(int index) {
    if (index >= 0 && index < _openFiles.length) {
      _secondaryFileIndex = index;
      _isSplitEditor = true;
      notifyListeners();
    }
  }

  void openHelpTopic(String? topic) {
    _requestedHelpTopic = topic;
    _helpRequestVersion++;
    _selectedWorkspaceSegment = 'Help';
    notifyListeners();
  }

  Future<void> setUsername(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _username = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessionUsername', _username);
    try {
      await UniLabBridge.instance.createSession(_username);
      _addConsoleMessage('Switched session user to $_username.', ConsoleMessageType.output);
    } catch (_) {}
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
        await sendSimControlUpdate(data['id']?.toString() ?? '', data['value']);
      }
      return null;
    });

    // Provide current plots to detached plots window
    dmw.WindowMethodChannel('plots_window_channel').setMethodCallHandler((
      call,
    ) async {
      if (call.method == 'get_plots') {
        return jsonEncode(_generatedPlots.map((p) => p.toJson()).toList());
      }
      return null;
    });
  }

  void updateSettings(SettingsProvider settings) {
    final oldTheme = _settingsProvider?.settings.syntaxHighlightTheme;
    final oldMode = _settingsProvider?.settings.themeMode;
    final oldCmap = _settingsProvider?.settings.plotColormap;
    final oldGrid = _settingsProvider?.settings.plotShowGrid;
    final oldLabels = _settingsProvider?.settings.plotShowLabels;
    final oldLegend = _settingsProvider?.settings.plotShowLegend;

    _settingsProvider = settings;
    UniLabBridge.instance.configure(
      kernelAddress: settings.settings.kernelAddress,
      connectionTimeout: settings.settings.connectionTimeout,
    );

    final bool plotSettingsChanged = oldTheme != settings.settings.syntaxHighlightTheme ||
        oldMode != settings.settings.themeMode ||
        oldCmap != settings.settings.plotColormap ||
        oldGrid != settings.settings.plotShowGrid ||
        oldLabels != settings.settings.plotShowLabels ||
        oldLegend != settings.settings.plotShowLegend;

    if (plotSettingsChanged && _backendStatus == BackendStatus.connected) {
      syncPlotSettingsToBackend(reRender: _generatedPlots.isNotEmpty);
    }

    notifyListeners();
  }

  Future<void> syncPlotSettingsToBackend({bool reRender = false}) async {
    if (_backendStatus != BackendStatus.connected) return;
    try {
      final s = _settingsProvider?.settings;
      if (s == null) return;

      final themeName = s.syntaxHighlightTheme;
      final selectedTheme = SyntaxHighlightTheme.all.firstWhere(
        (t) => t.name == themeName,
        orElse: () => SyntaxHighlightTheme.all.first,
      );

      String colorToHex(Color c) {
        return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
      }

      final isDark = s.themeMode == ThemeMode.dark ||
          (s.themeMode == ThemeMode.system &&
              (selectedTheme.backgroundColor.computeLuminance() < 0.5));
      final themeModeStr = isDark ? 'theme' : 'light';

      final bgColorHex = colorToHex(selectedTheme.backgroundColor);
      final fgColorHex = colorToHex(selectedTheme.foregroundColor);
      final axesBgHex = isDark
          ? colorToHex(Color.lerp(selectedTheme.backgroundColor, Colors.white, 0.04)!)
          : colorToHex(Color.lerp(selectedTheme.backgroundColor, Colors.black, 0.03)!);
      final mutedFgHex = colorToHex(Color.lerp(selectedTheme.foregroundColor, selectedTheme.backgroundColor, 0.45)!);
      final gridHex = isDark
          ? colorToHex(Color.lerp(selectedTheme.backgroundColor, Colors.white, 0.12)!)
          : colorToHex(Color.lerp(selectedTheme.backgroundColor, Colors.black, 0.12)!);
      final spineHex = isDark
          ? colorToHex(Color.lerp(selectedTheme.backgroundColor, Colors.white, 0.22)!)
          : colorToHex(Color.lerp(selectedTheme.backgroundColor, Colors.black, 0.22)!);

      final escapedCmap = (s.plotColormap).replaceAll("'", "\\'");
      final code = "unilab_configure_plots("
          "theme_mode='$themeModeStr', "
          "bg_color='$bgColorHex', "
          "axes_bg_color='$axesBgHex', "
          "fg_color='$fgColorHex', "
          "muted_fg_color='$mutedFgHex', "
          "grid_color='$gridHex', "
          "spine_color='$spineHex', "
          "colormap='$escapedCmap', "
          "show_grid=${s.plotShowGrid ? 1 : 0}, "
          "show_labels=${s.plotShowLabels ? 1 : 0}, "
          "show_legend=${s.plotShowLegend ? 1 : 0}, "
          "re_render=${reRender ? 1 : 0})";

      final res = await UniLabBridge.instance.execute(code);
      if (reRender && res.plots.isNotEmpty) {
        _updatePlotsFromResult(res);
      }
    } catch (e) {
      debugPrint('[AppProvider] syncPlotSettingsToBackend error: $e');
    }
  }

  Future<void> customizePlotFigure(
    String? figNum, {
    String? title,
    String? xlabel,
    String? ylabel,
    bool? showGrid,
    bool? showLegend,
    bool? showLabels,
    String? colormap,
    double? lineWidth,
    double? fontSize,
    String? themeMode,
  }) async {
    final cleanFig = figNum?.replaceAll(RegExp(r'[^0-9]'), '');
    final parts = <String>[];
    if (cleanFig != null && cleanFig.isNotEmpty) {
      parts.add("fig_num=$cleanFig");
    }
    if (title != null) {
      final escaped = title.replaceAll("'", "\\'");
      parts.add("title_text='$escaped'");
    }
    if (xlabel != null) {
      final escaped = xlabel.replaceAll("'", "\\'");
      parts.add("xlabel_text='$escaped'");
    }
    if (ylabel != null) {
      final escaped = ylabel.replaceAll("'", "\\'");
      parts.add("ylabel_text='$escaped'");
    }
    if (showGrid != null) {
      parts.add("show_grid=${showGrid ? 1 : 0}");
    }
    if (showLegend != null) {
      parts.add("show_legend=${showLegend ? 1 : 0}");
    }
    if (showLabels != null) {
      parts.add("show_labels=${showLabels ? 1 : 0}");
    }
    if (colormap != null && colormap.isNotEmpty) {
      final escaped = colormap.replaceAll("'", "\\'");
      parts.add("colormap_name='$escaped'");
    }
    if (lineWidth != null) {
      parts.add("line_width=$lineWidth");
    }
    if (fontSize != null) {
      parts.add("font_size=$fontSize");
    }
    if (themeMode != null && themeMode.isNotEmpty) {
      final escaped = themeMode.replaceAll("'", "\\'");
      parts.add("theme_mode='$escaped'");
    }

    final cmd = "unilab_customize_figure(${parts.join(', ')})";
    try {
      final result = await UniLabBridge.instance.execute(cmd);
      _updatePlotsFromResult(result);
    } catch (e) {
      _addConsoleMessage('Failed to customize figure: $e', ConsoleMessageType.error);
    }
  }

  Future<void> _loadRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('sessionUsername') ?? 'gui_user';
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
    if (path.isEmpty || path.startsWith('unilab://') || path.startsWith('web/')) {
      return;
    }
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
    _editorActionController.close();
    super.dispose();
  }

  Future<void> _initBridge() async {
    try {
      if (UniLabBridge.instance.initialized &&
          UniLabBridge.instance.sessionId == null) {
        UniLabBridge.resetInstance();
      }
      
      await UniLabBridge.instance.initialize();
      await UniLabBridge.instance.createSession(_username);
      _backendStatus = BackendStatus.connected;
      _serverInfo = await UniLabBridge.instance.getInfo();
      await syncPlotSettingsToBackend(reRender: false);

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
      _selectedWorkspaceSegment = 'Plots';
    } else if (type == 'CREATE_CONTROL') {
      _simulationControls.add(data);
      _selectedWorkspaceSegment = 'Plots';
    } else if (type == 'GRAPHICAL_PLOT') {
      _handleSimPlot(data);
      _updateWorkspacePlotsFromSimEvent(data);
      _selectedWorkspaceSegment = 'Plots';
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

  void _updateWorkspacePlotsFromSimEvent(Map<String, dynamic> data) {
    final figNum = data['fig']?.toString();
    final scriptPath = data['script'] as String?;
    final imageDataUri = data['data'] as String?;
    final meta = (data['meta'] is Map) ? Map<String, dynamic>.from(data['meta']) : <String, dynamic>{};

    int existingIndex = _generatedPlots.indexWhere(
      (p) => p.figNum == figNum && p.sourceScript == scriptPath,
    );

    String title = 'Figure $figNum';
    if (scriptPath != null) {
      title += ' (${p.basename(scriptPath)})';
    }

    final newPlot = PlotData(
      id: existingIndex != -1 ? _generatedPlots[existingIndex].id : null,
      title: title,
      plotTitle: meta['title']?.toString(),
      type: meta['is_3d'] == true ? 'surface' : 'image',
      xData: [],
      yData: [],
      imageDataUri: imageDataUri,
      sourceScript: scriptPath,
      figNum: figNum,
      xlabel: meta['xlabel']?.toString(),
      ylabel: meta['ylabel']?.toString(),
      showGrid: meta['has_grid'] as bool?,
      showLegend: meta['has_legend'] as bool?,
      showLabels: meta['show_labels'] as bool?,
      colormap: meta['colormap']?.toString(),
      lineWidth: (meta['line_width'] as num?)?.toDouble(),
      fontSize: (meta['font_size'] as num?)?.toDouble(),
      themeMode: meta['theme_mode']?.toString(),
      numSubplots: (meta['num_subplots'] as num?)?.toInt(),
      is3d: meta['is_3d'] as bool?,
      createdAt: DateTime.now(),
    );

    if (existingIndex != -1) {
      _generatedPlots[existingIndex] = newPlot;
    } else {
      _generatedPlots.add(newPlot);
    }

    onPlotsUpdated?.call(List.from(_generatedPlots));
  }

  Future<void> sendSimControlUpdate(String id, dynamic value) async {
    for (var i = 0; i < _simulationControls.length; i++) {
      if (_simulationControls[i]['id'] == id) {
        _simulationControls[i]['value'] = value;
        break;
      }
    }
    notifyListeners();
    await UniLabBridge.instance.sendSimEvent({'id': id, 'value': value});
  }

  Future<void> openDetachedSimWindow() async {
    _selectedWorkspaceSegment = 'Plots';
    notifyListeners();
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
    _untitledCounter++;
    final newFile = UniLabFile(
      id: const Uuid().v4(),
      name: 'Untitled$_untitledCounter.m',
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
    if (_projectRoot == null) {
      final existingIndex = _openFiles.indexWhere((f) => f.name == fileName);
      if (existingIndex != -1) {
        _activeFileIndex = existingIndex;
      } else {
        _openFiles.add(
          UniLabFile(
            id: const Uuid().v4(),
            name: fileName,
            path: '',
            content: content,
          ),
        );
        _activeFileIndex = _openFiles.length - 1;
      }
      _isWelcomeMode = false;
      notifyListeners();
      return;
    }
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
    if (index < 0 || index >= _openFiles.length) return;
    _openFiles.removeAt(index);
    if (index < _activeFileIndex) {
      _activeFileIndex -= 1;
    } else if (_activeFileIndex >= _openFiles.length) {
      _activeFileIndex = _openFiles.length - 1;
    }
    if (index < _secondaryFileIndex) {
      _secondaryFileIndex -= 1;
    } else if (_secondaryFileIndex >= _openFiles.length) {
      _secondaryFileIndex = _openFiles.length - 1;
    }
    if (_openFiles.isEmpty) {
      _isSplitEditor = false;
    }
    notifyListeners();
  }

  void closeOtherFiles(int keepIndex) {
    if (keepIndex < 0 || keepIndex >= _openFiles.length) return;
    final kept = _openFiles[keepIndex];
    _openFiles
      ..clear()
      ..add(kept);
    _activeFileIndex = 0;
    _secondaryFileIndex = 0;
    _isSplitEditor = false;
    notifyListeners();
  }

  void closeAllFiles() {
    _openFiles.clear();
    _activeFileIndex = -1;
    _secondaryFileIndex = -1;
    _isSplitEditor = false;
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
    if (activeFile != null) updateFileContent(activeFile!.id, content);
  }

  void insertCodeIntoActiveScript(
    String snippet, {
    bool replaceAll = false,
    String? suggestedFileName,
  }) {
    _flushEditorCallback?.call();
    if (_openFiles.isEmpty || _activeFileIndex < 0) {
      final fname = suggestedFileName ?? 'Engineering_Lab.m';
      final newId = const Uuid().v4();
      final newPath = (_projectRoot != null && _projectRoot!.isNotEmpty)
          ? p.join(_projectRoot!, fname)
          : '';
      _openFiles.add(
        UniLabFile(
          id: newId,
          name: fname,
          path: newPath,
          content: snippet,
          isModified: true,
        ),
      );
      _activeFileIndex = _openFiles.length - 1;
      notifyListeners();
      triggerEditorAction('editor.syncFromProvider');
      return;
    }

    final current = _openFiles[_activeFileIndex];
    final updatedContent = replaceAll || current.content.trim().isEmpty
        ? snippet
        : '${current.content.trimRight()}\n\n$snippet\n';
    _openFiles[_activeFileIndex] = current.copyWith(
      content: updatedContent,
      isModified: true,
    );
    notifyListeners();
    triggerEditorAction('editor.syncFromProvider');
  }

  Future<void> saveActiveFile() async {
    _flushEditorCallback?.call();
    if (_activeFileIndex < 0 || _activeFileIndex >= _openFiles.length || kIsWeb) {
      return;
    }
    var fileToSave = _openFiles[_activeFileIndex];
    if (_savingFileIds.contains(fileToSave.id)) return;

    // If the file does not have a disk path yet, assign it inside the active project root
    // (or current working directory) so Ctrl+S saves immediately and reliably.
    if (fileToSave.path.isEmpty) {
      final baseDir = (_projectRoot != null && _projectRoot!.isNotEmpty)
          ? _projectRoot!
          : io.Directory.current.path;
      final defaultName = fileToSave.name.endsWith('.m')
          ? fileToSave.name
          : '${fileToSave.name}.m';
      final assignedPath = p.join(baseDir, defaultName);
      fileToSave = fileToSave.copyWith(name: defaultName, path: assignedPath);
      _openFiles[_activeFileIndex] = fileToSave;
    }

    // Check if path is in a restricted/read-only location
    bool isReadOnly = false;
    if (!kIsWeb) {
      try {
        final file = io.File(fileToSave.path);
        if (await file.exists()) {
          final sink = file.openWrite(mode: io.FileMode.append);
          await sink.flush();
          await sink.close();
        } else {
          final parent = file.parent;
          if (!await parent.exists()) {
            await parent.create(recursive: true);
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
      _addConsoleMessage(
        'Saved ${fileToSave.name} -> ${fileToSave.path}',
        ConsoleMessageType.success,
        source: 'System',
      );
    } catch (e) {
      _addConsoleMessage('Error saving file: $e', ConsoleMessageType.error);
    } finally {
      _savingFileIds.remove(fileToSave.id);
      notifyListeners();
    }
  }

  Future<void> saveActiveFileAs() async {
    _flushEditorCallback?.call();
    if (_activeFileIndex < 0 || _activeFileIndex >= _openFiles.length || kIsWeb) {
      return;
    }
    final fileToSave = _openFiles[_activeFileIndex];

    String? outputFile;
    try {
      outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save File As',
        fileName: fileToSave.name,
        type: FileType.custom,
        allowedExtensions: ['m', 'txt', 'csv', 'json', 'py'],
      );
    } catch (e) {
      // Fallback to projectRoot if native dialog is unavailable on this desktop environment
      final baseDir = (_projectRoot != null && _projectRoot!.isNotEmpty)
          ? _projectRoot!
          : io.Directory.current.path;
      outputFile = p.join(baseDir, fileToSave.name);
    }

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
      _addConsoleMessage(
        'Saved ${p.basename(outputFile)} -> $outputFile',
        ConsoleMessageType.success,
        source: 'System',
      );
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
    _flushEditorCallback?.call();
    if (activeFile == null) return;

    // If a previous execution or simulation is still active, cancel it first so
    // the new script starts immediately without waiting.
    if (_isExecuting || _isSimulationActive) {
      await UniLabBridge.instance.cancelExecution();
      _isSimulationActive = false;
      _simulationControls.clear();
    }

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

    final int runId = ++_executionRunId;
    final fileToRun = activeFile!;
    _isExecuting = true;
    notifyListeners();
    _addConsoleMessage(
      '>> Running ${fileToRun.name}...',
      ConsoleMessageType.output,
      source: 'System',
    );
    try {
      await syncPlotSettingsToBackend(reRender: false);
      final timeout =
          _settingsProvider?.settings.executionTimeout.toDouble() ?? 300.0;
      final result = await UniLabBridge.instance.execute(
        fileToRun.content,
        filename: fileToRun.path.isNotEmpty ? fileToRun.path : fileToRun.name,
        timeout: timeout,
      );
      if (_executionRunId != runId) return;
      if (result.stdout.isNotEmpty) {
        _addConsoleMessage(
          result.stdout,
          ConsoleMessageType.output,
          source: 'Script',
        );
      }
      if (result.stderr.isNotEmpty) {
        final isStopped = result.stderr.contains('Execution stopped by user');
        _addConsoleMessage(
          result.stderr,
          isStopped
              ? ConsoleMessageType.warning
              : ConsoleMessageType.error,
          source: isStopped ? 'System' : 'Error',
        );
      }
      _updateVariablesFromResult(result);
      _updatePlotsFromResult(result);
    } catch (e) {
      if (_executionRunId != runId) return;
      _addConsoleMessage(
        'Execution Error: $e',
        ConsoleMessageType.error,
        source: 'Error',
      );
    } finally {
      if (_executionRunId == runId) {
        _isExecuting = false;
        await fetchWorkspaceVariables();
        notifyListeners();
      }
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
    final metaList = result.extra['plot_3d_data'] as List? ?? [];

    for (int i = 0; i < b64List.length; i++) {
      final scriptPath = i < scriptsList.length ? scriptsList[i] : null;
      final figNum = i < figuresList.length ? figuresList[i]?.toString() : null;
      final meta = (i < metaList.length && metaList[i] is Map) ? Map<String, dynamic>.from(metaList[i]) : <String, dynamic>{};
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

      final plotTitle = meta['title']?.toString();
      final xlabel = meta['xlabel']?.toString();
      final ylabel = meta['ylabel']?.toString();
      final showGrid = meta['has_grid'] as bool?;
      final showLegend = meta['has_legend'] as bool?;
      final showLabels = meta['show_labels'] as bool?;
      final colormap = meta['colormap']?.toString();
      final lineWidth = (meta['line_width'] as num?)?.toDouble();
      final fontSize = (meta['font_size'] as num?)?.toDouble();
      final themeMode = meta['theme_mode']?.toString();
      final numSubplots = (meta['num_subplots'] as num?)?.toInt();
      final is3d = meta['is_3d'] as bool?;

      final newPlot = PlotData(
        id: existingIndex != -1 ? _generatedPlots[existingIndex].id : null,
        title: title,
        plotTitle: plotTitle,
        type: is3d == true ? 'surface' : 'image',
        xData: [],
        yData: [],
        imageDataUri: imageDataUri,
        sourceScript: scriptPath,
        figNum: figNum,
        xlabel: xlabel,
        ylabel: ylabel,
        showGrid: showGrid,
        showLegend: showLegend,
        showLabels: showLabels,
        colormap: colormap,
        lineWidth: lineWidth,
        fontSize: fontSize,
        themeMode: themeMode,
        numSubplots: numSubplots,
        is3d: is3d,
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
    if (b64List.isNotEmpty && _generatedPlots.isNotEmpty) {
      _selectedWorkspaceSegment = 'Plots';
    }
    notifyListeners();
  }

  Future<void> openDetachedPlotsWindow() async {
    _selectedWorkspaceSegment = 'Plots';
    notifyListeners();
  }

  Future<void> openDetachedSimulationWindow() async {
    await openDetachedSimWindow();
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

    if (_isExecuting || _isSimulationActive) {
      await UniLabBridge.instance.cancelExecution();
      _isSimulationActive = false;
      _simulationControls.clear();
    }

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

    final int runId = ++_executionRunId;
    _isExecuting = true;
    notifyListeners();
    _addConsoleMessage(
      '>> $command',
      ConsoleMessageType.output,
      source: 'System',
    );
    try {
      await syncPlotSettingsToBackend(reRender: false);
      final timeout =
          _settingsProvider?.settings.executionTimeout.toDouble() ?? 300.0;
      final result = await UniLabBridge.instance.execute(
        command,
        timeout: timeout,
      );
      if (_executionRunId != runId) return;
      if (result.stdout.isNotEmpty) {
        _addConsoleMessage(
          result.stdout,
          ConsoleMessageType.output,
          source: 'Script',
        );
      }
      if (result.stderr.isNotEmpty) {
        final isStopped = result.stderr.contains('Execution stopped by user');
        _addConsoleMessage(
          result.stderr,
          isStopped
              ? ConsoleMessageType.warning
              : ConsoleMessageType.error,
          source: isStopped ? 'System' : 'Error',
        );
      }
      _updateVariablesFromResult(result);
      _updatePlotsFromResult(result);
    } catch (e) {
      if (_executionRunId != runId) return;
      _addConsoleMessage(
        'Error: $e',
        ConsoleMessageType.error,
        source: 'Error',
      );
    } finally {
      if (_executionRunId == runId) {
        _isExecuting = false;
        await fetchWorkspaceVariables();
        notifyListeners();
      }
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
    } catch (_) {}
  }

  Future<void> restartBackend() async {
    _addConsoleMessage(
      'Restarting backend server...',
      ConsoleMessageType.output,
      source: 'System',
    );
    _backendStatus = BackendStatus.connecting;
    notifyListeners();
    try {
      UniLabBridge.resetInstance();
      await _initBridge();
      await fetchWorkspaceVariables();
      _addConsoleMessage(
        'Backend restarted successfully.',
        ConsoleMessageType.success,
        source: 'System',
      );
    } catch (e) {
      _backendStatus = BackendStatus.error;
      _addConsoleMessage(
        'Failed to restart backend: $e',
        ConsoleMessageType.error,
        source: 'System',
      );
    }
    notifyListeners();
  }

  Future<void> openFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: kIsWeb,
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
          final bytes = fileData.bytes;
          final content =
              bytes != null ? utf8.decode(bytes, allowMalformed: true) : '';
          _openFiles.add(
            UniLabFile(
              id: const Uuid().v4(),
              name: fileData.name,
              path: path,
              content: content,
            ),
          );
          _activeFileIndex = _openFiles.length - 1;
        }
      } else if (result.files.single.path != null) {
        await openFile(io.File(result.files.single.path!));
      }
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
    } catch (_) {}
  }

  Future<void> stopExecution() async {
    _executionRunId++;
    final wasRunning = _isExecuting || _isSimulationActive;
    _isExecuting = false;
    _isSimulationActive = false;
    _simulationControls.clear();
    notifyListeners();

    await UniLabBridge.instance.cancelExecution();
    if (wasRunning) {
      _addConsoleMessage(
        '>> Execution stopped by user.',
        ConsoleMessageType.warning,
        source: 'System',
      );
    }
  }

  final StreamController<String> _editorActionController =
      StreamController<String>.broadcast();
  Stream<String> get editorActions => _editorActionController.stream;
  void triggerEditorAction(String action) =>
      _editorActionController.add(action);

  Future<void> navigateToFileLine(String? fileName, int line, [int column = 1]) async {
    if (fileName != null && fileName.isNotEmpty && fileName != 'Script' && fileName != 'System') {
      final openIdx = _openFiles.indexWhere(
        (f) => f.name == fileName || f.path == fileName || p.basename(f.path) == fileName,
      );
      if (openIdx != -1) {
        _activeFileIndex = openIdx;
        notifyListeners();
      } else if (!kIsWeb && _projectRoot != null) {
        final candidate = io.File(
          p.isAbsolute(fileName) ? fileName : p.join(_projectRoot!, fileName),
        );
        if (await candidate.exists()) {
          await openFile(candidate);
        }
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    triggerEditorAction('editor.gotoLine:$line:$column');
  }

  void updatePlotMetadata(
    String plotId, {
    String? title,
    String? xlabel,
    String? ylabel,
    bool? showGrid,
    bool? showLegend,
    bool? showLabels,
  }) {
    final idx = _generatedPlots.indexWhere((p) => p.id == plotId);
    if (idx == -1) return;
    _generatedPlots[idx] = _generatedPlots[idx].copyWith(
      title: title,
      xlabel: xlabel,
      ylabel: ylabel,
      showGrid: showGrid,
      showLegend: showLegend,
      showLabels: showLabels,
    );
    onPlotsUpdated?.call(List.from(_generatedPlots));
    notifyListeners();
  }

  Future<bool> exportPlotSnapshot([PlotData? targetPlot]) async {
    final plot = targetPlot ?? (_generatedPlots.isNotEmpty ? _generatedPlots.last : null);
    if (plot == null) {
      _addConsoleMessage('No plots available to snapshot.', ConsoleMessageType.warning);
      return false;
    }

    try {
      final sanitizedTitle = plot.title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      if (plot.imageDataUri != null && plot.imageDataUri!.isNotEmpty) {
        final base64String = plot.imageDataUri!.contains(',')
            ? plot.imageDataUri!.split(',').last
            : plot.imageDataUri!;
        final bytes = base64Decode(base64String);
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Plot Snapshot',
          fileName: '$sanitizedTitle.png',
          type: FileType.custom,
          allowedExtensions: ['png'],
        );
        if (outputFile == null) return false;
        if (!outputFile.toLowerCase().endsWith('.png')) outputFile += '.png';
        await io.File(outputFile).writeAsBytes(bytes);
        _addConsoleMessage('Plot snapshot saved to $outputFile', ConsoleMessageType.success);
        return true;
      } else {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Export Plot Data (CSV)',
          fileName: '$sanitizedTitle.csv',
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );
        if (outputFile == null) return false;
        if (!outputFile.toLowerCase().endsWith('.csv')) outputFile += '.csv';
        final buf = StringBuffer('x,y\n');
        final count = plot.yData.length;
        for (int i = 0; i < count; i++) {
          final x = i < plot.xData.length ? plot.xData[i] : i.toDouble();
          buf.writeln('$x,${plot.yData[i]}');
        }
        await io.File(outputFile).writeAsString(buf.toString());
        _addConsoleMessage('Plot data exported to $outputFile', ConsoleMessageType.success);
        return true;
      }
    } catch (e) {
      _addConsoleMessage('Failed to save plot snapshot: $e', ConsoleMessageType.error);
      return false;
    }
  }

  Future<bool> exportPlotsToPdf([PlotData? singlePlot]) async {
    final plotsToExport = singlePlot != null ? [singlePlot] : List<PlotData>.from(_generatedPlots);
    if (plotsToExport.isEmpty) {
      if (activeFile != null) {
        await exportToPdf();
        return true;
      }
      _addConsoleMessage('No plots available to export to PDF.', ConsoleMessageType.warning);
      return false;
    }

    try {
      final pdf = pw.Document();
      final boldFont = await PdfGoogleFonts.robotoMonoBold();
      final regularFont = await PdfGoogleFonts.robotoMonoRegular();

      for (final plot in plotsToExport) {
        pw.Widget plotContent;
        if (plot.imageDataUri != null && plot.imageDataUri!.isNotEmpty) {
          final base64String = plot.imageDataUri!.contains(',')
              ? plot.imageDataUri!.split(',').last
              : plot.imageDataUri!;
          final bytes = base64Decode(base64String);
          plotContent = pw.Center(
            child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
          );
        } else {
          plotContent = pw.Text(
            'Series points: ${plot.yData.length}',
            style: pw.TextStyle(font: regularFont, fontSize: 10),
          );
        }

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    plot.title,
                    style: pw.TextStyle(font: boldFont, fontSize: 16),
                  ),
                  if (plot.xlabel != null || plot.ylabel != null)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Text(
                        'X: ${plot.xlabel ?? '-'}   |   Y: ${plot.ylabel ?? '-'}',
                        style: pw.TextStyle(font: regularFont, fontSize: 9, color: PdfColors.grey700),
                      ),
                    ),
                  pw.SizedBox(height: 8),
                  pw.Divider(),
                  pw.SizedBox(height: 12),
                  pw.Expanded(child: plotContent),
                  pw.SizedBox(height: 8),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Exported from UniLab on ${DateTime.now().toIso8601String()}',
                      style: pw.TextStyle(font: regularFont, fontSize: 8, color: PdfColors.grey),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      final bytes = await pdf.save();
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Plots to PDF',
        fileName: singlePlot != null
            ? '${singlePlot.title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')}.pdf'
            : 'unilab_figures.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (outputFile == null) return false;
      if (!outputFile.toLowerCase().endsWith('.pdf')) outputFile += '.pdf';
      await io.File(outputFile).writeAsBytes(bytes);
      _addConsoleMessage('Exported plots PDF to $outputFile', ConsoleMessageType.success);
      return true;
    } catch (e) {
      _addConsoleMessage('Plot PDF export failed: $e', ConsoleMessageType.error);
      return false;
    }
  }

  Future<void> exportToHtmlReport() async {
    try {
      final scriptName = activeFile?.name ?? 'Workspace Session';
      final scriptContent = activeFile?.content ?? '% No active script';
      final defaultFileName = activeFile != null
          ? activeFile!.name.replaceAll(RegExp(r'\.[^.]+$'), '_report.html')
          : 'unilab_report.html';

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export HTML Report',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['html'],
      );
      if (outputFile == null) return;
      if (!outputFile.toLowerCase().endsWith('.html')) outputFile += '.html';

      const htmlEscape = HtmlEscape();
      final escapedCode = htmlEscape.convert(scriptContent);
      final escapedConsole = htmlEscape.convert(consoleOutput);

      final varsRows = StringBuffer();
      _workspaceVariables.forEach((name, info) {
        if (info is Map) {
          final shape = (info['shape'] as List?)?.join('x') ?? '1x1';
          final dtype = info['dtype'] ?? 'double';
          final preview = htmlEscape.convert(info['preview']?.toString() ?? '');
          varsRows.writeln(
            '<tr><td><code>${htmlEscape.convert(name)}</code></td><td>$dtype</td><td>$shape</td><td><code>$preview</code></td></tr>',
          );
        }
      });

      final plotsHtml = StringBuffer();
      for (final plot in _generatedPlots) {
        if (plot.imageDataUri != null && plot.imageDataUri!.isNotEmpty) {
          plotsHtml.writeln('''
          <div class="plot-card">
            <h3>${htmlEscape.convert(plot.title)}</h3>
            <img src="${plot.imageDataUri}" alt="${htmlEscape.convert(plot.title)}" />
          </div>
          ''');
        }
      }

      final htmlDoc = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>UniLab Report - ${htmlEscape.convert(scriptName)}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #e2e8f0; margin: 0; padding: 32px; }
    .container { max-width: 1024px; margin: 0 auto; }
    h1 { color: #38bdf8; border-bottom: 1px solid #334155; padding-bottom: 12px; }
    h2 { color: #94a3b8; margin-top: 28px; font-size: 16px; text-transform: uppercase; letter-spacing: 0.08em; }
    pre { background: #1e293b; border: 1px solid #334155; border-radius: 8px; padding: 16px; overflow-x: auto; color: #f8fafc; font-family: "JetBrains Mono", monospace; font-size: 13px; }
    table { width: 100%; border-collapse: collapse; background: #1e293b; border-radius: 8px; overflow: hidden; }
    th, td { text-align: left; padding: 10px 14px; border-bottom: 1px solid #334155; font-size: 13px; }
    th { background: #0f172a; color: #38bdf8; }
    .plots-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(360px, 1fr)); gap: 16px; }
    .plot-card { background: #1e293b; border: 1px solid #334155; border-radius: 8px; padding: 16px; }
    .plot-card img { max-width: 100%; border-radius: 4px; }
    .meta { color: #64748b; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>UniLab Technical Report: ${htmlEscape.convert(scriptName)}</h1>
    <p class="meta">Generated on ${DateTime.now().toIso8601String()}</p>
    <h2>Source Script</h2>
    <pre>$escapedCode</pre>
    <h2>Console Output</h2>
    <pre>${escapedConsole.isEmpty ? '(No console output)' : escapedConsole}</pre>
    <h2>Workspace Variables (${_workspaceVariables.length})</h2>
    <table>
      <thead><tr><th>Name</th><th>Type</th><th>Size</th><th>Value</th></tr></thead>
      <tbody>${varsRows.isEmpty ? '<tr><td colspan="4">No variables in workspace</td></tr>' : varsRows.toString()}</tbody>
    </table>
    ${plotsHtml.isNotEmpty ? '<h2>Generated Figures (${_generatedPlots.length})</h2><div class="plots-grid">$plotsHtml</div>' : ''}
  </div>
</body>
</html>''';

      await io.File(outputFile).writeAsString(htmlDoc);
      _addConsoleMessage('Exported HTML Report to $outputFile', ConsoleMessageType.success);
    } catch (e) {
      _addConsoleMessage('HTML Report export failed: $e', ConsoleMessageType.error);
    }
  }

  /// Splits a MATLAB/UniLab script into top-level executable blocks with their starting 1-based line numbers.
  List<Map<String, dynamic>> parseExecutableBlocks(String content) {
    final lines = content.split('\n');
    final blocks = <Map<String, dynamic>>[];
    final currentLines = <String>[];
    int blockStartLine = 1;
    int depth = 0;

    final openRx = RegExp(r'\b(for|while|if|switch|function|try)\b');
    final closeRx = RegExp(r'\bend\b');

    for (int i = 0; i < lines.length; i++) {
      final rawLine = lines[i];
      final stripped = rawLine.replaceAll(RegExp(r'%.*$'), '').trim();
      if (stripped.isEmpty) continue;

      if (currentLines.isEmpty) {
        blockStartLine = i + 1;
      }
      currentLines.add(rawLine);

      final opens = openRx.allMatches(stripped).length;
      final closes = closeRx.allMatches(stripped).length;
      depth += opens - closes;
      if (depth <= 0 && !stripped.endsWith('...')) {
        depth = 0;
        blocks.add({
          'line': blockStartLine,
          'endLine': i + 1,
          'code': currentLines.join('\n'),
          'preview': currentLines.first.trim(),
        });
        currentLines.clear();
      }
    }

    if (currentLines.isNotEmpty) {
      blocks.add({
        'line': blockStartLine,
        'endLine': lines.length,
        'code': currentLines.join('\n'),
        'preview': currentLines.first.trim(),
      });
    }
    return blocks;
  }

  Future<Map<String, dynamic>> runScriptProfiler() async {
    if (activeFile == null || activeFile!.content.trim().isEmpty) {
      return {
        'error': 'No active script content to profile.',
        'totalMs': 0.0,
        'entries': <Map<String, dynamic>>[],
      };
    }

    final blocks = parseExecutableBlocks(activeFile!.content);
    final entries = <Map<String, dynamic>>[];
    double totalMs = 0.0;

    _isExecuting = true;
    notifyListeners();

    try {
      for (final block in blocks) {
        final sw = Stopwatch()..start();
        final result = await UniLabBridge.instance.execute(
          block['code'] as String,
          filename: activeFile!.path,
        );
        sw.stop();
        final elapsedMs = sw.elapsedMicroseconds / 1000.0;
        totalMs += elapsedMs;
        entries.add({
          'line': block['line'],
          'endLine': block['endLine'],
          'code': block['preview'],
          'durationMs': elapsedMs,
          'success': result.success && result.stderr.isEmpty,
          'stderr': result.stderr,
        });
        _updateVariablesFromResult(result);
        _updatePlotsFromResult(result);
      }
    } catch (e) {
      return {
        'error': e.toString(),
        'totalMs': totalMs,
        'entries': entries,
      };
    } finally {
      _isExecuting = false;
      await fetchWorkspaceVariables();
      notifyListeners();
    }

    return {
      'scriptName': activeFile!.name,
      'totalMs': totalMs,
      'entries': entries,
      'variableCount': _workspaceVariables.length,
    };
  }

  Map<String, dynamic> analyzeDependencies() {
    final code = activeFile?.content ?? '';
    final cleaned = code
        .replaceAll(RegExp(r'%.*$', multiLine: true), '')
        .replaceAll(RegExp(r"'[^']*'"), "''");

    final definedFunctions = <String>{};
    final fnDefRx = RegExp(
      r'^\s*function\s+(?:(?:\[[^\]]*\]|[a-zA-Z_]\w*)\s*=\s*)?([a-zA-Z_]\w*)',
      multiLine: true,
    );
    for (final m in fnDefRx.allMatches(cleaned)) {
      if (m.group(1) != null) definedFunctions.add(m.group(1)!);
    }

    const keywords = {
      'if', 'elseif', 'else', 'for', 'while', 'switch', 'case', 'otherwise',
      'try', 'catch', 'function', 'return', 'break', 'continue', 'end',
      'global', 'persistent', 'true', 'false',
    };
    const builtins = {
      'sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'atan2', 'sinh', 'cosh', 'tanh',
      'exp', 'log', 'log10', 'log2', 'sqrt', 'abs', 'round', 'floor', 'ceil', 'mod', 'rem',
      'zeros', 'ones', 'eye', 'rand', 'randn', 'linspace', 'logspace', 'meshgrid',
      'size', 'length', 'numel', 'ndims', 'reshape', 'transpose', 'inv', 'det', 'eig', 'svd',
      'norm', 'rank', 'trace', 'diag', 'sum', 'prod', 'mean', 'median', 'std', 'var', 'min', 'max',
      'sort', 'find', 'unique', 'plot', 'scatter', 'bar', 'hist', 'surf', 'mesh', 'contour',
      'figure', 'subplot', 'hold', 'grid', 'title', 'xlabel', 'ylabel', 'legend', 'xlim', 'ylim',
      'disp', 'fprintf', 'sprintf', 'num2str', 'str2num', 'tic', 'toc', 'pause', 'clear', 'clc',
      'fft', 'ifft', 'conv', 'polyval', 'polyfit', 'roots', 'ode45', 'fsolve', 'fminbnd',
    };

    final projectScripts = <String, String>{};
    for (final entity in _projectFiles) {
      if (entity is io.File && entity.path.endsWith('.m')) {
        final base = p.basenameWithoutExtension(entity.path);
        projectScripts[base] = entity.path;
      }
    }
    for (final open in _openFiles) {
      if (open.name.endsWith('.m')) {
        final base = p.basenameWithoutExtension(open.name);
        projectScripts.putIfAbsent(base, () => open.path);
      }
    }

    final assignedVars = <String>{};
    final assignRx = RegExp(r'^\s*([a-zA-Z_]\w*)\s*=', multiLine: true);
    for (final m in assignRx.allMatches(cleaned)) {
      if (m.group(1) != null) assignedVars.add(m.group(1)!);
    }

    final calledBuiltins = <String>{};
    final localDeps = <Map<String, String>>[];
    final seenLocal = <String>{};
    final externalCalls = <String>{};

    final callRx = RegExp(r'\b([a-zA-Z_]\w*)\s*\(');
    for (final m in callRx.allMatches(cleaned)) {
      final name = m.group(1)!;
      if (keywords.contains(name) || definedFunctions.contains(name) || assignedVars.contains(name)) {
        continue;
      }
      if (builtins.contains(name)) {
        calledBuiltins.add(name);
      } else if (projectScripts.containsKey(name)) {
        if (seenLocal.add(name)) {
          localDeps.add({'name': name, 'path': projectScripts[name]!});
        }
      } else if (!_workspaceVariables.containsKey(name)) {
        externalCalls.add(name);
      }
    }

    return {
      'scriptName': activeFile?.name ?? 'Untitled',
      'definedFunctions': definedFunctions.toList()..sort(),
      'localDependencies': localDeps,
      'builtinCalls': calledBuiltins.toList()..sort(),
      'externalCalls': externalCalls.toList()..sort(),
    };
  }

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
