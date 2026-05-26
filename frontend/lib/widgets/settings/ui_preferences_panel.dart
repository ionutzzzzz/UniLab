import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class UIPreferencesPanel extends StatelessWidget {
  const UIPreferencesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        final settings = settingsProvider.settings;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UI Quick Toggles',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF858585),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildToggle(
              context,
              'Dark Mode',
              Icons.dark_mode,
              settings.themeMode == ThemeMode.dark ||
                  (settings.themeMode == ThemeMode.system &&
                      MediaQuery.of(context).platformBrightness == Brightness.dark),
              (value) {
                final mode = value ? ThemeMode.dark : ThemeMode.light;
                settingsProvider.updateSettings(
                  settings.copyWith(themeMode: mode),
                );
              },
            ),
            _buildToggle(
              context,
              'Show File Explorer',
              Icons.folder,
              settings.panelVisibility['fileExplorer'] ?? true,
              (value) {
                final visibility = Map<String, bool>.from(settings.panelVisibility);
                visibility['fileExplorer'] = value;
                settingsProvider.updateSettings(
                  settings.copyWith(panelVisibility: visibility),
                );
              },
            ),
            _buildToggle(
              context,
              'Show Workspace',
              Icons.dashboard,
              settings.panelVisibility['workspace'] ?? true,
              (value) {
                final visibility = Map<String, bool>.from(settings.panelVisibility);
                visibility['workspace'] = value;
                settingsProvider.updateSettings(
                  settings.copyWith(panelVisibility: visibility),
                );
              },
            ),
            _buildToggle(
              context,
              'Show Console',
              Icons.terminal,
              settings.panelVisibility['console'] ?? true,
              (value) {
                final visibility = Map<String, bool>.from(settings.panelVisibility);
                visibility['console'] = value;
                settingsProvider.updateSettings(
                  settings.copyWith(panelVisibility: visibility),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildToggle(
    BuildContext context,
    String label,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          SizedBox(
            height: 24,
            child: Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
