class MainDashboardDataModel {
  final String totalDebtsWeOwe;
  final String totalDebtsOwedToUs;
  final String totalProducts;
  final String numberOfEmployees;
  final String totalExpenses;
  final String totalCompletedTasks;
  final String totalIncompletedTasks;

  MainDashboardDataModel({
    required this.totalDebtsWeOwe,
    required this.totalDebtsOwedToUs,
    required this.totalProducts,
    required this.numberOfEmployees,
    required this.totalExpenses,
    required this.totalCompletedTasks,
    required this.totalIncompletedTasks,
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
    };
  }
}
