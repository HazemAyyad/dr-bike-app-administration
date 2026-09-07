class EmployeePerformanceModel {
  const EmployeePerformanceModel({
    required this.score,
    required this.rating,
    required this.change,
    required this.sections,
    required this.improvementTip,
    required this.monthlyTrend,
    required this.pointsSummary,
  });

  final double? score;
  final String rating;
  final double? change;
  final List<EmployeePerformanceSection> sections;
  final String improvementTip;
  final List<EmployeePerformanceTrendPoint> monthlyTrend;
  final EmployeePerformancePointsSummary pointsSummary;

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
      pointsSummary: EmployeePerformancePointsSummary.fromJson(
        _map(json['points_summary']),
      ),
    );
  }

  EmployeePerformanceSection? section(String key) {
    for (final item in sections) {
      if (item.key == key) return item;
    }
    return null;
  }
}

class EmployeePerformancePointsSummary {
  const EmployeePerformancePointsSummary({
    required this.available,
    required this.earned,
    required this.deducted,
    required this.net,
    required this.lifetimeNet,
    required this.movements,
  });

  final bool available;
  final int earned;
  final int deducted;
  final int net;
  final int lifetimeNet;
  final List<EmployeePerformancePointMovement> movements;

  factory EmployeePerformancePointsSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['recent_movements'];
    return EmployeePerformancePointsSummary(
      available: json['available'] == true,
      earned: _integer(json['earned_points']),
      deducted: _integer(json['deducted_points']),
      net: _integer(json['net_points']),
      lifetimeNet: _integer(json['lifetime_net_points']),
      movements: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) => EmployeePerformancePointMovement.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class EmployeePerformancePointMovement {
  const EmployeePerformancePointMovement({
    required this.isAdd,
    required this.points,
    required this.label,
    required this.date,
  });

  final bool isAdd;
  final int points;
  final String label;
  final String date;

  factory EmployeePerformancePointMovement.fromJson(
    Map<String, dynamic> json,
  ) => EmployeePerformancePointMovement(
    isAdd: json['operation_type'] == 'add',
    points: _integer(json['points']),
    label: '${json['label'] ?? 'حركة نقاط'}',
    date: '${json['date'] ?? ''}',
  );
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
