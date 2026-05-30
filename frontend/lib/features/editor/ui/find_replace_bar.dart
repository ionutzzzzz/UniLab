import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_icon_button.dart';
import '../../../widgets/ui_text.dart';

class FindReplaceBar extends StatefulWidget {
  const FindReplaceBar({
    super.key,
    required this.onClose,
    this.isReplaceMode = true, // Default to true for development
  });

  final VoidCallback onClose;
  final bool isReplaceMode;

  @override
  State<FindReplaceBar> createState() => _FindReplaceBarState();
}

class _FindReplaceBarState extends State<FindReplaceBar> {
  bool _isCaseSensitive = false;
  bool _useRegex = false;
  bool _matchWholeWord = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);

    return Container(
      margin: EdgeInsets.all(ui.spacing.sm),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ui.colors.panel,
        borderRadius: ui.spacing.radiusMd,
        border: Border.all(color: ui.colors.divider.withValues(alpha: 0.5)),
        boxShadow: ui.colors.shadowMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildToggleButton(ui, LucideIcons.caseSensitive, _isCaseSensitive, () => setState(() => _isCaseSensitive = !_isCaseSensitive), 'Case Sensitive'),
              SizedBox(width: ui.spacing.xxs),
              _buildToggleButton(ui, LucideIcons.regex, _useRegex, () => setState(() => _useRegex = !_useRegex), 'Use Regular Expression'),
              SizedBox(width: ui.spacing.xxs),
              _buildToggleButton(ui, LucideIcons.wholeWord, _matchWholeWord, () => setState(() => _matchWholeWord = !_matchWholeWord), 'Match Whole Word'),
              SizedBox(width: ui.spacing.md),
              Expanded(
                child: _buildSearchInput(ui, 'Find'),
              ),
              SizedBox(width: ui.spacing.md),
              UiText(
                text: '0 of 0',
                variant: UiTextVariant.label,
                fontSize: 10,
                color: ui.colors.textMuted,
              ),
              SizedBox(width: ui.spacing.md),
              UiIconButton(icon: LucideIcons.chevronUp, tooltip: 'Previous Match', size: 24, iconSize: 14),
              SizedBox(width: ui.spacing.xs),
              UiIconButton(icon: LucideIcons.chevronDown, tooltip: 'Next Match', size: 24, iconSize: 14),
              SizedBox(width: ui.spacing.md),
              UiIconButton(icon: LucideIcons.x, tooltip: 'Close', size: 24, iconSize: 14, onPressed: widget.onClose),
            ],
          ),
          if (widget.isReplaceMode) ...[
            SizedBox(height: ui.spacing.xs),
            Row(
              children: [
                const SizedBox(width: 90), // Offset for buttons above
                Expanded(
                  child: _buildSearchInput(ui, 'Replace'),
                ),
                SizedBox(width: ui.spacing.md),
                UiIconButton(icon: LucideIcons.replace, tooltip: 'Replace', size: 24, iconSize: 14),
                SizedBox(width: ui.spacing.xs),
                UiIconButton(icon: LucideIcons.replaceAll, tooltip: 'Replace All', size: 24, iconSize: 14),
                const SizedBox(width: 72), // Offset for navigation buttons
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleButton(UiTheme ui, IconData icon, bool isActive, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? ui.colors.accent.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: ui.spacing.radiusSm,
            border: Border.all(color: isActive ? ui.colors.accent.withValues(alpha: 0.5) : Colors.transparent),
          ),
          child: Icon(icon, size: 16, color: isActive ? ui.colors.accent : ui.colors.textMuted),
        ),
      ),
    );
  }

  Widget _buildSearchInput(UiTheme ui, String hint) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: ui.colors.canvas,
        borderRadius: ui.spacing.radiusSm,
        border: Border.all(color: ui.colors.divider.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        style: ui.typography.body.copyWith(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: ui.typography.body.copyWith(fontSize: 12, color: ui.colors.textMuted),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
