import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/ui_theme.dart';
import '../widgets/ui_text.dart';

class TitleStrip extends StatelessWidget {
  const TitleStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);

    Widget content = Row(
      children: [
        SizedBox(width: ui.spacing.md),
        // MATLAB-inspired Brand Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ui.colors.canvas.withValues(alpha: 0.8),
                ui.colors.canvas,
              ],
            ),
            borderRadius: BorderRadius.circular(
              8,
            ), // Slightly more square for professional look
            border: Border.all(color: ui.colors.border.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: 0,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.beaker, size: 14, color: ui.colors.accent),
              const SizedBox(width: 8),
              const UiText(
                text: 'UniLab',
                variant: UiTextVariant.label,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: null, // Uses default textPrimary from theme
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 10, color: ui.colors.divider),
              const SizedBox(width: 8),
              UiText(
                text: 'v1.2.2',
                variant: UiTextVariant.label,
                color: ui.colors.accent,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ],
          ),
        ),
        SizedBox(width: ui.spacing.lg),
        // File / Workspace Indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.terminal, size: 12, color: ui.colors.textSecondary),
            const SizedBox(width: 8),
            UiText(
              text: 'unilab_workspaces/default',
              variant: UiTextVariant.label,
              color: ui.colors.textSecondary,
              letterSpacing: 0.1,
            ),
          ],
        ),
      ],
    );

    return Container(
      height: 40, // Slightly taller
      decoration: BoxDecoration(
        color: ui.colors.panelHeader,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withValues(alpha: 0.4),
            width: ui.spacing.strokeHair,
          ),
        ),
        boxShadow: [
          // Inner top highlight
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.03),
            offset: const Offset(0, 1),
            blurRadius: 0,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ui.colors.panelHeader.withValues(alpha: 0.9),
            ui.colors.panelHeader,
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(child: kIsWeb ? content : DragToMoveArea(child: content)),
          if (!kIsWeb) const WindowButtons(),
        ],
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          icon: LucideIcons.minus,
          onTap: () => windowManager.minimize(),
          hoverColor: ui.colors.hover,
        ),
        _WindowButton(
          icon: LucideIcons.square,
          onTap: () async {
            if (await windowManager.isMaximized()) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
          hoverColor: ui.colors.hover,
        ),
        _WindowButton(
          icon: LucideIcons.x,
          onTap: () => windowManager.close(),
          hoverColor: ui.colors.danger.withValues(alpha: 0.8),
          isClose: true,
        ),
      ],
    );
  }
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.icon,
    required this.onTap,
    required this.hoverColor,
    this.isClose = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color hoverColor;
  final bool isClose;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 46,
          height: double.infinity,
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverColor : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _isHovered
                ? (widget.isClose ? Colors.white : ui.colors.textPrimary)
                : ui.colors.textMuted,
          ),
        ),
      ),
    );
  }
}
