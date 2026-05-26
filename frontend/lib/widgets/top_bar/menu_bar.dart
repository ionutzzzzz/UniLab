import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../screens/settings_screen.dart';

class MenuBar extends StatelessWidget {
  final TabController tabController;

  const MenuBar({
    super.key,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: WindowCaption(
        brightness: Theme.of(context).brightness,
        backgroundColor: Theme.of(context).canvasColor,
        title: SizedBox(
          width: MediaQuery.of(context).size.width - 120, // Provide bounded width for Expanded
          child: Row(
            children: [
              // Logo / App Name
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  'UniLab',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              // Traditional Menu
              Expanded(
                child: Row(
                  children: [
                    _buildMenuButton(context, 'File'),
                    _buildMenuButton(context, 'Edit'),
                    _buildMenuButton(context, 'View'),
                    _buildMenuButton(context, 'Tools'),
                    _buildMenuButton(context, 'Help'),
                  ],
                ),
              ),
              // Right Side Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeaderIcon(
                    context,
                    Icons.search,
                    'Search',
                    onPressed: () {},
                  ),
                  _buildHeaderIcon(
                    context,
                    Icons.settings,
                    'Settings',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildHeaderIcon(
                    context,
                    Icons.circle,
                    'Status',
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFFCCCCCC),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(
    BuildContext context,
    IconData icon,
    String tooltip, {
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 14),
        onPressed: onPressed,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 24,
        ),
        splashRadius: 16,
      ),
    );
  }
}
