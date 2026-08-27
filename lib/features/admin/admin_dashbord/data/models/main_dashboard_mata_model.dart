class MainDashboardDataModel {
  final String totalDebtsWeOwe;
  final String totalDebtsOwedToUs;
  final String totalProducts;
  final String numberOfEmployees;
  final String totalExpenses;
  final String totalCompletedTasks;
  final String totalIncompletedTasks;
  final Map<String, int> dashboardBadges;
  final List<DashboardCheckModel> upcomingIncomingChecks;
  final List<DashboardCheckModel> upcomingOutgoingChecks;

  MainDashboardDataModel({
    required this.totalDebtsWeOwe,
    required this.totalDebtsOwedToUs,
    required this.totalProducts,
    required this.numberOfEmployees,
    required this.totalExpenses,
    required this.totalCompletedTasks,
    required this.totalIncompletedTasks,
    this.dashboardBadges = const {},
    this.upcomingIncomingChecks = const [],
    this.upcomingOutgoingChecks = const [],
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
      upcomingIncomingChecks: _parseChecks(json['upcoming_incoming_checks']),
      upcomingOutgoingChecks: _parseChecks(json['upcoming_outgoing_checks']),
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
      'upcoming_incoming_checks':
          upcomingIncomingChecks.map((e) => e.toJson()).toList(),
      'upcoming_outgoing_checks':
          upcomingOutgoingChecks.map((e) => e.toJson()).toList(),
    };
  }
}

class DashboardCheckModel {
  final int id;
  final String checkId;
  final String bankName;
  final String personName;
  final double total;
  final String currency;
  final DateTime? dueDate;
  final String notes;

  const DashboardCheckModel({
    required this.id,
    required this.checkId,
    required this.bankName,
    required this.personName,
    required this.total,
    required this.currency,
    required this.dueDate,
    required this.notes,
  });

  factory DashboardCheckModel.fromJson(Map<String, dynamic> json) =>
      DashboardCheckModel(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        checkId: json['check_id']?.toString() ?? '-',
        bankName: json['bank_name']?.toString() ?? '-',
        personName: json['person_name']?.toString() ?? '-',
        total: double.tryParse(json['total']?.toString() ?? '') ?? 0,
        currency: json['currency']?.toString() ?? '',
        dueDate: DateTime.tryParse(json['due_date']?.toString() ?? ''),
        notes: json['notes']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'check_id': checkId,
        'bank_name': bankName,
        'person_name': personName,
        'total': total,
        'currency': currency,
        'due_date': dueDate?.toIso8601String(),
        'notes': notes,
      };
}

List<DashboardCheckModel> _parseChecks(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => DashboardCheckModel.fromJson(item.cast<String, dynamic>()))
      .toList(growable: false);
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
