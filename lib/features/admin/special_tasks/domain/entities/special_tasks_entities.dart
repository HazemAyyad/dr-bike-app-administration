class SpecialTaskEntity {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCanceled;
  final String status;

  SpecialTaskEntity({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isCanceled,
    required this.status,
  });
}
