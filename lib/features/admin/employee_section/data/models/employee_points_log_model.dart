import '../../../../../core/helpers/json_safe_parser.dart';

class EmployeePointsLogModel {
  const EmployeePointsLogModel({
    required this.id,
    required this.employeeId,
    required this.points,
    required this.operationType,
    required this.category,
    this.categoryId,
    this.categoryNameAr,
    this.categoryNameEn,
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
  final int? categoryId;
  final String? categoryNameAr;
  final String? categoryNameEn;
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
      categoryId: j['category_id'] == null ? null : asInt(j['category_id']),
      categoryNameAr: asNullableString(j['category_name_ar']),
      categoryNameEn: asNullableString(j['category_name_en']),
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
    this.rewardRuleId,
    this.rewardStatusLabel,
    this.rewardStatusColor,
  });

  final int month;
  final int year;
  final int earnedPoints;
  final int deductedPoints;
  final int netPoints;
  final String rewardAmount; // formatted "0.00"
  final int? matchedRuleId;
  final int? rewardRuleId;
  final String? rewardStatusLabel;
  final String? rewardStatusColor;

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
      rewardRuleId:
          s['reward_rule_id'] == null ? null : asInt(s['reward_rule_id']),
      rewardStatusLabel: asNullableString(s['reward_status_label']),
      rewardStatusColor: asNullableString(s['reward_status_color']),
    );
  }
}

class EmployeePointsCategoriesModel {
  const EmployeePointsCategoriesModel({
    required this.positive,
    required this.negative,
    this.configurable = const <EmployeePointCategoryModel>[],
  });

  final List<String> positive;
  final List<String> negative;
  final List<EmployeePointCategoryModel> configurable;

  factory EmployeePointsCategoriesModel.fromJson(Map<String, dynamic> json) {
    final j = asMap(json);
    final c = asMap(j['categories']);
    return EmployeePointsCategoriesModel(
      positive: asStringList(c['positive']),
      negative: asStringList(c['negative']),
      configurable: mapList(
        j['configurable_categories'],
        (Map<String, dynamic> m) => EmployeePointCategoryModel.fromJson(m),
      ),
    );
  }
}

/// Configurable category record managed via the admin settings screen. Each
/// row defines a behavior (prayer, lateness, ...) along with its default
/// points and operation type so the points dialog can auto-fill values.
class EmployeePointCategoryModel {
  const EmployeePointCategoryModel({
    required this.id,
    required this.nameAr,
    this.nameEn,
    required this.code,
    required this.operationType,
    required this.defaultPoints,
    required this.isActive,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String nameAr;
  final String? nameEn;
  final String code;
  final String operationType; // 'add' | 'deduct'
  final int defaultPoints;
  final bool isActive;
  final int sortOrder;
  final String? createdAt;
  final String? updatedAt;

  bool get isAdd => operationType == 'add';
  bool get isDeduct => operationType == 'deduct';
  int get signedDefault => isAdd ? defaultPoints : -defaultPoints;

  factory EmployeePointCategoryModel.fromJson(Map<String, dynamic> json) {
    final j = asMap(json);
    return EmployeePointCategoryModel(
      id: asInt(j['id']),
      nameAr: asString(j['name_ar']),
      nameEn: asNullableString(j['name_en']),
      code: asString(j['code']),
      operationType: asString(j['operation_type'], 'add'),
      defaultPoints: asInt(j['default_points'], 1),
      isActive: asBool(j['is_active'], true),
      sortOrder: asInt(j['sort_order']),
      createdAt: asNullableString(j['created_at']),
      updatedAt: asNullableString(j['updated_at']),
    );
  }

  EmployeePointCategoryModel copyWith({
    int? id,
    String? nameAr,
    String? nameEn,
    String? code,
    String? operationType,
    int? defaultPoints,
    bool? isActive,
    int? sortOrder,
  }) {
    return EmployeePointCategoryModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      code: code ?? this.code,
      operationType: operationType ?? this.operationType,
      defaultPoints: defaultPoints ?? this.defaultPoints,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Per-employee row used by the global points screen + employees list +
/// reports. Wraps the points summary plus the colour/status badge.
class EmployeePointsRowModel {
  const EmployeePointsRowModel({
    required this.employeeId,
    this.employeeName,
    this.employeeImg,
    required this.earnedPoints,
    required this.deductedPoints,
    required this.netPoints,
    required this.rewardAmount,
    this.rewardRuleId,
    this.rewardStatusLabel,
    this.rewardStatusColor,
    this.logs = const <EmployeePointsLogModel>[],
  });

  final int employeeId;
  final String? employeeName;
  final String? employeeImg;
  final int earnedPoints;
  final int deductedPoints;
  final int netPoints;
  final String rewardAmount;
  final int? rewardRuleId;
  final String? rewardStatusLabel;
  final String? rewardStatusColor;
  final List<EmployeePointsLogModel> logs;

  double get rewardAmountDouble =>
      double.tryParse(rewardAmount.toString()) ?? 0.0;

  factory EmployeePointsRowModel.fromJson(Map<String, dynamic> json) {
    final j = asMap(json);
    return EmployeePointsRowModel(
      employeeId: asInt(j['employee_id']),
      employeeName: asNullableString(j['employee_name']),
      employeeImg: asNullableString(j['employee_img']),
      earnedPoints: asInt(j['earned_points']),
      deductedPoints: asInt(j['deducted_points']),
      netPoints: asInt(j['net_points']),
      rewardAmount: asString(j['reward_amount'], '0.00'),
      rewardRuleId:
          j['reward_rule_id'] == null ? null : asInt(j['reward_rule_id']),
      rewardStatusLabel: asNullableString(j['reward_status_label']),
      rewardStatusColor: asNullableString(j['reward_status_color']),
      logs: mapList(
        j['logs'],
        (Map<String, dynamic> m) => EmployeePointsLogModel.fromJson(m),
      ),
    );
  }
}

/// Aggregate response of the global points report endpoint.
class EmployeePointsReportModel {
  const EmployeePointsReportModel({
    required this.month,
    required this.year,
    required this.employees,
    required this.totalEarnedPoints,
    required this.totalDeductedPoints,
    required this.totalNetPoints,
    required this.totalRewardAmount,
  });

  final int month;
  final int year;
  final List<EmployeePointsRowModel> employees;
  final int totalEarnedPoints;
  final int totalDeductedPoints;
  final int totalNetPoints;
  final String totalRewardAmount;

  factory EmployeePointsReportModel.fromJson(Map<String, dynamic> json) {
    final j = asMap(json);
    final d = asMap(j['data']);
    final totals = asMap(d['totals']);
    return EmployeePointsReportModel(
      month: asInt(d['month']),
      year: asInt(d['year']),
      employees: mapList(
        d['employees'],
        (Map<String, dynamic> m) => EmployeePointsRowModel.fromJson(m),
      ),
      totalEarnedPoints: asInt(totals['earned_points']),
      totalDeductedPoints: asInt(totals['deducted_points']),
      totalNetPoints: asInt(totals['net_points']),
      totalRewardAmount: asString(totals['reward_amount'], '0.00'),
    );
  }
}
