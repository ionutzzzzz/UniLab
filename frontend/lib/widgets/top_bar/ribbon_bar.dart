import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

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
      height: 115, // Increased height for better spacing
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
            height: 32,
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                const SizedBox(width: 8),
                // Ribbon Tabs
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: ribbonBgColor,
                      border: Border(
                        left: BorderSide(color: borderColor),
                        right: BorderSide(color: borderColor),
                        top: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: const Color(0xFF999999),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                    labelStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                    tabs: const [
                      Tab(height: 32, text: 'HOME'),
                      Tab(height: 32, text: 'PLOTS'),
                      Tab(height: 32, text: 'EDITOR'),
                      Tab(height: 32, text: 'ANALYZE'),
                      Tab(height: 32, text: 'VIEW'),
                    ],
                  ),
                ),
                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuickActionButton(context, Icons.save_outlined, 'Save (Ctrl+S)', () => appProvider.saveActiveFile()),
                      _buildQuickActionButton(context, Icons.undo, 'Undo', () {}),
                      _buildQuickActionButton(context, Icons.redo, 'Redo', () {}),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Ribbon Content Area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildHomeTab(context, appProvider),
                _buildPlotsTab(context, appProvider),
                _buildEditorTab(context, appProvider),
                _buildAnalyzeTab(context, appProvider),
                _buildViewTab(context, appProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, AppProvider appProvider) {
    return ListView(
      primary: false,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      children: [
        _RibbonGroup(
          title: 'FILE',
          children: [
            _RibbonButton(
              icon: Icons.note_add_outlined,
              label: 'New Script',
              onPressed: () => appProvider.addNewFile(),
              isLarge: true,
              tooltip: 'Create a new script file (Ctrl+N)',
            ),
            _RibbonButton(
              icon: Icons.folder_open_outlined,
              label: 'Open',
              onPressed: () => appProvider.openFilePicker(),
              tooltip: 'Open an existing file (Ctrl+O)',
            ),
            _RibbonButton(
              icon: Icons.save_outlined,
              label: 'Save',
              onPressed: () => appProvider.saveActiveFile(),
              tooltip: 'Save current file (Ctrl+S)',
            ),
          ],
        ),
        _RibbonGroup(
          title: 'EXECUTION',
          children: [
            _RibbonButton(
              icon: Icons.play_circle_outline,
              label: 'Run',
              iconColor: const Color(0xFF4EC9B0),
              onPressed: () => appProvider.runActiveFile(),
              isLarge: true,
              tooltip: 'Run the active script (F5)',
            ),
            _RibbonButton(
              icon: Icons.playlist_play,
              label: 'Run Section',
              onPressed: () => appProvider.runActiveFile(),
              tooltip: 'Run current code section (Ctrl+Enter)',
            ),
            _RibbonButton(
              icon: Icons.stop_circle_outlined,
              label: 'Stop',
              iconColor: const Color(0xFFF48771),
              onPressed: () => appProvider.stopExecution(),
              tooltip: 'Stop execution',
            ),
          ],
        ),
        _RibbonGroup(
          title: 'WORKSPACE',
          children: [
            _RibbonButton(
              icon: Icons.cleaning_services_outlined,
              label: 'Clear',
              onPressed: () => appProvider.clearWorkspace(),
              tooltip: 'Clear variables from workspace',
            ),
            _RibbonButton(
              icon: Icons.import_export,
              label: 'Import Data',
              onPressed: () {},
            ),
          ],
        ),
        _RibbonGroup(
          title: 'SAMPLES',
          children: appProvider.availableSamples.take(5).map((file) {
            final fileName = file.path.split('/').last.replaceAll('.m', '');
            return _RibbonButton(
              icon: Icons.science_outlined,
              label: fileName.length > 12 ? '${fileName.substring(0, 12)}...' : fileName,
              onPressed: () => appProvider.openSample(file),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlotsTab(BuildContext context, AppProvider appProvider) {
    return ListView(
      primary: false,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      children: [
        _RibbonGroup(
          title: 'CREATE',
          children: [
            _RibbonButton(
              icon: Icons.show_chart,
              label: 'Plot',
              isLarge: true,
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.bar_chart,
              label: 'Bar',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.pie_chart_outline,
              label: 'Pie',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.scatter_plot,
              label: 'Scatter',
              onPressed: () {},
            ),
          ],
        ),
        _RibbonGroup(
          title: 'MANAGE',
          children: [
            _RibbonButton(
              icon: Icons.add_to_photos_outlined,
              label: 'New Figure',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.grid_on,
              label: 'Grid',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.legend_toggle,
              label: 'Legend',
              onPressed: () {},
            ),
          ],
        ),
        _RibbonGroup(
          title: 'EXPORT',
          children: [
            _RibbonButton(
              icon: Icons.image_outlined,
              label: 'PNG/JPG',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.picture_as_pdf_outlined,
              label: 'PDF',
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditorTab(BuildContext context, AppProvider appProvider) {
    return ListView(
      primary: false,
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
          title: 'NAVIGATE',
          children: [
            _RibbonButton(
              icon: Icons.find_in_page_outlined,
              label: 'Find',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.find_replace,
              label: 'Replace',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.redo,
              label: 'Go To Line',
              onPressed: () {},
            ),
          ],
        ),
        _RibbonGroup(
          title: 'CODE',
          children: [
            _RibbonButton(
              icon: Icons.comment_outlined,
              label: 'Comment',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.format_indent_increase,
              label: 'Indent',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.auto_awesome,
              label: 'Smart Fix',
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyzeTab(BuildContext context, AppProvider appProvider) {
    return ListView(
      primary: false,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      children: [
        _RibbonGroup(
          title: 'CHECK',
          children: [
            _RibbonButton(
              icon: Icons.bug_report_outlined,
              label: 'Analyze',
              isLarge: true,
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.spellcheck,
              label: 'Check Code',
              onPressed: () {},
            ),
          ],
        ),
        _RibbonGroup(
          title: 'PERFORMANCE',
          children: [
            _RibbonButton(
              icon: Icons.speed,
              label: 'Run Time',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.timer_outlined,
              label: 'Profiler',
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewTab(BuildContext context, AppProvider appProvider) {
    return ListView(
      primary: false,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      children: [
        _RibbonGroup(
          title: 'PANELS',
          children: [
            _RibbonButton(
              icon: Icons.folder_outlined,
              label: 'Files',
              onPressed: () {},
              isActive: true,
            ),
            _RibbonButton(
              icon: Icons.grid_view,
              label: 'Workspace',
              onPressed: () {},
              isActive: true,
            ),
            _RibbonButton(
              icon: Icons.terminal_outlined,
              label: 'Console',
              onPressed: () {},
              isActive: true,
            ),
          ],
        ),
        _RibbonGroup(
          title: 'LAYOUT',
          children: [
            _RibbonButton(
              icon: Icons.view_quilt_outlined,
              label: 'Default',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.fullscreen_exit,
              label: 'Minimize All',
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
          width: widget.isLarge ? 64 : 54,
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
                size: widget.isLarge ? 20 : 16,
                color: widget.iconColor ?? (widget.isActive ? Theme.of(context).primaryColor : const Color(0xFFCCCCCC).withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: widget.isActive ? Theme.of(context).primaryColor : const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                    height: 1.1,
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
