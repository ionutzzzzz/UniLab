import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Find and Replace dialog
class FindReplaceDialog extends StatefulWidget {
  final String initialText;
  final Function(String, String, {bool? matchCase, bool? wholeWord})
      onReplace;
  final Function(String, int)? onFind; // Search string and occurrence number
  final VoidCallback onClose;

  const FindReplaceDialog({
    super.key,
    required this.initialText,
    required this.onReplace,
    this.onFind,
    required this.onClose,
  });

  @override
  State<FindReplaceDialog> createState() => _FindReplaceDialogState();
}

class _FindReplaceDialogState extends State<FindReplaceDialog> {
  late TextEditingController _findController;
  late TextEditingController _replaceController;
  late FocusNode _findFocus;
  late FocusNode _replaceFocus;
  bool _showReplace = false;
  bool _matchCase = false;
  bool _wholeWord = false;
  int _matchCount = 0;

  @override
  void initState() {
    super.initState();
    _findController = TextEditingController(text: widget.initialText);
    _replaceController = TextEditingController();
    _findFocus = FocusNode();
    _replaceFocus = FocusNode();
    _findFocus.requestFocus();

    _findController.addListener(_updateMatchCount);
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    _findFocus.dispose();
    _replaceFocus.dispose();
    super.dispose();
  }

  void _updateMatchCount() {
    // This would be implemented to count actual matches in the editor
    final text = _findController.text;
    if (text.isEmpty) {
      setState(() {
        _matchCount = 0;
      });
      return;
    }
    // Placeholder: actual implementation would search the editor content
    widget.onFind?.call(text, _matchCount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkPanelBackground,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Find row
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    _showReplace ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                  ),
                  onPressed: () {
                    setState(() {
                      _showReplace = !_showReplace;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _findController,
                  focusNode: _findFocus,
                  decoration: InputDecoration(
                    hintText: 'Find',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkTextSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.zero,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    suffixText: _matchCount > 0
                        ? '$_matchCount found'
                        : _findController.text.isNotEmpty
                            ? 'No match'
                            : '',
                    suffixStyle: TextStyle(
                      fontSize: 11,
                      color: _matchCount > 0
                          ? AppTheme.darkAccentColor
                          : Colors.red,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Navigation buttons
              _IconButton(
                icon: Icons.arrow_upward,
                tooltip: 'Previous (Shift+Enter)',
                onPressed: () {},
              ),
              const SizedBox(width: 4),
              _IconButton(
                icon: Icons.arrow_downward,
                tooltip: 'Next (Enter)',
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              // Options
              _ToggleButton(
                label: 'Aa',
                tooltip: 'Match Case',
                isSelected: _matchCase,
                onChanged: (value) {
                  setState(() {
                    _matchCase = value;
                  });
                },
              ),
              const SizedBox(width: 4),
              _ToggleButton(
                label: 'Ab',
                tooltip: 'Match Whole Word',
                isSelected: _wholeWord,
                onChanged: (value) {
                  setState(() {
                    _wholeWord = value;
                  });
                },
              ),
              const SizedBox(width: 8),
              _IconButton(
                icon: Icons.close,
                tooltip: 'Close (Escape)',
                onPressed: widget.onClose,
              ),
            ],
          ),

          // Replace row
          if (_showReplace)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const SizedBox(width: 32), // Align with find row
                  Expanded(
                    child: TextField(
                      controller: _replaceController,
                      focusNode: _replaceFocus,
                      decoration: InputDecoration(
                        hintText: 'Replace',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.darkTextSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.zero,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.darkTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _IconButton(
                    icon: Icons.swap_horiz,
                    tooltip: 'Replace (Ctrl+Shift+1)',
                    onPressed: () {
                      widget.onReplace(
                        _findController.text,
                        _replaceController.text,
                        matchCase: _matchCase,
                        wholeWord: _wholeWord,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  _IconButton(
                    icon: Icons.swap_vert,
                    tooltip: 'Replace All (Ctrl+Alt+Enter)',
                    onPressed: () {
                      widget.onReplace(
                        _findController.text,
                        _replaceController.text,
                        matchCase: _matchCase,
                        wholeWord: _wholeWord,
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Simple icon button for find bar
class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            hoverColor: AppTheme.darkHoverColor,
            child: Icon(
              icon,
              size: 14,
              color: AppTheme.darkTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Toggle button for find options
class _ToggleButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool isSelected;
  final Function(bool) onChanged;

  const _ToggleButton({
    required this.label,
    required this.tooltip,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!isSelected),
          hoverColor: AppTheme.darkHoverColor,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? AppTheme.darkAccentColor
                    : Theme.of(context).dividerColor,
                width: 1.0,
              ),
              color:
                  isSelected ? AppTheme.darkAccentColor.withOpacity(0.2) : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? AppTheme.darkAccentColor : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
