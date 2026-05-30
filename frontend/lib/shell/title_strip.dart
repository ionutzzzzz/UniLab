import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/ui_theme.dart';
import '../widgets/ui_text.dart';

class TitleStrip extends StatelessWidget {
  const TitleStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: ui.colors.panelHeader,
        border: Border(bottom: BorderSide(color: ui.colors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Row(
                children: [
                  SizedBox(width: ui.spacing.md),
                  UiText(
                    text: '◐ UniLab · workspace-name.unilab',
                    variant: UiTextVariant.label,
                    color: ui.colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const WindowButtons(),
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
          icon: Icons.minimize,
          onTap: () => windowManager.minimize(),
          hoverColor: ui.colors.hover,
        ),
        _WindowButton(
          icon: Icons.crop_square,
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
          icon: Icons.close,
          onTap: () => windowManager.close(),
          hoverColor: ui.colors.danger,
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
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color hoverColor;

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
        child: Container(
          width: 40,
          height: double.infinity,
          color: _isHovered ? widget.hoverColor : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 14,
            color: _isHovered ? ui.colors.textInverse : ui.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
