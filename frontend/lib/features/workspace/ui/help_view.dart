import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_input_field.dart';

class HelpView extends StatefulWidget {
  const HelpView({super.key});

  @override
  State<HelpView> createState() => _HelpViewState();
}

class _HelpViewState extends State<HelpView> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedTopic;

  final List<Map<String, dynamic>> _quickLinks = [
    {'title': 'Language Basics', 'icon': LucideIcons.bookOpen},
    {'title': 'Plotting Data', 'icon': LucideIcons.lineChart},
    {'title': 'Linear Algebra', 'icon': LucideIcons.grid},
    {'title': 'Optimization', 'icon': LucideIcons.zap},
  ];

  final List<Map<String, String>> _popularFunctions = [
    {'name': 'plot(x, y)', 'desc': '2D line plot'},
    {'name': 'surf(X, Y, Z)', 'desc': '3D shaded surface plot'},
    {'name': 'eig(A)', 'desc': 'Eigenvalues and eigenvectors'},
    {'name': 'inv(A)', 'desc': 'Matrix inverse'},
    {'name': 'fft(x)', 'desc': 'Fast Fourier Transform'},
    {'name': 'ode45(...)', 'desc': 'Solve differential equations'},
  ];

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);

    if (_selectedTopic != null) {
      return _buildTopicDetail(ui);
    }

    return Container(
      color: ui.colors.canvas,
      child: ListView(
        padding: EdgeInsets.all(ui.spacing.md),
        children: [
          // Search Bar
          UiInputField(
            controller: _searchController,
            hintText: 'Search documentation...',
            prefixIcon: LucideIcons.search,
            onSubmitted: (value) {
              // TODO: Implement search
            },
          ),
          const SizedBox(height: 20),

          // Quick Links Grid
          UiText(
            text: 'Getting Started'.toUpperCase(),
            variant: UiTextVariant.label,
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 0.5,
            color: ui.colors.textMuted,
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.5,
            ),
            itemCount: _quickLinks.length,
            itemBuilder: (context, index) {
              final link = _quickLinks[index];
              return _buildQuickLinkCard(ui, link);
            },
          ),
          const SizedBox(height: 24),

          // Popular Functions
          UiText(
            text: 'Popular Functions'.toUpperCase(),
            variant: UiTextVariant.label,
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 0.5,
            color: ui.colors.textMuted,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: ui.colors.panel,
              borderRadius: ui.spacing.radiusMd,
              border: Border.all(color: ui.colors.divider.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: _popularFunctions.map((func) => _buildFunctionRow(ui, func)).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Community Section
          _buildCommunityCard(ui),
        ],
      ),
    );
  }

  Widget _buildQuickLinkCard(UiTheme ui, Map<String, dynamic> link) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _selectedTopic = link['title']),
        child: Container(
          padding: EdgeInsets.all(ui.spacing.sm),
          decoration: BoxDecoration(
            color: ui.colors.panel,
            borderRadius: ui.spacing.radiusMd,
            border: Border.all(color: ui.colors.divider.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ui.colors.accent.withValues(alpha: 0.1),
                  borderRadius: ui.spacing.radiusSm,
                ),
                child: Icon(link['icon'], size: 14, color: ui.colors.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: UiText(
                  text: link['title'],
                  variant: UiTextVariant.label,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionRow(UiTheme ui, Map<String, String> func) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: ui.spacing.sm, vertical: ui.spacing.xs + 2),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.1))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiText(
                    text: func['name']!,
                    variant: UiTextVariant.codeBody,
                    fontSize: 11,
                    color: ui.colors.accent,
                  ),
                  UiText(
                    text: func['desc']!,
                    variant: UiTextVariant.caption,
                    fontSize: 9,
                    color: ui.colors.textMuted,
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 12, color: ui.colors.textDisabled),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityCard(UiTheme ui) {
    return Container(
      padding: EdgeInsets.all(ui.spacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ui.colors.accent.withValues(alpha: 0.1),
            ui.colors.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: ui.spacing.radiusMd,
        border: Border.all(color: ui.colors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.users, size: 24, color: ui.colors.accent),
          SizedBox(height: ui.spacing.sm),
          UiText(
            text: 'Need more help?',
            variant: UiTextVariant.label,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: ui.spacing.xs),
          UiText(
            text: 'Join the UniLab community to share scripts and get help.',
            variant: UiTextVariant.caption,
            textAlign: TextAlign.center,
            color: ui.colors.textSecondary,
          ),
          SizedBox(height: ui.spacing.md),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: ui.colors.accent,
              foregroundColor: ui.colors.textInverse,
              padding: EdgeInsets.symmetric(horizontal: ui.spacing.md, vertical: ui.spacing.xs),
              shape: RoundedRectangleBorder(borderRadius: ui.spacing.radiusMd),
            ),
            child: const Text('Visit Forum', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicDetail(UiTheme ui) {
    return Container(
      color: ui.colors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: ui.spacing.sm, vertical: ui.spacing.xs),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.3))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(LucideIcons.arrowLeft, size: 16, color: ui.colors.textSecondary),
                  onPressed: () => setState(() => _selectedTopic = null),
                  visualDensity: VisualDensity.compact,
                ),
                UiText(
                  text: _selectedTopic!,
                  variant: UiTextVariant.label,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(ui.spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiText(
                    text: 'Documentation for $_selectedTopic',
                    variant: UiTextVariant.title,
                    fontSize: 18,
                  ),
                  SizedBox(height: ui.spacing.md),
                  UiText(
                    text: 'This is a placeholder for the actual documentation content. ',
                    variant: UiTextVariant.body,
                    color: ui.colors.textSecondary,
                  ),
                  SizedBox(height: ui.spacing.lg),
                  _buildSampleCode(ui),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleCode(UiTheme ui) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ui.spacing.md),
      decoration: BoxDecoration(
        color: ui.colors.panel,
        borderRadius: ui.spacing.radiusMd,
        border: Border.all(color: ui.colors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.code, size: 14, color: ui.colors.textMuted),
              SizedBox(width: ui.spacing.xs),
              UiText(
                text: 'Example',
                variant: UiTextVariant.caption,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          SizedBox(height: ui.spacing.sm),
          UiText(
            text: 'x = linspace(0, 2*pi, 100);\ny = sin(x);\nplot(x, y);',
            variant: UiTextVariant.codeBody,
            fontSize: 12,
            color: ui.colors.textPrimary,
          ),
        ],
      ),
    );
  }
}