import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../models/sim_definition.dart';
import '../services/simulation_registry.dart';
import '../services/simulation_controller.dart';

class SimulationCatalogDialog extends StatefulWidget {
  const SimulationCatalogDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final ui = UiTheme.of(context);
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: ui.colors.border),
        ),
        child: const SizedBox(
          width: 1080,
          height: 740,
          child: SimulationCatalogDialog(),
        ),
      ),
    );
  }

  @override
  State<SimulationCatalogDialog> createState() => _SimulationCatalogDialogState();
}

class _SimulationCatalogDialogState extends State<SimulationCatalogDialog> {
  String _searchQuery = '';
  SimCategory? _selectedCategory;
  SimDimension? _selectedDimension;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    final allModels = SimulationRegistry.instance.all;

    // Filter models
    final filtered = allModels.where((m) {
      if (_selectedCategory != null && m.category != _selectedCategory) return false;
      if (_selectedDimension != null && m.dimension != _selectedDimension) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return m.name.toLowerCase().contains(q) ||
            m.description.toLowerCase().contains(q) ||
            m.tags.any((t) => t.toLowerCase().contains(q));
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Modal Header
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: ui.colors.panelHeader,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(bottom: BorderSide(color: ui.colors.divider)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.boxes, size: 20, color: ui.colors.accent),
              const SizedBox(width: 12),
              const UiText(
                text: 'UniLab Simulation Studio Library',
                variant: UiTextVariant.body,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              const Spacer(),
              IconButton(
                icon: Icon(LucideIcons.x, size: 18, color: ui.colors.textMuted),
                tooltip: 'Close Library',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Search & Filter Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: ui.colors.panel,
            border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              // Search field
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: ui.colors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search 28+ preinstalled simulations, formulas, or fields...',
                    hintStyle: TextStyle(color: ui.colors.textMuted, fontSize: 13),
                    prefixIcon: Icon(LucideIcons.search, size: 16, color: ui.colors.textMuted),
                    isDense: true,
                    filled: true,
                    fillColor: ui.colors.canvas,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: ui.colors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Dimension Filter Toggle (All, 2D, 3D)
              SegmentedButton<SimDimension?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('All')),
                  ButtonSegment(value: SimDimension.twoD, label: Text('2D')),
                  ButtonSegment(value: SimDimension.threeD, label: Text('3D Orbit')),
                ],
                selected: {_selectedDimension},
                onSelectionChanged: (set) => setState(() => _selectedDimension = set.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return ui.colors.accent.withValues(alpha: 0.2);
                    }
                    return Colors.transparent;
                  }),
                ),
              ),
            ],
          ),
        ),

        // Body: Categories Sidebar + Models Grid
        Expanded(
          child: Row(
            children: [
              // Category Sidebar
              Container(
                width: 220,
                decoration: BoxDecoration(
                  color: ui.colors.panelHeader.withValues(alpha: 0.6),
                  border: Border(right: BorderSide(color: ui.colors.divider)),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildCategoryTile('All Disciplines', null, LucideIcons.layoutGrid, ui),
                    ...SimCategory.values.map((cat) => _buildCategoryTile(cat.label, cat, cat.icon, ui)),
                  ],
                ),
              ),

              // Simulation Grid View
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.searchX, size: 48, color: ui.colors.textMuted),
                            const SizedBox(height: 12),
                            UiText(
                              text: 'No simulations matched "$_searchQuery"',
                              variant: UiTextVariant.body,
                              color: ui.colors.textMuted,
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.6,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildModelCard(filtered[index], ui);
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTile(String title, SimCategory? cat, IconData icon, UiTheme ui) {
    final isSelected = _selectedCategory == cat;
    return ListTile(
      dense: true,
      selected: isSelected,
      leading: Icon(icon, size: 16, color: isSelected ? ui.colors.accent : ui.colors.textMuted),
      title: UiText(
        text: title,
        variant: UiTextVariant.label,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? ui.colors.accent : ui.colors.textPrimary,
      ),
      onTap: () => setState(() => _selectedCategory = cat),
    );
  }

  Widget _buildModelCard(SimulationModel model, UiTheme ui) {
    final is3D = model.dimension == SimDimension.threeD;

    return Container(
      decoration: BoxDecoration(
        color: ui.colors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ui.colors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: is3D ? const Color(0xFF673AB7).withValues(alpha: 0.2) : ui.colors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: is3D ? const Color(0xFF673AB7) : ui.colors.accent, width: 0.8),
                ),
                child: Text(
                  is3D ? '3D ORBIT' : '2D PLANE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: is3D ? const Color(0xFFB39DDB) : ui.colors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: UiText(
                  text: model.category.label,
                  variant: UiTextVariant.label,
                  fontSize: 10,
                  color: ui.colors.textMuted,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          UiText(
            text: model.name,
            variant: UiTextVariant.body,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              model.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: ui.colors.textMuted, fontSize: 11, height: 1.3),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Wrap(
                spacing: 4,
                children: model.tags.take(2).map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ui.colors.canvas,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(t, style: TextStyle(color: ui.colors.textMuted, fontSize: 9)),
                  );
                }).toList(),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ui.colors.accent,
                  foregroundColor: ui.colors.textInverse,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
                icon: const Icon(LucideIcons.play, size: 13),
                label: const Text('Launch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  SimulationController.instance.selectModel(model.id);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
