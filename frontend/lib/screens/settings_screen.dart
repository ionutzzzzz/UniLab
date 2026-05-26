import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Appearance', 'icon': Icons.palette},
    {'title': 'Editor', 'icon': Icons.code},
    {'title': 'Workspace', 'icon': Icons.dashboard},
    {'title': 'Shortcuts', 'icon': Icons.keyboard},
    {'title': 'Notifications', 'icon': Icons.notifications},
  ];

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final settings = settingsProvider.settings;

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontSize: 14)),
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0,
        toolbarHeight: 48,
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedIndex == index;
                return ListTile(
                  leading: Icon(category['icon'], size: 18, color: isSelected ? Theme.of(context).primaryColor : null),
                  title: Text(
                    category['title'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  selected: isSelected,
                  onTap: () => setState(() => _selectedIndex = index),
                  dense: true,
                );
              },
            ),
          ),
          // Content
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: _buildCategoryContent(settingsProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(SettingsProvider settingsProvider) {
    switch (_selectedIndex) {
      case 0: return _buildAppearanceSettings(settingsProvider);
      case 1: return _buildEditorSettings(settingsProvider);
      default: return const Center(child: Text('Coming soon...'));
    }
  }

  Widget _buildAppearanceSettings(SettingsProvider settingsProvider) {
    final settings = settingsProvider.settings;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('Theme'),
        _buildSettingItem(
          'Theme Mode',
          DropdownButton<ThemeMode>(
            value: settings.themeMode,
            style: const TextStyle(fontSize: 12, color: Colors.white),
            underline: Container(),
            onChanged: (ThemeMode? newValue) {
              if (newValue != null) {
                settingsProvider.updateSettings(settings.copyWith(themeMode: newValue));
              }
            },
            items: ThemeMode.values.map((mode) {
              return DropdownMenuItem(value: mode, child: Text(mode.toString().split('.').last));
            }).toList(),
          ),
        ),
        _buildSettingItem(
          'Primary Color',
          Row(
            children: [
               _colorCircle(const Color(0xFF007ACC), settings.primaryColor, () => _updateColor(settingsProvider, const Color(0xFF007ACC))),
               _colorCircle(const Color(0xFF4EC9B0), settings.primaryColor, () => _updateColor(settingsProvider, const Color(0xFF4EC9B0))),
               _colorCircle(const Color(0xFFCE9178), settings.primaryColor, () => _updateColor(settingsProvider, const Color(0xFFCE9178))),
               _colorCircle(const Color(0xFFF48771), settings.primaryColor, () => _updateColor(settingsProvider, const Color(0xFFF48771))),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Layout'),
        _buildSettingItem(
          'UI Scale',
          Slider(
            value: 1.0, // TODO: Store in settings
            min: 0.8,
            max: 1.5,
            onChanged: (val) {},
          ),
        ),
      ],
    );
  }

  void _updateColor(SettingsProvider provider, Color color) {
    provider.updateSettings(provider.settings.copyWith(primaryColor: color));
  }

  Widget _colorCircle(Color color, Color current, VoidCallback onTap) {
    final isSelected = color.value == current.value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
      ),
    );
  }

  Widget _buildEditorSettings(SettingsProvider settingsProvider) {
    final settings = settingsProvider.settings;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('Typography'),
        _buildSettingItem(
          'Font Size',
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: settings.fontSize,
                  min: 10,
                  max: 30,
                  onChanged: (val) {
                    settingsProvider.updateSettings(settings.copyWith(fontSize: val));
                  },
                ),
              ),
              Text('${settings.fontSize.toInt()}px'),
            ],
          ),
        ),
        _buildSettingItem(
          'Font Family',
          const Text('Consolas, "Courier New", monospace', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 16),
          if (trailing is Expanded) trailing else SizedBox(width: 200, child: Align(alignment: Alignment.centerRight, child: trailing)),
        ],
      ),
    );
  }
}
