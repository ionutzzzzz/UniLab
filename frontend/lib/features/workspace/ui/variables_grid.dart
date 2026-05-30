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
    final ui = UiTheme.of(context);
    columns = [
      PlutoColumn(
        title: 'Name',
        field: 'name',
        type: PlutoColumnType.text(),
        width: 80,
      ),
      PlutoColumn(
        title: 'Value',
        field: 'value',
        type: PlutoColumnType.text(),
        width: 120,
      ),
      PlutoColumn(
        title: 'Size',
        field: 'size',
        type: PlutoColumnType.text(),
        width: 60,
      ),
      PlutoColumn(
        title: 'Class',
        field: 'class',
        type: PlutoColumnType.text(),
        width: 70,
      ),
      PlutoColumn(
        title: 'Min',
        field: 'min',
        type: PlutoColumnType.text(),
        width: 50,
      ),
      PlutoColumn(
        title: 'Max',
        field: 'max',
        type: PlutoColumnType.text(),
        width: 50,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final variablesAsync = ref.watch(workspaceVariablesProvider);

    return variablesAsync.when(
      data: (variables) {
        if (variables.isEmpty) {
          return Center(
            child: UiText(
              text: 'No variables in workspace yet — run a script.',
              variant: UiTextVariant.body,
              color: ui.colors.textMuted,
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

        return PlutoGrid(
          columns: columns,
          rows: rows,
          onLoaded: (PlutoGridOnLoadedEvent event) {
            stateManager = event.stateManager;
            stateManager!.setShowColumnFilter(false);
          },
          configuration: PlutoGridConfiguration(
            style: PlutoGridStyleConfig(
              enableGridBorderShadow: false,
              gridBackgroundColor: ui.colors.panel,
              rowColor: ui.colors.panel,
              oddRowColor: ui.colors.panel,
              evenRowColor: ui.colors.panel,
              activatedColor: ui.colors.hover,
              checkedColor: ui.colors.selected,
              cellColorInEditState: ui.colors.panel,
              cellColorInReadOnlyState: ui.colors.panel,
              columnTextStyle: ui.typography.label.copyWith(color: ui.colors.textSecondary),
              cellTextStyle: ui.typography.body.copyWith(color: ui.colors.textPrimary),
              borderColor: ui.colors.divider,
              gridBorderColor: ui.colors.divider,
              activatedBorderColor: ui.colors.accent,
              inactivatedBorderColor: ui.colors.divider,
              columnFilterHeight: 30,
              rowHeight: 28,
              columnHeight: 28,
              enableColumnBorderVertical: true,
              enableColumnBorderHorizontal: true,
              enableCellBorderVertical: true,
              enableCellBorderHorizontal: true,
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: UiText(text: 'Error: $err', color: ui.colors.danger)),
    );
  }
}
