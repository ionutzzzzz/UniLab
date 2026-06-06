import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../state/workspace_providers.dart';

class PropertyInspector extends ConsumerWidget {
  const PropertyInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = UiTheme.of(context);
    final variable = ref.watch(selectedVariableProvider);
    
    if (variable == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.mousePointer2, size: 40, color: ui.colors.textDisabled),
            const SizedBox(height: 16),
            UiText(
              text: 'Select a variable to inspect',
              variant: UiTextVariant.body,
              color: ui.colors.textMuted,
            ),
          ],
        ),
      );
    }

    final properties = [
      {'name': 'Name', 'value': variable.name},
      {'name': 'Class', 'value': variable.typeClass},
      {'name': 'Size', 'value': variable.size},
      {'name': 'Min', 'value': variable.min},
      {'name': 'Max', 'value': variable.max},
      {'name': 'Mean', 'value': variable.mean},
      {'name': 'Median', 'value': variable.median},
      {'name': 'Sum', 'value': variable.sum},
      {'name': 'Variance', 'value': variable.variance},
      {'name': 'Std Dev', 'value': variable.std},
      {'name': 'Range', 'value': variable.range},
      {'name': 'Mode', 'value': variable.mode},
    ].where((p) => p['value'] != null && p['value']!.toString().isNotEmpty).toList();

    return Column(
      children: [
        // Inspector Header/Toolbar
        Container(
          padding: EdgeInsets.symmetric(horizontal: ui.spacing.md, vertical: 6),
          decoration: BoxDecoration(
            color: ui.colors.accent.withValues(alpha: 0.1),
            border: Border(bottom: BorderSide(color: ui.colors.accent.withValues(alpha: 0.3))),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.info, size: 14, color: ui.colors.accent),
              const SizedBox(width: 8),
              UiText(
                text: 'PROPERTY INSPECTOR',
                variant: UiTextVariant.label,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: ui.colors.accent,
              ),
              const Spacer(),
              Icon(LucideIcons.settings2, size: 14, color: ui.colors.textMuted),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: ui.colors.canvas,
            child: ListView.builder(
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final prop = properties[index];
                return _PropertyRow(
                  name: prop['name']!,
                  value: prop['value']!.toString(),
                  isEven: index % 2 == 0,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PropertyRow extends StatefulWidget {
  const _PropertyRow({
    required this.name,
    required this.value,
    required this.isEven,
  });

  final String name;
  final String value;
  final bool isEven;

  @override
  State<_PropertyRow> createState() => _PropertyRowState();
}

class _PropertyRowState extends State<_PropertyRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: ui.spacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: _isHovered 
              ? ui.colors.hover.withValues(alpha: 0.5) 
              : (widget.isEven ? Colors.transparent : ui.colors.panelHeader.withValues(alpha: 0.2)),
          border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.1))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: UiText(
                text: widget.name,
                variant: UiTextVariant.label,
                color: ui.colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              flex: 3,
              child: UiText(
                text: widget.value,
                variant: UiTextVariant.body,
                fontSize: 12,
                color: ui.colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
