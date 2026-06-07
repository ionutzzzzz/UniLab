import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../../../../theme/ui_theme.dart';
import '../../../../widgets/ui_text.dart';
import '../../../../widgets/ui_button.dart';
import '../../../../widgets/ui_glass_container.dart';
import '../../../../providers/app_provider.dart';
import 'dart:io' as io;

class FileBackstage extends StatefulWidget {
  const FileBackstage({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const FileBackstage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0); // Slide from left (more traditional)
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: animation.drive(tween), child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  State<FileBackstage> createState() => _FileBackstageState();
}

class _FileBackstageState extends State<FileBackstage> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'New', 'icon': LucideIcons.filePlus2},
    {'title': 'Open', 'icon': LucideIcons.folderOpen},
    {'title': 'Save', 'icon': LucideIcons.save},
    {'title': 'Save As', 'icon': LucideIcons.fileOutput},
    {'divider': true},
    {'title': 'Export', 'icon': LucideIcons.share2},
    {'title': 'Print', 'icon': LucideIcons.printer},
    {'divider': true},
    {'title': 'Close Project', 'icon': LucideIcons.logOut},
  ];

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: ui.colors.canvas,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: ui.colors.accent,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 8),
                      UiText(
                        text: 'UniLab',
                        variant: UiTextVariant.body,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      if (item.containsKey('divider')) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
                        );
                      }
                      final isSelected = _selectedIndex == index;
                      return _BackstageMenuItem(
                        title: item['title'],
                        icon: item['icon'],
                        isSelected: isSelected,
                        onTap: () => _handleMenuTap(index, item['title'], appProvider),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UiText(
                        text: 'v1.0.0'.toUpperCase(),
                        variant: UiTextVariant.caption,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: appProvider.backendStatus == BackendStatus.connected 
                                  ? Colors.greenAccent 
                                  : Colors.orangeAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          UiText(
                            text: appProvider.backendStatus.name,
                            variant: UiTextVariant.caption,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(64, 80, 64, 40),
              child: _buildContent(ui, appProvider),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuTap(int index, String title, AppProvider appProvider) {
    if (title == 'Save') {
      appProvider.saveActiveFile();
      Navigator.pop(context);
    } else if (title == 'Save As') {
      appProvider.saveActiveFileAs();
      Navigator.pop(context);
    } else if (title == 'Close Project') {
      Navigator.pop(context);
      appProvider.resetToWelcome();
    } else if (title == 'Print') {
      appProvider.printActiveFile();
      Navigator.pop(context);
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  Widget _buildContent(UiTheme ui, AppProvider appProvider) {
    final title = _menuItems[_selectedIndex]['title'] ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            UiText(text: title, variant: UiTextVariant.title, fontSize: 40, fontWeight: FontWeight.w200),
            const SizedBox(width: 16),
            UiText(
              text: 'Project: ${appProvider.projectRoot != null ? p.basename(appProvider.projectRoot!) : 'None'}', 
              variant: UiTextVariant.caption, 
              color: ui.colors.textMuted
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: ui.colors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 48),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(
                key: ValueKey('content_$_selectedIndex'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title == 'New') _buildNewSection(ui, appProvider),
                  if (title == 'Open') _buildOpenSection(ui, appProvider),
                  if (title == 'Export') _buildExportSection(ui, appProvider),
                  if (title == 'Save' || title == 'Save As') _buildSaveSection(ui, appProvider),
                  if (title == 'Print') const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewSection(UiTheme ui, AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(text: 'Templates', variant: UiTextVariant.label, fontWeight: FontWeight.bold),
        const SizedBox(height: 24),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            _buildTemplateCard(
              ui, 
              'Blank Script', 
              LucideIcons.fileCode2, 
              'Start with a clean .m file',
              onTap: () {
                appProvider.addNewFile();
                Navigator.pop(context);
              }
            ),
            _buildTemplateCard(
              ui, 
              'Function', 
              LucideIcons.functionSquare, 
              'Template for reusable logic',
              onTap: () {
                appProvider.createProjectFile('new_function.m', 'function [out] = new_function(in)\n\t% NEW_FUNCTION Summary of this function goes here\n\t% Detailed explanation goes here\n\tout = in;\nend');
                Navigator.pop(context);
              }
            ),
            _buildTemplateCard(
              ui, 
              'Live Script', 
              LucideIcons.sparkles, 
              'Rich text and embedded code',
              onTap: () {
                appProvider.addNewFile();
                Navigator.pop(context);
              }
            ),
            _buildTemplateCard(
              ui, 
              'Data Import', 
              LucideIcons.database, 
              'Import and analyze data files',
              onTap: () {
                appProvider.openImportDataTab();
                Navigator.pop(context);
              }
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOpenSection(UiTheme ui, AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            UiButton(
              label: 'Browse Files...', 
              icon: LucideIcons.fileSearch, 
              variant: UiButtonVariant.primary, 
              onPressed: () {
                appProvider.openFilePicker();
                Navigator.pop(context);
              }
            ),
            const SizedBox(width: 16),
            UiButton(
              label: 'Open Folder...', 
              icon: LucideIcons.folderSearch, 
              variant: UiButtonVariant.secondary, 
              onPressed: () {
                appProvider.openFolderPicker();
                Navigator.pop(context);
              }
            ),
          ],
        ),
        const SizedBox(height: 64),
        Row(
          children: [
            const Icon(LucideIcons.clock, size: 18),
            const SizedBox(width: 12),
            UiText(text: 'Recent Files', variant: UiTextVariant.label, fontWeight: FontWeight.bold),
          ],
        ),
        const SizedBox(height: 24),
        if (appProvider.recentFiles.isEmpty)
          UiGlassContainer(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: UiText(text: 'No recent files found in this workspace.', variant: UiTextVariant.body, color: ui.colors.textMuted),
            ),
          )
        else
          ...appProvider.recentFiles.map((path) => _buildRecentItem(
            ui, 
            p.basename(path), 
            path,
            onTap: () {
              appProvider.openFile(io.File(path));
              Navigator.pop(context);
            }
          )),
      ],
    );
  }

  Widget _buildSaveSection(UiTheme ui, AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (appProvider.activeFile != null) ...[
          UiText(text: 'Current File', variant: UiTextVariant.label, fontWeight: FontWeight.bold),
          const SizedBox(height: 16),
          _buildRecentItem(
            ui, 
            appProvider.activeFile!.name, 
            appProvider.activeFile!.path.isEmpty ? 'Not saved yet' : appProvider.activeFile!.path,
            icon: LucideIcons.fileEdit,
          ),
          const SizedBox(height: 48),
        ],
        UiText(text: 'Project Information', variant: UiTextVariant.label, fontWeight: FontWeight.bold),
        const SizedBox(height: 24),
        UiGlassContainer(
          padding: const EdgeInsets.all(24),
          opacity: 0.1,
          child: Column(
            children: [
              _buildInfoRow(ui, LucideIcons.folder, 'Project Root', appProvider.projectRoot ?? 'No project opened'),
              const Divider(height: 32),
              _buildInfoRow(ui, LucideIcons.files, 'Files in Project', '${appProvider.projectFiles.length} items'),
              const Divider(height: 32),
              _buildInfoRow(ui, LucideIcons.calendar, 'Last Modified', 'Today'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(UiTheme ui, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ui.colors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: ui.colors.accent),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UiText(text: label, variant: UiTextVariant.caption, color: ui.colors.textMuted),
            UiText(text: value, variant: UiTextVariant.body, fontWeight: FontWeight.w600),
          ],
        ),
      ],
    );
  }

  Widget _buildExportSection(UiTheme ui, AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(text: 'Export Options', variant: UiTextVariant.label, fontWeight: FontWeight.bold),
        const SizedBox(height: 24),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            _buildTemplateCard(ui, 'PDF Document', LucideIcons.fileType, 'Export current work to PDF', onTap: () {
               appProvider.exportToPdf();
               Navigator.pop(context);
            }),
            _buildTemplateCard(ui, 'Python Script', LucideIcons.code, 'Transpile to Python', onTap: () {
               appProvider.exportToPython();
               Navigator.pop(context);
            }),
            _buildTemplateCard(ui, 'HTML Report', LucideIcons.fileJson, 'Generate interactive report', onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report generation coming soon.')));
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplateCard(UiTheme ui, String title, IconData icon, String desc, {VoidCallback? onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: UiGlassContainer(
          width: 240,
          padding: const EdgeInsets.all(24),
          opacity: 0.1, // Subtler glass effect
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ui.colors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: ui.colors.accent, size: 28),
              ),
              const SizedBox(height: 24),
              UiText(text: title, variant: UiTextVariant.body, fontWeight: FontWeight.bold),
              const SizedBox(height: 8),
              UiText(text: desc, variant: UiTextVariant.caption, color: ui.colors.textMuted),
              const SizedBox(height: 20),
              Row(
                children: [
                  UiText(text: 'CREATE', variant: UiTextVariant.caption, fontWeight: FontWeight.bold, color: ui.colors.accent),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.arrowRight, size: 12, color: ui.colors.accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentItem(UiTheme ui, String title, String path, {IconData icon = LucideIcons.file, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: UiGlassContainer(
            padding: const EdgeInsets.all(16),
            opacity: 0.1, // Subtler glass effect
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ui.colors.panel,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: ui.colors.accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UiText(text: title, variant: UiTextVariant.body, fontWeight: FontWeight.w600),
                      UiText(
                        text: path, 
                        variant: UiTextVariant.caption, 
                        color: ui.colors.textMuted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 16, color: ui.colors.textMuted.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackstageMenuItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _BackstageMenuItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_BackstageMenuItem> createState() => _BackstageMenuItemState();
}

class _BackstageMenuItemState extends State<_BackstageMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? Colors.white.withValues(alpha: 0.15) 
                : (_isHovered ? Colors.white.withValues(alpha: 0.08) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected 
                  ? Colors.white.withValues(alpha: 0.2) 
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon, 
                size: 20, 
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              UiText(
                text: widget.title,
                variant: UiTextVariant.body,
                color: Colors.white,
                fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}