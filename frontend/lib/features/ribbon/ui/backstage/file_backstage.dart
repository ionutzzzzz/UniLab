import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../theme/ui_theme.dart';
import '../../../../widgets/ui_text.dart';
import '../../../../widgets/ui_button.dart';
import '../../../../providers/app_provider.dart';

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

    return Scaffold(
      backgroundColor: ui.colors.canvas,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            color: ui.colors.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
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
                          child: Divider(color: Colors.black.withValues(alpha: 0.1), height: 1),
                        );
                      }
                      final isSelected = _selectedIndex == index;
                      return _BackstageMenuItem(
                        title: item['title'],
                        icon: item['icon'],
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(64, 80, 64, 40),
              child: _buildContent(ui),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(UiTheme ui) {
    final title = _menuItems[_selectedIndex]['title'] ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(text: title, variant: UiTextVariant.title, fontSize: 32, fontWeight: FontWeight.w300),
        const SizedBox(height: 48),
        if (title == 'New') _buildNewSection(ui),
        if (title == 'Open') _buildOpenSection(ui),
        if (title == 'Export') _buildExportSection(ui),
        if (title == 'Save' || title == 'Save As') _buildSaveSection(ui),
      ],
    );
  }

  Widget _buildNewSection(UiTheme ui) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        _buildTemplateCard(ui, 'Blank Script', LucideIcons.fileCode2, 'Start with a clean .m file'),
        _buildTemplateCard(ui, 'Function', LucideIcons.functionSquare, 'Template for reusable logic'),
        _buildTemplateCard(ui, 'App Designer', LucideIcons.layoutTemplate, 'Interactive UI template'),
        _buildTemplateCard(ui, 'Live Script', LucideIcons.sparkles, 'Rich text and embedded code'),
      ],
    );
  }

  Widget _buildOpenSection(UiTheme ui) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(text: 'Recent Files', variant: UiTextVariant.label, fontWeight: FontWeight.bold),
        const SizedBox(height: 16),
        _buildRecentItem(ui, 'analysis_v1.m', '~/Documents/UniLab/projects/analysis_v1.m'),
        _buildRecentItem(ui, 'simulation_data.csv', '~/Downloads/simulation_data.csv'),
        _buildRecentItem(ui, 'plot_utils.m', '~/Documents/UniLab/libs/plot_utils.m'),
        const SizedBox(height: 32),
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
      ],
    );
  }

  Widget _buildSaveSection(UiTheme ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(text: 'Save location', variant: UiTextVariant.label, fontWeight: FontWeight.bold),
        const SizedBox(height: 16),
        _buildRecentItem(ui, 'Current Project', '~/Documents/UniLab/projects/default'),
        _buildRecentItem(ui, 'Local Disk (C:)', '/home/user/'),
        _buildRecentItem(ui, 'Cloud Storage', 'Connected as john.doe@example.com'),
      ],
    );
  }

  Widget _buildExportSection(UiTheme ui) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        _buildTemplateCard(ui, 'PDF Document', LucideIcons.fileType, 'Export current work to PDF'),
        _buildTemplateCard(ui, 'Excel Spreadsheet', LucideIcons.table, 'Export variables to .xlsx'),
        _buildTemplateCard(ui, 'Python Script', LucideIcons.code, 'Transpile to Python'),
        _buildTemplateCard(ui, 'Standalone Executable', LucideIcons.box, 'Build as desktop binary'),
      ],
    );
  }

  Widget _buildTemplateCard(UiTheme ui, String title, IconData icon, String desc) {
    return Container(
      width: 200,
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
    );
  }

  Widget _buildRecentItem(UiTheme ui, String title, String path) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ui.colors.panel,
        borderRadius: ui.spacing.radiusSm,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.clock, size: 16, color: ui.colors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UiText(text: title, variant: UiTextVariant.body, fontWeight: FontWeight.w500),
                UiText(text: path, variant: UiTextVariant.caption, color: ui.colors.textMuted),
              ],
            ),
          ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? Colors.black.withValues(alpha: 0.15) 
                : (_isHovered ? Colors.black.withValues(alpha: 0.05) : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: Colors.black87),
              const SizedBox(width: 16),
              UiText(
                text: widget.title,
                variant: UiTextVariant.body,
                color: Colors.black87,
                fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
