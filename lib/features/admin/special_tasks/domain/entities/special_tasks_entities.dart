class SpecialTaskEntity {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCanceled;
  final String status;
  final int progress;
  final List<String> subtaskNames;

  SpecialTaskEntity({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isCanceled,
    required this.status,
    this.progress = 0,
    this.subtaskNames = const [],
  });

  bool matchesSearchQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (name.toLowerCase().contains(q)) return true;
    for (final subtask in subtaskNames) {
      if (subtask.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  List<String> matchingSubtaskNames(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return subtaskNames
        .where((subtask) => subtask.toLowerCase().contains(q))
        .toList();
  }
}
