import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../state/terminal_providers.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_icon_button.dart';

class AppTerminalView extends ConsumerStatefulWidget {
  const AppTerminalView({super.key});

  @override
  ConsumerState<AppTerminalView> createState() => _AppTerminalViewState();
}

class _AppTerminalViewState extends ConsumerState<AppTerminalView> {
  @override
  void initState() {
    super.initState();
    // Initialize a terminal session if none exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(terminalSessionsProvider).isEmpty) {
        ref.read(terminalSessionsProvider.notifier).addSession();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final sessions = ref.watch(terminalSessionsProvider);
    final activeId = ref.watch(activeTerminalSessionIdProvider);

    if (sessions.isEmpty) {
      return Center(
        child: UiText(
          text: 'No active terminal sessions.',
          color: ui.colors.textMuted,
        ),
      );
    }

    final activeSession = sessions.firstWhere((s) => s.id == activeId, orElse: () => sessions.first);

    return Column(
      children: [
        // Terminal Tab Bar (if multiple sessions)
        if (sessions.length > 1)
          Container(
            height: 28,
            color: ui.colors.panelHeader,
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final isActive = session.id == activeId;
                      return GestureDetector(
                        onTap: () => ref.read(activeTerminalSessionIdProvider.notifier).state = session.id,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
                          decoration: BoxDecoration(
                            color: isActive ? ui.colors.panel : Colors.transparent,
                            border: Border(
                              right: BorderSide(color: ui.colors.divider),
                              bottom: BorderSide(
                                color: isActive ? ui.colors.accent : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              UiText(
                                text: session.name,
                                variant: UiTextVariant.label,
                                color: isActive ? ui.colors.textPrimary : ui.colors.textSecondary,
                              ),
                              SizedBox(width: ui.spacing.sm),
                              UiIconButton(
                                icon: LucideIcons.x,
                                tooltip: 'Close Terminal',
                                size: 20,
                                iconSize: 12,
                                onPressed: () => ref.read(terminalSessionsProvider.notifier).removeSession(session.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        
        // Terminal Content
        Expanded(
          child: Container(
            color: ui.colors.canvas, // Terminal background
            padding: EdgeInsets.all(ui.spacing.sm),
            child: TerminalViewWidget(
              activeSession.terminal,
              textStyle: TerminalStyle(
                fontFamily: ui.typography.codeBody.fontFamily!,
                fontSize: ui.typography.codeBody.fontSize!,
              ),
              theme: TerminalTheme(
                cursor: ui.colors.accent,
                selection: ui.colors.selected,
                foreground: ui.colors.textPrimary,
                background: ui.colors.canvas,
                black: const Color(0XFF1E2127),
                red: const Color(0XFFF14C4C),
                green: const Color(0XFF23D18B),
                yellow: const Color(0XFFE5E510),
                blue: const Color(0XFF4AA3FF),
                magenta: const Color(0XFFC4B5FD),
                cyan: const Color(0XFF29B8DB),
                white: const Color(0XFFE5E7EB),
                brightBlack: const Color(0XFF6B7280),
                brightRed: const Color(0XFFF14C4C),
                brightGreen: const Color(0XFF23D18B),
                brightYellow: const Color(0XFFF5F543),
                brightBlue: const Color(0XFF6BB1FF),
                brightMagenta: const Color(0XFFD670D6),
                brightCyan: const Color(0XFF29B8DB),
                brightWhite: const Color(0XFFFFFFFF),
                searchHitBackground: const Color(0XFFFFFF2B),
                searchHitBackgroundCurrent: const Color(0XFF31FF26),
                searchHitForeground: const Color(0XFF000000),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Wrapper for xterm TerminalView to handle focus automatically
class TerminalViewWidget extends StatefulWidget {
  final Terminal terminal;
  final TerminalStyle textStyle;
  final TerminalTheme theme;

  const TerminalViewWidget(this.terminal, {
    super.key,
    required this.textStyle,
    required this.theme,
  });

  @override
  State<TerminalViewWidget> createState() => _TerminalViewWidgetState();
}

class _TerminalViewWidgetState extends State<TerminalViewWidget> {
  final TerminalController _terminalController = TerminalController();

  @override
  Widget build(BuildContext context) {
    return TerminalView(
      widget.terminal,
      controller: _terminalController,
      textStyle: widget.textStyle,
      theme: widget.theme,
      autofocus: true,
    );
  }
}
