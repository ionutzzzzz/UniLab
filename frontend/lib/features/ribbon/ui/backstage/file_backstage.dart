import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../../../../theme/ui_theme.dart';
import '../../../../widgets/ui_text.dart';
import '../../../../widgets/ui_button.dart';
import '../../../../providers/app_provider.dart';
import 'dart:io' as io;

class FileBackstage extends StatefulWidget {
  const FileBackstage({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const FileBackstage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
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
    {'title': 'Close', 'icon': LucideIcons.xCircle},
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
            color: ui.colors.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      if (item.containsKey('divider')) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                        text: 'UniLab v1.0.0',
                        variant: UiTextVariant.caption,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 4),
                      UiText(
                        text: 'Connected: ${appProvider.backendStatus.name}',
                        variant: UiTextVariant.caption,
                        color: Colors.white.withValues(alpha: 0.7),
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
    } else if (title == 'Close') {
      if (appProvider.activeFileIndex != -1) {
        appProvider.closeFile(appProvider.activeFileIndex);
      }
      Navigator.pop(context);
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
        UiText(text: title, variant: UiTextVariant.title, fontSize: 32, fontWeight: FontWeight.w300),
        const SizedBox(height: 48),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title == 'New') _buildNewSection(ui, appProvider),
                if (title == 'Open') _buildOpenSection(ui, appProvider),
                if (title == 'Export') _buildExportSection(ui, appProvider),
                if (title == 'Save' || title == 'Save As') _buildSaveSection(ui, appProvider),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewSection(UiTheme ui, AppProvider appProvider) {
    return Wrap(
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
        const SizedBox(height: 48),
        UiText(text: 'Recent Files', variant: UiTextVariant.label, fontWeight: FontWeight.bold),
        const SizedBox(height: 16),
        if (appProvider.recentFiles.isEmpty)
          UiText(text: 'No recent files', variant: UiTextVariant.body, color: ui.colors.textMuted)
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
          const SizedBox(height: 32),
        ],
        UiText(text: 'Project Root', variant: UiTextVariant.label, fontWeight: FontWeight.bold),
        const SizedBox(height: 16),
        _buildRecentItem(
          ui, 
          appProvider.projectRoot != null ? p.basename(appProvider.projectRoot!) : 'None', 
          appProvider.projectRoot ?? 'No project opened',
          icon: LucideIcons.folder,
        ),
      ],
    );
  }

  Widget _buildExportSection(UiTheme ui, AppProvider appProvider) {
    return Wrap(
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
    );
  }

  Widget _buildTemplateCard(UiTheme ui, String title, IconData icon, String desc, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: ui.spacing.radiusMd,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ui.colors.panel,
          borderRadius: ui.spacing.radiusMd,
          border: Border.all(color: ui.colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: ui.colors.accent, size: 32),
            const SizedBox(height: 16),
            UiText(text: title, variant: UiTextVariant.body, fontWeight: FontWeight.bold),
            const SizedBox(height: 8),
            UiText(text: desc, variant: UiTextVariant.caption, color: ui.colors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem(UiTheme ui, String title, String path, {IconData icon = LucideIcons.clock, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: ui.spacing.radiusSm,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ui.colors.panel,
          borderRadius: ui.spacing.radiusSm,
          border: Border.all(color: ui.colors.divider.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ui.colors.textMuted),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiText(text: title, variant: UiTextVariant.body, fontWeight: FontWeight.w500),
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
          ],
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
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? Colors.white.withValues(alpha: 0.2) 
                : (_isHovered ? Colors.white.withValues(alpha: 0.1) : Colors.transparent),
            border: Border(
              left: BorderSide(
                color: widget.isSelected ? Colors.white : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: Colors.white),
              const SizedBox(width: 16),
              UiText(
                text: widget.title,
                variant: UiTextVariant.body,
                color: Colors.white,
                fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}