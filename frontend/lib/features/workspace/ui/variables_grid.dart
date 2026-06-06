import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../state/workspace_providers.dart';

class VariablesGrid extends ConsumerStatefulWidget {
  const VariablesGrid({super.key});

  @override
  ConsumerState<VariablesGrid> createState() => _VariablesGridState();
}

class _VariablesGridState extends ConsumerState<VariablesGrid> {
  late List<PlutoColumn> columns;
  PlutoGridStateManager? stateManager;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    columns = [
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
    ];
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
      },
    )).toList();

    // If stateManager is initialized, update rows directly
    if (stateManager != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (stateManager != null) {
          // Avoid unnecessary updates if row count is same (basic check)
          // To be perfectly accurate we can just clear and append
          stateManager!.removeAllRows();
          stateManager!.appendRows(rows);
        }
      });
    }

    return Container(
      color: ui.colors.canvas,
      child: PlutoGrid(
        columns: columns,
        rows: rows,
        onLoaded: (PlutoGridOnLoadedEvent event) {
          stateManager = event.stateManager;
          stateManager!.setShowColumnFilter(false);
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
    );
  }
}
