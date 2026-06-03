class WorkspaceVariable {
  final String name;
  final String value;
  final String size;
  final String typeClass;
  final String min;
  final String max;

  const WorkspaceVariable({
    required this.name,
    required this.value,
    required this.size,
    required this.typeClass,
    this.min = '',
    this.max = '',
  });
}
