import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import 'workspace_segmented.dart';
import 'variables_grid.dart';
import 'plots_gallery.dart';
import 'property_inspector.dart';

class WorkspacePanel extends StatefulWidget {
  const WorkspacePanel({super.key});

  @override
  State<WorkspacePanel> createState() => _WorkspacePanelState();
}

class _WorkspacePanelState extends State<WorkspacePanel> {
  String _activeSegment = 'Variables';
  final List<String> _segments = ['Variables', 'Inspector', 'Plots', 'Help'];

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);

    Widget activeView;
    switch (_activeSegment) {
      case 'Variables':
        activeView = const VariablesGrid();
        break;
      case 'Inspector':
        activeView = const PropertyInspector();
        break;
      case 'Plots':
        activeView = const PlotsGallery();
        break;
      case 'Help':
        activeView = Center(child: UiText(text: 'Help Pane', color: ui.colors.textMuted));
        break;
      default:
        activeView = const SizedBox.shrink();
    }

    return Container(
      color: ui.colors.panel,
      child: Column(
        children: [
          Container(
            height: 38,
            padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: ui.colors.panelHeader,
              border: Border(bottom: BorderSide(color: ui.colors.divider.withOpacity(0.5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    UiText(
                      text: 'Workspace',
                      variant: UiTextVariant.body,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ],
                ),
                Icon(LucideIcons.moreVertical, size: 14, color: ui.colors.textMuted),
              ],
            ),
          ),
          WorkspaceSegmented(
            segments: _segments,
            activeSegment: _activeSegment,
            onSegmentChanged: (segment) => setState(() => _activeSegment = segment),
          ),
          Expanded(
            child: activeView,
          ),
        ],
      ),
    );
  }
}
