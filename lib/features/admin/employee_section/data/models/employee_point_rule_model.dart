import '../../../../../core/helpers/json_safe_parser.dart';

class EmployeePointRuleModel {
  const EmployeePointRuleModel({
    required this.id,
    required this.name,
    this.description,
    required this.conditionType,
    required this.periodType,
    required this.operationType,
    required this.defaultPoints,
    required this.appliesToAll,
    required this.settings,
    this.effectiveFrom,
    required this.isActive,
    required this.sortOrder,
    required this.employeeIds,
  });

  final int id;
  final String name;
  final String? description;
  final String conditionType;
  final String periodType;
  final String operationType;
  final int defaultPoints;
  final bool appliesToAll;
  final Map<String, dynamic> settings;
  final String? effectiveFrom;
  final bool isActive;
  final int sortOrder;
  final List<int> employeeIds;

  String get cutoffTime => settings['cutoff_time']?.toString() ?? '02:00';

  factory EmployeePointRuleModel.fromJson(Map<String, dynamic> json) {
    final j = asMap(json);
    final rawEmployeeIds = j['employee_ids'];
    return EmployeePointRuleModel(
      id: asInt(j['id']),
      name: asString(j['name']),
      description: asNullableString(j['description']),
      conditionType: asString(j['condition_type']),
      periodType: asString(j['period_type'], 'daily'),
      operationType: asString(j['operation_type'], 'add'),
      defaultPoints: asInt(j['default_points']),
      appliesToAll: asBool(j['applies_to_all'], true),
      settings: asMap(j['settings']),
      effectiveFrom: asNullableString(j['effective_from']),
      isActive: asBool(j['is_active'], true),
      sortOrder: asInt(j['sort_order']),
      employeeIds: rawEmployeeIds is List
          ? rawEmployeeIds.map((e) => asInt(e)).where((e) => e > 0).toList()
          : const <int>[],
    );
  }
}

class EmployeePointRuleOverrideModel {
  const EmployeePointRuleOverrideModel({
    required this.id,
    required this.ruleId,
    required this.employeeId,
    this.ruleName,
    this.points,
    this.operationType,
    required this.isExcluded,
    this.effectiveFrom,
    this.notes,
  });

  final int id;
  final int ruleId;
  final int employeeId;
  final String? ruleName;
  final int? points;
  final String? operationType;
  final bool isExcluded;
  final String? effectiveFrom;
  final String? notes;

  factory EmployeePointRuleOverrideModel.fromJson(Map<String, dynamic> json) {
    final j = asMap(json);
    return EmployeePointRuleOverrideModel(
      id: asInt(j['id']),
      ruleId: asInt(j['rule_id']),
      employeeId: asInt(j['employee_id']),
      ruleName: asNullableString(j['rule_name']),
      points: j['points'] == null ? null : asInt(j['points']),
      operationType: asNullableString(j['operation_type']),
      isExcluded: asBool(j['is_excluded']),
      effectiveFrom: asNullableString(j['effective_from']),
      notes: asNullableString(j['notes']),
    );
  }
}
