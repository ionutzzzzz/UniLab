import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

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
    var fontFamily = prefs.getString('fontFamily') ?? 'JetBrains Mono';
    if (fontFamily == 'RobotoMono' || fontFamily == 'Roboto Mono') {
      fontFamily = 'JetBrains Mono';
    }
    final primaryColorValue = prefs.getInt('primaryColor') ?? 0xFF007ACC;
    final accentColorValue = prefs.getInt('accentColor') ?? 0xFF00A4EF;
    final editorTheme = prefs.getString('editorTheme') ?? 'monokai';
    
    // Load new settings
    final uiScale = prefs.getDouble('uiScale') ?? 1.0;
    final animationEnabled = prefs.getBool('animationEnabled') ?? true;
    final rememberLayout = prefs.getBool('rememberLayout') ?? true;
    final tabSize = prefs.getInt('tabSize') ?? 4;
    final showLineNumbers = prefs.getBool('showLineNumbers') ?? true;
    final wordWrap = prefs.getBool('wordWrap') ?? true;
    final showMinimap = prefs.getBool('showMinimap') ?? false;
    
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
    
    // Save new settings
    await prefs.setDouble('uiScale', _settings.uiScale);
    await prefs.setBool('animationEnabled', _settings.animationEnabled);
    await prefs.setBool('rememberLayout', _settings.rememberLayout);
    await prefs.setInt('tabSize', _settings.tabSize);
    await prefs.setBool('showLineNumbers', _settings.showLineNumbers);
    await prefs.setBool('wordWrap', _settings.wordWrap);
    await prefs.setBool('showMinimap', _settings.showMinimap);
    
    // Save panel visibility
    for (final entry in _settings.panelVisibility.entries) {
      await prefs.setBool('panel_${entry.key}', entry.value);
    }
    
    // Save panel sizes
    for (final entry in _settings.panelSizes.entries) {
      await prefs.setDouble('panelSize_${entry.key}', entry.value);
    }
  }
}
