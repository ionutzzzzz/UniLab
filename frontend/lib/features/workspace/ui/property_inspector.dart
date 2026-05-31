import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';

class PropertyInspector extends StatelessWidget {
  const PropertyInspector({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    // Mock properties for a selected variable
    final mockProperties = [
      {'name': 'Name', 'value': 'results_matrix'},
      {'name': 'Class', 'value': 'double'},
      {'name': 'Size', 'value': '500x500'},
      {'name': 'Min', 'value': '0.0012'},
      {'name': 'Max', 'value': '0.9984'},
      {'name': 'Mean', 'value': '0.4521'},
      {'name': 'Complexity', 'value': 'Real'},
    ];

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
              itemCount: mockProperties.length,
              itemBuilder: (context, index) {
                final prop = mockProperties[index];
                return _PropertyRow(
                  name: prop['name']!,
                  value: prop['value']!,
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
