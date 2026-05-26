import 'package:flutter/material.dart';

class UserSettings {
  final ThemeMode themeMode;
  final String fontFamily;
  final double fontSize;
  final Color primaryColor;
  final String editorTheme;
  
  // New UI/UX settings
  final Color accentColor;
  final Map<String, bool> panelVisibility;
  final Map<String, double> panelSizes;
  final double uiScale;
  final bool animationEnabled;
  final bool rememberLayout;
  final int tabSize;
  final bool showLineNumbers;
  final bool wordWrap;
  final bool showMinimap;

  UserSettings({
    this.themeMode = ThemeMode.system,
    this.fontFamily = 'Roboto Mono',
    this.fontSize = 14.0,
    this.primaryColor = const Color(0xFF007ACC),
    this.editorTheme = 'monokai',
    this.accentColor = const Color(0xFF00A4EF),
    this.panelVisibility = const {
      'fileExplorer': true,
      'workspace': true,
      'console': true,
    },
    this.panelSizes = const {
      'leftPanel': 0.2,
      'rightPanel': 0.25,
    },
    this.uiScale = 1.0,
    this.animationEnabled = true,
    this.rememberLayout = true,
    this.tabSize = 4,
    this.showLineNumbers = true,
    this.wordWrap = true,
    this.showMinimap = false,
  });

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
  final String name;
  final String path;
  final String content;
  final bool isModified;

  UniLabFile({
    required this.name,
    required this.path,
    required this.content,
    this.isModified = false,
  });

  UniLabFile copyWith({
    String? name,
    String? path,
    String? content,
    bool? isModified,
  }) {
    return UniLabFile(
      name: name ?? this.name,
      path: path ?? this.path,
      content: content ?? this.content,
      isModified: isModified ?? this.isModified,
    );
  }
}
