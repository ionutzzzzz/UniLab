import 'package:flutter/material.dart';
import '../../providers/app_provider.dart';

/// Quick Actions Toolbar - Compact buttons in the top bar
class QuickActionsBar extends StatelessWidget {
  final AppProvider appProvider;

  const QuickActionsBar({
    super.key,
    required this.appProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // File Operations
          _buildQuickButton(
            context,
            Icons.note_add,
            'New File',
            () => appProvider.addNewFile(),
          ),
          _buildQuickButton(
            context,
            Icons.folder_open,
            'Open',
            () {},
          ),
          _buildQuickButton(
            context,
            Icons.save,
            'Save',
            () {},
          ),
          _buildDivider(context),
          // Edit Operations
          _buildQuickButton(
            context,
            Icons.undo,
            'Undo',
            () {},
          ),
          _buildQuickButton(
            context,
            Icons.redo,
            'Redo',
            () {},
          ),
          _buildDivider(context),
          // Execution
          _buildQuickButton(
            context,
            Icons.play_arrow,
            'Run',
            () => appProvider.runActiveFile(),
            color: const Color(0xFF4EC9B0),
            loading: appProvider.isExecuting,
          ),
          _buildQuickButton(
            context,
            Icons.stop,
            'Stop',
            () {},
            color: const Color(0xFFF48771),
          ),
          const Spacer(),
          // Right-aligned actions
          _buildQuickButton(
            context,
            Icons.help_outline,
            'Help',
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    Color? color,
    bool loading = false,
  }) {
    final isEnabled = !loading;
    return Tooltip(
      message: loading ? 'Executing...' : tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          hoverColor: Theme.of(context).hoverColor,
          borderRadius: BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    icon,
                    size: 14,
                    color: isEnabled ? (color ?? const Color(0xFFCCCCCC)) : Colors.grey,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: VerticalDivider(
        color: Theme.of(context).dividerColor,
        width: 1,
        thickness: 1,
      ),
    );
  }
}
