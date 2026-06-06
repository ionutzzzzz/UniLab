class WorkspaceVariable {
  final String name;
  final String value;
  final String size;
  final String typeClass;
  final String min;
  final String max;
  final String mean;
  final String median;
  final String sum;
  final String variance;
  final String std;
  final String range;
  final String mode;

  const WorkspaceVariable({
    required this.name,
    required this.value,
    required this.size,
    required this.typeClass,
    this.min = '',
    this.max = '',
    this.mean = '',
    this.median = '',
    this.sum = '',
    this.variance = '',
    this.std = '',
    this.range = '',
    this.mode = '',
  });
}
