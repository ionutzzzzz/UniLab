import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/ui_theme.dart';
import '../ui_glass_container.dart';

class FindReplaceBar extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String query)? onFind;
  final Function(String query, String replacement)? onReplace;
  final Function(String query, String replacement)? onReplaceAll;

  const FindReplaceBar({
    super.key,
    required this.onClose,
    this.onFind,
    this.onReplace,
    this.onReplaceAll,
  });

  @override
  State<FindReplaceBar> createState() => _FindReplaceBarState();
}

class _FindReplaceBarState extends State<FindReplaceBar> {
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final FocusNode _findFocus = FocusNode();
  
  bool _isReplaceExpanded = false;
  bool _matchCase = false;
  bool _regex = false;
  bool _wholeWord = false;

  @override
  void initState() {
    super.initState();
    _findFocus.requestFocus();
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    _findFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: UiGlassContainer(
        width: 420,
        height: _isReplaceExpanded ? 110 : 60,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: ui.spacing.radiusMd,
        blur: 15,
        opacity: 0.8,
        child: Column(
          children: [
            // Find Row
            Row(
              children: [
                _buildExpandToggle(ui),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInput(
                    controller: _findController,
                    focusNode: _findFocus,
                    hint: 'Find',
                    ui: ui,
                    onSubmitted: (val) => widget.onFind?.call(val),
                  ),
                ),
                const SizedBox(width: 8),
                _buildMatchOptions(ui),
                const SizedBox(width: 8),
                _buildActionIcon(LucideIcons.chevronUp, ui, 'Previous'),
                _buildActionIcon(LucideIcons.chevronDown, ui, 'Next'),
                _buildActionIcon(LucideIcons.x, ui, 'Close', onTap: widget.onClose),
              ],
            ),
            
            // Replace Row
            if (_isReplaceExpanded) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 24), // Offset for expand toggle
                  Expanded(
                    child: _buildInput(
                      controller: _replaceController,
                      hint: 'Replace',
                      ui: ui,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionIcon(
                    LucideIcons.replace, 
                    ui, 
                    'Replace',
                    onTap: () => widget.onReplace?.call(_findController.text, _replaceController.text),
                  ),
                  _buildActionIcon(
                    LucideIcons.replaceAll, 
                    ui, 
                    'Replace All',
                    onTap: () => widget.onReplaceAll?.call(_findController.text, _replaceController.text),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandToggle(UiTheme ui) {
    return GestureDetector(
      onTap: () => setState(() => _isReplaceExpanded = !_isReplaceExpanded),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Icon(
          _isReplaceExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
          size: 16,
          color: ui.colors.textMuted,
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required UiTheme ui,
    FocusNode? focusNode,
    Function(String)? onSubmitted,
  }) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: ui.colors.canvas.withValues(alpha: 0.5),
        border: Border.all(color: ui.colors.border, width: ui.spacing.strokeHair),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        cursorColor: ui.colors.accent,
        style: ui.typography.body.copyWith(fontSize: 12, color: ui.colors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: ui.typography.body.copyWith(fontSize: 12, color: ui.colors.textDisabled),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }

  Widget _buildMatchOptions(UiTheme ui) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOptionToggle('Aa', 'Match Case', _matchCase, ui, (v) => setState(() => _matchCase = v)),
        _buildOptionToggle('W', 'Whole Word', _wholeWord, ui, (v) => setState(() => _wholeWord = v)),
        _buildOptionToggle('.*', 'Regex', _regex, ui, (v) => setState(() => _regex = v)),
      ],
    );
  }

  Widget _buildOptionToggle(String label, String tooltip, bool active, UiTheme ui, Function(bool) onToggle) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => onToggle(!active),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? ui.colors.accent.withValues(alpha: 0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
              border: active ? Border.all(color: ui.colors.accent.withValues(alpha: 0.5), width: 0.5) : null,
            ),
            child: Text(
              label,
              style: ui.typography.label.copyWith(
                fontSize: 9,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? ui.colors.accent : ui.colors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, UiTheme ui, String tooltip, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(icon, size: 14, color: ui.colors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}
