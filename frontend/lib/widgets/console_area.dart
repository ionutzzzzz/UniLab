import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ConsoleArea extends StatelessWidget {
  const ConsoleArea({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tool Window Header
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor, width: 1.0),
                bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1.0),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Command Window', 
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFCCCCCC))
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => appProvider.clearConsole(),
                    hoverColor: Theme.of(context).hoverColor,
                    borderRadius: BorderRadius.circular(4.0),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.block, size: 14, color: Color(0xFF999999)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Console Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: SelectableText(
                appProvider.consoleOutput.isEmpty ? '>> ' : appProvider.consoleOutput,
                style: const TextStyle(color: Color(0xFF4EC9B0), fontFamily: 'monospace', fontSize: 13, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}