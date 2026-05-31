import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../theme/ui_theme.dart';
import '../../../../widgets/ui_text.dart';
import '../../../../widgets/ui_button.dart';
import '../../../../widgets/ui_input_field.dart';

class ImportDataView extends StatelessWidget {
  const ImportDataView({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Container(
      color: ui.colors.canvas,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wizard Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: ui.spacing.xl, vertical: ui.spacing.lg),
            decoration: BoxDecoration(
              color: ui.colors.panelHeader.withValues(alpha: 0.3),
              border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ui.colors.accent.withValues(alpha: 0.1),
                    borderRadius: ui.spacing.radiusMd,
                  ),
                  child: Icon(LucideIcons.database, size: 24, color: ui.colors.accent),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const UiText(
                      text: 'Import Data Wizard',
                      variant: UiTextVariant.title,
                      fontSize: 18,
                    ),
                    UiText(
                      text: 'Prepare your workspace by importing external datasets',
                      variant: UiTextVariant.caption,
                      color: ui.colors.textMuted,
                    ),
                  ],
                ),
                const Spacer(),
                UiButton(
                  label: 'Help',
                  variant: UiButtonVariant.ghost,
                  size: UiButtonSize.sm,
                  icon: LucideIcons.helpCircle,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          
          // Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(ui.spacing.xl),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(ui, LucideIcons.server, 'Database Configuration'),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Expanded(flex: 3, child: _FieldLabel(label: 'Host', child: UiInputField(hintText: 'e.g. localhost'))),
                          SizedBox(width: 16),
                          Expanded(flex: 1, child: _FieldLabel(label: 'Port', child: UiInputField(hintText: '5432'))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel(label: 'Database Name', child: UiInputField(hintText: 'production_db')),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(child: _FieldLabel(label: 'Username', child: UiInputField(hintText: 'admin'))),
                          SizedBox(width: 16),
                          Expanded(child: _FieldLabel(label: 'Password', child: UiInputField(hintText: '••••••••', suffixIcon: Icon(LucideIcons.eyeOff, size: 14)))),
                        ],
                      ),
                      
                      const SizedBox(height: 48),
                      
                      _buildSectionHeader(ui, LucideIcons.fileUp, 'Local File Import'),
                      const SizedBox(height: 20),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: ui.colors.panelHeader.withValues(alpha: 0.1),
                            borderRadius: ui.spacing.radiusLg,
                            border: Border.all(
                              color: ui.colors.divider,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.uploadCloud, size: 48, color: ui.colors.accent.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              UiText(
                                text: 'Drop data files here or click to browse',
                                variant: UiTextVariant.body,
                                fontWeight: FontWeight.w500,
                              ),
                              const SizedBox(height: 4),
                              UiText(
                                text: 'Supports CSV, TSV, JSON, and Text formats',
                                variant: UiTextVariant.caption,
                                color: ui.colors.textDisabled,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Footer Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          UiButton(
                            label: 'Reset Form',
                            variant: UiButtonVariant.ghost,
                            onPressed: () {},
                          ),
                          const SizedBox(width: 12),
                          UiButton(
                            label: 'Connect & Import Dataset',
                            variant: UiButtonVariant.primary,
                            icon: LucideIcons.chevronRight,
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(UiTheme ui, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ui.colors.accent),
        const SizedBox(width: 12),
        UiText(
          text: title.toUpperCase(),
          variant: UiTextVariant.label,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          fontSize: 11,
          color: ui.colors.textPrimary,
        ),
        const SizedBox(width: 16),
        Expanded(child: Divider(color: ui.colors.divider.withValues(alpha: 0.3))),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(
          text: label,
          variant: UiTextVariant.label,
          fontSize: 10,
          color: ui.colors.textMuted,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
