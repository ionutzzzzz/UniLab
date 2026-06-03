import 'package:flutter/material.dart';

enum StatusBarSlotAlignment { left, right }

class StatusBarSlot {
  final String id;
  final String label;
  final IconData? icon;
  final String? tooltip;
  final VoidCallback? onTap;
  final StatusBarSlotAlignment alignment;
  final int priority; // higher priority shows closer to the center

  const StatusBarSlot({
    required this.id,
    required this.label,
    this.icon,
    this.tooltip,
    this.onTap,
    this.alignment = StatusBarSlotAlignment.left,
    this.priority = 0,
  });
}
