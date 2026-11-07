import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart' as p;
import 'package:path/path.dart' as p_path;
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/riverpod_providers.dart';
import '../../../utils/platform_io.dart' as io;
import '../domain/status_bar_slot.dart';

String _getGitBranch(String? projectRoot) {
  if (kIsWeb || projectRoot == null) return 'main';
  try {
    final headFile = io.File(p_path.join(projectRoot, '.git', 'HEAD'));
    if (headFile.existsSync()) {
      final content = headFile.readAsStringSync().trim();
      if (content.startsWith('ref: refs/heads/')) {
        return content.replaceFirst('ref: refs/heads/', '');
      }
      return content.length > 7 ? content.substring(0, 7) : content;
    }
  } catch (_) {}
  return 'main';
}

class AppStatusBar extends ConsumerStatefulWidget {
  const AppStatusBar({super.key});

  @override
  ConsumerState<AppStatusBar> createState() => _AppStatusBarState();
}

class _AppStatusBarState extends ConsumerState<AppStatusBar> {
  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final appProvider = p.Provider.of<AppProvider>(context);
    final cursorPosition = ref.watch(cursorPositionProvider);

    // Build the status label based on execution state & backend status
    String statusLabel;
    switch (appProvider.backendStatus) {
      case BackendStatus.connected:
        statusLabel = appProvider.isExecuting ? 'Running script...' : 'Ready';
        break;
      case BackendStatus.connecting:
        statusLabel = 'Connecting to backend...';
        break;
      case BackendStatus.error:
        statusLabel = 'Backend Error';
        break;
    }

    final branchName = _getGitBranch(appProvider.projectRoot);
    
    final slots = [
      StatusBarSlot(
        id: 'status',
        label: statusLabel,
        alignment: StatusBarSlotAlignment.left,
        priority: 100,
      ),
      StatusBarSlot(
        id: 'branch', 
        label: branchName, 
        icon: LucideIcons.gitBranch, 
        alignment: StatusBarSlotAlignment.left, 
        priority: 90
      ),
      StatusBarSlot(
        id: 'cursor', 
        label: 'Ln ${cursorPosition['line']}, Col ${cursorPosition['column']}', 
        alignment: StatusBarSlotAlignment.right, 
        priority: 100
      ),
      const StatusBarSlot(id: 'encoding', label: 'UTF-8', alignment: StatusBarSlotAlignment.right, priority: 90),
    ];

    final leftSlots = slots.where((s) => s.alignment == StatusBarSlotAlignment.left).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    final rightSlots = slots.where((s) => s.alignment == StatusBarSlotAlignment.right).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return Container(
      width: double.infinity,
      height: 24,
      decoration: BoxDecoration(
        color: ui.colors.panelHeader,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.4),
            width: ui.spacing.strokeHair,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.02),
            offset: const Offset(0, -1),
            blurRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
      child: DefaultTextStyle(
        style: ui.typography.label.copyWith(
          color: ui.colors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: leftSlots.map((s) => _SlotWidget(slot: s)).toList(),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...rightSlots.map((s) => _SlotWidget(slot: s)),
                SizedBox(width: ui.spacing.sm),
                Icon(LucideIcons.bell, size: 14, color: ui.colors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotWidget extends StatefulWidget {
  const _SlotWidget({required this.slot});
  final StatusBarSlot slot;

  @override
  State<_SlotWidget> createState() => _SlotWidgetState();
}

class _SlotWidgetState extends State<_SlotWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final isClickable = widget.slot.onTap != null;
    final isStatusSlot = widget.slot.id == 'status';

    Widget content = Padding(
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isStatusSlot) ...[
            // Get current status color from context
            Builder(builder: (ctx) {
              final appProvider = p.Provider.of<AppProvider>(ctx);
              final statusColor = appProvider.isExecuting ? ui.colors.warning : ui.colors.success;
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              );
            }),
            SizedBox(width: ui.spacing.sm),
          ],
          if (widget.slot.icon != null) ...[
            Icon(widget.slot.icon,
                size: 12,
                color: _isHovered && isClickable
                    ? ui.colors.accent
                    : ui.colors.textMuted),
            SizedBox(width: ui.spacing.xs),
          ],
          UiText(
            text: widget.slot.label,
            variant: UiTextVariant.label,
            fontSize: 10,
            color: _isHovered && isClickable
                ? ui.colors.textPrimary
                : ui.colors.textMuted,
          ),
        ],
      ),
    );

    if (isClickable) {
      content = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.slot.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: _isHovered ? ui.colors.hover.withValues(alpha: 0.5) : Colors.transparent,
            child: content,
          ),
        ),
      );
    }

    if (widget.slot.tooltip != null) {
      return Tooltip(
        message: widget.slot.tooltip!,
        child: content,
      );
    }

    return content;
  }
}