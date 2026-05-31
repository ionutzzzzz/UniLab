import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart' as p;
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../providers/app_provider.dart';
import 'workspace_segmented.dart';
import 'variables_grid.dart';
import 'plots_gallery.dart';
import 'property_inspector.dart';
import 'help_view.dart';
import '../../../widgets/ui_icon_button.dart';

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
    final appProvider = p.Provider.of<AppProvider>(context);

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
        activeView = const HelpView();
        break;
      default:
        activeView = const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 240;

        return Container(
          color: ui.colors.panel,
          child: Column(
            children: [
              // Header
              Container(
                height: 38,
                padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
                decoration: BoxDecoration(
                  color: ui.colors.panelHeader,
                  border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: UiText(
                        text: 'Workspace'.toUpperCase(),
                        variant: UiTextVariant.label,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        fontSize: 10,
                        color: ui.colors.textMuted,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    UiIconButton(
                      icon: LucideIcons.refreshCcw, 
                      tooltip: 'Refresh Workspace', 
                      size: 24, 
                      iconSize: 14, 
                      onPressed: () => appProvider.refreshProjectFiles(),
                    ),
                    const SizedBox(width: 4),
                    UiIconButton(
                      icon: LucideIcons.trash2, 
                      tooltip: 'Clear Workspace', 
                      size: 24, 
                      iconSize: 14, 
                      onPressed: () => appProvider.clearWorkspace(),
                    ),
                  ],
                ),
              ),
              // Navigation
              WorkspaceSegmented(
                segments: _segments,
                activeSegment: _activeSegment,
                showLabels: !isCompact,
                onSegmentChanged: (segment) => setState(() => _activeSegment = segment),
              ),
              // Content
              Expanded(
                child: activeView,
              ),
            ],
          ),
        );
      }
    );
  }
}
