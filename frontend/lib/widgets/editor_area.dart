import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

class EditorArea extends StatelessWidget {
  final CodeController codeController;

  const EditorArea({super.key, required this.codeController});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    if (appProvider.activeFile == null) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.code, size: 48, color: Theme.of(context).dividerColor),
              const SizedBox(height: 16),
              Text(
                'Open a script to begin.', 
                style: TextStyle(color: Theme.of(context).dividerColor, fontSize: 13)
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Custom Desktop IDE Tabs
          Container(
            height: 35,
            color: Theme.of(context).canvasColor, // Darker bg for the tab bar strip
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: appProvider.openFiles.length,
              itemBuilder: (context, index) {
                final file = appProvider.openFiles[index];
                final isActive = index == appProvider.activeFileIndex;
                
                return GestureDetector(
                  onTap: () => appProvider.setActiveFile(index),
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    decoration: BoxDecoration(
                      color: isActive ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).canvasColor,
                      border: Border(
                        top: BorderSide(
                          color: isActive ? Theme.of(context).primaryColor : Colors.transparent, 
                          width: 2.0
                        ),
                        right: BorderSide(color: Theme.of(context).dividerColor, width: 1.0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file, 
                          size: 14, 
                          color: isActive ? Theme.of(context).primaryColor : Colors.grey
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            file.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isActive ? Colors.white : const Color(0xFF999999),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => appProvider.closeFile(index),
                            hoverColor: Theme.of(context).hoverColor,
                            borderRadius: BorderRadius.circular(2.0),
                            child: const Padding(
                              padding: EdgeInsets.all(2.0),
                              child: Icon(Icons.close, size: 14, color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // File Breadcrumbs (Optional but highly requested IDE feel)
          Container(
            height: 24,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1.0)),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              appProvider.activeFile!.path.isNotEmpty 
                  ? appProvider.activeFile!.path 
                  : 'Workspace > ${appProvider.activeFile!.name}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
            ),
          ),
          // Editor Body
          Expanded(
            child: CodeTheme(
              data: CodeThemeData(styles: monokaiSublimeTheme),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CodeField(
                    controller: codeController,
                    onChanged: (val) => appProvider.updateActiveFileContent(val),
                    textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.4),
                    cursorColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}