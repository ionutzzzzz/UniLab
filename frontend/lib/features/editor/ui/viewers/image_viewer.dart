import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../theme/ui_theme.dart';
import '../../../../widgets/ui_text.dart';
import 'image_view_helper.dart';

class ImageViewer extends StatelessWidget {
  final String path;
  final String name;

  const ImageViewer({super.key, required this.path, required this.name});

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    debugPrint('ImageViewer: Loading image from path: $path');
    
    return Container(
      color: ui.colors.canvas,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: InteractiveViewer(
                  maxScale: 5.0,
                  child: kIsWeb 
                    ? _buildWebPlaceholder(ui)
                    : buildPlatformImage(path, ui),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: ui.colors.panelHeader,
            child: Row(
              children: [
                Icon(Icons.image, size: 14, color: ui.colors.accent),
                const SizedBox(width: 8),
                UiText(text: name, variant: UiTextVariant.caption),
                const Spacer(),
                UiText(text: kIsWeb ? 'Web View' : 'Pinch to zoom', variant: UiTextVariant.caption, color: ui.colors.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebPlaceholder(UiTheme ui) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off, size: 64, color: ui.colors.textDisabled),
        const SizedBox(height: 16),
        const UiText(text: 'Image viewing on web is not yet supported in this build.', variant: UiTextVariant.body),
      ],
    );
  }
}
