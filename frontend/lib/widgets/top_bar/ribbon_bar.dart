import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../screens/settings_screen.dart';

/// Enhanced Ribbon Bar with professional layout similar to MATLAB/Office
class RibbonBar extends StatefulWidget {
  const RibbonBar({super.key});

  @override
  State<RibbonBar> createState() => _RibbonBarState();
}

class _RibbonBarState extends State<RibbonBar> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final ribbonBgColor = Theme.of(context).canvasColor;
    final borderColor = Theme.of(context).dividerColor;

    return Container(
      height: 95, // Slightly more compact
      decoration: BoxDecoration(
        color: ribbonBgColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ribbon Tab Navigation
          Container(
            height: 30, // Tighter tab bar
            color: Theme.of(context).canvasColor,
            child: Row(
              children: [
                // App Logo / Title
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'UniLab',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      fontSize: 13,
                    ),
                  ),
                ),
                // Ribbon Tabs
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border(
                        top: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                        left: BorderSide(color: borderColor),
                        right: BorderSide(color: borderColor),
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: const Color(0xFF999999),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                    labelStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    tabs: const [
                      Tab(height: 30, text: 'HOME'),
                      Tab(height: 30, text: 'PLOTS'),
                      Tab(height: 30, text: 'EDITOR'),
                      Tab(height: 30, text: 'TOOLS'),
                      Tab(height: 30, text: 'VIEW'),
                    ],
                  ),
                ),
                // Quick Actions in Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuickActionButton(
                        context,
                        Icons.undo,
                        'Undo',
                        () {},
                      ),
                      _buildQuickActionButton(
                        context,
                        Icons.redo,
                        'Redo',
                        () {},
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionButton(
                        context,
                        Icons.help_outline,
                        'Help',
                        () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Ribbon Content Area
          Expanded(
            child: Container(
              color: ribbonBgColor,
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildHomeTab(context, appProvider),
                  _buildPlotsTab(context),
                  _buildEditorTab(context, appProvider),
                  _buildToolsTab(context, appProvider),
                  _buildViewTab(context, appProvider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, AppProvider appProvider) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      children: [
        _RibbonGroup(
          title: 'FILE',
          children: [
            _RibbonButton(
              icon: Icons.note_add,
              label: 'New',
              onPressed: () => appProvider.addNewFile(),
              isLarge: true,
              tooltip: 'Create a new script file (Ctrl+N)',
            ),
            _RibbonButton(
              icon: Icons.folder_open,
              label: 'Open',
              onPressed: () {},
              tooltip: 'Open an existing file (Ctrl+O)',
            ),
            _RibbonButton(
              icon: Icons.save,
              label: 'Save',
              onPressed: () {},
              tooltip: 'Save current file (Ctrl+S)',
            ),
          ],
        ),
        _RibbonGroup(
          title: 'EXECUTION',
          children: [
            _RibbonButton(
              icon: Icons.play_arrow,
              label: 'Run',
              iconColor: const Color(0xFF4EC9B0),
              onPressed: () => appProvider.runActiveFile(),
              isLarge: true,
              tooltip: 'Run the active script (F5)',
            ),
            _RibbonButton(
              icon: Icons.playlist_play,
              label: 'Run Section',
              onPressed: () {},
              tooltip: 'Run the current section (Ctrl+Enter)',
            ),
            _RibbonButton(
              icon: Icons.stop,
              label: 'Stop',
              iconColor: const Color(0xFFF48771),
              onPressed: () {},
              tooltip: 'Stop execution',
            ),
          ],
        ),
        _RibbonGroup(
          title: 'SAMPLES',
          children: appProvider.availableSamples.take(8).map((file) {
            final fileName = file.path.split('/').last.replaceAll('.m', '');
            return _RibbonButton(
              icon: Icons.science,
              label: fileName.length > 10 ? '${fileName.substring(0, 10)}...' : fileName,
              onPressed: () => appProvider.openSample(file),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlotsTab(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      children: [
        _RibbonGroup(
          title: 'FIGURES',
          children: [
            _RibbonButton(
              icon: Icons.show_chart,
              label: 'New Figure',
              onPressed: () {},
              isLarge: true,
            ),
            _RibbonButton(
              icon: Icons.refresh,
              label: 'Refresh',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.delete_sweep,
              label: 'Clear All',
              onPressed: () {},
            ),
          ],
        ),
        _RibbonGroup(
          title: 'EXPORT',
          children: [
            _RibbonButton(
              icon: Icons.image,
              label: 'PNG',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.image,
              label: 'PDF',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.insert_chart,
              label: 'SVG',
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditorTab(BuildContext context, AppProvider appProvider) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      children: [
        _RibbonGroup(
          title: 'EDIT',
          children: [
            _RibbonButton(
              icon: Icons.content_cut,
              label: 'Cut',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.content_copy,
              label: 'Copy',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.content_paste,
              label: 'Paste',
              isLarge: true,
              onPressed: () {},
            ),
          ],
        ),
        _RibbonGroup(
          title: 'FIND & REPLACE',
          children: [
            _RibbonButton(
              icon: Icons.search,
              label: 'Find',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.find_replace,
              label: 'Replace',
              isLarge: true,
              onPressed: () {},
            ),
          ],
        ),
        _RibbonGroup(
          title: 'FORMAT',
          children: [
            _RibbonButton(
              icon: Icons.format_indent_increase,
              label: 'Indent',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.format_indent_decrease,
              label: 'Dedent',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.comment,
              label: 'Comment',
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolsTab(BuildContext context, AppProvider appProvider) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      children: [
        _RibbonGroup(
          title: 'ENVIRONMENT',
          children: [
            _RibbonButton(
              icon: Icons.settings,
              label: 'Settings',
              isLarge: true,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            _RibbonButton(
              icon: Icons.terminal,
              label: 'Terminal',
              onPressed: () {},
            ),
          ],
        ),
        _RibbonGroup(
          title: 'ANALYZE',
          children: [
            _RibbonButton(
              icon: Icons.analytics,
              label: 'Profiler',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.bug_report,
              label: 'Lint',
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewTab(BuildContext context, AppProvider appProvider) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      children: [
        _RibbonGroup(
          title: 'PANELS',
          children: [
            _RibbonButton(
              icon: Icons.folder,
              label: 'Files',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.dashboard,
              label: 'Workspace',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.terminal,
              label: 'Console',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.search,
              label: 'Search',
              onPressed: () {},
            ),
          ],
        ),
        _RibbonGroup(
          title: 'APPEARANCE',
          children: [
            _RibbonButton(
              icon: Icons.dark_mode,
              label: 'Dark Mode',
              onPressed: () {},
              isActive: true,
            ),
            _RibbonButton(
              icon: Icons.zoom_in,
              label: 'Zoom In',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.zoom_out,
              label: 'Zoom Out',
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 14),
        onPressed: onPressed,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
      ),
    );
  }
}

/// Group of ribbon buttons
class _RibbonGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _RibbonGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: children,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 2),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const VerticalDivider(width: 1, indent: 10, endIndent: 10),
          ],
        ),
      ),
    );
  }
}

/// Individual ribbon button
class _RibbonButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? iconColor;
  final bool isLarge;
  final bool isActive;
  final String? tooltip;

  const _RibbonButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor,
    this.isLarge = false,
    this.isActive = false,
    this.tooltip,
  });

  @override
  State<_RibbonButton> createState() => _RibbonButtonState();
}

class _RibbonButtonState extends State<_RibbonButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final content = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: widget.isLarge ? 48 : 42,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          decoration: BoxDecoration(
            color: _isHovered || widget.isActive
                ? Theme.of(context).hoverColor.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.zero,
            border: widget.isActive
                ? Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: widget.isLarge ? 18 : 12,
                color: widget.iconColor ?? (widget.isActive ? Theme.of(context).primaryColor : const Color(0xFFCCCCCC)),
              ),
              const SizedBox(height: 1),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 8,
                    color: widget.isActive ? Theme.of(context).primaryColor : const Color(0xFFCCCCCC),
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 500),
        child: content,
      );
    }
    return content;
  }
}
