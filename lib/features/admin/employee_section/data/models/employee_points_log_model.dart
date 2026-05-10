import '../../../../../core/helpers/json_safe_parser.dart';

class EmployeePointsLogModel {
  const EmployeePointsLogModel({
    required this.id,
    required this.employeeId,
    required this.points,
    required this.operationType,
    required this.category,
    required this.source,
    this.reason,
    this.notes,
    this.pointsDate,
    this.createdById,
    this.createdByName,
    this.createdAt,
  });

  final int id;
  final int employeeId;
  final int points;
  final String operationType; // 'add' | 'deduct'
  final String category;
  final String source;
  final String? reason;
  final String? notes;
  final String? pointsDate;
  final int? createdById;
  final String? createdByName;
  final String? createdAt;

  bool get isAdd => operationType == 'add';
  bool get isDeduct => operationType == 'deduct';
  int get signedPoints => isAdd ? points : -points;

  factory EmployeePointsLogModel.fromJson(Map<String, dynamic> json) {
    final j = asMap(json);
    return EmployeePointsLogModel(
      id: asInt(j['id']),
      employeeId: asInt(j['employee_id']),
      points: asInt(j['points']),
      operationType: asString(j['operation_type'], 'add'),
      category: asString(j['category']),
      source: asString(j['source'], 'manual'),
      reason: asNullableString(j['reason']),
      notes: asNullableString(j['notes']),
      pointsDate: asNullableString(j['points_date']),
      createdById: j['created_by'] == null ? null : asInt(j['created_by']),
      createdByName: asNullableString(j['created_by_name']),
      createdAt: asNullableString(j['created_at']),
    );
  }
}

class EmployeePointsLogsPage {
  const EmployeePointsLogsPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<EmployeePointsLogModel> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  factory EmployeePointsLogsPage.fromJson(Map<String, dynamic> json) {
    final j = asMap(json);
    final meta = asMap(j['meta']);
    return EmployeePointsLogsPage(
      items: mapList(
        j['logs'],
        (Map<String, dynamic> m) => EmployeePointsLogModel.fromJson(m),
      ),
      currentPage: asInt(meta['current_page'], 1),
      lastPage: asInt(meta['last_page'], 1),
      perPage: asInt(meta['per_page'], 0),
      total: asInt(meta['total'], 0),
    );
  }
}

class EmployeePointsMonthlySummaryModel {
  const EmployeePointsMonthlySummaryModel({
    required this.month,
    required this.year,
    required this.earnedPoints,
    required this.deductedPoints,
    required this.netPoints,
    required this.rewardAmount,
    this.matchedRuleId,
  });

  final int month;
  final int year;
  final int earnedPoints;
  final int deductedPoints;
  final int netPoints;
  final String rewardAmount; // formatted "0.00"
  final int? matchedRuleId;

  double get rewardAmountDouble =>
      double.tryParse(rewardAmount.toString()) ?? 0.0;

  factory EmployeePointsMonthlySummaryModel.fromJson(Map<String, dynamic> json) {
    final j = asMap(json);
    final s = asMap(j['summary']);
    return EmployeePointsMonthlySummaryModel(
      month: asInt(j['month']),
      year: asInt(j['year']),
      earnedPoints: asInt(s['earned_points']),
      deductedPoints: asInt(s['deducted_points']),
      netPoints: asInt(s['net_points']),
      rewardAmount: asString(s['reward_amount'], '0.00'),
      matchedRuleId:
          s['matched_rule_id'] == null ? null : asInt(s['matched_rule_id']),
    );
  }
}

class EmployeePointsCategoriesModel {
  const EmployeePointsCategoriesModel({
    required this.positive,
    required this.negative,
  });

  final List<String> positive;
  final List<String> negative;

  factory EmployeePointsCategoriesModel.fromJson(Map<String, dynamic> json) {
    final j = asMap(json);
    final c = asMap(j['categories']);
    return EmployeePointsCategoriesModel(
      positive: asStringList(c['positive']),
      negative: asStringList(c['negative']),
    );
  }
}
