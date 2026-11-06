import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../theme/ui_theme.dart';
import '../../../../widgets/ui_text.dart';
import '../../../../widgets/ui_button.dart';
import '../../../../widgets/ui_input_field.dart';
import '../../../../providers/app_provider.dart';

class ImportDataView extends StatefulWidget {
  const ImportDataView({super.key});

  @override
  State<ImportDataView> createState() => _ImportDataViewState();
}

class _ImportDataViewState extends State<ImportDataView> {
  String? _fileName;
  List<String> _headers = [];
  List<List<String>> _previewRows = [];
  int _totalRows = 0;
  final TextEditingController _varNameController = TextEditingController();
  bool _isImporting = false;

  @override
  void dispose() {
    _varNameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'tsv', 'json', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      final content = utf8.decode(bytes, allowMalformed: true);
      final extension = file.extension?.toLowerCase() ?? '';
      final baseName = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
      final sanitizedVarName = baseName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

      _varNameController.text = sanitizedVarName.isEmpty ? 'dataset' : sanitizedVarName;
      _fileName = file.name;

      if (extension == 'json') {
        _parseJson(content);
      } else {
        _parseCsv(content, isTsv: extension == 'tsv');
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to parse file: $e')),
        );
      }
    }
  }

  void _parseCsv(String content, {bool isTsv = false}) {
    final delimiter = isTsv ? '\t' : ',';
    final lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return;

    _totalRows = lines.length;
    final firstLine = lines.first.split(delimiter).map((e) => e.trim().replaceAll('"', '')).toList();
    _headers = firstLine;

    _previewRows = lines.skip(1).take(10).map((line) {
      return line.split(delimiter).map((e) => e.trim().replaceAll('"', '')).toList();
    }).toList();
  }

  void _parseJson(String content) {
    try {
      final parsed = jsonDecode(content);
      if (parsed is List && parsed.isNotEmpty) {
        _totalRows = parsed.length;
        if (parsed.first is Map) {
          final firstMap = parsed.first as Map;
          _headers = firstMap.keys.map((k) => k.toString()).toList();
          _previewRows = parsed.take(10).map((row) {
            final map = row as Map;
            return _headers.map((h) => map[h]?.toString() ?? '').toList();
          }).toList();
        } else {
          _headers = ['Value'];
          _previewRows = parsed.take(10).map((item) => [item.toString()]).toList();
        }
      } else if (parsed is Map) {
        _totalRows = parsed.length;
        _headers = ['Key', 'Value'];
        _previewRows = parsed.entries.take(10).map((e) => [e.key.toString(), e.value.toString()]).toList();
      }
    } catch (_) {}
  }

  void _importToWorkspace() {
    final varName = _varNameController.text.trim();
    if (varName.isEmpty) return;

    setState(() => _isImporting = true);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Format MATLAB command
    // If table contains purely numbers, construct matrix literal
    bool allNumeric = true;
    for (final row in _previewRows) {
      for (final cell in row) {
        if (double.tryParse(cell) == null) {
          allNumeric = false;
          break;
        }
      }
      if (!allNumeric) break;
    }

    String command;
    if (allNumeric && _previewRows.isNotEmpty) {
      final rowsStr = _previewRows.map((r) => r.join(', ')).join('; ');
      command = '$varName = [ $rowsStr ];';
    } else {
      command = '% Imported $_fileName ($_totalRows records)\n$varName = { ${_headers.map((h) => "'$h'").join(', ')} };';
    }

    appProvider.runConsoleCommand(command);

    setState(() => _isImporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported $varName to Workspace ($totalRowsLabel)')),
    );
  }

  String get totalRowsLabel => '$_totalRows row${_totalRows == 1 ? '' : 's'}';

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
                      _buildSectionHeader(ui, LucideIcons.fileUp, 'Local File Import'),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickFile,
                        borderRadius: ui.spacing.radiusLg,
                        child: Container(
                          height: 130,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: ui.colors.panelHeader.withValues(alpha: 0.1),
                            borderRadius: ui.spacing.radiusLg,
                            border: Border.all(
                              color: _fileName != null ? ui.colors.accent : ui.colors.divider,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _fileName != null ? LucideIcons.fileCheck : LucideIcons.uploadCloud,
                                size: 40,
                                color: ui.colors.accent,
                              ),
                              const SizedBox(height: 12),
                              UiText(
                                text: _fileName ?? 'Drop data files here or click to browse',
                                variant: UiTextVariant.body,
                                fontWeight: FontWeight.w500,
                              ),
                              const SizedBox(height: 4),
                              UiText(
                                text: _fileName != null ? totalRowsLabel : 'Supports CSV, TSV, JSON, and Text formats',
                                variant: UiTextVariant.caption,
                                color: ui.colors.textDisabled,
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_previewRows.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _buildSectionHeader(ui, LucideIcons.table, 'Dataset Preview (First 10 rows)'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _FieldLabel(
                                label: 'Workspace Variable Name',
                                child: UiInputField(
                                  controller: _varNameController,
                                  hintText: 'e.g. data',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: UiButton(
                                label: _isImporting ? 'Importing...' : 'Import to Workspace',
                                variant: UiButtonVariant.primary,
                                icon: LucideIcons.arrowRight,
                                onPressed: _isImporting ? null : _importToWorkspace,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: ui.colors.panel,
                            borderRadius: ui.spacing.radiusMd,
                            border: Border.all(color: ui.colors.divider),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowHeight: 36,
                              dataRowMinHeight: 32,
                              dataRowMaxHeight: 32,
                              columns: _headers
                                  .map((h) => DataColumn(
                                        label: UiText(
                                          text: h,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ))
                                  .toList(),
                              rows: _previewRows.map((row) {
                                return DataRow(
                                  cells: List.generate(_headers.length, (i) {
                                    final val = i < row.length ? row[i] : '';
                                    return DataCell(
                                      UiText(
                                        text: val,
                                        fontSize: 11,
                                        fontFamily: 'JetBrains Mono',
                                      ),
                                    );
                                  }),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 48),
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
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          UiButton(
                            label: 'Connect & Import Database',
                            variant: UiButtonVariant.secondary,
                            icon: LucideIcons.database,
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
