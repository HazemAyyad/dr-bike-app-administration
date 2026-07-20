class MainDashboardDataModel {
  final String totalDebtsWeOwe;
  final String totalDebtsOwedToUs;
  final String totalProducts;
  final String numberOfEmployees;
  final String totalExpenses;
  final String totalCompletedTasks;
  final String totalIncompletedTasks;
  final Map<String, int> dashboardBadges;

  MainDashboardDataModel({
    required this.totalDebtsWeOwe,
    required this.totalDebtsOwedToUs,
    required this.totalProducts,
    required this.numberOfEmployees,
    required this.totalExpenses,
    required this.totalCompletedTasks,
    required this.totalIncompletedTasks,
    this.dashboardBadges = const {},
  });

  factory MainDashboardDataModel.fromJson(Map<String, dynamic> json) {
    return MainDashboardDataModel(
      totalDebtsWeOwe: json['total_debts_we_owe'].toString(),
      totalDebtsOwedToUs: json['total_debts_owed_to_us'].toString(),
      totalProducts: json['total_products'].toString(),
      numberOfEmployees: json['number_of_employees'].toString(),
      totalExpenses: json['total_expenses'].toString(),
      totalCompletedTasks: json['total_completed_tasks'].toString(),
      totalIncompletedTasks: json['total_incompleted_tasks'].toString(),
      dashboardBadges: _parseBadges(json['dashboard_badges']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_debts_we_owe': totalDebtsWeOwe,
      'total_debts_owed_to_us': totalDebtsOwedToUs,
      'total_products': totalProducts,
      'number_of_employees': numberOfEmployees,
      'total_expenses': totalExpenses,
      'total_completed_tasks': totalCompletedTasks,
      'total_incompleted_tasks': totalIncompletedTasks,
      'dashboard_badges': dashboardBadges,
    };
  }
}

Map<String, int> _parseBadges(dynamic raw) {
  if (raw is! Map) return const {};
  return raw.map(
    (key, value) => MapEntry(
      key.toString(),
      int.tryParse(value?.toString() ?? '') ?? 0,
    ),
  );
}
