import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:xterm/xterm.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../state/terminal_providers.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_icon_button.dart';
import '../../../providers/settings_provider.dart';

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
    final settings = p.Provider.of<SettingsProvider>(context).settings;

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
        // Terminal Tab Bar / Toolbar
        Container(
          height: 34,
          decoration: BoxDecoration(
            color: ui.colors.panelHeader,
            border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5), width: ui.spacing.strokeHair)),
          ),
          child: Row(
            children: [
              if (sessions.length > 1)
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
                )
              else
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
                  child: UiText(
                    text: 'TERMINAL',
                    variant: UiTextVariant.label,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              
              const Spacer(),
              
              UiIconButton(
                icon: LucideIcons.plus,
                tooltip: 'New Terminal',
                size: 28,
                iconSize: 14,
                onPressed: () => ref.read(terminalSessionsProvider.notifier).addSession(),
              ),
              UiIconButton(
                icon: LucideIcons.eraser,
                tooltip: 'Clear Terminal',
                size: 28,
                iconSize: 14,
                onPressed: () {
                  // ANSI sequence to clear screen and home cursor
                  activeSession.terminal.write('\x1b[2J\x1b[H');
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        
        // Terminal Content
        Expanded(
          child: Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                final isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                                      HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight) ||
                                      HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaLeft) ||
                                      HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaRight);
                if (isCtrlPressed) {
                  final provider = p.Provider.of<SettingsProvider>(context, listen: false);
                  final currentSize = provider.settings.fontSize;
                  // scrollDelta.dy > 0 means scroll down (zoom out), < 0 means scroll up (zoom in)
                  final newSize = (currentSize - (pointerSignal.scrollDelta.dy > 0 ? 1 : -1)).clamp(8.0, 48.0);
                  if (newSize != currentSize) {
                    provider.updateSettings(provider.settings.copyWith(fontSize: newSize));
                  }
                }
              }
            },
            child: Container(
              color: ui.colors.canvas,
              padding: const EdgeInsets.only(left: 8),
              child: TerminalViewWidget(
                activeSession.terminal,
                textStyle: TerminalStyle(
                  fontFamily: settings.fontFamily,
                  fontSize: settings.fontSize,
                ),
                theme: TerminalTheme(
                  cursor: ui.colors.accent,
                  selection: ui.colors.selected,
                  foreground: ui.colors.textPrimary,
                  background: ui.colors.canvas,
                  black: const Color(0XFF1E2127),
                  red: ui.colors.danger,
                  green: ui.colors.success,
                  yellow: ui.colors.yellow,
                  blue: ui.colors.accent,
                  magenta: const Color(0XFFC4B5FD),
                  cyan: const Color(0XFF29B8DB),
                  white: const Color(0XFFE5E7EB),
                  brightBlack: const Color(0XFF6B7280),
                  brightRed: ui.colors.danger,
                  brightGreen: ui.colors.success,
                  brightYellow: ui.colors.yellow,
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
        ),
      ],
    );
  }
}

// Wrapper for xterm TerminalView to handle focus and scrolling
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
      backgroundOpacity: 0,
      padding: const EdgeInsets.all(4),
    );
  }
}
