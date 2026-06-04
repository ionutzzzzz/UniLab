import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_badge.dart';
import '../../../models/editor_models.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/settings_provider.dart';
import 'terminal_view.dart';
import 'problems_view.dart';

class ConsoleDock extends StatefulWidget {
  const ConsoleDock({super.key});

  @override
  State<ConsoleDock> createState() => _ConsoleDockState();
}

class _ConsoleDockState extends State<ConsoleDock> {
  String _activeTab = 'Console';
  final List<String> _tabs = ['Console', 'Problems', 'Terminal'];

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);

    Widget activeView;
    switch (_activeTab) {
      case 'Console':
        activeView = const _ConsoleView();
        break;
      case 'Problems':
        activeView = const ProblemsView();
        break;
      case 'Terminal':
        activeView = const AppTerminalView();
        break;
      default:
        activeView = const SizedBox.shrink();
    }

    return Container(
      color: ui.colors.panel,
      child: Column(
        children: [
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: ui.colors.panelHeader,
              border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5), width: ui.spacing.strokeHair)),
            ),
            child: Row(
              children: [
                SizedBox(width: ui.spacing.md),
                const UiText(
                  text: 'COMMAND WINDOW',
                  variant: UiTextVariant.label,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontSize: 10,
                ),
                SizedBox(width: ui.spacing.lg),
                Expanded(
                  child: Row(
                    children: _tabs.map((tab) {
                      final isActive = tab == _activeTab;
                      return GestureDetector(
                        onTap: () => setState(() => _activeTab = tab),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: isActive 
                                    ? BorderSide(color: ui.colors.accent, width: 2.0) 
                                    : BorderSide.none,
                              ),
                            ),
                            child: Row(
                              children: [
                                UiText(
                                  text: tab.toUpperCase(),
                                  variant: UiTextVariant.label,
                                  fontSize: 10,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                  color: isActive ? ui.colors.textPrimary : ui.colors.textMuted,
                                  letterSpacing: 0.2,
                                ),
                                if (tab == 'Problems') ...[
                                  SizedBox(width: ui.spacing.xs),
                                  const UiBadge(label: '3', variant: UiBadgeVariant.neutral),
                                ]
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: activeView),
        ],
      ),
    );
  }
}

class _ConsoleView extends StatefulWidget {
  const _ConsoleView();

  @override
  State<_ConsoleView> createState() => _ConsoleViewState();
}

class _ConsoleViewState extends State<_ConsoleView> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  int _historyIndex = -1;
  String _currentInput = '';
  
  List<String> _suggestions = [];
  int _suggestionIndex = -1;
  int _lastAutocompleteOffset = -1;
  String _originalWord = '';
  int _originalStart = -1;

  @override
  void initState() {
    super.initState();
    _focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.tab) {
          _handleTabKey();
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _handleHistoryNavigation(true);
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _handleHistoryNavigation(false);
          return KeyEventResult.handled;
        }
        
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          final isShiftPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
                                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftRight);
          
          if (!isShiftPressed) {
            _submitCommand();
            return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    };
  }

  void _handleHistoryNavigation(bool up) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final history = appProvider.commandHistory;
    if (history.isEmpty) return;

    if (_historyIndex == -1) {
      _currentInput = _controller.text;
    }

    if (up) {
      if (_historyIndex < history.length - 1) {
        _historyIndex++;
        _controller.text = history[_historyIndex];
        _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      }
    } else {
      if (_historyIndex > -1) {
        _historyIndex--;
        if (_historyIndex == -1) {
          _controller.text = _currentInput;
        } else {
          _controller.text = history[_historyIndex];
        }
        _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      }
    }
  }

  void _submitCommand() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (appProvider.isExecuting) return; 
    
    final value = _controller.text.trim();
    if (value.isNotEmpty) {
      appProvider.runConsoleCommand(value);
      _controller.clear();
      _historyIndex = -1;
      _currentInput = '';
      _resetAutocomplete();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
    _focusNode.requestFocus();
  }

  void _resetAutocomplete() {
    _suggestions = [];
    _suggestionIndex = -1;
    _lastAutocompleteOffset = -1;
    _originalWord = '';
    _originalStart = -1;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleTabKey() async {
    final text = _controller.text;
    final selection = _controller.selection;

    if (!selection.isValid) return;

    final offset = selection.baseOffset;
    
    // Cycle through suggestions if we are still at the same position
    if (_lastAutocompleteOffset != -1 && offset == _lastAutocompleteOffset && _suggestions.length > 1) {
      _suggestionIndex = (_suggestionIndex + 1) % _suggestions.length;
      _applyCompletion(_suggestions[_suggestionIndex], _originalWord, _originalStart, offset);
      return;
    }

    // Find the start of the current "word" (from last separator or start of line)
    // We don't include / or \ as separators to allow path completion
    final separators = [' ', '(', ',', '[', '{', '=', '+', '-', '*', ';', ':', '<', '>', '&', '|', '!'];
    int start = offset;
    while (start > 0 && !separators.contains(text[start - 1])) {
      start--;
    }

    final currentWord = text.substring(start, offset);
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    // Show loading state or similar if needed, but here we just fetch
    final suggestions = await appProvider.getAutocomplete(currentWord, fullLine: text);

    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        if (suggestions.isNotEmpty) {
          _suggestionIndex = 0;
          _originalWord = currentWord;
          _originalStart = start;
          _applyCompletion(_suggestions[_suggestionIndex], currentWord, start, offset);
        } else {
          _resetAutocomplete();
        }
      });
    }
  }

  void _applyCompletion(String completion, String lastWord, int start, int end) {
    final text = _controller.text;
    final newText = text.replaceRange(start, end, completion);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + completion.length,
      ),
    );
    _lastAutocompleteOffset = start + completion.length;
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final appProvider = Provider.of<AppProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final settings = settingsProvider.settings;
    final messages = appProvider.consoleMessages;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight) ||
                                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaLeft) ||
                                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaRight);
          if (isCtrlPressed) {
            final currentSize = settings.fontSize;
            final newSize = (currentSize - (pointerSignal.scrollDelta.dy > 0 ? 1 : -1)).clamp(8.0, 48.0);
            if (newSize != currentSize) {
              settingsProvider.updateSettings(settings.copyWith(fontSize: newSize));
            }
          }
        }
      },
      child: Column(
        children: [
          Expanded(
            child: SelectionArea(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(ui.spacing.md),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isError = msg.type == ConsoleMessageType.error;
                  final isCommand = msg.source == 'System' && msg.type == ConsoleMessageType.output;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isCommand)
                          UiText(
                            text: ' ',
                            variant: UiTextVariant.consoleBody,
                            fontWeight: FontWeight.bold,
                            color: ui.colors.accent,
                            fontSize: settings.fontSize,
                          ),
                        Expanded(
                          child: UiText(
                            text: msg.text,
                            variant: UiTextVariant.consoleBody,
                            color: isError ? ui.colors.danger : (isCommand ? ui.colors.textPrimary : ui.colors.textSecondary),
                            fontSize: settings.fontSize,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (_suggestions.length > 1)
            Container(
              padding: EdgeInsets.symmetric(horizontal: ui.spacing.md, vertical: 4),
              decoration: BoxDecoration(
                color: ui.colors.panel,
                border: Border(top: BorderSide(color: ui.colors.divider.withValues(alpha: 0.2))),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _suggestions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final suggestion = entry.value;
                  final isSelected = idx == _suggestionIndex;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _suggestionIndex = idx;
                          _applyCompletion(suggestion, _originalWord, _originalStart, _lastAutocompleteOffset);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? ui.colors.accent.withValues(alpha: 0.2) : Colors.transparent,
                          border: Border.all(color: isSelected ? ui.colors.accent : ui.colors.divider.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: UiText(
                          text: suggestion,
                          variant: UiTextVariant.label,
                          fontSize: 9,
                          color: isSelected ? ui.colors.accent : ui.colors.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: ui.spacing.md, vertical: 8),
            decoration: BoxDecoration(
              color: ui.colors.panelHeader.withValues(alpha: 0.5),
              border: Border(top: BorderSide(color: ui.colors.divider.withValues(alpha: 0.3), width: ui.spacing.strokeHair)),
            ),
            child: Row(
              children: [
                UiText(
                  text: '>> ',
                  variant: UiTextVariant.consoleBody,
                  fontWeight: FontWeight.bold,
                  color: ui.colors.accent,
                  fontSize: settings.fontSize,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    enabled: true,
                    maxLines: null,
                    minLines: 1,
                    style: ui.typography.consoleBody.copyWith(
                      color: appProvider.isExecuting ? ui.colors.textDisabled : ui.colors.textPrimary,
                      fontSize: settings.fontSize,
                      fontFamily: settings.fontFamily,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      hintText: appProvider.isExecuting ? 'Waiting for execution to finish...' : null,
                      hintStyle: TextStyle(color: ui.colors.textDisabled),
                    ),
                    onChanged: (value) {
                      _resetAutocomplete();
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}