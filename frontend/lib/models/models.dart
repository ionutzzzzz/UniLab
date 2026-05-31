import 'package:flutter/material.dart';

class UserSettings {
  final ThemeMode? _themeMode;
  final String? _fontFamily;
  final double? _fontSize;
  final Color? _primaryColor;
  final String? _editorTheme;
  final Color? _accentColor;
  final Map<String, bool>? _panelVisibility;
  final Map<String, double>? _panelSizes;
  final double? _uiScale;
  final bool? _animationEnabled;
  final bool? _rememberLayout;
  final int? _tabSize;
  final bool? _showLineNumbers;
  final bool? _wordWrap;
  final bool? _showMinimap;
  final bool? _autoSave;
  final bool? _bracketMatching;
  final bool? _showHiddenFiles;
  final bool? _autoRefreshExplorer;
  final bool? _realTimeInspector;
  final bool? _restrictedExecution;
  final bool? _networkAccess;
  final bool? _telemetry;
  final String? _kernelAddress;
  final int? _connectionTimeout;
  final bool? _showWhitespace;
  final bool? _enableAutocomplete;
  final String? _defaultProjectPath;
  final String? _plotColormap;
  final String? _syntaxHighlightTheme;
  final bool? _showToolbar;
  final bool? _showStatusBar;

  ThemeMode get themeMode => _themeMode ?? ThemeMode.system;
  String get fontFamily => _fontFamily ?? 'JetBrains Mono';
  double get fontSize => _fontSize ?? 14.0;
  Color get primaryColor => _primaryColor ?? const Color(0xFF007ACC);
  String get editorTheme => _editorTheme ?? 'monokai';
  Color get accentColor => _accentColor ?? const Color(0xFF4AA3FF);
  Map<String, bool> get panelVisibility => _panelVisibility ?? const {
    'fileExplorer': true,
    'workspace': true,
    'console': true,
  };
  Map<String, double> get panelSizes => _panelSizes ?? const {
    'leftPanel': 0.2,
    'rightPanel': 0.25,
  };
  double get uiScale => _uiScale ?? 1.0;
  bool get animationEnabled => _animationEnabled ?? true;
  bool get rememberLayout => _rememberLayout ?? true;
  int get tabSize => _tabSize ?? 4;
  bool get showLineNumbers => _showLineNumbers ?? true;
  bool get wordWrap => _wordWrap ?? false;
  bool get showMinimap => _showMinimap ?? false;
  bool get autoSave => _autoSave ?? true;
  bool get bracketMatching => _bracketMatching ?? true;
  bool get showHiddenFiles => _showHiddenFiles ?? false;
  bool get autoRefreshExplorer => _autoRefreshExplorer ?? true;
  bool get realTimeInspector => _realTimeInspector ?? true;
  bool get restrictedExecution => _restrictedExecution ?? true;
  bool get networkAccess => _networkAccess ?? false;
  bool get telemetry => _telemetry ?? true;
  String get kernelAddress => _kernelAddress ?? 'http://localhost:8000';
  int get connectionTimeout => _connectionTimeout ?? 30;
  bool get showWhitespace => _showWhitespace ?? false;
  bool get enableAutocomplete => _enableAutocomplete ?? true;
  String get defaultProjectPath => _defaultProjectPath ?? '';
  String get plotColormap => _plotColormap ?? 'Blues';
  String get syntaxHighlightTheme => _syntaxHighlightTheme ?? 'Seaborn Deep';
  bool get showToolbar => _showToolbar ?? true;
  bool get showStatusBar => _showStatusBar ?? true;

  UserSettings({
    ThemeMode? themeMode,
    String? fontFamily,
    double? fontSize,
    Color? primaryColor,
    String? editorTheme,
    Color? accentColor,
    Map<String, bool>? panelVisibility,
    Map<String, double>? panelSizes,
    double? uiScale,
    bool? animationEnabled,
    bool? rememberLayout,
    int? tabSize,
    bool? showLineNumbers,
    bool? wordWrap,
    bool? showMinimap,
    bool? autoSave,
    bool? bracketMatching,
    bool? showHiddenFiles,
    bool? autoRefreshExplorer,
    bool? realTimeInspector,
    bool? restrictedExecution,
    bool? networkAccess,
    bool? telemetry,
    String? kernelAddress,
    int? connectionTimeout,
    bool? showWhitespace,
    bool? enableAutocomplete,
    String? defaultProjectPath,
    String? plotColormap,
    String? syntaxHighlightTheme,
    bool? showToolbar,
    bool? showStatusBar,
  }) : 
    _themeMode = themeMode,
    _fontFamily = fontFamily,
    _fontSize = fontSize,
    _primaryColor = primaryColor,
    _editorTheme = editorTheme,
    _accentColor = accentColor,
    _panelVisibility = panelVisibility,
    _panelSizes = panelSizes,
    _uiScale = uiScale,
    _animationEnabled = animationEnabled,
    _rememberLayout = rememberLayout,
    _tabSize = tabSize,
    _showLineNumbers = showLineNumbers,
    _wordWrap = wordWrap,
    _showMinimap = showMinimap,
    _autoSave = autoSave,
    _bracketMatching = bracketMatching,
    _showHiddenFiles = showHiddenFiles,
    _autoRefreshExplorer = autoRefreshExplorer,
    _realTimeInspector = realTimeInspector,
    _restrictedExecution = restrictedExecution,
    _networkAccess = networkAccess,
    _telemetry = telemetry,
    _kernelAddress = kernelAddress,
    _connectionTimeout = connectionTimeout,
    _showWhitespace = showWhitespace,
    _enableAutocomplete = enableAutocomplete,
    _defaultProjectPath = defaultProjectPath,
    _plotColormap = plotColormap,
    _syntaxHighlightTheme = syntaxHighlightTheme,
    _showToolbar = showToolbar,
    _showStatusBar = showStatusBar;

  UserSettings copyWith({
    ThemeMode? themeMode,
    String? fontFamily,
    double? fontSize,
    Color? primaryColor,
    String? editorTheme,
    Color? accentColor,
    Map<String, bool>? panelVisibility,
    Map<String, double>? panelSizes,
    double? uiScale,
    bool? animationEnabled,
    bool? rememberLayout,
    int? tabSize,
    bool? showLineNumbers,
    bool? wordWrap,
    bool? showMinimap,
    bool? autoSave,
    bool? bracketMatching,
    bool? showHiddenFiles,
    bool? autoRefreshExplorer,
    bool? realTimeInspector,
    bool? restrictedExecution,
    bool? networkAccess,
    bool? telemetry,
    String? kernelAddress,
    int? connectionTimeout,
    bool? showWhitespace,
    bool? enableAutocomplete,
    String? defaultProjectPath,
    String? plotColormap,
    String? syntaxHighlightTheme,
    bool? showToolbar,
    bool? showStatusBar,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      primaryColor: primaryColor ?? this.primaryColor,
      editorTheme: editorTheme ?? this.editorTheme,
      accentColor: accentColor ?? this.accentColor,
      panelVisibility: panelVisibility ?? this.panelVisibility,
      panelSizes: panelSizes ?? this.panelSizes,
      uiScale: uiScale ?? this.uiScale,
      animationEnabled: animationEnabled ?? this.animationEnabled,
      rememberLayout: rememberLayout ?? this.rememberLayout,
      tabSize: tabSize ?? this.tabSize,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      wordWrap: wordWrap ?? this.wordWrap,
      showMinimap: showMinimap ?? this.showMinimap,
      autoSave: autoSave ?? this.autoSave,
      bracketMatching: bracketMatching ?? this.bracketMatching,
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      autoRefreshExplorer: autoRefreshExplorer ?? this.autoRefreshExplorer,
      realTimeInspector: realTimeInspector ?? this.realTimeInspector,
      restrictedExecution: restrictedExecution ?? this.restrictedExecution,
      networkAccess: networkAccess ?? this.networkAccess,
      telemetry: telemetry ?? this.telemetry,
      kernelAddress: kernelAddress ?? this.kernelAddress,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      showWhitespace: showWhitespace ?? this.showWhitespace,
      enableAutocomplete: enableAutocomplete ?? this.enableAutocomplete,
      defaultProjectPath: defaultProjectPath ?? this.defaultProjectPath,
      plotColormap: plotColormap ?? this.plotColormap,
      syntaxHighlightTheme: syntaxHighlightTheme ?? this.syntaxHighlightTheme,
      showToolbar: showToolbar ?? this.showToolbar,
      showStatusBar: showStatusBar ?? this.showStatusBar,
    );
  }
}

class ExecutionResult {
  final bool success;
  final String stdout;
  final String stderr;
  final Map<String, dynamic> variables;
  final List<String> plots;

  ExecutionResult({
    required this.success,
    required this.stdout,
    required this.stderr,
    required this.variables,
    required this.plots,
  });

  factory ExecutionResult.fromJson(Map<String, dynamic> json) {
    return ExecutionResult(
      success: json['success'] ?? false,
      stdout: json['stdout'] ?? '',
      stderr: json['stderr'] ?? '',
      variables: json['variables_snapshot'] ?? {},
      plots: List<String>.from(json['plots'] ?? []),
    );
  }
}

class UniLabFile {
  final String id;
  final String name;
  final String path;
  final String content;
  final bool isModified;

  UniLabFile({
    required this.id,
    required this.name,
    required this.path,
    required this.content,
    this.isModified = false,
  });

  UniLabFile copyWith({
    String? id,
    String? name,
    String? path,
    String? content,
    bool? isModified,
  }) {
    return UniLabFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      content: content ?? this.content,
      isModified: isModified ?? this.isModified,
    );
  }
}
