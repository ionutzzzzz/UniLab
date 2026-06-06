import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../theme/syntax_themes.dart';

class SettingsProvider with ChangeNotifier {
  UserSettings _settings = UserSettings();
  
  UserSettings get settings => _settings;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeIndex = prefs.getInt('themeMode') ?? ThemeMode.system.index;
    final fontSize = prefs.getDouble('fontSize') ?? 14.0;
    final fontFamily = prefs.getString('fontFamily') ?? 'JetBrains Mono';
    
    final primaryColorValue = prefs.getInt('primaryColor') ?? 0xFF007ACC;
    final accentColorValue = prefs.getInt('accentColor') ?? 0xFF4AA3FF;
    final editorTheme = prefs.getString('editorTheme') ?? 'monokai';
    
    final uiScale = prefs.getDouble('uiScale') ?? 1.0;
    final animationEnabled = prefs.getBool('animationEnabled') ?? true;
    final rememberLayout = prefs.getBool('rememberLayout') ?? true;
    final tabSize = prefs.getInt('tabSize') ?? 4;
    final showLineNumbers = prefs.getBool('showLineNumbers') ?? true;
    final wordWrap = prefs.getBool('wordWrap') ?? false;
    final showMinimap = prefs.getBool('showMinimap') ?? false;

    final autoSave = prefs.getBool('autoSave') ?? true;
    final bracketMatching = prefs.getBool('bracketMatching') ?? true;
    final showHiddenFiles = prefs.getBool('showHiddenFiles') ?? false;
    final autoRefreshExplorer = prefs.getBool('autoRefreshExplorer') ?? true;
    final realTimeInspector = prefs.getBool('realTimeInspector') ?? true;
    final restrictedExecution = prefs.getBool('restrictedExecution') ?? true;
    final networkAccess = prefs.getBool('networkAccess') ?? false;
    final telemetry = prefs.getBool('telemetry') ?? true;
    final kernelAddress = prefs.getString('kernelAddress') ?? 'http://localhost:8000';
    final connectionTimeout = prefs.getInt('connectionTimeout') ?? 30;
    final executionTimeout = prefs.getInt('executionTimeout') ?? 300;
    final showWhitespace = prefs.getBool('showWhitespace') ?? false;
    final enableAutocomplete = prefs.getBool('enableAutocomplete') ?? true;
    final defaultProjectPath = prefs.getString('defaultProjectPath') ?? '';
    final plotColormap = prefs.getString('plotColormap') ?? 'Blues';
    String syntaxHighlightTheme = prefs.getString('syntaxHighlightTheme') ?? 'Dracula';
    
    // Validate that the loaded theme actually exists in our theme list
    final availableThemes = SyntaxHighlightTheme.all.map((t) => t.name).toList();
    if (!availableThemes.contains(syntaxHighlightTheme)) {
      syntaxHighlightTheme = 'Dracula';
    }
    
    final showToolbar = prefs.getBool('showToolbar') ?? true;
    final showStatusBar = prefs.getBool('showStatusBar') ?? true;
    
    Map<String, bool> panelVisibility = {
      'fileExplorer': prefs.getBool('panel_fileExplorer') ?? true,
      'workspace': prefs.getBool('panel_workspace') ?? true,
      'console': prefs.getBool('panel_console') ?? true,
    };
    
    Map<String, double> panelSizes = {
      'leftPanel': prefs.getDouble('panelSize_left') ?? 0.15,
      'rightPanel': prefs.getDouble('panelSize_right') ?? 0.20,
    };

    _settings = UserSettings(
      themeMode: ThemeMode.values[themeIndex],
      fontSize: fontSize,
      fontFamily: fontFamily,
      primaryColor: Color(primaryColorValue),
      accentColor: Color(accentColorValue),
      editorTheme: editorTheme,
      panelVisibility: panelVisibility,
      panelSizes: panelSizes,
      uiScale: uiScale,
      animationEnabled: animationEnabled,
      rememberLayout: rememberLayout,
      tabSize: tabSize,
      showLineNumbers: showLineNumbers,
      wordWrap: wordWrap,
      showMinimap: showMinimap,
      autoSave: autoSave,
      bracketMatching: bracketMatching,
      showHiddenFiles: showHiddenFiles,
      autoRefreshExplorer: autoRefreshExplorer,
      realTimeInspector: realTimeInspector,
      restrictedExecution: restrictedExecution,
      networkAccess: networkAccess,
      telemetry: telemetry,
      kernelAddress: kernelAddress,
      connectionTimeout: connectionTimeout,
      executionTimeout: executionTimeout,
      showWhitespace: showWhitespace,
      enableAutocomplete: enableAutocomplete,
      defaultProjectPath: defaultProjectPath,
      plotColormap: plotColormap,
      syntaxHighlightTheme: syntaxHighlightTheme,
      showToolbar: showToolbar,
      showStatusBar: showStatusBar,
    );
    notifyListeners();
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _settings.themeMode.index);
    await prefs.setDouble('fontSize', _settings.fontSize);
    await prefs.setString('fontFamily', _settings.fontFamily);
    await prefs.setInt('primaryColor', _settings.primaryColor.toARGB32());
    await prefs.setInt('accentColor', _settings.accentColor.toARGB32());
    await prefs.setString('editorTheme', _settings.editorTheme);
    
    await prefs.setDouble('uiScale', _settings.uiScale);
    await prefs.setBool('animationEnabled', _settings.animationEnabled);
    await prefs.setBool('rememberLayout', _settings.rememberLayout);
    await prefs.setInt('tabSize', _settings.tabSize);
    await prefs.setBool('showLineNumbers', _settings.showLineNumbers);
    await prefs.setBool('wordWrap', _settings.wordWrap);
    await prefs.setBool('showMinimap', _settings.showMinimap);

    await prefs.setBool('autoSave', _settings.autoSave);
    await prefs.setBool('bracketMatching', _settings.bracketMatching);
    await prefs.setBool('showHiddenFiles', _settings.showHiddenFiles);
    await prefs.setBool('autoRefreshExplorer', _settings.autoRefreshExplorer);
    await prefs.setBool('realTimeInspector', _settings.realTimeInspector);
    await prefs.setBool('restrictedExecution', _settings.restrictedExecution);
    await prefs.setBool('networkAccess', _settings.networkAccess);
    await prefs.setBool('telemetry', _settings.telemetry);
    await prefs.setString('kernelAddress', _settings.kernelAddress);
    await prefs.setInt('connectionTimeout', _settings.connectionTimeout);
    await prefs.setInt('executionTimeout', _settings.executionTimeout);
    await prefs.setBool('showWhitespace', _settings.showWhitespace);
    await prefs.setBool('enableAutocomplete', _settings.enableAutocomplete);
    await prefs.setString('defaultProjectPath', _settings.defaultProjectPath);
    await prefs.setString('plotColormap', _settings.plotColormap);
    await prefs.setString('syntaxHighlightTheme', _settings.syntaxHighlightTheme);
    await prefs.setBool('showToolbar', _settings.showToolbar);
    
    // Save panel visibility
    for (final entry in _settings.panelVisibility.entries) {
      await prefs.setBool('panel_${entry.key}', entry.value);
    }
    
    // Save panel sizes
    for (final entry in _settings.panelSizes.entries) {
      await prefs.setDouble('panelSize_${entry.key}', entry.value);
    }
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _loadSettings();
  }
}