import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_icon.dart';
import '../../../widgets/ui_text.dart';
import '../../../providers/settings_provider.dart';

class RibbonButton extends StatefulWidget {
  const RibbonButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.isPrimary = false,
    this.isLarge = false,
    this.color,
    this.hasDropdown = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isLarge;
  final Color? color;
  final bool hasDropdown;

  @override
  State<RibbonButton> createState() => _RibbonButtonState();
}

class _RibbonButtonState extends State<RibbonButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final settings = context.watch<SettingsProvider>().settings;
    final isEnabled = widget.onTap != null;
    final animDuration = settings.animationEnabled ? const Duration(milliseconds: 150) : Duration.zero;

    Color bgColor = Colors.transparent;
    // Normal state: use custom color for icon/text if provided, else default text primary color
    // Replaced textSecondary with textPrimary to ensure it matches the 'FILE' button and active states.
    Color fgColor = isEnabled ? (widget.color ?? ui.colors.textPrimary) : ui.colors.textDisabled;

    if (_isHovered && isEnabled) {
      // On hover, all buttons uniformly use the global accent color for background
      // and inverse color for foreground for maximum legibility.
      bgColor = ui.colors.accent;
      fgColor = ui.colors.textInverse;
    }

    // All buttons now have the same professional height for consistency
    final double minWidth = widget.isLarge ? 56 : 48;
    const double height = 68;

    return IntrinsicWidth(
      child: Container(
        constraints: BoxConstraints(
          minWidth: minWidth,
          minHeight: height,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 1.0),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _isHovered && isEnabled ? 1.02 : 1.0,
              duration: animDuration,
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: animDuration,
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(
                  horizontal: ui.spacing.sm, // Increased padding to ensure text doesn't overlap
                  vertical: ui.spacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: ui.spacing.radiusMd, // 6px-8px for desktop polish
                  border: Border.all(
                    color: _isHovered && isEnabled
                      ? ui.colors.border.withValues(alpha: 0.3)
                      : Colors.transparent,
                    width: 1.0,
                  ),
                  boxShadow: _isHovered && isEnabled ? ui.colors.shadowSm : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: animDuration,
                      transform: Matrix4.identity()..translate(0.0, _isHovered ? -1.0 : 0.0),
                      child: UiIcon(
                        widget.icon,
                        size: widget.isLarge ? 24 : 18, // Slightly smaller icon for standard buttons
                        color: fgColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: UiText(
                              text: widget.label,
                              variant: UiTextVariant.label,
                              fontSize: 10,
                              fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                              color: fgColor,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                          if (widget.hasDropdown)
                            Icon(Icons.keyboard_arrow_down, size: 12, color: fgColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}