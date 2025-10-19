class ReportInformationModel {
  final String totalDebtsWeOwe;
  final String totalSales;
  final String profits;
  final String totalBoxes;
  final String totalChecks;
  final String totalBills;
  final String numberOfPeople;
  final String numberOfProjects;
  final String numberOfEmployees;
  final String totalExpenses;
  final String totalReturns;
  final String totalGoods;
  final String shopCapital;
  final String netShopCapital;
  final String completedEmployeeTasksDaily;
  final String incompletedEmployeeTasksDaily;
  final String completedEmployeeTasksMonthly;
  final String incompletedEmployeeTasksMonthly;

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
      totalDebtsWeOwe: json['total_debts_we_owe']?.toString() ?? "0",
      totalSales: json['total_sales']?.toString() ?? "0",
      profits: json['profits']?.toString() ?? "0",
      totalBoxes: json['total_boxes']?.toString() ?? "0",
      totalChecks: json['total_checks']?.toString() ?? "0",
      totalBills: json['total_bills']?.toString() ?? "0",
      numberOfPeople: json['number_of_people']?.toString() ?? "0",
      numberOfProjects: json['number_of_projects']?.toString() ?? "0",
      numberOfEmployees: json['number_of_employees']?.toString() ?? "0",
      totalExpenses: json['total_expenses']?.toString() ?? "0",
      totalReturns: json['total_returns']?.toString() ?? "0",
      totalGoods: json['total_goods']?.toString() ?? "0",
      shopCapital: json['shop_capital']?.toString() ?? "0",
      netShopCapital: json['net_shop_capital']?.toString() ?? "0",
      completedEmployeeTasksDaily:
          json['completed_employee_tasks_daily']?.toString() ?? "0",
      incompletedEmployeeTasksDaily:
          json['incompleted_employee_tasks_daily']?.toString() ?? "0",
      completedEmployeeTasksMonthly:
          json['completed_employee_tasks_monthly']?.toString() ?? "0",
      incompletedEmployeeTasksMonthly:
          json['incompleted_employee_tasks_monthly']?.toString() ?? "0",
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
