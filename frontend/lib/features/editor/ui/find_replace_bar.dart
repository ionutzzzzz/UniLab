import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_icon_button.dart';
import '../../../widgets/ui_text.dart';

class FindReplaceBar extends StatefulWidget {
  const FindReplaceBar({
    super.key,
    required this.onClose,
    this.isReplaceMode = true,
    required this.controller,
  });

  final VoidCallback onClose;
  final bool isReplaceMode;
  final CodeController controller;

  @override
  State<FindReplaceBar> createState() => _FindReplaceBarState();
}

class _FindReplaceBarState extends State<FindReplaceBar> {
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  
  bool _isCaseSensitive = false;
  bool _useRegex = false;
  bool _matchWholeWord = false;
  
  int _currentMatchIndex = -1;
  List<int> _matchPositions = [];

  @override
  void initState() {
    super.initState();
    _findController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _findController.text;
    if (query.isEmpty) {
      setState(() {
        _matchPositions = [];
        _currentMatchIndex = -1;
      });
      return;
    }

    final text = widget.controller.text;
    final List<int> positions = [];
    
    if (_useRegex) {
      try {
        final regex = RegExp(query, caseSensitive: _isCaseSensitive);
        for (final match in regex.allMatches(text)) {
          positions.add(match.start);
        }
      } catch (e) {
        // Invalid regex
      }
    } else {
      String searchText = _isCaseSensitive ? text : text.toLowerCase();
      String findText = _isCaseSensitive ? query : query.toLowerCase();
      
      int start = 0;
      while (true) {
        final index = searchText.indexOf(findText, start);
        if (index == -1) break;
        
        bool isMatch = true;
        if (_matchWholeWord) {
          final isStartWord = index == 0 || !RegExp(r'[a-zA-Z0-9_]').hasMatch(text[index - 1]);
          final isEndWord = index + query.length == text.length || !RegExp(r'[a-zA-Z0-9_]').hasMatch(text[index + query.length]);
          isMatch = isStartWord && isEndWord;
        }
        
        if (isMatch) {
          positions.add(index);
        }
        start = index + query.length;
      }
    }

    setState(() {
      _matchPositions = positions;
      if (positions.isNotEmpty) {
        _currentMatchIndex = 0;
        _jumpToMatch(0);
      } else {
        _currentMatchIndex = -1;
      }
    });
  }

  void _jumpToMatch(int index) {
    if (index < 0 || index >= _matchPositions.length) return;
    final pos = _matchPositions[index];
    widget.controller.selection = TextSelection(
      baseOffset: pos,
      extentOffset: pos + _findController.text.length,
    );
  }

  void _nextMatch() {
    if (_matchPositions.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchPositions.length;
      _jumpToMatch(_currentMatchIndex);
    });
  }

  void _prevMatch() {
    if (_matchPositions.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _matchPositions.length) % _matchPositions.length;
      _jumpToMatch(_currentMatchIndex);
    });
  }

  void _replace() {
    if (_currentMatchIndex == -1) return;
    final pos = _matchPositions[_currentMatchIndex];
    final text = widget.controller.text;
    final newText = text.replaceRange(pos, pos + _findController.text.length, _replaceController.text);
    widget.controller.text = newText;
    _onSearchChanged(); // Refresh matches
  }

  void _replaceAll() {
    if (_matchPositions.isEmpty) return;
    String text = widget.controller.text;
    final query = _findController.text;
    final replacement = _replaceController.text;
    
    if (_useRegex) {
       text = text.replaceAll(RegExp(query, caseSensitive: _isCaseSensitive), replacement);
    } else {
       // Simple replace all can be complex if overlapping or Case insensitive
       // For now keep it simple
       if (_isCaseSensitive && !_matchWholeWord) {
          text = text.replaceAll(query, replacement);
       } else {
          // Manual replace to handle whole word and case sensitivity
          final sortedPositions = List<int>.from(_matchPositions)..sort((a, b) => b.compareTo(a));
          for (final pos in sortedPositions) {
            text = text.replaceRange(pos, pos + query.length, replacement);
          }
       }
    }
    
    widget.controller.text = text;
    _onSearchChanged();
  }

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
              _buildToggleButton(ui, LucideIcons.caseSensitive, _isCaseSensitive, () {
                setState(() => _isCaseSensitive = !_isCaseSensitive);
                _onSearchChanged();
              }, 'Case Sensitive'),
              SizedBox(width: ui.spacing.xxs),
              _buildToggleButton(ui, LucideIcons.regex, _useRegex, () {
                setState(() => _useRegex = !_useRegex);
                _onSearchChanged();
              }, 'Use Regular Expression'),
              SizedBox(width: ui.spacing.xxs),
              _buildToggleButton(ui, LucideIcons.wholeWord, _matchWholeWord, () {
                setState(() => _matchWholeWord = !_matchWholeWord);
                _onSearchChanged();
              }, 'Match Whole Word'),
              SizedBox(width: ui.spacing.md),
              Expanded(
                child: _buildSearchInput(ui, 'Find', _findController),
              ),
              SizedBox(width: ui.spacing.md),
              UiText(
                text: _matchPositions.isEmpty ? '0 of 0' : '${_currentMatchIndex + 1} of ${_matchPositions.length}',
                variant: UiTextVariant.label,
                fontSize: 10,
                color: ui.colors.textMuted,
              ),
              SizedBox(width: ui.spacing.md),
              UiIconButton(
                icon: LucideIcons.chevronUp, 
                tooltip: 'Previous Match', 
                size: 24, 
                iconSize: 14,
                onPressed: _matchPositions.isNotEmpty ? _prevMatch : null,
              ),
              SizedBox(width: ui.spacing.xs),
              UiIconButton(
                icon: LucideIcons.chevronDown, 
                tooltip: 'Next Match', 
                size: 24, 
                iconSize: 14,
                onPressed: _matchPositions.isNotEmpty ? _nextMatch : null,
              ),
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
                  child: _buildSearchInput(ui, 'Replace', _replaceController),
                ),
                SizedBox(width: ui.spacing.md),
                UiIconButton(
                  icon: LucideIcons.replace, 
                  tooltip: 'Replace', 
                  size: 24, 
                  iconSize: 14,
                  onPressed: _currentMatchIndex != -1 ? _replace : null,
                ),
                SizedBox(width: ui.spacing.xs),
                UiIconButton(
                  icon: LucideIcons.replaceAll, 
                  tooltip: 'Replace All', 
                  size: 24, 
                  iconSize: 14,
                  onPressed: _matchPositions.isNotEmpty ? _replaceAll : null,
                ),
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

  Widget _buildSearchInput(UiTheme ui, String hint, TextEditingController controller) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: ui.colors.canvas,
        borderRadius: ui.spacing.radiusSm,
        border: Border.all(color: ui.colors.divider.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: controller,
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
