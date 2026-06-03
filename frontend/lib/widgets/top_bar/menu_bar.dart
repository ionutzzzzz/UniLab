import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../screens/settings_screen.dart';

class MenuBar extends StatelessWidget {
  final TabController tabController;

  const MenuBar({
    super.key,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: WindowCaption(
        brightness: Theme.of(context).brightness,
        backgroundColor: Colors.transparent,
        title: SizedBox(
          width: MediaQuery.of(context).size.width - 150,
          child: Row(
            children: [
              // Logo / App Name
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'UniLab',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Traditional Menu
              _buildMenuButton(context, 'File'),
              _buildMenuButton(context, 'Edit'),
              _buildMenuButton(context, 'View'),
              _buildMenuButton(context, 'Tools'),
              _buildMenuButton(context, 'Analyze'),
              _buildMenuButton(context, 'Publish'),
              _buildMenuButton(context, 'Help'),
              const SizedBox(width: 24),
              // Project Path Display
              Expanded(
                child: Consumer<AppProvider>(
                  builder: (context, appProvider, _) {
                    return Text(
                      'Project: ${appProvider.projectRoot}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF858585),
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
              // Right Side Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeaderIcon(
                    context,
                    Icons.search,
                    'Search (Ctrl+Shift+F)',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Global search coming soon.')));
                    },
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
                    'System Status: Active',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backend connection is active.')));
                    },
                    color: const Color(0xFF4EC9B0),
                  ),
                  const SizedBox(width: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFFCCCCCC),
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(
    BuildContext context,
    IconData icon,
    String tooltip, {
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 14, color: color),
        onPressed: onPressed,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 28,
        ),
        splashRadius: 16,
      ),
    );
  }
}

