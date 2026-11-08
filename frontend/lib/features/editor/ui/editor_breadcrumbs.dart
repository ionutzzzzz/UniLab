import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/riverpod_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EditorBreadcrumbs extends StatelessWidget {
  const EditorBreadcrumbs({
    super.key,
    required this.pathSegments,
  });

  final List<String> pathSegments;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    // Filter out empty segments and handle root/empty paths
    final segments = pathSegments.where((s) => s.isNotEmpty && s != '/' && s != '\\').toList();
    if (segments.isEmpty) {
      if (pathSegments.isNotEmpty && (pathSegments.first == '/' || pathSegments.first == '\\')) {
         segments.add('Root');
      } else {
         segments.add('Untitled');
      }
    }

    return Container(
      height: 28, // Slightly taller for better readability
      decoration: BoxDecoration(
        color: ui.colors.panelHeader.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5))),
      ),
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.sm),
      child: Row(
        children: [
          SizedBox(width: ui.spacing.xs),
          Icon(LucideIcons.fileCode, size: 14, color: ui.colors.accent),
          SizedBox(width: ui.spacing.sm),
          
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < segments.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(LucideIcons.chevronRight, size: 12, color: ui.colors.textMuted.withValues(alpha: 0.4)),
                      ),
                    _BreadcrumbSegment(
                      label: segments[i],
                      isLast: i == segments.length - 1,
                      icon: i == segments.length - 1 ? null : LucideIcons.folder,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          Container(width: 1, height: 14, color: ui.colors.divider.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          
          // Function Navigator
          const _FunctionNavigator(),
        ],
      ),
    );
  }
}

class _BreadcrumbSegment extends StatefulWidget {
  const _BreadcrumbSegment({
    required this.label, 
    required this.isLast,
    this.icon,
  });
  
  final String label;
  final bool isLast;
  final IconData? icon;

  @override
  State<_BreadcrumbSegment> createState() => _BreadcrumbSegmentState();
}

class _BreadcrumbSegmentState extends State<_BreadcrumbSegment> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          final appProvider = p.Provider.of<AppProvider?>(context, listen: false);
          final fullPath = appProvider?.activeFile?.path.isNotEmpty == true
              ? appProvider!.activeFile!.path
              : widget.label;
          Clipboard.setData(ClipboardData(text: fullPath));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied path: $fullPath'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: _isHovered ? ui.colors.hover : Colors.transparent,
            borderRadius: ui.spacing.radiusSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 12, color: ui.colors.textMuted.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
              ],
              UiText(
                text: widget.label,
                variant: UiTextVariant.label,
                fontSize: 11,
                fontWeight: widget.isLast ? FontWeight.w600 : FontWeight.w400,
                color: widget.isLast ? ui.colors.textPrimary : ui.colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FunctionNavigator extends ConsumerStatefulWidget {
  const _FunctionNavigator();

  @override
  ConsumerState<_FunctionNavigator> createState() => _FunctionNavigatorState();
}

class _FunctionNavigatorState extends ConsumerState<_FunctionNavigator> {
  bool _isHovered = false;

  List<Map<String, dynamic>> _parseSymbols(String content) {
    final symbols = <Map<String, dynamic>>[];
    final lines = content.split('\n');
    final fnRx = RegExp(
      r'^\s*function\s+(?:(?:\[[^\]]*\]|[a-zA-Z_]\w*)\s*=\s*)?([a-zA-Z_]\w*)',
    );
    final secRx = RegExp(r'^\s*%%\s*(.+)$');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final fnMatch = fnRx.firstMatch(line);
      if (fnMatch != null && fnMatch.group(1) != null) {
        symbols.add({
          'label': '${fnMatch.group(1)}()',
          'line': i + 1,
          'isSection': false,
        });
        continue;
      }
      final secMatch = secRx.firstMatch(line);
      if (secMatch != null && secMatch.group(1) != null) {
        symbols.add({
          'label': '%% ${secMatch.group(1)!.trim()}',
          'line': i + 1,
          'isSection': true,
        });
      }
    }
    return symbols;
  }

  void _showSymbolsMenu(
    BuildContext context,
    AppProvider appProvider,
    List<Map<String, dynamic>> symbols,
  ) {
    final ui = UiTheme.of(context);
    final RenderBox box = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final items = <PopupMenuEntry<int>>[
      PopupMenuItem<int>(
        value: 1,
        child: Row(
          children: [
            Icon(LucideIcons.fileCode, size: 13, color: ui.colors.accent),
            const SizedBox(width: 8),
            UiText(text: 'Top of Script (Line 1)', variant: UiTextVariant.label),
          ],
        ),
      ),
      if (symbols.isNotEmpty) const PopupMenuDivider(),
      ...symbols.map(
        (s) => PopupMenuItem<int>(
          value: s['line'] as int,
          child: Row(
            children: [
              Icon(
                (s['isSection'] as bool) ? LucideIcons.bookmark : LucideIcons.squareFunction,
                size: 13,
                color: ui.colors.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: UiText(
                  text: s['label'] as String,
                  variant: UiTextVariant.codeBody,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              UiText(
                text: ':${s['line']}',
                variant: UiTextVariant.caption,
                color: ui.colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    ];

    showMenu<int>(
      context: context,
      position: position,
      color: ui.colors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: ui.colors.border),
      ),
      items: items,
    ).then((selectedLine) {
      if (selectedLine != null) {
        appProvider.triggerEditorAction('editor.gotoLine:$selectedLine:1');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final appProvider = p.Provider.of<AppProvider>(context);
    final cursor = ref.watch(cursorPositionProvider);
    final currentLine = cursor['line'] ?? 1;
    final content = appProvider.activeFile?.content ?? '';
    final symbols = _parseSymbols(content);

    String activeScope = 'Main Scope';
    for (final s in symbols) {
      if ((s['line'] as int) <= currentLine) {
        activeScope = s['label'] as String;
      } else {
        break;
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showSymbolsMenu(context, appProvider, symbols),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _isHovered ? ui.colors.accent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: ui.spacing.radiusSm,
            border: Border.all(
              color: _isHovered ? ui.colors.accent.withValues(alpha: 0.3) : Colors.transparent,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.squareFunction, 
                size: 13, 
                color: _isHovered ? ui.colors.accent : ui.colors.textMuted
              ),
              const SizedBox(width: 6),
              UiText(
                text: activeScope,
                variant: UiTextVariant.label,
                fontSize: 11,
                color: _isHovered ? ui.colors.accent : ui.colors.textMuted,
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.chevronDown, 
                size: 12, 
                color: _isHovered ? ui.colors.accent : ui.colors.textMuted.withValues(alpha: 0.5)
              ),
            ],
          ),
        ),
      ),
    );
  }
}