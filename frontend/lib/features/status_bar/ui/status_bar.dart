import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/status_bar_slot.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';

final statusBarSlotsProvider = Provider<List<StatusBarSlot>>((ref) {
  // Hardcode 3 starter slots for now as a mock
  return [
    const StatusBarSlot(id: 'status', label: 'Ready', alignment: StatusBarSlotAlignment.left, priority: 100),
    const StatusBarSlot(id: 'cursor', label: 'Ln 1, Col 1', alignment: StatusBarSlotAlignment.right, priority: 100),
    const StatusBarSlot(id: 'encoding', label: 'UTF-8', alignment: StatusBarSlotAlignment.right, priority: 90),
  ];
});

class AppStatusBar extends ConsumerWidget {
  const AppStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = UiTheme.of(context);
    final slots = ref.watch(statusBarSlotsProvider);

    final leftSlots = slots.where((s) => s.alignment == StatusBarSlotAlignment.left).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    final rightSlots = slots.where((s) => s.alignment == StatusBarSlotAlignment.right).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return Container(
      height: 22,
      color: ui.colors.panelHeader,
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.sm),
      child: DefaultTextStyle(
        style: ui.typography.caption.copyWith(color: ui.colors.textMuted),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: leftSlots.map((s) => _SlotWidget(slot: s)).toList(),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: rightSlots.map((s) => _SlotWidget(slot: s)).toList(),
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

    Widget content = Padding(
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.slot.icon != null) ...[
            Icon(widget.slot.icon, size: 14, color: _isHovered && isClickable ? ui.colors.textPrimary : ui.colors.textMuted),
            SizedBox(width: ui.spacing.xs),
          ],
          UiText(
            text: widget.slot.label,
            variant: UiTextVariant.caption,
            color: _isHovered && isClickable ? ui.colors.textPrimary : ui.colors.textMuted,
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
          child: Container(
            color: _isHovered ? ui.colors.hover : Colors.transparent,
            child: content,
          ),
        ),
      );
    } else {
      content = Container(
        color: Colors.transparent,
        child: content,
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
