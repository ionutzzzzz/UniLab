import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:context_menus/context_menus.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../providers/app_provider.dart';
import '../../theme/ui_theme.dart';
import '../../theme/ui_decorations.dart';

class WorkspacePanel extends StatefulWidget {
  const WorkspacePanel({super.key});

  @override
  State<WorkspacePanel> createState() => _WorkspacePanelState();
}

class _WorkspacePanelState extends State<WorkspacePanel> {
  final List<PlutoColumn> columns = [
    PlutoColumn(
      title: 'Name',
      field: 'name',
      type: PlutoColumnType.text(),
      enableEditingMode: false,
      width: 100,
      renderer: (rendererContext) {
        return ContextMenuRegion(
          contextMenu: GenericContextMenu(
            buttonConfigs: [
              ContextMenuButtonConfig(
                'Plot "${rendererContext.cell.value}"',
                onPressed: () {
                  // Trigger plot via provider if possible
                },
                icon: const Icon(Icons.show_chart, size: 16),
              ),
              ContextMenuButtonConfig(
                'Copy Name',
                onPressed: () {},
                icon: const Icon(Icons.copy, size: 16),
              ),
            ],
          ),
          child: Text(
            rendererContext.cell.value.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'JetBrains Mono',
              color: Color(0xFFB3CDE3), // Pastel Blue Accent
            ),
          ),
        );
      },
    ),
    PlutoColumn(
      title: 'Value',
      field: 'value',
      type: PlutoColumnType.text(),
      enableEditingMode: false,
      width: 150,
    ),
    PlutoColumn(
      title: 'Size',
      field: 'size',
      type: PlutoColumnType.text(),
      enableEditingMode: false,
      width: 80,
    ),
    PlutoColumn(
      title: 'Class',
      field: 'class',
      type: PlutoColumnType.text(),
      enableEditingMode: false,
      width: 80,
    ),
    PlutoColumn(
      title: 'Min',
      field: 'min',
      type: PlutoColumnType.text(),
      enableEditingMode: false,
      width: 60,
    ),
    PlutoColumn(
      title: 'Max',
      field: 'max',
      type: PlutoColumnType.text(),
      enableEditingMode: false,
      width: 60,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Container(
      decoration: ShellDecorations.panelDecoration(ui),
      margin: const EdgeInsets.all(2.0), // Give room for the shadow
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ui.colors.panelHeader,
              border: Border(
                bottom: BorderSide(
                  color: ui.colors.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'WORKSPACE',
                  style: ui.typography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.refresh, size: 14, color: ui.colors.icon),
                      onPressed: () => Provider.of<AppProvider>(context, listen: false).refreshProjectFiles(),
                      tooltip: 'Refresh Workspace',
                      iconSize: 14,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_sweep, size: 14, color: ui.colors.icon),
                      onPressed: () => Provider.of<AppProvider>(context, listen: false).clearWorkspace(),
                      tooltip: 'Clear Workspace',
                      iconSize: 14,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // PlutoGrid View
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, appProvider, _) {
                final variables = appProvider.workspaceVariables;

                if (variables.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 40,
                          color: ui.colors.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No variables in workspace',
                          style: ui.typography.label.copyWith(
                            color: ui.colors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final rows = variables.entries.map((entry) {
                  final value = entry.value;
                  String size = '1x1';
                  String className = 'double';
                  
                  if (value is List) {
                    size = '${value.length}x1';
                    className = 'list';
                  } else if (value is Map) {
                    size = '${value.length}x${value.keys.length}';
                    className = 'struct';
                  } else if (value is String) {
                    size = '1x${value.length}';
                    className = 'char';
                  }

                  return PlutoRow(
                    cells: {
                      'name': PlutoCell(value: entry.key),
                      'value': PlutoCell(value: value.toString()),
                      'size': PlutoCell(value: size),
                      'class': PlutoCell(value: className),
                      'min': PlutoCell(value: '-'),
                      'max': PlutoCell(value: '-'),
                    },
                  );
                }).toList();

                return PlutoGrid(
                  columns: columns,
                  rows: rows,
                  configuration: PlutoGridConfiguration(
                    columnSize: const PlutoGridColumnSizeConfig(
                      autoSizeMode: PlutoAutoSizeMode.equal,
                    ),
                    style: PlutoGridStyleConfig(
                      gridBackgroundColor: ui.colors.canvas,
                      rowColor: ui.colors.canvas,
                      oddRowColor: ui.colors.canvas,
                      activatedColor: ui.colors.hover,
                      activatedBorderColor: ui.colors.accent,
                      gridBorderColor: ui.colors.border,
                      borderColor: ui.colors.border,
                      menuBackgroundColor: ui.colors.canvas,
                      columnTextStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ui.colors.textMuted,
                      ),
                      cellTextStyle: TextStyle(
                        fontSize: 12,
                        fontFamily: 'JetBrains Mono',
                        color: ui.colors.textPrimary,
                      ),
                      enableColumnBorderVertical: true,
                      rowHeight: 28.0, 
                      columnHeight: 32.0, 
                    ),
                    scrollbar: const PlutoGridScrollbarConfig(
                      scrollbarThickness: 8,
                      scrollbarThicknessWhileDragging: 10,
                      isAlwaysShown: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

