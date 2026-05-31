import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../domain/status_bar_slot.dart';

// Use a unique name for the provider to avoid hot-reload type conflicts
final dynamicSystemMetricsProvider = StreamProvider<Map<String, double>>((ref) {
  final random = Random();
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return {
      'cpu': 8 + random.nextDouble() * 15, // 8-23%
      'ram': 1.1 + random.nextDouble() * 0.4, // 1.1-1.5 GB
    };
  }).map((metrics) => metrics);
});

final statusBarSlotsProvider = Provider<List<StatusBarSlot>>((ref) {
  // Watch the dynamic metrics
  final metricsAsync = ref.watch(dynamicSystemMetricsProvider);
  final metrics = metricsAsync.value ?? {'cpu': 12.0, 'ram': 1.2};
  
  return [
    const StatusBarSlot(id: 'status', label: 'Ready', alignment: StatusBarSlotAlignment.left, priority: 100),
    const StatusBarSlot(id: 'branch', label: 'main', icon: LucideIcons.gitBranch, alignment: StatusBarSlotAlignment.left, priority: 90),
    StatusBarSlot(
      id: 'cpu', 
      label: 'CPU: ${metrics['cpu']!.toStringAsFixed(1)}%', 
      alignment: StatusBarSlotAlignment.right, 
      priority: 85
    ),
    StatusBarSlot(
      id: 'ram', 
      label: 'RAM: ${metrics['ram']!.toStringAsFixed(1)}GB', 
      alignment: StatusBarSlotAlignment.right, 
      priority: 80
    ),
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
      height: 24,
      decoration: BoxDecoration(
        color: ui.colors.panelHeader,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.4),
            width: 1.0,
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
    final isClickable = widget.slot.onTap != null || ['cpu', 'ram'].contains(widget.slot.id);
    final isStatusSlot = widget.slot.id == 'status';
    final isMetric = ['cpu', 'ram'].contains(widget.slot.id);

    Widget content = Padding(
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isStatusSlot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: ui.colors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ui.colors.success.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
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
          if (isMetric) ...[
            _MetricIndicator(id: widget.slot.id, label: widget.slot.label),
          ] else
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

    if (widget.slot.tooltip != null || isMetric) {
      return Tooltip(
        message: widget.slot.tooltip ?? (widget.slot.id == 'cpu' ? 'CPU Usage' : 'Memory Usage'),
        child: content,
      );
    }

    return content;
  }
}

class _MetricIndicator extends ConsumerWidget {
  const _MetricIndicator({required this.id, required this.label});
  final String id;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = UiTheme.of(context);
    final metricsAsync = ref.watch(dynamicSystemMetricsProvider);
    final metrics = metricsAsync.value ?? {'cpu': 12.0, 'ram': 1.2};
    
    double value;
    if (id == 'cpu') {
      value = metrics['cpu']!;
    } else {
      // For RAM, normalize to a percentage for the indicator bar (assuming 16GB max)
      value = (metrics['ram']! / 16.0) * 100;
      if (value < 5) value = 5; // Min visible
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UiText(
          text: label,
          variant: UiTextVariant.label,
          fontSize: 10,
          color: ui.colors.textMuted,
        ),
        SizedBox(width: ui.spacing.xs),
        Container(
          width: 30,
          height: 4,
          decoration: BoxDecoration(
            color: ui.colors.divider.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (value / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: value > 80 ? ui.colors.danger : ui.colors.accent.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}