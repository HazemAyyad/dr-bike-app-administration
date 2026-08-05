import '../../../../../core/helpers/json_safe_parser.dart';

class EmployeeActivityLogsResult {
  final List<EmployeeActivityLogModel> logs;
  final EmployeeActivitySummary summary;
  final EmployeeActivityPagination pagination;
  final List<String> modules;

  const EmployeeActivityLogsResult({
    required this.logs,
    required this.summary,
    required this.pagination,
    required this.modules,
  });

  factory EmployeeActivityLogsResult.fromJson(Map<String, dynamic> json) {
    return EmployeeActivityLogsResult(
      logs: mapList(json['logs'], (m) => EmployeeActivityLogModel.fromJson(m)),
      summary: EmployeeActivitySummary.fromJson(asMap(json['summary'])),
      pagination:
          EmployeeActivityPagination.fromJson(asMap(json['pagination'])),
      modules: asStringList(json['modules']),
    );
  }
}

class EmployeeActivitySummary {
  final int totalLogs;
  final double salesAmount;
  final double debtsAmount;
  final int completedTasks;

  const EmployeeActivitySummary({
    required this.totalLogs,
    required this.salesAmount,
    required this.debtsAmount,
    required this.completedTasks,
  });

  factory EmployeeActivitySummary.fromJson(Map<String, dynamic> json) {
    return EmployeeActivitySummary(
      totalLogs: asInt(json['total_logs']),
      salesAmount: asDouble(json['sales_amount']),
      debtsAmount: asDouble(json['debts_amount']),
      completedTasks: asInt(json['completed_tasks']),
    );
  }
}

class EmployeeActivityPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const EmployeeActivityPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory EmployeeActivityPagination.fromJson(Map<String, dynamic> json) {
    return EmployeeActivityPagination(
      currentPage: asInt(json['current_page'], 1),
      lastPage: asInt(json['last_page'], 1),
      perPage: asInt(json['per_page'], 20),
      total: asInt(json['total']),
    );
  }
}

class EmployeeActivityLogModel {
  final int id;
  final String module;
  final String action;
  final String title;
  final String description;
  final double? amount;
  final String createdAt;
  final EmployeeActivityNavigation? navigation;

  const EmployeeActivityLogModel({
    required this.id,
    required this.module,
    required this.action,
    required this.title,
    required this.description,
    required this.amount,
    required this.createdAt,
    required this.navigation,
  });

  factory EmployeeActivityLogModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return EmployeeActivityLogModel(
      id: asInt(j['id']),
      module: asString(j['module']),
      action: asString(j['action']),
      title: asString(j['title']),
      description: asString(j['description']),
      amount: j['amount'] == null ? null : asDouble(j['amount']),
      createdAt: asString(j['created_at']),
      navigation: j['navigation'] == null
          ? null
          : EmployeeActivityNavigation.fromJson(asMap(j['navigation'])),
    );
  }
}

class EmployeeActivityNavigation {
  final String type;
  final int id;
  final String label;

  const EmployeeActivityNavigation({
    required this.type,
    required this.id,
    required this.label,
  });

  factory EmployeeActivityNavigation.fromJson(Map<String, dynamic> json) {
    return EmployeeActivityNavigation(
      type: asString(json['type']),
      id: asInt(json['id']),
      label: asString(json['label']),
    );
  }
}
