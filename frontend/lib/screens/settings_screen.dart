import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/settings_provider.dart';
import '../theme/ui_theme.dart';
import '../widgets/ui_text.dart';
import '../widgets/ui_button.dart';
import '../widgets/ui_glass_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Appearance', 'icon': LucideIcons.palette},
    {'title': 'Editor', 'icon': LucideIcons.code2},
    {'title': 'Workspace', 'icon': LucideIcons.layoutGrid},
    {'title': 'Shortcuts', 'icon': LucideIcons.keyboard},
    {'title': 'Network', 'icon': LucideIcons.network},
  ];

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
                right: BorderSide(color: ui.colors.divider.withOpacity(0.5)),
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
                  child: Container(
                    padding: EdgeInsets.all(ui.spacing.xl),
                    child: _buildCategoryContent(ui, settingsProvider),
                  ),
                ),
                _buildContentFooter(ui),
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
        border: Border(bottom: BorderSide(color: ui.colors.divider.withOpacity(0.3))),
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

  Widget _buildContentFooter(UiTheme ui) {
    return Container(
      padding: EdgeInsets.all(ui.spacing.lg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ui.colors.divider.withOpacity(0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          UiButton(
            label: 'Restore Defaults',
            variant: UiButtonVariant.secondary,
            onPressed: () {},
          ),
          SizedBox(width: ui.spacing.md),
          UiButton(
            label: 'Apply Changes',
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
      default: return _buildComingSoon(ui);
    }
  }

  Widget _buildAppearanceSettings(UiTheme ui, SettingsProvider settingsProvider) {
    final settings = settingsProvider.settings;
    return ListView(
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
          Row(
            children: [
               _colorCircle(ui, const Color(0xFF4AA3FF), settings.accentColor, () => _updateAccent(settingsProvider, const Color(0xFF4AA3FF))),
               _colorCircle(ui, const Color(0xFF23D18B), settings.accentColor, () => _updateAccent(settingsProvider, const Color(0xFF23D18B))),
               _colorCircle(ui, const Color(0xFFF14C4C), settings.accentColor, () => _updateAccent(settingsProvider, const Color(0xFFF14C4C))),
               _colorCircle(ui, const Color(0xFFE5E510), settings.accentColor, () => _updateAccent(settingsProvider, const Color(0xFFE5E510))),
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
          true,
          (val) {},
        ),
      ],
    );
  }

  void _updateAccent(SettingsProvider provider, Color color) {
    provider.updateSettings(provider.settings.copyWith(accentColor: color));
  }

  Widget _colorCircle(UiTheme ui, Color color, Color current, VoidCallback onTap) {
    final isSelected = color.value == current.value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)] : null,
        ),
      ),
    );
  }

  Widget _buildEditorSettings(UiTheme ui, SettingsProvider settingsProvider) {
    final settings = settingsProvider.settings;
    return ListView(
      children: [
        _buildSectionHeader(ui, 'Code Aesthetics'),
        _buildSettingItem(
          ui,
          'Font Size',
          'Adjust the text size for the primary editor surface.',
          Row(
            children: [
              Expanded(
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
          SizedBox(width: 220, child: Align(alignment: Alignment.centerRight, child: control)),
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
        activeColor: ui.colors.accent,
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
                ? ui.colors.accent.withOpacity(0.15) 
                : (_isHovered ? ui.colors.hover.withOpacity(0.5) : Colors.transparent),
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
