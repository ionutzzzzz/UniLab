class FileNode {
  final String path;
  final String name;
  final bool isDirectory;
  final List<FileNode> children;

  const FileNode({
    required this.path,
    required this.name,
    this.isDirectory = false,
    this.children = const [],
  });

  FileNode copyWith({
    String? path,
    String? name,
    bool? isDirectory,
    List<FileNode>? children,
  }) {
    return FileNode(
      path: path ?? this.path,
      name: name ?? this.name,
      isDirectory: isDirectory ?? this.isDirectory,
      children: children ?? this.children,
    );
  }
}
