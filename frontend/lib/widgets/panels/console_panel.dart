import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/ui_theme.dart';
import '../../theme/ui_decorations.dart';

class ConsolePanel extends StatefulWidget {
  const ConsolePanel({super.key});

  @override
  State<ConsolePanel> createState() => _ConsolePanelState();
}

class _ConsolePanelState extends State<ConsolePanel> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _filterController = TextEditingController();
  bool _autoScroll = true;
  String _selectedTab = 'output';

  @override
  void dispose() {
    _scrollController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);

    return Container(
      decoration: ShellDecorations.panelDecoration(ui),
      margin: const EdgeInsets.all(2.0),
      child: Column(
        children: [
          // Tab Bar and Search
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: ui.colors.panelHeader,
              border: Border(
                bottom: BorderSide(
                  color: ui.colors.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildTab('Output', 'output', ui),
                      _buildTab('Issues', 'issues', ui),
                      _buildTab('Terminal', 'terminal', ui),
                      _buildTab('Debug', 'debug', ui),
                    ],
                  ),
                ),
                // Compact Search Bar
                Container(
                  width: 200,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _filterController,
                    style: TextStyle(fontSize: 10, color: ui.colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Filter output...',
                      hintStyle: TextStyle(fontSize: 10, color: ui.colors.textMuted),
                      prefixIcon: Icon(Icons.search, size: 12, color: ui.colors.icon),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(2),
                        borderSide: BorderSide(color: ui.colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(2),
                        borderSide: BorderSide(color: ui.colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(2),
                        borderSide: BorderSide(color: ui.colors.accent),
                      ),
                      filled: true,
                      fillColor: ui.colors.canvas,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                _buildActionButton(
                  icon: Icons.block,
                  tooltip: 'Clear Console',
                  ui: ui,
                  onPressed: () {
                    Provider.of<AppProvider>(context, listen: false).clearConsole();
                  },
                ),
                _buildActionButton(
                  icon: _autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_top,
                  tooltip: _autoScroll ? 'Auto-scroll: On' : 'Auto-scroll: Off',
                  ui: ui,
                  onPressed: () {
                    setState(() => _autoScroll = !_autoScroll);
                    if (_autoScroll) _scrollToBottom();
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          // Console Output
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, appProvider, _) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                String displayText = appProvider.consoleOutput;
                if (_filterController.text.isNotEmpty) {
                  final lines = displayText.split('\n');
                  final filtered = lines
                      .where((line) =>
                          line.toLowerCase().contains(_filterController.text.toLowerCase()))
                      .toList();
                  displayText = filtered.join('\n');
                }

                return Container(
                  color: ui.colors.canvas,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ListView(
                    controller: _scrollController,
                    primary: false,
                    children: [
                      SelectableText(
                        displayText.isEmpty ? '>> Ready' : displayText,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          color: displayText.isEmpty
                              ? ui.colors.textMuted
                              : displayText.contains('Error')
                                  ? ui.colors.danger
                                  : ui.colors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, String id, UiTheme ui) {
    final isActive = _selectedTab == id;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? ui.colors.canvas : Colors.transparent,
          border: Border(
            right: BorderSide(color: ui.colors.border, width: 1),
            top: BorderSide(
              color: isActive ? ui.colors.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          label,
          style: ui.typography.label.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? ui.colors.textInverse : ui.colors.textMuted,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required UiTheme ui,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 14, color: ui.colors.icon),
        onPressed: onPressed,
        iconSize: 14,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),
      ),
    );
  }
}
