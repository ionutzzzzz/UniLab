import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../theme/ui_theme.dart';
import '../../../../widgets/ui_text.dart';

class UniLabPdfViewer extends StatelessWidget {
  final String path;
  final String name;

  const UniLabPdfViewer({super.key, required this.path, required this.name});

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Container(
      color: ui.colors.canvas,
      child: Column(
        children: [
          Expanded(
            child: SfPdfViewer.file(
              io.File(path),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: ui.colors.panelHeader,
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, size: 14, color: ui.colors.danger),
                const SizedBox(width: 8),
                UiText(text: name, variant: UiTextVariant.caption),
                const Spacer(),
                UiText(text: 'PDF Document', variant: UiTextVariant.caption, color: ui.colors.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
