import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../theme/ui_theme.dart';
import '../../../../widgets/ui_text.dart';
import '../../../../widgets/ui_icon_button.dart';

class UniLabPdfViewer extends StatefulWidget {
  final String path;
  final String name;

  const UniLabPdfViewer({super.key, required this.path, required this.name});

  @override
  State<UniLabPdfViewer> createState() => _UniLabPdfViewerState();
}

class _UniLabPdfViewerState extends State<UniLabPdfViewer> {
  late PdfViewerController _controller;
  int _currentPage = 1;
  int _totalPages = 0;
  
  // Static map to persist page position across component rebuilds/tab swaps
  static final Map<String, int> _lastPageCache = {};

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
  }

  @override
  void dispose() {
    // Save current page before disposing
    _lastPageCache[widget.path] = _currentPage;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);
    
    return Container(
      color: ui.colors.canvas,
      child: Column(
        children: [
          // Navigation Toolbar
          _buildToolbar(ui),
          
          Expanded(
            child: PdfViewer.file(
              widget.path,
              controller: _controller,
              params: PdfViewerParams(
                enableTextSelection: true,
                maxScale: 8.0,
                loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
                  return Center(
                    child: CircularProgressIndicator(
                      value: totalBytes != null ? bytesDownloaded / totalBytes : null,
                      color: ui.colors.accent,
                    ),
                  );
                },
                onViewerReady: (document, controller) {
                  setState(() {
                    _totalPages = document.pages.length;
                  });
                  // Restore last page if available
                  final savedPage = _lastPageCache[widget.path];
                  if (savedPage != null && savedPage > 0 && savedPage <= _totalPages) {
                    controller.goToPage(pageNumber: savedPage);
                  }
                },
                onPageChanged: (pageNumber) {
                  if (mounted && pageNumber != null) {
                    setState(() {
                      _currentPage = pageNumber;
                    });
                  }
                },
                errorBannerBuilder: (context, error, stackTrace, documentRef) {
                  return Container(
                    color: ui.colors.danger.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.fileWarning, color: ui.colors.danger, size: 48),
                          const SizedBox(height: 16),
                          UiText(
                            text: 'Failed to load PDF document',
                            variant: UiTextVariant.body,
                            fontWeight: FontWeight.bold,
                            color: ui.colors.danger,
                          ),
                          const SizedBox(height: 8),
                          UiText(
                            text: error.toString(),
                            variant: UiTextVariant.caption,
                            color: ui.colors.textSecondary,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          UiText(
                            text: 'Path: ${widget.path}',
                            variant: UiTextVariant.caption,
                            fontSize: 9,
                            color: ui.colors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Status Bar
          _buildStatusBar(ui),
        ],
      ),
    );
  }

  Widget _buildToolbar(UiTheme ui) {
    return Container(
      height: 38,
      padding: EdgeInsets.symmetric(horizontal: ui.spacing.md),
      decoration: BoxDecoration(
        color: ui.colors.panelHeader,
        border: Border(bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          // Page Navigation
          UiIconButton(
            icon: LucideIcons.chevronLeft,
            tooltip: 'Previous Page',
            onPressed: _currentPage > 1 ? () => _controller.goToPage(pageNumber: _currentPage - 1) : null,
            size: 28,
            iconSize: 16,
          ),
          const SizedBox(width: 4),
          Container(
            width: 40,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ui.colors.canvas.withValues(alpha: 0.5),
              borderRadius: ui.spacing.radiusSm,
              border: Border.all(color: ui.colors.divider),
            ),
            child: InkWell(
              onTap: () => _showGoToPageDialog(context, ui),
              child: UiText(
                text: '$_currentPage',
                variant: UiTextVariant.label,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: UiText(
              text: '/ $_totalPages',
              variant: UiTextVariant.label,
              fontSize: 11,
              color: ui.colors.textMuted,
            ),
          ),
          UiIconButton(
            icon: LucideIcons.chevronRight,
            tooltip: 'Next Page',
            onPressed: _currentPage < _totalPages ? () => _controller.goToPage(pageNumber: _currentPage + 1) : null,
            size: 28,
            iconSize: 16,
          ),
          
          const VerticalDivider(width: 24, indent: 8, endIndent: 8),
          
          // Zoom Controls
          UiIconButton(
            icon: LucideIcons.zoomOut,
            tooltip: 'Zoom Out',
            onPressed: () => _controller.zoomDown(),
            size: 28,
            iconSize: 16,
          ),
          UiIconButton(
            icon: LucideIcons.zoomIn,
            tooltip: 'Zoom In',
            onPressed: () => _controller.zoomUp(),
            size: 28,
            iconSize: 16,
          ),
          UiIconButton(
            icon: LucideIcons.maximize,
            tooltip: 'Fit to Width',
            onPressed: () {
              _controller.setZoom(Offset.zero, 1.0);
            },
            size: 28,
            iconSize: 16,
          ),
          
          const Spacer(),
          
          // Secondary actions
          UiIconButton(
            icon: LucideIcons.search,
            tooltip: 'Search in Document',
            onPressed: () {
              // Implementation would require more pdfrx search logic
            },
            size: 28,
            iconSize: 16,
          ),
          UiIconButton(
            icon: LucideIcons.printer,
            tooltip: 'Print Document',
            onPressed: () {},
            size: 28,
            iconSize: 16,
          ),
        ],
      ),
    );
  }

  void _showGoToPageDialog(BuildContext context, UiTheme ui) {
    final controller = TextEditingController(text: '$_currentPage');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ui.colors.panel,
        title: const UiText(text: 'Go to Page', variant: UiTextVariant.body, fontWeight: FontWeight.bold),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: TextStyle(color: ui.colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter page number (1 - $_totalPages)',
            hintStyle: TextStyle(color: ui.colors.textMuted, fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: UiText(text: 'Cancel', color: ui.colors.textMuted),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page > 0 && page <= _totalPages) {
                _controller.goToPage(pageNumber: page);
              }
              Navigator.pop(context);
            },
            child: UiText(text: 'Go', color: ui.colors.accent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(UiTheme ui) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: ui.colors.panelHeader,
        border: Border(top: BorderSide(color: ui.colors.divider.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.fileText, size: 12, color: ui.colors.danger.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Expanded(
            child: UiText(
              text: widget.name, 
              variant: UiTextVariant.caption,
              fontSize: 10,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          UiText(
            text: 'PDF Engine: pdfrx', 
            variant: UiTextVariant.caption, 
            fontSize: 10,
            color: ui.colors.textMuted,
          ),
        ],
      ),
    );
  }
}