import 'package:uuid/uuid.dart';

/// Represents an open file in the editor
class OpenFile {
  final String id;
  final String name;
  final String path;
  String content;
  bool isDirty;
  DateTime lastModified;

  OpenFile({
    String? id,
    required this.name,
    required this.path,
    this.content = '',
    this.isDirty = false,
    DateTime? lastModified,
  })  : id = id ?? const Uuid().v4(),
        lastModified = lastModified ?? DateTime.now();

  OpenFile copyWith({
    String? id,
    String? name,
    String? path,
    String? content,
    bool? isDirty,
    DateTime? lastModified,
  }) {
    return OpenFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      content: content ?? this.content,
      isDirty: isDirty ?? this.isDirty,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

/// Represents a variable in the workspace
class WorkspaceVariable {
  final String name;
  final String type; // 'double', 'matrix', 'string', etc.
  final String value;
  final String? size; // e.g., "100x100"
  final double? min;
  final double? max;
  final List<dynamic>? data; // For storing actual data

  WorkspaceVariable({
    required this.name,
    required this.type,
    required this.value,
    this.size,
    this.min,
    this.max,
    this.data,
  });

  WorkspaceVariable copyWith({
    String? name,
    String? type,
    String? value,
    String? size,
    double? min,
    double? max,
    List<dynamic>? data,
  }) {
    return WorkspaceVariable(
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      size: size ?? this.size,
      min: min ?? this.min,
      max: max ?? this.max,
      data: data ?? this.data,
    );
  }
}

/// Represents a console message
enum ConsoleMessageType {
  output,
  error,
  warning,
  success,
}

class ConsoleMessage {
  final String text;
  final ConsoleMessageType type;
  final DateTime timestamp;
  final String? source; // e.g., 'System', 'Script', 'Error'

  ConsoleMessage({
    required this.text,
    required this.type,
    DateTime? timestamp,
    this.source,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Represents a plot in the plot gallery
class PlotData {
  final String id;
  final String title;
  final String type; // 'line', 'scatter', 'bar', 'surface', etc.
  final List<double> xData;
  final List<double> yData;
  final List<List<double>>? zData; // For 3D plots
  final String? fileName;
  DateTime createdAt;

  PlotData({
    String? id,
    required this.title,
    required this.type,
    required this.xData,
    required this.yData,
    this.zData,
    this.fileName,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  PlotData copyWith({
    String? id,
    String? title,
    String? type,
    List<double>? xData,
    List<double>? yData,
    List<List<double>>? zData,
    String? fileName,
    DateTime? createdAt,
  }) {
    return PlotData(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      xData: xData ?? this.xData,
      yData: yData ?? this.yData,
      zData: zData ?? this.zData,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Represents editor state
class EditorState {
  final int activeTabIndex;
  final List<OpenFile> openFiles;
  final bool isSearchOpen;
  final bool isFindReplaceOpen;
  final String searchText;

  EditorState({
    this.activeTabIndex = 0,
    this.openFiles = const [],
    this.isSearchOpen = false,
    this.isFindReplaceOpen = false,
    this.searchText = '',
  });

  EditorState copyWith({
    int? activeTabIndex,
    List<OpenFile>? openFiles,
    bool? isSearchOpen,
    bool? isFindReplaceOpen,
    String? searchText,
  }) {
    return EditorState(
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      openFiles: openFiles ?? this.openFiles,
      isSearchOpen: isSearchOpen ?? this.isSearchOpen,
      isFindReplaceOpen: isFindReplaceOpen ?? this.isFindReplaceOpen,
      searchText: searchText ?? this.searchText,
    );
  }
}
