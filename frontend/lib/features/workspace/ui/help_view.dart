import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_text.dart';
import '../../../widgets/ui_input_field.dart';
import '../../../providers/app_provider.dart';
import 'guides_data.dart';

class HelpView extends StatefulWidget {
  const HelpView({super.key});

  @override
  State<HelpView> createState() => _HelpViewState();
}

class _HelpViewState extends State<HelpView> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedTopic;
  String? _helpContent;
  bool _isMarkdown = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _quickLinks = [
    {'title': 'Language Basics', 'icon': LucideIcons.bookOpen, 'topic': 'scripting'},
    {'title': 'Plotting Data', 'icon': LucideIcons.lineChart, 'topic': 'plotting'},
    {'title': 'Linear Algebra', 'icon': LucideIcons.grid, 'topic': 'matrices'},
    {'title': 'Optimization', 'icon': LucideIcons.zap, 'topic': 'optimization'},
  ];

  final List<Map<String, String>> _popularFunctions = [
    {'name': 'plot(x, y)', 'desc': '2D line plot', 'topic': 'plot'},
    {'name': 'surf(X, Y, Z)', 'desc': '3D shaded surface plot', 'topic': 'surf'},
    {'name': 'eig(A)', 'desc': 'Eigenvalues and eigenvectors', 'topic': 'eig'},
    {'name': 'inv(A)', 'desc': 'Matrix inverse', 'topic': 'inv'},
    {'name': 'fft(x)', 'desc': 'Fast Fourier Transform', 'topic': 'fft'},
    {'name': 'ode45(...)', 'desc': 'Solve differential equations', 'topic': 'ode45'},
    {'name': 'linspace(s, e, n)', 'desc': 'Linearly spaced vector', 'topic': 'linspace'},
    {'name': 'zeros(m, n)', 'desc': 'Matrix of zeros', 'topic': 'zeros'},
    {'name': 'rand(m, n)', 'desc': 'Uniformly distributed random numbers', 'topic': 'rand'},
    {'name': 'disp(x)', 'desc': 'Display value of variable', 'topic': 'disp'},
  ];

  Future<void> _fetchHelp(String topic) async {
    setState(() {
      _selectedTopic = topic;
      _isLoading = true;
      _helpContent = null;
      _isMarkdown = false;
    });

    // Check if it's a guide
    final guide = GuidesData.guides.where((g) => g.topic == topic).firstOrNull;
    if (guide != null) {
      setState(() {
        _helpContent = guide.content;
        _isMarkdown = true;
        _isLoading = false;
      });
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final content = await appProvider.fetchHelp(topic);

    if (mounted) {
      setState(() {
        _helpContent = content;
        _isLoading = false;
      });
    }
  }

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
              if (value.trim().isNotEmpty) {
                _fetchHelp(value.trim());
              }
            },
          ),
          const SizedBox(height: 20),

          // Guides Section
          UiText(
            text: 'User Guides'.toUpperCase(),
            variant: UiTextVariant.label,
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 0.5,
            color: ui.colors.textMuted,
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: GuidesData.guides.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final guide = GuidesData.guides[index];
              return _buildGuideCard(ui, guide);
            },
          ),
          const SizedBox(height: 24),

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

  Widget _buildGuideCard(UiTheme ui, HelpGuide guide) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _fetchHelp(guide.topic),
        child: Container(
          padding: EdgeInsets.all(ui.spacing.sm),
          decoration: BoxDecoration(
            color: ui.colors.panel,
            borderRadius: ui.spacing.radiusMd,
            border: Border.all(color: ui.colors.divider.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.book, size: 16, color: ui.colors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: UiText(
                  text: guide.title,
                  variant: UiTextVariant.label,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 14, color: ui.colors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLinkCard(UiTheme ui, Map<String, dynamic> link) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _fetchHelp(link['topic']),
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
      child: GestureDetector(
        onTap: () => _fetchHelp(func['topic']!),
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
                  onPressed: () => setState(() {
                    _selectedTopic = null;
                    _helpContent = null;
                  }),
                  visualDensity: VisualDensity.compact,
                ),
                UiText(
                  text: 'Documentation',
                  variant: UiTextVariant.label,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.all(ui.spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isMarkdown)
                        UiText(
                          text: _selectedTopic!,
                          variant: UiTextVariant.title,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: ui.colors.accent,
                        ),
                      if (!_isMarkdown) const SizedBox(height: 20),
                      if (_helpContent != null)
                        _isMarkdown 
                          ? MarkdownBody(
                              data: _helpContent!,
                              selectable: true,
                              builders: {
                                'code': CodeBlockBuilder(ui: ui, context: context),
                              },
                              styleSheet: MarkdownStyleSheet(
                                h1: TextStyle(color: ui.colors.accent, fontSize: 24, fontWeight: FontWeight.bold),
                                h2: TextStyle(color: ui.colors.accent, fontSize: 20, fontWeight: FontWeight.bold),
                                h3: TextStyle(color: ui.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                                p: TextStyle(color: ui.colors.textSecondary, fontSize: 13),
                                listBullet: TextStyle(color: ui.colors.textSecondary),
                                code: TextStyle(
                                  backgroundColor: ui.colors.panelHeader,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: ui.colors.accent,
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: ui.colors.panelHeader,
                                  borderRadius: ui.spacing.radiusMd,
                                  border: Border.all(color: ui.colors.divider.withValues(alpha: 0.3)),
                                ),
                              ),
                            )
                          : Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(ui.spacing.md),
                              decoration: BoxDecoration(
                                color: ui.colors.panel,
                                borderRadius: ui.spacing.radiusMd,
                                border: Border.all(color: ui.colors.divider.withValues(alpha: 0.3)),
                              ),
                              child: UiText(
                                text: _helpContent!,
                                variant: UiTextVariant.codeBody,
                                fontSize: 12,
                                color: ui.colors.textPrimary,
                              ),
                            ),
                      if (_helpContent == null && !_isLoading)
                         UiText(
                           text: 'No documentation found for this topic.',
                           variant: UiTextVariant.body,
                           color: ui.colors.textSecondary,
                         ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class CodeBlockBuilder extends MarkdownElementBuilder {

  final UiTheme ui;

  final BuildContext context;



  CodeBlockBuilder({required this.ui, required this.context});



  @override

  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {

    var content = element.textContent;

    if (content.endsWith('\n')) {

      content = content.substring(0, content.length - 1);

    }



    final isInline = element.attributes['class'] == null;



    if (isInline) {

      return Container(

        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),

        decoration: BoxDecoration(

          color: ui.colors.panelHeader,

          borderRadius: BorderRadius.circular(4),

        ),

        child: Text(

          content,

          style: preferredStyle?.copyWith(color: ui.colors.accent, fontSize: 11),

        ),

      );

    }



    return Container(

      margin: const EdgeInsets.symmetric(vertical: 8),

      width: double.infinity,

      decoration: BoxDecoration(

        color: ui.colors.panelHeader,

        borderRadius: ui.spacing.radiusMd,

        border: Border.all(color: ui.colors.divider.withValues(alpha: 0.3)),

      ),

      child: Stack(

        children: [

          Padding(

            padding: const EdgeInsets.all(12),

            child: SingleChildScrollView(

              scrollDirection: Axis.horizontal,

              child: SelectableText(

                content,

                style: TextStyle(

                  color: ui.colors.textPrimary,

                  fontFamily: 'monospace',

                  fontSize: 12,

                ),

              ),

            ),

          ),

          Positioned(

            top: 4,

            right: 4,

            child: Material(

              color: Colors.transparent,

              child: IconButton(

                icon: Icon(LucideIcons.copy, size: 14, color: ui.colors.textMuted),

                onPressed: () {

                  Clipboard.setData(ClipboardData(text: content));

                  ScaffoldMessenger.of(context).showSnackBar(

                    SnackBar(

                      content: const Text('Code copied to clipboard'),

                      duration: const Duration(seconds: 1),

                      backgroundColor: ui.colors.accent,

                      behavior: SnackBarBehavior.floating,

                      width: 200,

                    ),

                  );

                },

                tooltip: 'Copy Code',

                visualDensity: VisualDensity.compact,

              ),

            ),

          ),

        ],

      ),

    );

  }

}
