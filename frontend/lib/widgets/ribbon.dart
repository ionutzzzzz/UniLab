import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/app_provider.dart';
import '../screens/settings_screen.dart';
import '../theme/ui_theme.dart';

class UniLabRibbon extends StatefulWidget {
  const UniLabRibbon({super.key});

  @override
  State<UniLabRibbon> createState() => _UniLabRibbonState();
}

class _UniLabRibbonState extends State<UniLabRibbon> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final ui = UiTheme.of(context);

    return Container(
      height: 110, // Compact, desktop-class height
      decoration: BoxDecoration(
        color: ui.colors.panelHeader,
        border: Border(bottom: BorderSide(color: ui.colors.border, width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Bar Area
          Container(
            height: 30,
            color: ui.colors.ribbonTabs,
            child: Row(
              children: [
                // Highlighted "File" button area
                Container(
                  color: ui.colors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  alignment: Alignment.center,
                  child: Text('FILE', style: TextStyle(color: ui.colors.textInverse, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _AnimatedRibbonTab(
                        title: 'HOME',
                        isActive: _tabController.index == 0,
                        onTap: () => _tabController.animateTo(0),
                        ui: ui,
                      ),
                      _AnimatedRibbonTab(
                        title: 'EDITOR',
                        isActive: _tabController.index == 1,
                        onTap: () => _tabController.animateTo(1),
                        ui: ui,
                      ),
                      _AnimatedRibbonTab(
                        title: 'PLOTS',
                        isActive: _tabController.index == 2,
                        onTap: () => _tabController.animateTo(2),
                        ui: ui,
                      ),
                      _AnimatedRibbonTab(
                        title: 'APPS',
                        isActive: _tabController.index == 3,
                        onTap: () => _tabController.animateTo(3),
                        ui: ui,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Ribbon Body Content
          Expanded(
            child: Container(
              color: ui.colors.panelHeader,
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildHomeTab(context, appProvider, ui),
                  _buildEditorTab(context, appProvider, ui),
                  _buildPlotsTab(context, ui),
                  _buildSamplesTab(context, appProvider, ui),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, AppProvider appProvider, UiTheme ui) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _RibbonSection(
          title: 'FILE',
          ui: ui,
          children: [
            _RibbonButton(
              icon: LucideIcons.filePlus,
              label: 'New Script',
              onPressed: () => appProvider.addNewFile(),
              isLarge: true,
              ui: ui,
            ),
            _RibbonButton(
              icon: LucideIcons.folderOpen,
              label: 'Open',
              onPressed: () {},
              ui: ui,
            ),
            _RibbonButton(
              icon: LucideIcons.save,
              label: 'Save',
              onPressed: () {},
              ui: ui,
            ),
          ],
        ),
        _RibbonSection(
          title: 'EXECUTION',
          ui: ui,
          children: [
            _RibbonButton(
              icon: LucideIcons.play,
              label: 'Run',
              iconColor: ui.colors.success, // Soft code-green
              onPressed: () => appProvider.runActiveFile(),
              isLarge: true,
              ui: ui,
            ),
            _RibbonButton(
              icon: LucideIcons.square,
              label: 'Stop',
              iconColor: ui.colors.danger,
              onPressed: () {},
              ui: ui,
            ),
          ],
        ),
        _RibbonSection(
          title: 'ENVIRONMENT',
          ui: ui,
          children: [
            _RibbonButton(
              icon: LucideIcons.settings,
              label: 'Settings',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
              isLarge: true,
              ui: ui,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditorTab(BuildContext context, AppProvider appProvider, UiTheme ui) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _RibbonSection(
          title: 'EDIT',
          ui: ui,
          children: [
            _RibbonButton(
              icon: LucideIcons.scissors,
              label: 'Cut',
              onPressed: () {},
              ui: ui,
            ),
            _RibbonButton(
              icon: LucideIcons.copy,
              label: 'Copy',
              onPressed: () {},
              ui: ui,
            ),
            _RibbonButton(
              icon: LucideIcons.clipboard,
              label: 'Paste',
              onPressed: () {},
              isLarge: true,
              ui: ui,
            ),
          ],
        ),
        _RibbonSection(
          title: 'NAVIGATE',
          ui: ui,
          children: [
            _RibbonButton(
              icon: LucideIcons.search,
              label: 'Find',
              onPressed: () {},
              ui: ui,
            ),
            _RibbonButton(
              icon: LucideIcons.replace,
              label: 'Replace',
              onPressed: () {},
              ui: ui,
            ),
          ],
        ),
        _RibbonSection(
          title: 'FORMAT',
          ui: ui,
          children: [
            _RibbonButton(
              icon: LucideIcons.indent,
              label: 'Indent',
              onPressed: () {},
              ui: ui,
            ),
            _RibbonButton(
              icon: LucideIcons.messageSquare,
              label: 'Comment',
              onPressed: () {},
              ui: ui,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlotsTab(BuildContext context, UiTheme ui) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _RibbonSection(
          title: 'FIGURES',
          ui: ui,
          children: [
            _RibbonButton(
              icon: LucideIcons.lineChart,
              label: 'New Figure',
              onPressed: () {},
              isLarge: true,
              ui: ui,
            ),
            _RibbonButton(
              icon: LucideIcons.eraser,
              label: 'Clear All',
              onPressed: () {},
              ui: ui,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSamplesTab(BuildContext context, AppProvider appProvider, UiTheme ui) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _RibbonSection(
          title: 'AVAILABLE SAMPLES',
          ui: ui,
          children: appProvider.availableSamples.take(10).map((file) {
            final fileName = file.path.split('/').last;
            return _RibbonButton(
              icon: LucideIcons.flaskConical,
              label: fileName.replaceAll('.m', ''),
              onPressed: () => appProvider.openSample(file),
              ui: ui,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AnimatedRibbonTab extends StatefulWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  final UiTheme ui;

  const _AnimatedRibbonTab({
    required this.title,
    required this.isActive,
    required this.onTap,
    required this.ui,
  });

  @override
  State<_AnimatedRibbonTab> createState() => _AnimatedRibbonTabState();
}

class _AnimatedRibbonTabState extends State<_AnimatedRibbonTab> {
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
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isActive 
                ? widget.ui.colors.panelHeader 
                : (_isHovered ? widget.ui.colors.hover : Colors.transparent),
            border: Border(
              top: BorderSide(
                color: widget.isActive ? widget.ui.colors.accent : Colors.transparent,
                width: 2.0,
              ),
              left: BorderSide(color: widget.isActive ? widget.ui.colors.border : Colors.transparent, width: 1.0),
              right: BorderSide(color: widget.isActive ? widget.ui.colors.border : Colors.transparent, width: 1.0),
            ),
          ),
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w500,
              color: widget.isActive ? widget.ui.colors.textPrimary : widget.ui.colors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _RibbonSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final UiTheme ui;

  const _RibbonSection({required this.title, required this.children, required this.ui});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: ui.colors.divider, width: 1.0)),
      ),
      padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 4.0, bottom: 2.0),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title, 
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: ui.colors.textMuted)
          ),
        ],
      ),
    );
  }
}

class _RibbonButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? iconColor;
  final bool isLarge;
  final UiTheme ui;

  const _RibbonButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.ui,
    this.iconColor,
    this.isLarge = false,
  });

  @override
  State<_RibbonButton> createState() => _RibbonButtonState();
}

class _RibbonButtonState extends State<_RibbonButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.0),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              constraints: const BoxConstraints(
                minWidth: 50.0,
                minHeight: 72.0,
              ),
              decoration: BoxDecoration(
                color: _isHovered ? widget.ui.colors.hover : Colors.transparent,
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                  color: _isHovered ? widget.ui.colors.border : Colors.transparent,
                  width: 1.0,
                ),
                boxShadow: _isHovered ? widget.ui.colors.shadowSm : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon, 
                    size: 20,
                    color: widget.iconColor ?? widget.ui.colors.icon
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      widget.label, 
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10, 
                        color: widget.ui.colors.textSecondary, 
                        height: 1.1,
                        fontWeight: FontWeight.w500,
                      )
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}