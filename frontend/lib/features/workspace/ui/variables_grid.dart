import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_icon_button.dart';
import '../state/workspace_providers.dart';

class VariablesGrid extends ConsumerStatefulWidget {
  const VariablesGrid({super.key});

  @override
  ConsumerState<VariablesGrid> createState() => _VariablesGridState();
}

class _VariablesGridState extends ConsumerState<VariablesGrid> {
  PlutoGridStateManager? stateManager;
  final GlobalKey _columnPickerKey = GlobalKey();
  
  // Track visible columns
  final Set<String> _visibleColumnFields = {
    'name',
    'value',
    'size',
    'class',
    'min',
    'max',
  };

  List<PlutoColumn> _buildColumns() {
    final allColumns = [
      PlutoColumn(
        title: 'Name',
        field: 'name',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Value',
        field: 'value',
        type: PlutoColumnType.text(),
        width: 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Size',
        field: 'size',
        type: PlutoColumnType.text(),
        width: 80,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Class',
        field: 'class',
        type: PlutoColumnType.text(),
        width: 80,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Min',
        field: 'min',
        type: PlutoColumnType.text(),
        width: 70,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Max',
        field: 'max',
        type: PlutoColumnType.text(),
        width: 70,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Mean',
        field: 'mean',
        type: PlutoColumnType.text(),
        width: 70,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Median',
        field: 'median',
        type: PlutoColumnType.text(),
        width: 70,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Sum',
        field: 'sum',
        type: PlutoColumnType.text(),
        width: 70,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Variance',
        field: 'variance',
        type: PlutoColumnType.text(),
        width: 70,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Std',
        field: 'std',
        type: PlutoColumnType.text(),
        width: 70,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Range',
        field: 'range',
        type: PlutoColumnType.text(),
        width: 70,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Mode',
        field: 'mode',
        type: PlutoColumnType.text(),
        width: 70,
        enableEditingMode: false,
      ),
    ];

    return allColumns.where((col) => _visibleColumnFields.contains(col.field)).toList();
  }

  void _showColumnPicker(BuildContext context, UiTheme ui) {
    final RenderBox renderBox = _columnPickerKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    final allOptions = [
      {'field': 'name', 'label': 'Name'},
      {'field': 'value', 'label': 'Value'},
      {'field': 'size', 'label': 'Size'},
      {'field': 'class', 'label': 'Class'},
      {'field': 'min', 'label': 'Min'},
      {'field': 'max', 'label': 'Max'},
      {'field': 'mean', 'label': 'Mean'},
      {'field': 'median', 'label': 'Median'},
      {'field': 'sum', 'label': 'Sum'},
      {'field': 'variance', 'label': 'Variance'},
      {'field': 'std', 'label': 'Std'},
      {'field': 'range', 'label': 'Range'},
      {'field': 'mode', 'label': 'Mode'},
    ];

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx, 
        offset.dy + renderBox.size.height, 
        offset.dx + renderBox.size.width, 
        0
      ),
      color: ui.colors.panel,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: ui.spacing.radiusMd,
        side: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5)),
      ),
      items: allOptions.map((opt) {
        return PopupMenuItem(
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (context, setStateMenu) {
              final isVisible = _visibleColumnFields.contains(opt['field']);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: CheckboxListTile(
                  value: isVisible,
                  title: UiText(
                    text: opt['label']!,
                    variant: UiTextVariant.label,
                    fontSize: 11,
                  ),
                  dense: true,
                  activeColor: ui.colors.accent,
                  checkColor: ui.colors.textInverse,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _visibleColumnFields.add(opt['field']!);
                      } else {
                        if (_visibleColumnFields.length > 1) {
                          _visibleColumnFields.remove(opt['field']!);
                        }
                      }
                    });
                    setStateMenu(() {});
                  },
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final variables = ref.watch(workspaceVariablesProvider);

    if (variables.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ui.colors.panelHeader.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.table_rows_outlined, size: 40, color: ui.colors.textDisabled),
              ),
              const SizedBox(height: 20),
              UiText(
                text: 'Workspace is empty',
                variant: UiTextVariant.body,
                fontWeight: FontWeight.bold,
                color: ui.colors.textSecondary,
              ),
              const SizedBox(height: 8),
              UiText(
                text: 'Execute a script to see variables and matrices populated here.',
                variant: UiTextVariant.label,
                color: ui.colors.textMuted,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final rows = variables.map((v) => PlutoRow(
      cells: {
        'name': PlutoCell(value: v.name),
        'value': PlutoCell(value: v.value),
        'size': PlutoCell(value: v.size),
        'class': PlutoCell(value: v.typeClass),
        'min': PlutoCell(value: v.min),
        'max': PlutoCell(value: v.max),
        'mean': PlutoCell(value: v.mean),
        'median': PlutoCell(value: v.median),
        'sum': PlutoCell(value: v.sum),
        'variance': PlutoCell(value: v.variance),
        'std': PlutoCell(value: v.std),
        'range': PlutoCell(value: v.range),
        'mode': PlutoCell(value: v.mode),
      },
    )).toList();

    // If stateManager is initialized, update rows directly
    if (stateManager != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (stateManager != null) {
          stateManager!.removeAllRows();
          stateManager!.appendRows(rows);
        }
      });
    }

    return Column(
      children: [
        // Grid Toolbar
        Container(
          height: 28,
          padding: EdgeInsets.symmetric(horizontal: ui.spacing.sm),
          decoration: BoxDecoration(
            color: ui.colors.panelHeader.withValues(alpha: 0.5),
            border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.3))),
          ),
          child: Row(
            children: [
              const Spacer(),
              UiIconButton(
                key: _columnPickerKey,
                icon: LucideIcons.columns2,
                tooltip: 'Select Columns',
                size: 20,
                iconSize: 12,
                onPressed: () => _showColumnPicker(context, ui),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: ui.colors.canvas,
            child: PlutoGrid(
              key: ValueKey(_visibleColumnFields.join(',')), // Force rebuild on column change
              columns: _buildColumns(),
              rows: rows,
              onLoaded: (PlutoGridOnLoadedEvent event) {
                stateManager = event.stateManager;
                stateManager!.setShowColumnFilter(false);
              },
              onSelected: (event) {
                if (event.row != null) {
                  final name = event.row!.cells['name']?.value;
                  ref.read(selectedVariableNameProvider.notifier).state = name;
                }
              },
              configuration: PlutoGridConfiguration(
                columnSize: const PlutoGridColumnSizeConfig(
                  autoSizeMode: PlutoAutoSizeMode.equal,
                ),
                style: PlutoGridStyleConfig(
                  enableGridBorderShadow: false,
                  gridBackgroundColor: ui.colors.canvas,
                  rowColor: ui.colors.canvas,
                  oddRowColor: ui.colors.canvas,
                  evenRowColor: ui.colors.canvas,
                  activatedColor: ui.colors.hover.withValues(alpha: 0.5),
                  checkedColor: ui.colors.selected,
                  cellColorInEditState: ui.colors.canvas,
                  cellColorInReadOnlyState: ui.colors.canvas,
                  columnTextStyle: ui.typography.label.copyWith(
                    color: ui.colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  cellTextStyle: ui.typography.body.copyWith(
                    color: ui.colors.textPrimary,
                    fontSize: 11,
                    fontFamily: 'JetBrains Mono',
                  ),
                  borderColor: ui.colors.divider.withValues(alpha: 0.3),
                  gridBorderColor: ui.colors.divider.withValues(alpha: 0.3),
                  activatedBorderColor: ui.colors.accent.withValues(alpha: 0.5),
                  inactivatedBorderColor: ui.colors.divider.withValues(alpha: 0.2),
                  menuBackgroundColor: ui.colors.canvas,
                  columnFilterHeight: 0,
                  rowHeight: 24,
                  columnHeight: 28,
                  enableColumnBorderVertical: true,
                  enableColumnBorderHorizontal: false,
                  enableCellBorderVertical: true,
                  enableCellBorderHorizontal: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}