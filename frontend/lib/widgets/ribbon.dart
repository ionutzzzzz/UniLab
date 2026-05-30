import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../screens/settings_screen.dart';

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
      height: 110, // Compact, desktop-class height
      decoration: BoxDecoration(
        color: ribbonBgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Bar Area
          Container(
            height: 30,
            color: ribbonBgColor,
            child: Row(
              children: [
                // Highlighted "File" button area
                Container(
                  color: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  alignment: Alignment.center,
                  child: const Text('FILE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    dividerColor: Colors.transparent,
                    indicatorColor: Theme.of(context).primaryColor,
                    indicatorWeight: 2.0,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF999999),
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: 'HOME'),
                      Tab(text: 'EDITOR'),
                      Tab(text: 'PLOTS'),
                      Tab(text: 'APPS'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Ribbon Body Content
          Expanded(
            child: Container(
              color: ribbonBgColor,
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildHomeTab(context, appProvider),
                  _buildEditorTab(context, appProvider),
                  _buildPlotsTab(context),
                  _buildSamplesTab(context, appProvider),
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
      children: [
        _RibbonSection(
          title: 'FILE',
          children: [
            _RibbonButton(
              icon: Icons.note_add,
              label: 'New Script',
              onPressed: () => appProvider.addNewFile(),
              isLarge: true,
            ),
            _RibbonButton(
              icon: Icons.folder_open,
              label: 'Open',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.save,
              label: 'Save',
              onPressed: () {},
            ),
          ],
        ),
        _RibbonSection(
          title: 'EXECUTION',
          children: [
            _RibbonButton(
              icon: Icons.play_arrow,
              label: 'Run',
              iconColor: const Color(0xFF4EC9B0), // Soft code-green
              onPressed: () => appProvider.runActiveFile(),
              isLarge: true,
            ),
            _RibbonButton(
              icon: Icons.stop,
              label: 'Stop',
              iconColor: const Color(0xFFF44336),
              onPressed: () {},
            ),
          ],
        ),
        _RibbonSection(
          title: 'ENVIRONMENT',
          children: [
            _RibbonButton(
              icon: Icons.settings,
              label: 'Settings',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
              isLarge: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditorTab(BuildContext context, AppProvider appProvider) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _RibbonSection(
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
              onPressed: () {},
              isLarge: true,
            ),
          ],
        ),
        _RibbonSection(
          title: 'NAVIGATE',
          children: [
            _RibbonButton(
              icon: Icons.search,
              label: 'Find',
              onPressed: () {},
            ),
            _RibbonButton(
              icon: Icons.find_replace,
              label: 'Replace',
              onPressed: () {},
            ),
          ],
        ),
        _RibbonSection(
          title: 'FORMAT',
          children: [
            _RibbonButton(
              icon: Icons.format_indent_increase,
              label: 'Indent',
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

  Widget _buildPlotsTab(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _RibbonSection(
          title: 'FIGURES',
          children: [
            _RibbonButton(
              icon: Icons.show_chart,
              label: 'New Figure',
              onPressed: () {},
              isLarge: true,
            ),
            _RibbonButton(
              icon: Icons.delete_sweep,
              label: 'Clear All',
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSamplesTab(BuildContext context, AppProvider appProvider) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _RibbonSection(
          title: 'AVAILABLE SAMPLES',
          children: appProvider.availableSamples.take(10).map((file) {
            final fileName = file.path.split('/').last;
            return _RibbonButton(
              icon: Icons.science,
              label: fileName.replaceAll('.m', ''),
              onPressed: () => appProvider.openSample(file),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RibbonSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _RibbonSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor, width: 1.0)),
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
            style: const TextStyle(fontSize: 9, color: Color(0xFF888888))
          ),
        ],
      ),
    );
  }
}

class _RibbonButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? iconColor;
  final bool isLarge;

  const _RibbonButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          hoverColor: Theme.of(context).hoverColor,
          borderRadius: BorderRadius.circular(4.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            constraints: BoxConstraints(minWidth: isLarge ? 50 : 40, maxWidth: isLarge ? 65 : 55),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon, 
                  size: isLarge ? 24 : 16, 
                  color: iconColor ?? const Color(0xFFCCCCCC)
                ),
                SizedBox(height: isLarge ? 3 : 1),
                Flexible(
                  child: Text(
                    label, 
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, color: Color(0xFFCCCCCC), height: 1.1)
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
