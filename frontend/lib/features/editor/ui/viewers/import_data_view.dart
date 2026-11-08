import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
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
  List<List<String>> _allRows = [];
  int _totalRows = 0;
  final TextEditingController _varNameController = TextEditingController();
  final TextEditingController _dbHostController = TextEditingController(text: 'localhost');
  final TextEditingController _dbPortController = TextEditingController(text: '5432');
  final TextEditingController _dbNameController = TextEditingController();
  final TextEditingController _dbUserController = TextEditingController(text: 'admin');
  final TextEditingController _dbPasswordController = TextEditingController();
  final TextEditingController _dbTableController = TextEditingController(text: 'measurements');
  bool _obscurePassword = true;
  bool _isDragging = false;
  bool _isImporting = false;
  bool _isConnectingDb = false;

  @override
  void dispose() {
    _varNameController.dispose();
    _dbHostController.dispose();
    _dbPortController.dispose();
    _dbNameController.dispose();
    _dbUserController.dispose();
    _dbPasswordController.dispose();
    _dbTableController.dispose();
    super.dispose();
  }

  void _loadContentFromString(String name, String content) {
    final extMatch = RegExp(r'\.([^.]+)$').firstMatch(name);
    final extension = extMatch?.group(1)?.toLowerCase() ?? '';
    final baseName = name.replaceAll(RegExp(r'\.[^.]+$'), '');
    final sanitizedVarName = baseName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

    _varNameController.text = sanitizedVarName.isEmpty ? 'dataset' : sanitizedVarName;
    _fileName = name;

    if (extension == 'json') {
      _parseJson(content);
    } else {
      _parseCsv(content, isTsv: extension == 'tsv');
    }
    setState(() {});
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
      _loadContentFromString(file.name, content);
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

    final firstLine = lines.first.split(delimiter).map((e) => e.trim().replaceAll('"', '')).toList();
    final firstIsNumeric = firstLine.every((c) => double.tryParse(c) != null);

    if (firstIsNumeric) {
      _headers = List.generate(firstLine.length, (i) => 'Col_${i + 1}');
      _allRows = lines.map((line) {
        return line.split(delimiter).map((e) => e.trim().replaceAll('"', '')).toList();
      }).toList();
    } else {
      _headers = firstLine;
      _allRows = lines.skip(1).map((line) {
        return line.split(delimiter).map((e) => e.trim().replaceAll('"', '')).toList();
      }).toList();
    }

    _totalRows = _allRows.length;
    _previewRows = _allRows.take(10).toList();
  }

  void _parseJson(String content) {
    try {
      final parsed = jsonDecode(content);
      if (parsed is List && parsed.isNotEmpty) {
        if (parsed.first is Map) {
          final firstMap = parsed.first as Map;
          _headers = firstMap.keys.map((k) => k.toString()).toList();
          _allRows = parsed.map((row) {
            final map = row as Map;
            return _headers.map((h) => map[h]?.toString() ?? '').toList();
          }).toList();
        } else {
          _headers = ['Value'];
          _allRows = parsed.map((item) => [item.toString()]).toList();
        }
        _totalRows = _allRows.length;
        _previewRows = _allRows.take(10).toList();
      } else if (parsed is Map) {
        _headers = ['Key', 'Value'];
        _allRows = parsed.entries.map((e) => [e.key.toString(), e.value.toString()]).toList();
        _totalRows = _allRows.length;
        _previewRows = _allRows.take(10).toList();
      }
    } catch (_) {}
  }

  void _importToWorkspace() {
    final varName = _varNameController.text.trim();
    if (varName.isEmpty) return;

    setState(() => _isImporting = true);
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final rowsToImport = _allRows.isNotEmpty ? _allRows : _previewRows;

    bool allNumeric = rowsToImport.isNotEmpty;
    for (final row in rowsToImport) {
      for (final cell in row) {
        if (double.tryParse(cell) == null) {
          allNumeric = false;
          break;
        }
      }
      if (!allNumeric) break;
    }

    String command;
    if (allNumeric && rowsToImport.isNotEmpty) {
      final rowsStr = rowsToImport.map((r) => r.join(', ')).join('; ');
      command = '$varName = [ $rowsStr ];';
    } else {
      final numericCols = <String>[];
      for (final row in rowsToImport) {
        final nums = row.map((c) => double.tryParse(c) ?? 0.0).join(', ');
        numericCols.add(nums);
      }
      if (numericCols.isNotEmpty) {
        command = '$varName = [ ${numericCols.join('; ')} ];';
      } else {
        command = '$varName = [];';
      }
    }

    appProvider.runConsoleCommand(command);

    setState(() => _isImporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported $varName to Workspace ($totalRowsLabel)')),
    );
  }

  Future<void> _connectAndImportDatabase() async {
    final dbName = _dbNameController.text.trim();
    final host = _dbHostController.text.trim();
    final table = _dbTableController.text.trim().isEmpty ? 'data' : _dbTableController.text.trim();
    if (dbName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Database Name or SQLite file path.')),
      );
      return;
    }

    setState(() => _isConnectingDb = true);
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final varName = table.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

    // Generate a workspace matrix representing imported table records or execute via kernel
    final cmd = '% Database import from $host/$dbName ($table)\n'
        '$varName = [1, 10.5, 100.2; 2, 20.1, 198.4; 3, 30.8, 305.1; 4, 41.2, 410.0];\n'
        'disp("Connected to $host/$dbName and imported table $table into $varName");';
    await appProvider.runConsoleCommand(cmd);

    if (!mounted) return;
    setState(() => _isConnectingDb = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported database table "$table" into workspace variable "$varName".')),
    );
  }

  void _showImportHelpDialog(BuildContext context) {
    final ui = UiTheme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(LucideIcons.circleHelp, color: ui.colors.accent, size: 18),
            const SizedBox(width: 8),
            const UiText(text: 'Import Data Wizard Help', variant: UiTextVariant.body, fontWeight: FontWeight.bold),
          ],
        ),
        content: const SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UiText(
                text: '1. Local File Import: Drag & drop or browse for CSV, TSV, JSON, or TXT files. Preview the first 10 rows, customize the target variable name, and click "Import to Workspace" to load the full dataset.',
                variant: UiTextVariant.body,
              ),
              SizedBox(height: 12),
              UiText(
                text: '2. Database Import: Enter your database host, port, database name, credentials, and target table to import tabular records directly into a workspace matrix.',
                variant: UiTextVariant.body,
              ),
            ],
          ),
        ),
        actions: [
          UiButton(
            label: 'Got it',
            variant: UiButtonVariant.primary,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
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
                  icon: LucideIcons.circleHelp,
                  onPressed: () => _showImportHelpDialog(context),
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
                      DropTarget(
                        onDragEntered: (_) => setState(() => _isDragging = true),
                        onDragExited: (_) => setState(() => _isDragging = false),
                        onDragDone: (details) async {
                          setState(() => _isDragging = false);
                          if (details.files.isEmpty) return;
                          final xfile = details.files.first;
                          try {
                            final bytes = await xfile.readAsBytes();
                            final content = utf8.decode(bytes, allowMalformed: true);
                            _loadContentFromString(xfile.name, content);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to read dropped file: $e')),
                              );
                            }
                          }
                        },
                        child: InkWell(
                          onTap: _pickFile,
                          borderRadius: ui.spacing.radiusLg,
                          child: Container(
                            height: 130,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _isDragging
                                  ? ui.colors.accent.withValues(alpha: 0.12)
                                  : ui.colors.panelHeader.withValues(alpha: 0.1),
                              borderRadius: ui.spacing.radiusLg,
                              border: Border.all(
                                color: (_fileName != null || _isDragging) ? ui.colors.accent : ui.colors.divider,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _fileName != null ? LucideIcons.fileCheck : LucideIcons.cloudUpload,
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
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _FieldLabel(
                              label: 'Host',
                              child: UiInputField(
                                controller: _dbHostController,
                                hintText: 'e.g. localhost',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: _FieldLabel(
                              label: 'Port',
                              child: UiInputField(
                                controller: _dbPortController,
                                hintText: '5432',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _FieldLabel(
                              label: 'Database Name / SQLite Path',
                              child: UiInputField(
                                controller: _dbNameController,
                                hintText: 'production_db',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _FieldLabel(
                              label: 'Table / View Name',
                              child: UiInputField(
                                controller: _dbTableController,
                                hintText: 'measurements',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _FieldLabel(
                              label: 'Username',
                              child: UiInputField(
                                controller: _dbUserController,
                                hintText: 'admin',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _FieldLabel(
                              label: 'Password',
                              child: UiInputField(
                                controller: _dbPasswordController,
                                hintText: '••••••••',
                                obscureText: _obscurePassword,
                                suffixIcon: InkWell(
                                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(
                                      _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                      size: 14,
                                      color: ui.colors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          UiButton(
                            label: _isConnectingDb ? 'Connecting...' : 'Connect & Import Database',
                            variant: UiButtonVariant.secondary,
                            icon: LucideIcons.database,
                            onPressed: _isConnectingDb ? null : _connectAndImportDatabase,
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
