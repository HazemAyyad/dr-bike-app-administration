class EmployeePerformanceModel {
  const EmployeePerformanceModel({
    required this.score,
    required this.rating,
    required this.change,
    required this.sections,
    required this.improvementTip,
    required this.monthlyTrend,
  });

  final double? score;
  final String rating;
  final double? change;
  final List<EmployeePerformanceSection> sections;
  final String improvementTip;
  final List<EmployeePerformanceTrendPoint> monthlyTrend;

  factory EmployeePerformanceModel.fromJson(Map<String, dynamic> json) {
    final rating = _map(json['rating']);
    final comparison = _map(json['comparison']);
    final rawSections = json['sections'];
    return EmployeePerformanceModel(
      score: _number(json['score']),
      rating: '${rating['label'] ?? 'لا توجد بيانات كافية'}',
      change: _number(comparison['change']),
      sections: rawSections is List
          ? rawSections
                .whereType<Map>()
                .map(
                  (item) => EmployeePerformanceSection.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      improvementTip: '${json['improvement_tip'] ?? ''}',
      monthlyTrend: _trendPoints(json['monthly_trend']),
    );
  }

  EmployeePerformanceSection? section(String key) {
    for (final item in sections) {
      if (item.key == key) return item;
    }
    return null;
  }
}

class EmployeePerformanceTrendPoint {
  const EmployeePerformanceTrendPoint({
    required this.label,
    required this.score,
    required this.tasksTotal,
    required this.tasksCompleted,
  });

  final String label;
  final double? score;
  final int tasksTotal;
  final int tasksCompleted;

  factory EmployeePerformanceTrendPoint.fromJson(Map<String, dynamic> json) =>
      EmployeePerformanceTrendPoint(
        label: '${json['label'] ?? ''}',
        score: _number(json['score']),
        tasksTotal: _integer(json['tasks_total']),
        tasksCompleted: _integer(json['tasks_completed']),
      );
}

List<EmployeePerformanceTrendPoint> _trendPoints(dynamic value) {
  final map = _map(value);
  final points = map['points'];
  if (points is! List) return const [];
  return points
      .whereType<Map>()
      .map(
        (item) => EmployeePerformanceTrendPoint.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
}

class EmployeePerformanceSection {
  const EmployeePerformanceSection({
    required this.key,
    required this.label,
    required this.score,
    required this.available,
    required this.metrics,
  });

  final String key;
  final String label;
  final double? score;
  final bool available;
  final Map<String, dynamic> metrics;

  factory EmployeePerformanceSection.fromJson(Map<String, dynamic> json) =>
      EmployeePerformanceSection(
        key: '${json['key'] ?? ''}',
        label: '${json['label'] ?? ''}',
        score: _number(json['score']),
        available: json['available'] == true,
        metrics: _map(json['metrics']),
      );
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

double? _number(dynamic value) => value is num
    ? value.toDouble()
    : value == null
    ? null
    : double.tryParse('$value');

int _integer(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('${value ?? ''}') ?? 0;
