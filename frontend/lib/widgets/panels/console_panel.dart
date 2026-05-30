import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

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
    return Column(
      children: [
        // Tab Bar and Search
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildTab('Output', 'output'),
                    _buildTab('Issues', 'issues'),
                    _buildTab('Terminal', 'terminal'),
                    _buildTab('Debug', 'debug'),
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
                  style: const TextStyle(fontSize: 10, color: Color(0xFFCCCCCC)),
                  decoration: InputDecoration(
                    hintText: 'Filter output...',
                    hintStyle: const TextStyle(fontSize: 10, color: Color(0xFF858585)),
                    prefixIcon: const Icon(Icons.search, size: 12),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              _buildActionButton(
                icon: Icons.block,
                tooltip: 'Clear Console',
                onPressed: () {
                  Provider.of<AppProvider>(context, listen: false).clearConsole();
                },
              ),
              _buildActionButton(
                icon: _autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_top,
                tooltip: _autoScroll ? 'Auto-scroll: On' : 'Auto-scroll: Off',
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
                color: Theme.of(context).scaffoldBackgroundColor,
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
                            ? const Color(0xFF858585)
                            : displayText.contains('Error')
                                ? const Color(0xFFF48771)
                                : const Color(0xFFCCCCCC),
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
    );
  }

  Widget _buildTab(String label, String id) {
    final isActive = _selectedTab == id;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = id);
      },
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).scaffoldBackgroundColor : Colors.transparent,
          border: Border(
            right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
            bottom: BorderSide(
              color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.white : const Color(0xFF858585),
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
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 14),
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
