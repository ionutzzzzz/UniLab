import 'package:flutter/material.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import 'workspace_segmented.dart';
import 'variables_grid.dart';

class WorkspacePanel extends StatefulWidget {
  const WorkspacePanel({super.key});

  @override
  State<WorkspacePanel> createState() => _WorkspacePanelState();
}

class _WorkspacePanelState extends State<WorkspacePanel> {
  String _activeSegment = 'Variables';
  final List<String> _segments = ['Variables', 'Inputs', 'Plots', 'Help'];

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);

    Widget activeView;
    switch (_activeSegment) {
      case 'Variables':
        activeView = const VariablesGrid();
        break;
      case 'Inputs':
        activeView = Center(child: UiText(text: 'Inputs Form', color: ui.colors.textMuted));
        break;
      case 'Plots':
        activeView = Center(child: UiText(text: 'Plots Thumbnails', color: ui.colors.textMuted));
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
            height: 36,
            padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: ui.colors.panelHeader,
              border: Border(bottom: BorderSide(color: ui.colors.divider)),
            ),
            child: UiText(
              text: 'WORKSPACE',
              variant: UiTextVariant.title,
              color: ui.colors.textPrimary,
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
