import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../providers/settings_provider.dart';

class ProblemsView extends StatelessWidget {
  const ProblemsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final settings = settingsProvider.settings;
    
    // Mock problems for UI development
    final mockProblems = [
      _Problem(
        type: _ProblemType.error,
        message: "Undefined function or variable 'alpha'.",
        file: "main.m",
        line: 12,
        column: 5,
      ),
      _Problem(
        type: _ProblemType.warning,
        message: "The variable 'x' is assigned a value but never used.",
        file: "utils.m",
        line: 45,
        column: 1,
      ),
      _Problem(
        type: _ProblemType.info,
        message: "Consider using 'vec' instead of 'array' for performance.",
        file: "main.m",
        line: 8,
        column: 12,
      ),
    ];

    if (mockProblems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.checkCircle2, size: 40, color: ui.colors.success.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            UiText(
              text: 'No problems detected in your workspace.',
              variant: UiTextVariant.body,
              color: ui.colors.textMuted,
            ),
          ],
        ),
      );
    }

    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight) ||
                                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaLeft) ||
                                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaRight);
          if (isCtrlPressed) {
            final currentSize = settings.fontSize;
            // scrollDelta.dy > 0 means scroll down (zoom out), < 0 means scroll up (zoom in)
            final newSize = (currentSize - (pointerSignal.scrollDelta.dy > 0 ? 1 : -1)).clamp(8.0, 48.0);
            if (newSize != currentSize) {
              settingsProvider.updateSettings(settings.copyWith(fontSize: newSize));
            }
          }
        }
      },
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: EdgeInsets.symmetric(horizontal: ui.spacing.md, vertical: 4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.3))),
            ),
            child: Row(
              children: [
                UiText(
                  text: '${mockProblems.length} Problems',
                  variant: UiTextVariant.label,
                  fontWeight: FontWeight.bold,
                ),
                const Spacer(),
                _FilterPill(label: 'Errors', count: 1, color: ui.colors.danger),
                const SizedBox(width: 8),
                _FilterPill(label: 'Warnings', count: 1, color: ui.colors.warning),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: mockProblems.length,
              itemBuilder: (context, index) {
                return _ProblemRow(problem: mockProblems[index], fontSize: settings.fontSize);
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _ProblemType { error, warning, info }

class _Problem {
  final _ProblemType type;
  final String message;
  final String file;
  final int line;
  final int column;

  _Problem({
    required this.type,
    required this.message,
    required this.file,
    required this.line,
    required this.column,
  });
}

class _ProblemRow extends StatefulWidget {
  const _ProblemRow({required this.problem, required this.fontSize});
  final _Problem problem;
  final double fontSize;

  @override
  State<_ProblemRow> createState() => _ProblemRowState();
}

class _ProblemRowState extends State<_ProblemRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    IconData icon;
    Color color;
    switch (widget.problem.type) {
      case _ProblemType.error:
        icon = LucideIcons.xCircle;
        color = ui.colors.danger;
        break;
      case _ProblemType.warning:
        icon = LucideIcons.alertTriangle;
        color = ui.colors.warning;
        break;
      case _ProblemType.info:
        icon = LucideIcons.info;
        color = ui.colors.info;
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: ui.spacing.md, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? ui.colors.hover.withValues(alpha: 0.5) : Colors.transparent,
            border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.1))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiText(
                      text: widget.problem.message,
                      variant: UiTextVariant.body,
                      fontSize: widget.fontSize,
                      color: ui.colors.textPrimary,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        UiText(
                          text: widget.problem.file,
                          variant: UiTextVariant.label,
                          fontSize: widget.fontSize - 1,
                          color: ui.colors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        UiText(
                          text: '${widget.problem.line}:${widget.problem.column}',
                          variant: UiTextVariant.label,
                          fontSize: widget.fontSize - 1,
                          color: ui.colors.textMuted.withValues(alpha: 0.7),
                          fontFamily: 'JetBrains Mono',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UiText(text: label, variant: UiTextVariant.label, fontSize: 9, color: color, fontWeight: FontWeight.bold),
          const SizedBox(width: 4),
          UiText(text: count.toString(), variant: UiTextVariant.label, fontSize: 9, color: color),
        ],
      ),
    );
  }
}
