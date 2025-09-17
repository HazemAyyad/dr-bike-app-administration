class ReportInformationModel {
  final int totalDebtsWeOwe;
  final String totalSales;
  final int profits;
  final String totalBoxes;
  final int totalChecks;
  final int totalBills;
  final int numberOfPeople;
  final int numberOfProjects;
  final int numberOfEmployees;
  final String totalExpenses;
  final int totalReturns;
  final int totalGoods;
  final int shopCapital;
  final int netShopCapital;
  final int completedEmployeeTasksDaily;
  final int incompletedEmployeeTasksDaily;
  final int completedEmployeeTasksMonthly;
  final int incompletedEmployeeTasksMonthly;

  ReportInformationModel({
    required this.totalDebtsWeOwe,
    required this.totalSales,
    required this.profits,
    required this.totalBoxes,
    required this.totalChecks,
    required this.totalBills,
    required this.numberOfPeople,
    required this.numberOfProjects,
    required this.numberOfEmployees,
    required this.totalExpenses,
    required this.totalReturns,
    required this.totalGoods,
    required this.shopCapital,
    required this.netShopCapital,
    required this.completedEmployeeTasksDaily,
    required this.incompletedEmployeeTasksDaily,
    required this.completedEmployeeTasksMonthly,
    required this.incompletedEmployeeTasksMonthly,
  });

  factory ReportInformationModel.fromJson(Map<String, dynamic> json) {
    return ReportInformationModel(
      totalDebtsWeOwe: json['total_debts_we_owe'] ?? 0,
      totalSales: json['total_sales'] ?? "0",
      profits: json['profits'] ?? 0,
      totalBoxes: json['total_boxes'] ?? "0",
      totalChecks: json['total_checks'] ?? 0,
      totalBills: json['total_bills'] ?? 0,
      numberOfPeople: json['number_of_people'] ?? 0,
      numberOfProjects: json['number_of_projects'] ?? 0,
      numberOfEmployees: json['number_of_employees'] ?? 0,
      totalExpenses: json['total_expenses'] ?? "0",
      totalReturns: json['total_returns'] ?? 0,
      totalGoods: json['total_goods'] ?? 0,
      shopCapital: json['shop_capital'] ?? 0,
      netShopCapital: json['net_shop_capital'] ?? 0,
      completedEmployeeTasksDaily: json['completed_employee_tasks_daily'] ?? 0,
      incompletedEmployeeTasksDaily:
          json['incompleted_employee_tasks_daily'] ?? 0,
      completedEmployeeTasksMonthly:
          json['completed_employee_tasks_monthly'] ?? 0,
      incompletedEmployeeTasksMonthly:
          json['incompleted_employee_tasks_monthly'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_debts_we_owe': totalDebtsWeOwe,
      'total_sales': totalSales,
      'profits': profits,
      'total_boxes': totalBoxes,
      'total_checks': totalChecks,
      'total_bills': totalBills,
      'number_of_people': numberOfPeople,
      'number_of_projects': numberOfProjects,
      'number_of_employees': numberOfEmployees,
      'total_expenses': totalExpenses,
      'total_returns': totalReturns,
      'total_goods': totalGoods,
      'shop_capital': shopCapital,
      'net_shop_capital': netShopCapital,
      'completed_employee_tasks_daily': completedEmployeeTasksDaily,
      'incompleted_employee_tasks_daily': incompletedEmployeeTasksDaily,
      'completed_employee_tasks_monthly': completedEmployeeTasksMonthly,
      'incompleted_employee_tasks_monthly': incompletedEmployeeTasksMonthly,
    };
  }
}
