import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:context_menus/context_menus.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../providers/app_provider.dart';

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
              fontSize: 11,
              color: Color(0xFF00A4EF),
              fontWeight: FontWeight.bold,
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
    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'WORKSPACE',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 14),
                      onPressed: () => Provider.of<AppProvider>(context, listen: false).refreshProjectFiles(),
                      tooltip: 'Refresh Workspace',
                      iconSize: 14,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, size: 14),
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
                          color: const Color(0xFF858585).withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No variables in workspace',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF858585),
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
                    style: PlutoGridStyleConfig(
                      gridBackgroundColor: Theme.of(context).cardColor,
                      rowColor: Theme.of(context).cardColor,
                      columnTextStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF888888),
                      ),
                      cellTextStyle: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFCCCCCC),
                      ),
                      borderColor: Theme.of(context).dividerColor,
                      gridBorderColor: Theme.of(context).dividerColor,
                      activatedColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      enableColumnBorderVertical: true,
                    ),
                    columnSize: const PlutoGridColumnSizeConfig(
                      autoSizeMode: PlutoAutoSizeMode.none,
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

