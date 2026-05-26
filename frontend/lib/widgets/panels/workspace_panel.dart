import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:context_menus/context_menus.dart';
import '../../providers/app_provider.dart';
import '../draggable/draggable_component.dart';
import '../settings/ui_preferences_panel.dart';

class WorkspacePanel extends StatefulWidget {
  const WorkspacePanel({super.key});

  @override
  State<WorkspacePanel> createState() => _WorkspacePanelState();
}

class _WorkspacePanelState extends State<WorkspacePanel> {
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
                      onPressed: () {},
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
          // Tabular Data View
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, appProvider, _) {
                final variables = appProvider.workspaceVariables;

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Theme.of(context).dividerColor,
                      ),
                      child: DataTable(
                        columnSpacing: 20,
                        headingRowHeight: 28,
                        dataRowMinHeight: 24,
                        dataRowMaxHeight: 24,
                        headingTextStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF888888),
                        ),
                        horizontalMargin: 12,
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Value')),
                          DataColumn(label: Text('Size')),
                          DataColumn(label: Text('Class')),
                        ],
                        rows: variables.isEmpty 
                          ? [] 
                          : variables.entries.map((entry) {
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

                              return DataRow(
                                cells: [
                                  DataCell(
                                    ContextMenuRegion(
                                      contextMenu: GenericContextMenu(
                                        buttonConfigs: [
                                          ContextMenuButtonConfig(
                                            'Plot "${entry.key}"',
                                            onPressed: () {},
                                            icon: const Icon(Icons.show_chart, size: 16),
                                          ),
                                          ContextMenuButtonConfig(
                                            'Copy Name',
                                            onPressed: () {},
                                            icon: const Icon(Icons.copy, size: 16),
                                          ),
                                        ],
                                      ),
                                      child: Text(entry.key, style: const TextStyle(fontSize: 11, color: Color(0xFF00A4EF))),
                                    ),
                                  ),
                                  DataCell(Text(value.toString(), style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                  DataCell(Text(size, style: const TextStyle(fontSize: 11))),
                                  DataCell(Text(className, style: const TextStyle(fontSize: 11))),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Empty State Message (Optional, placed below or inside table)
          Consumer<AppProvider>(
            builder: (context, appProvider, _) {
              if (appProvider.workspaceVariables.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No variables in workspace',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF858585),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
