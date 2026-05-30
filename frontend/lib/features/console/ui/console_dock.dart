import 'package:flutter/material.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_badge.dart';
import 'terminal_view.dart';

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
        activeView = Center(child: UiText(text: 'Problems View', color: ui.colors.textMuted));
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
            height: 30,
            color: ui.colors.panelHeader,
            child: Row(
              children: _tabs.map((tab) {
                final isActive = tab == _activeTab;
                return GestureDetector(
                  onTap: () => setState(() => _activeTab = tab),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
                    decoration: BoxDecoration(
                      color: isActive ? ui.colors.panel : Colors.transparent,
                      border: Border(
                        right: BorderSide(color: ui.colors.divider),
                        top: isActive 
                            ? BorderSide(color: ui.colors.accent, width: 2.0) 
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      children: [
                        UiText(
                          text: tab.toUpperCase(),
                          variant: UiTextVariant.label,
                          color: isActive ? ui.colors.textPrimary : ui.colors.textSecondary,
                        ),
                        if (tab == 'Problems') ...[
                          SizedBox(width: ui.spacing.xs),
                          const UiBadge(label: '0', variant: UiBadgeVariant.neutral),
                        ]
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(child: activeView),
        ],
      ),
    );
  }
}

class _ConsoleView extends StatelessWidget {
  const _ConsoleView();

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return Container(
      padding: EdgeInsets.all(ui.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiText(text: '>> Ready', variant: UiTextVariant.consoleBody, color: ui.colors.textSecondary),
        ],
      ),
    );
  }
}
