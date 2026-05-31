import 'package:flutter/material.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_badge.dart';
import 'terminal_view.dart';
import 'problems_view.dart';

class ConsoleDock extends StatefulWidget {
  const ConsoleDock({super.key});

  @override
  State<ConsoleDock> createState() => _ConsoleDockState();
}

class _ConsoleDockState extends State<ConsoleDock> {
  String _activeTab = 'Console';
  final List<String> _tabs = ['Console', 'Problems', 'Terminal', 'Run'];

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);

    Widget activeView;
    switch (_activeTab) {
      case 'Console':
        activeView = const _ConsoleView();
        break;
      case 'Problems':
        activeView = const ProblemsView();
        break;
      case 'Terminal':
        activeView = const AppTerminalView();
        break;
      case 'Run':
        activeView = Center(child: UiText(text: 'Run Output View', color: ui.colors.textMuted));
        break;
      default:
        activeView = const SizedBox.shrink();
    }

    return Container(
      color: ui.colors.panel,
      child: Column(
        children: [
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: ui.colors.panelHeader,
              border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5))),
            ),
            child: Row(
              children: [
                SizedBox(width: ui.spacing.md),
                const UiText(
                  text: 'COMMAND WINDOW',
                  variant: UiTextVariant.label,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontSize: 10,
                ),
                SizedBox(width: ui.spacing.lg),
                Expanded(
                  child: Row(
                    children: _tabs.map((tab) {
                      final isActive = tab == _activeTab;
                      return GestureDetector(
                        onTap: () => setState(() => _activeTab = tab),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: isActive 
                                    ? BorderSide(color: ui.colors.accent, width: 2.0) 
                                    : BorderSide.none,
                              ),
                            ),
                            child: Row(
                              children: [
                                UiText(
                                  text: tab.toUpperCase(),
                                  variant: UiTextVariant.label,
                                  fontSize: 10,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                  color: isActive ? ui.colors.textPrimary : ui.colors.textMuted,
                                  letterSpacing: 0.2,
                                ),
                                if (tab == 'Problems') ...[
                                  SizedBox(width: ui.spacing.xs),
                                  const UiBadge(label: '3', variant: UiBadgeVariant.neutral),
                                ]
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: activeView),
        ],
      ),
    );
  }
}

class _ConsoleView extends StatefulWidget {
  const _ConsoleView();

  @override
  State<_ConsoleView> createState() => _ConsoleViewState();
}

class _ConsoleViewState extends State<_ConsoleView> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _history = [
    'UniLab R2026 loaded. Initializing kernel...',
    '>> disp("Welcome to UniLab")',
    'Welcome to UniLab',
    '>> x = linspace(0, 10, 100);',
    '>> y = sin(x);',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return Column(
      children: [
        // Console History
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(ui.spacing.md),
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final line = _history[index];
              final isCommand = line.startsWith('>>');
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCommand)
                      UiText(
                        text: '>> ',
                        variant: UiTextVariant.consoleBody,
                        fontWeight: FontWeight.bold,
                        color: ui.colors.accent,
                      ),
                    Expanded(
                      child: UiText(
                        text: isCommand ? line.substring(3) : line,
                        variant: UiTextVariant.consoleBody,
                        color: isCommand ? ui.colors.textPrimary : ui.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Input Line
        Container(
          padding: EdgeInsets.symmetric(horizontal: ui.spacing.md, vertical: 8),
          decoration: BoxDecoration(
            color: ui.colors.panelHeader.withValues(alpha: 0.5),
            border: Border(top: BorderSide(color: ui.colors.divider.withValues(alpha: 0.3))),
          ),
          child: Row(
            children: [
              UiText(
                text: '>> ',
                variant: UiTextVariant.consoleBody,
                fontWeight: FontWeight.bold,
                color: ui.colors.accent,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: ui.typography.consoleBody.copyWith(
                    color: ui.colors.textPrimary,
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _history.add('>> $value');
                        _controller.clear();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
