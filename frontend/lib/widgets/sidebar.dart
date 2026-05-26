import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class UniLabSidebar extends StatelessWidget {
  const UniLabSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          _buildToolWindowHeader(context, 'Workspace'),
          Expanded(
            flex: 1,
            child: ListView.separated(
              itemCount: appProvider.workspaceVariables.length,
              separatorBuilder: (context, index) => Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),
              itemBuilder: (context, index) {
                final key = appProvider.workspaceVariables.keys.elementAt(index);
                final val = appProvider.workspaceVariables[key];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.grid_on, size: 14, color: Color(0xFF007ACC)),
                  title: Text(key, style: const TextStyle(fontSize: 12, color: Colors.white)),
                  subtitle: Text(val['preview'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                  trailing: Text(val['size'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                );
              },
            ),
          ),
          _buildToolWindowHeader(context, 'Current Folder'),
          Expanded(
            flex: 1,
            child: ListView(
              children: const [
                _FileItem(icon: Icons.folder, name: 'scripts', color: Colors.amber),
                _FileItem(icon: Icons.insert_drive_file, name: 'main_script.m', color: Color(0xFFCCCCCC)),
                _FileItem(icon: Icons.insert_drive_file, name: 'data_analysis.m', color: Color(0xFFCCCCCC)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolWindowHeader(BuildContext context, String title) {
    return Container(
      height: 28,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1.0),
          top: title == 'Current Folder' 
              ? BorderSide(color: Theme.of(context).dividerColor, width: 1.0) 
              : BorderSide.none,
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFCCCCCC)),
      ),
    );
  }
}

class _FileItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final Color color;

  const _FileItem({required this.icon, required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(fontSize: 12, color: Color(0xFFCCCCCC))),
        ],
      ),
    );
  }
}