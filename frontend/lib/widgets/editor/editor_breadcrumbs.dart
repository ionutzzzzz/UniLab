import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/ui_theme.dart';

class EditorBreadcrumbs extends StatelessWidget {
  final String filePath;
  final List<String> symbols;
  final String? activeSymbol;
  final Function(String)? onSymbolSelected;

  const EditorBreadcrumbs({
    super.key,
    required this.filePath,
    this.symbols = const [],
    this.activeSymbol,
    this.onSymbolSelected,
  });

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final parts = filePath.split('/');
    
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ui.colors.panelHeader,
        border: Border(
          bottom: BorderSide(
            color: ui.colors.border,
            width: ui.spacing.strokeHair,
          ),
        ),
      ),
      child: Row(
        children: [
          // Path breadcrumbs
          ...parts.asMap().entries.map((entry) {
            final isLast = entry.key == parts.length - 1;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (entry.key == 0)
                  Icon(LucideIcons.folder, size: 14, color: ui.colors.textMuted)
                else
                  Icon(LucideIcons.chevronRight, size: 12, color: ui.colors.textDisabled),
                
                const SizedBox(width: 4),
                
                Text(
                  entry.value,
                  style: ui.typography.label.copyWith(
                    fontSize: 11,
                    color: isLast ? ui.colors.textPrimary : ui.colors.textMuted,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            );
          }),

          const SizedBox(width: 8),
          Icon(LucideIcons.chevronRight, size: 12, color: ui.colors.textDisabled),
          const SizedBox(width: 8),

          // Symbol Navigator
          _buildSymbolDropdown(context, ui),
          
          const Spacer(),
          
          // Action buttons
          _buildActionIcon(LucideIcons.split, ui, 'Split Editor'),
          _buildActionIcon(LucideIcons.moreHorizontal, ui, 'More Actions'),
        ],
      ),
    );
  }

  Widget _buildSymbolDropdown(BuildContext context, UiTheme ui) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: PopupMenuButton<String>(
        tooltip: 'Go to Symbol',
        offset: const Offset(0, 24),
        surfaceTintColor: Colors.transparent,
        color: ui.colors.overlay,
        shape: RoundedRectangleBorder(
          borderRadius: ui.spacing.radiusSm,
          side: BorderSide(color: ui.colors.border, width: ui.spacing.strokeHair),
        ),
        onSelected: onSymbolSelected,
        itemBuilder: (context) {
          if (symbols.isEmpty) {
            return [
              PopupMenuItem(
                enabled: false,
                child: Text('No symbols found', style: ui.typography.label.copyWith(color: ui.colors.textDisabled)),
              )
            ];
          }
          return symbols.map((symbol) => PopupMenuItem<String>(
            value: symbol,
            height: 32,
            child: Row(
              children: [
                Icon(LucideIcons.functionSquare, size: 14, color: ui.colors.accent),
                const SizedBox(width: 8),
                Text(
                  symbol,
                  style: ui.typography.body.copyWith(
                    fontSize: 12,
                    color: symbol == activeSymbol ? ui.colors.accent : ui.colors.textPrimary,
                  ),
                ),
              ],
            ),
          )).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.functionSquare, size: 13, color: ui.colors.accent),
              const SizedBox(width: 6),
              Text(
                activeSymbol ?? 'Global Scope',
                style: ui.typography.label.copyWith(
                  fontSize: 11,
                  color: ui.colors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronDown, size: 12, color: ui.colors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, UiTheme ui, String tooltip) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Tooltip(
        message: tooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Icon(icon, size: 14, color: ui.colors.textMuted),
        ),
      ),
    );
  }
}
