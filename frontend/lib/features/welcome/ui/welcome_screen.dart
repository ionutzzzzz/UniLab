import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../providers/app_provider.dart';
import '../../../shell/title_strip.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: ui.colors.canvas,
      body: Column(
        children: [
          const TitleStrip(),
          Expanded(
            child: Row(
              children: [
                // Left side - Brand and Actions
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: EdgeInsets.all(ui.spacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        Row(
                          children: [
                            Image.asset('assets/logo.png', width: 64, height: 64),
                            SizedBox(width: ui.spacing.lg),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UiText(
                                  text: 'UniLab',
                                  variant: UiTextVariant.title,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: ui.colors.accent,
                                ),
                                UiText(
                                  text: 'Unified Laboratory for Science & Engineering',
                                  variant: UiTextVariant.label,
                                  color: ui.colors.textSecondary,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: ui.spacing.xl),
                        UiText(
                          text: 'Start',
                          variant: UiTextVariant.title,
                          color: ui.colors.textPrimary,
                        ),
                        SizedBox(height: ui.spacing.lg),
                        _ActionItem(
                          icon: LucideIcons.folderPlus,
                          title: 'New Project',
                          subtitle: 'Create a new project in a new directory',
                          onTap: () async {
                            String? path = await FilePicker.platform.getDirectoryPath(
                              dialogTitle: 'Select Directory for New Project',
                            );
                            if (path != null) {
                              appProvider.setProjectRoot(path);
                            }
                          },
                        ),
                        _ActionItem(
                          icon: LucideIcons.folderOpen,
                          title: 'Open Project',
                          subtitle: 'Open an existing project directory',
                          onTap: () async {
                            String? path = await FilePicker.platform.getDirectoryPath(
                              dialogTitle: 'Open Project Directory',
                            );
                            if (path != null) {
                              appProvider.setProjectRoot(path);
                            }
                          },
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                // Right side - Recent Projects
                Expanded(
                  flex: 3,
                  child: Container(
                    color: ui.colors.panel,
                    padding: EdgeInsets.all(ui.spacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UiText(
                          text: 'Recent',
                          variant: UiTextVariant.title,
                          color: ui.colors.textPrimary,
                        ),
                        SizedBox(height: ui.spacing.lg),
                        if (appProvider.recentProjects.isEmpty)
                          Expanded(
                            child: Center(
                              child: UiText(
                                text: 'No recent projects',
                                variant: UiTextVariant.body,
                                color: ui.colors.textMuted,
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: appProvider.recentProjects.length,
                              itemBuilder: (context, index) {
                                final projectPath = appProvider.recentProjects[index];
                                return _RecentProjectItem(
                                  path: projectPath,
                                  onTap: () => appProvider.setProjectRoot(projectPath),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatefulWidget {
  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_ActionItem> createState() => _ActionItemState();
}

class _ActionItemState extends State<_ActionItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: ui.spacing.md),
          padding: EdgeInsets.all(ui.spacing.md),
          decoration: BoxDecoration(
            color: _isHovered ? ui.colors.hover : Colors.transparent,
            borderRadius: ui.spacing.radiusMd,
            border: Border.all(
              color: _isHovered ? ui.colors.accent.withValues(alpha: 0.3) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: ui.colors.accent, size: 24),
              SizedBox(width: ui.spacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiText(
                    text: widget.title,
                    variant: UiTextVariant.body,
                    fontWeight: FontWeight.bold,
                  ),
                  UiText(
                    text: widget.subtitle,
                    variant: UiTextVariant.caption,
                    color: ui.colors.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentProjectItem extends StatefulWidget {
  const _RecentProjectItem({
    required this.path,
    required this.onTap,
  });

  final String path;
  final VoidCallback onTap;

  @override
  State<_RecentProjectItem> createState() => _RecentProjectItemState();
}

class _RecentProjectItemState extends State<_RecentProjectItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final name = p.basename(widget.path);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: ui.spacing.xs),
          padding: EdgeInsets.symmetric(horizontal: ui.spacing.md, vertical: ui.spacing.sm),
          decoration: BoxDecoration(
            color: _isHovered ? ui.colors.hover : Colors.transparent,
            borderRadius: ui.spacing.radiusSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UiText(
                text: name,
                variant: UiTextVariant.body,
                fontWeight: FontWeight.bold,
                color: _isHovered ? ui.colors.accent : ui.colors.textPrimary,
              ),
              UiText(
                text: widget.path,
                variant: UiTextVariant.caption,
                color: ui.colors.textMuted,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
