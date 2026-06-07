import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../providers/settings_provider.dart';
import '../providers/app_provider.dart';
import '../theme/ui_theme.dart';
import '../theme/syntax_themes.dart';
import '../widgets/ui_text.dart';
import '../widgets/ui_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;
  final TextEditingController _hexController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Appearance', 'icon': LucideIcons.palette},
    {'title': 'Editor', 'icon': LucideIcons.code2},
    {'title': 'Workspace', 'icon': LucideIcons.layoutGrid},
    {'title': 'Shortcuts', 'icon': LucideIcons.keyboard},
    {'title': 'Network', 'icon': LucideIcons.network},
    {'title': 'Security', 'icon': LucideIcons.shieldCheck},
    {'title': 'Backend', 'icon': LucideIcons.server},
  ];

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: ui.colors.canvas,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: ui.colors.panel,
              border: Border(
                right: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5)),
              ),
            ),
            child: Column(
              children: [
                _buildSidebarHeader(ui),
                Expanded(
                  child: ListView.builder(
                    itemCount: _categories.length,
                    padding: EdgeInsets.symmetric(vertical: ui.spacing.sm),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedIndex == index;
                      return _CategoryItem(
                        title: category['title'],
                        icon: category['icon'],
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),
                _buildSidebarFooter(ui),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Column(
              children: [
                _buildContentHeader(ui),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(ui.spacing.xl),
                    child: _buildCategoryContent(ui, settingsProvider),
                  ),
                ),
                _buildContentFooter(ui, settingsProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(UiTheme ui) {
    return Container(
      padding: EdgeInsets.all(ui.spacing.lg),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(LucideIcons.settings, size: 20, color: ui.colors.accent),
          SizedBox(width: ui.spacing.md),
          const UiText(
            text: 'Settings',
            variant: UiTextVariant.body,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter(UiTheme ui) {
    return Container(
      padding: EdgeInsets.all(ui.spacing.lg),
      child: UiButton(
        label: 'Back to Editor',
        variant: UiButtonVariant.ghost,
        icon: LucideIcons.arrowLeft,
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildContentHeader(UiTheme ui) {
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.xl),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          UiText(
            text: _categories[_selectedIndex]['title'],
            variant: UiTextVariant.body,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildContentFooter(UiTheme ui, SettingsProvider provider) {
    return Container(
      padding: EdgeInsets.all(ui.spacing.lg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ui.colors.divider.withValues(alpha: 0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          UiButton(
            label: 'Restore Defaults',
            variant: UiButtonVariant.secondary,
            onPressed: () => provider.resetToDefaults(),
          ),
          SizedBox(width: ui.spacing.md),
          UiButton(
            label: 'Done',
            variant: UiButtonVariant.primary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(UiTheme ui, SettingsProvider settingsProvider) {
    switch (_selectedIndex) {
      case 0: return _buildAppearanceSettings(ui, settingsProvider);
      case 1: return _buildEditorSettings(ui, settingsProvider);
      case 2: return _buildWorkspaceSettings(ui, settingsProvider);
      case 3: return _buildShortcutsSettings(ui, settingsProvider);
      case 4: return _buildNetworkSettings(ui, settingsProvider);
      case 5: return _buildSecuritySettings(ui, settingsProvider);
      case 6: return _buildBackendSettings(ui);
      default: return _buildComingSoon(ui);
    }
  }

  Widget _buildBackendSettings(UiTheme ui) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final info = appProvider.serverInfo;
        final capabilities = (info['capabilities'] as List<dynamic>?)?.cast<String>() ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(ui, 'Server Information'),
            _buildSettingItem(
              ui,
              'Server Name',
              'The name of the connected backend engine.',
              UiText(text: info['name'] ?? 'Disconnected', variant: UiTextVariant.body, fontWeight: FontWeight.bold),
            ),
            _buildSettingItem(
              ui,
              'Version',
              'Current version of the backend server.',
              UiText(text: info['version'] ?? 'N/A', variant: UiTextVariant.body),
            ),
            _buildSettingItem(
              ui,
              'Status',
              'Current operational status of the server.',
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: info['status'] == 'active' ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  UiText(text: info['status']?.toUpperCase() ?? 'OFFLINE', variant: UiTextVariant.label),
                ],
              ),
            ),
            SizedBox(height: ui.spacing.xl),
            _buildSectionHeader(ui, 'Capabilities'),
            if (capabilities.isEmpty)
              UiText(text: 'No capabilities reported', variant: UiTextVariant.label, color: ui.colors.textMuted)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: capabilities.map((cap) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ui.colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: ui.colors.accent.withValues(alpha: 0.3)),
                  ),
                  child: UiText(
                    text: cap.toUpperCase(),
                    variant: UiTextVariant.label,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: ui.colors.accent,
                  ),
                )).toList(),
              ),
            SizedBox(height: ui.spacing.xl),
            _buildSectionHeader(ui, 'Session Control'),
            UiButton(
              label: 'Restart Backend Server',
              variant: UiButtonVariant.secondary,
              icon: LucideIcons.refreshCw,
              onPressed: () {
                // TODO: Implement backend restart
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppearanceSettings(UiTheme ui, SettingsProvider settingsProvider) {
    final settings = settingsProvider.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(ui, 'Theme Selection'),
        _buildSettingItem(
          ui,
          'Interface Theme',
          'Choose the overall look and feel of the application.',
          DropdownButton<ThemeMode>(
            value: settings.themeMode,
            dropdownColor: ui.colors.panel,
            style: ui.typography.body.copyWith(color: ui.colors.textPrimary),
            underline: Container(),
            onChanged: (ThemeMode? newValue) {
              if (newValue != null) {
                settingsProvider.updateSettings(settings.copyWith(themeMode: newValue));
              }
            },
            items: ThemeMode.values.map((mode) {
              return DropdownMenuItem(
                value: mode, 
                child: Text(mode.toString().split('.').last.toUpperCase(), style: const TextStyle(fontSize: 11)),
              );
            }).toList(),
          ),
        ),
        _buildSettingItem(
          ui,
          'Accent Color',
          'Primary color used for buttons, links, and highlights.',
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                   _colorCircle(ui, const Color(0xFF4AA3FF), settings.accentColor, () => _updateAccent(settingsProvider, const Color(0xFF4AA3FF))),
                   _colorCircle(ui, const Color(0xFF23D18B), settings.accentColor, () => _updateAccent(settingsProvider, const Color(0xFF23D18B))),
                   _colorCircle(ui, const Color(0xFFF14C4C), settings.accentColor, () => _updateAccent(settingsProvider, const Color(0xFFF14C4C))),
                   _colorCircle(ui, const Color(0xFFE5E510), settings.accentColor, () => _updateAccent(settingsProvider, const Color(0xFFE5E510))),
                   _colorCircle(ui, const Color(0xFFA44AFF), settings.accentColor, () => _updateAccent(settingsProvider, const Color(0xFFA44AFF))),
                   _colorCircle(ui, const Color(0xFFFF8C42), settings.accentColor, () => _updateAccent(settingsProvider, const Color(0xFFFF8C42))),
                   _colorCircle(ui, const Color(0xFF70C1B3), settings.accentColor, () => _updateAccent(settingsProvider, const Color(0xFF70C1B3))),
                   _colorCircle(ui, const Color(0xFFE9724C), settings.accentColor, () => _updateAccent(settingsProvider, const Color(0xFFE9724C))),
                   _colorCircle(ui, const Color(0xFF255C99), settings.accentColor, () => _updateAccent(settingsProvider, const Color(0xFF255C99))),
                   _colorCircle(ui, const Color(0xFFC33C54), settings.accentColor, () => _updateAccent(settingsProvider, const Color(0xFFC33C54))),
                ],
              ),
              const SizedBox(height: 12),
              UiButton(
                label: 'Choose Custom Color',
                size: UiButtonSize.sm,
                variant: UiButtonVariant.secondary,
                icon: LucideIcons.pipette,
                onPressed: () => _showColorPicker(context, settingsProvider),
              ),
            ],
          ),
        ),
        _buildSettingItem(
          ui,
          'UI Scale',
          'Adjust the overall size of the user interface elements.',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                child: Slider(
                  value: settings.uiScale,
                  min: 0.8,
                  max: 1.4,
                  divisions: 6,
                  activeColor: ui.colors.accent,
                  onChanged: (val) => settingsProvider.updateSettings(settings.copyWith(uiScale: val)),
                ),
              ),
              const SizedBox(width: 8),
              UiText(text: '${(settings.uiScale * 100).toInt()}%', variant: UiTextVariant.label),
            ],
          ),
        ),
        SizedBox(height: ui.spacing.xl),
        _buildSectionHeader(ui, 'Layout Customization'),
        _buildSettingToggle(
          ui,
          'Glassmorphism Effects',
          'Enable backdrop blur on transient surfaces for a premium feel.',
          true,
          (val) {},
        ),
        _buildSettingToggle(
          ui,
          'Smooth Animations',
          'Enable interface transitions and micro-animations.',
          settings.animationEnabled,
          (val) => settingsProvider.updateSettings(settings.copyWith(animationEnabled: val)),
        ),
        _buildSettingToggle(
          ui,
          'Remember Layout',
          'Persist panel sizes and visibility across sessions.',
          settings.rememberLayout,
          (val) => settingsProvider.updateSettings(settings.copyWith(rememberLayout: val)),
        ),
        SizedBox(height: ui.spacing.xl),
        _buildSectionHeader(ui, 'Shell Visibility'),
        _buildSettingToggle(
          ui,
          'Show Toolbar',
          'Display the top ribbon navigation bar.',
          settings.showToolbar,
          (val) => settingsProvider.updateSettings(settings.copyWith(showToolbar: val)),
        ),
        _buildSettingToggle(
          ui,
          'Show Status Bar',
          'Display the bottom application status bar.',
          settings.showStatusBar,
          (val) => settingsProvider.updateSettings(settings.copyWith(showStatusBar: val)),
        ),
      ],
    );
  }

  Future<void> _showColorPicker(BuildContext context, SettingsProvider provider) async {
    Color colorBeforeDialog = provider.settings.accentColor;
    
    if (await ColorPicker(
      color: provider.settings.accentColor,
      onColorChanged: (Color color) => _updateAccent(provider, color),
      width: 40,
      height: 40,
      borderRadius: 4,
      spacing: 5,
      runSpacing: 5,
      wheelDiameter: 155,
      heading: UiText(text: 'Select Accent Color', variant: UiTextVariant.body, fontWeight: FontWeight.bold),
      subheading: UiText(text: 'Select color shade', variant: UiTextVariant.label),
      wheelSubheading: UiText(text: 'Selected color and its shades', variant: UiTextVariant.label),
      showColorName: true,
      showColorCode: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        longPressMenu: true,
      ),
      materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
      pickerTypeLabels: const <ColorPickerType, String>{
        ColorPickerType.primary: 'Primary',
        ColorPickerType.accent: 'Accent',
      },
    ).showPickerDialog(
      context,
      constraints: const BoxConstraints(minWidth: 480, minHeight: 480, maxWidth: 480, maxHeight: 600),
    )) {
      // Picked
    } else {
      _updateAccent(provider, colorBeforeDialog);
    }
  }

  void _updateAccent(SettingsProvider provider, Color color) {
    provider.updateSettings(provider.settings.copyWith(accentColor: color));
  }

  Widget _colorCircle(UiTheme ui, Color color, Color current, VoidCallback onTap) {
    final isSelected = color.toARGB32() == current.toARGB32();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : Border.all(color: Colors.white24, width: 1),
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)] : null,
        ),
      ),
    );
  }

  Widget _buildEditorSettings(UiTheme ui, SettingsProvider settingsProvider) {
    final settings = settingsProvider.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(ui, 'Code Aesthetics'),
        _buildSettingItem(
          ui,
          'Font Family',
          'The typeface used for code display.',
          DropdownButton<String>(
            value: settings.fontFamily,
            dropdownColor: ui.colors.panel,
            style: ui.typography.body.copyWith(color: ui.colors.textPrimary),
            underline: Container(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                settingsProvider.updateSettings(settings.copyWith(fontFamily: newValue));
              }
            },
            items: ['JetBrains Mono', 'Roboto Mono', 'Fira Code', 'Source Code Pro'].map((font) {
              return DropdownMenuItem(
                value: font, 
                child: Text(font, style: const TextStyle(fontSize: 11)),
              );
            }).toList(),
          ),
        ),
        _buildSettingItem(
          ui,
          'Font Size',
          'Adjust the text size for the primary editor surface.',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                child: Slider(
                  value: settings.fontSize,
                  min: 10,
                  max: 24,
                  activeColor: ui.colors.accent,
                  onChanged: (val) {
                    settingsProvider.updateSettings(settings.copyWith(fontSize: val));
                  },
                ),
              ),
              const SizedBox(width: 12),
              UiText(text: '${settings.fontSize.toInt()}px', variant: UiTextVariant.label),
            ],
          ),
        ),
        _buildSettingToggle(
          ui,
          'Line Numbers',
          'Show gutter line numbers in the editor.',
          settings.showLineNumbers,
          (val) => settingsProvider.updateSettings(settings.copyWith(showLineNumbers: val)),
        ),
        _buildSettingToggle(
          ui,
          'Minimap',
          'Display a code overview on the right side of the editor.',
          settings.showMinimap,
          (val) => settingsProvider.updateSettings(settings.copyWith(showMinimap: val)),
        ),
        _buildSettingItem(
          ui,
          'Highlight Theme',
          'Theme colors used for code syntax highlighting.',
          DropdownButton<String>(
            value: SyntaxHighlightTheme.all.any((m) => m.name == settings.syntaxHighlightTheme)
                ? settings.syntaxHighlightTheme
                : SyntaxHighlightTheme.all.first.name,
            dropdownColor: ui.colors.panel,
            style: ui.typography.body.copyWith(color: ui.colors.textPrimary),
            underline: Container(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                settingsProvider.updateSettings(settings.copyWith(syntaxHighlightTheme: newValue));
              }
            },
            items: SyntaxHighlightTheme.all.map((map) {
              return DropdownMenuItem(
                value: map.name, 
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: map.backgroundColor,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(map.name, style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 12),
                    Row(
                      children: map.colors.take(4).map((c) => Container(width: 6, height: 6, color: c)).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        _buildSettingToggle(
          ui,
          'Show Whitespace',
          'Display visible characters for spaces and tabs.',
          settings.showWhitespace,
          (val) => settingsProvider.updateSettings(settings.copyWith(showWhitespace: val)),
        ),
        SizedBox(height: ui.spacing.xl),
        _buildSectionHeader(ui, 'Behavior'),
        _buildSettingToggle(
          ui,
          'Enable Autocomplete',
          'Show intelligent code suggestions as you type.',
          settings.enableAutocomplete,
          (val) => settingsProvider.updateSettings(settings.copyWith(enableAutocomplete: val)),
        ),
        _buildSettingItem(
          ui,
          'Tab Size',
          'Number of spaces per indentation level.',
          DropdownButton<int>(
            value: settings.tabSize,
            dropdownColor: ui.colors.panel,
            style: ui.typography.body.copyWith(color: ui.colors.textPrimary),
            underline: Container(),
            onChanged: (int? newValue) {
              if (newValue != null) {
                settingsProvider.updateSettings(settings.copyWith(tabSize: newValue));
              }
            },
            items: [2, 4, 8].map((size) {
              return DropdownMenuItem(
                value: size, 
                child: Text('$size Spaces', style: const TextStyle(fontSize: 11)),
              );
            }).toList(),
          ),
        ),
        _buildSettingToggle(
          ui,
          'Auto-save',
          'Automatically save changes to disk after a short delay.',
          settings.autoSave,
          (val) => settingsProvider.updateSettings(settings.copyWith(autoSave: val)),
        ),
        _buildSettingToggle(
          ui,
          'Word Wrap',
          'Force long lines to wrap within the editor width.',
          settings.wordWrap,
          (val) => settingsProvider.updateSettings(settings.copyWith(wordWrap: val)),
        ),
        _buildSettingToggle(
          ui,
          'Bracket Matching',
          'Highlight matching brackets when the cursor is near one.',
          settings.bracketMatching,
          (val) => settingsProvider.updateSettings(settings.copyWith(bracketMatching: val)),
        ),
      ],
    );
  }

  Widget _buildWorkspaceSettings(UiTheme ui, SettingsProvider settingsProvider) {
    final settings = settingsProvider.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(ui, 'Project Management'),
        _buildSettingItem(
          ui,
          'Default Project Path',
          'Initial directory loaded when no project is specified.',
          SizedBox(
            width: 250,
            child: TextField(
              controller: TextEditingController(text: settings.defaultProjectPath),
              onSubmitted: (val) => settingsProvider.updateSettings(settings.copyWith(defaultProjectPath: val)),
              decoration: const InputDecoration(
                hintText: '/home/user/unilab_projects',
                isDense: true,
              ),
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ),
        _buildSettingToggle(
          ui,
          'Auto-refresh Explorer',
          'Listen for file system changes and update the sidebar automatically.',
          settings.autoRefreshExplorer,
          (val) => settingsProvider.updateSettings(settings.copyWith(autoRefreshExplorer: val)),
        ),
        _buildSettingToggle(
          ui,
          'Show Hidden Files',
          'Display dotfiles and hidden system entries in the explorer.',
          settings.showHiddenFiles,
          (val) => settingsProvider.updateSettings(settings.copyWith(showHiddenFiles: val)),
        ),
        SizedBox(height: ui.spacing.xl),
        _buildSectionHeader(ui, 'Data Display'),
        _buildSettingToggle(
          ui,
          'Real-time Inspector',
          'Update property inspector while simulation is running.',
          settings.realTimeInspector,
          (val) => settingsProvider.updateSettings(settings.copyWith(realTimeInspector: val)),
        ),
      ],
    );
  }

  Widget _buildShortcutsSettings(UiTheme ui, SettingsProvider settingsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(ui, 'Keyboard Mapping'),
        _buildShortcutItem(ui, 'Execute Script', 'F5'),
        _buildShortcutItem(ui, 'Command Palette', 'Ctrl+Shift+P'),
        _buildShortcutItem(ui, 'Find in File', 'Ctrl+F'),
        _buildShortcutItem(ui, 'Save All', 'Ctrl+S'),
        _buildShortcutItem(ui, 'Toggle Sidebar', 'Ctrl+B'),
        _buildShortcutItem(ui, 'Toggle Console', 'Ctrl+J'),
        SizedBox(height: ui.spacing.lg),
        Center(
          child: UiButton(
            label: 'Customize All Shortcuts',
            variant: UiButtonVariant.secondary,
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutItem(UiTheme ui, String action, String key) {
    return Padding(
      padding: EdgeInsets.only(bottom: ui.spacing.md),
      child: Row(
        children: [
          Expanded(child: UiText(text: action, variant: UiTextVariant.body)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ui.colors.panelHeader,
              borderRadius: ui.spacing.radiusSm,
              border: Border.all(color: ui.colors.divider),
            ),
            child: UiText(
              text: key,
              variant: UiTextVariant.codeBody,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: ui.colors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSettings(UiTheme ui, SettingsProvider settingsProvider) {
    final settings = settingsProvider.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(ui, 'Backend Connectivity'),
        _buildSettingItem(
          ui,
          'Kernel Address',
          'Endpoint URL for the UniLab computation engine.',
          SizedBox(
            width: 200,
            child: TextField(
              controller: TextEditingController(text: settings.kernelAddress),
              onSubmitted: (val) => settingsProvider.updateSettings(settings.copyWith(kernelAddress: val)),
              decoration: const InputDecoration(
                hintText: 'http://localhost:8000',
                isDense: true,
              ),
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ),
        _buildSettingItem(
          ui,
          'Connection Timeout',
          'Seconds to wait before aborting a request.',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: settings.connectionTimeout.toDouble(), 
                min: 5, 
                max: 120, 
                divisions: 23,
                onChanged: (v) => settingsProvider.updateSettings(settings.copyWith(connectionTimeout: v.toInt())),
              ),
              UiText(text: '${settings.connectionTimeout}s', variant: UiTextVariant.label),
            ],
          ),
        ),
        _buildSettingItem(
          ui,
          'Execution Timeout',
          'Maximum seconds allowed for a single script or command to run.',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: settings.executionTimeout.toDouble(), 
                min: 5, 
                max: 1800, // Up to 30 minutes
                divisions: 359,
                onChanged: (v) => settingsProvider.updateSettings(settings.copyWith(executionTimeout: v.toInt())),
              ),
              UiText(text: '${settings.executionTimeout}s', variant: UiTextVariant.label),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySettings(UiTheme ui, SettingsProvider settingsProvider) {
    final settings = settingsProvider.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(ui, 'Sandbox & Privacy'),
        _buildSettingToggle(
          ui,
          'Restricted Execution',
          'Prevent scripts from accessing system paths outside project root.',
          settings.restrictedExecution,
          (val) => settingsProvider.updateSettings(settings.copyWith(restrictedExecution: val)),
        ),
        _buildSettingToggle(
          ui,
          'Network Access',
          'Allow user scripts to make outbound network requests.',
          settings.networkAccess,
          (val) => settingsProvider.updateSettings(settings.copyWith(networkAccess: val)),
        ),
        _buildSettingToggle(
          ui,
          'Telemetry',
          'Send anonymous usage data to improve UniLab.',
          settings.telemetry,
          (val) => settingsProvider.updateSettings(settings.copyWith(telemetry: val)),
        ),
      ],
    );
  }

  Widget _buildComingSoon(UiTheme ui) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.construction, size: 48, color: ui.colors.textDisabled),
          const SizedBox(height: 16),
          UiText(text: 'Settings section coming soon', color: ui.colors.textMuted),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(UiTheme ui, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: ui.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiText(
            text: title.toUpperCase(),
            variant: UiTextVariant.label,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            fontSize: 10,
            color: ui.colors.textMuted,
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildSettingItem(UiTheme ui, String title, String description, Widget control) {
    return Padding(
      padding: EdgeInsets.only(bottom: ui.spacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UiText(text: title, variant: UiTextVariant.body, fontWeight: FontWeight.bold),
                const SizedBox(height: 4),
                UiText(text: description, variant: UiTextVariant.label, color: ui.colors.textMuted),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Align(alignment: Alignment.centerRight, child: control),
        ],
      ),
    );
  }

  Widget _buildSettingToggle(UiTheme ui, String title, String description, bool value, ValueChanged<bool> onChanged) {
    return _buildSettingItem(
      ui,
      title,
      description,
      Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: ui.colors.accent,
      ),
    );
  }
}

class _CategoryItem extends StatefulWidget {
  const _CategoryItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(horizontal: ui.spacing.md, vertical: 2),
          padding: EdgeInsets.symmetric(horizontal: ui.spacing.md, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? ui.colors.accent.withValues(alpha: 0.15) 
                : (_isHovered ? ui.colors.hover.withValues(alpha: 0.5) : Colors.transparent),
            borderRadius: ui.spacing.radiusMd,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon, 
                size: 16, 
                color: widget.isSelected ? ui.colors.accent : ui.colors.textMuted
              ),
              SizedBox(width: ui.spacing.md),
              UiText(
                text: widget.title,
                variant: UiTextVariant.body,
                fontSize: 12,
                fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                color: widget.isSelected ? ui.colors.textPrimary : ui.colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
