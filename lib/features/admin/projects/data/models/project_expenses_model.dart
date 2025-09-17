class ProjectExpensesModel {
  final List<ProjectExpense> projectExpenses;
  final double totalExpenses;

  ProjectExpensesModel({
    required this.projectExpenses,
    required this.totalExpenses,
  });

  factory ProjectExpensesModel.fromJson(Map<String, dynamic> json) {
    return ProjectExpensesModel(
      projectExpenses: (json['project_expenses'] as List<dynamic>? ?? [])
          .map((e) => ProjectExpense.fromJson(e))
          .toList(),
      totalExpenses: double.tryParse(json['total_expenses'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_expenses': projectExpenses.map((e) => e.toJson()).toList(),
      'total_expenses': totalExpenses,
    };
  }
}

class ProjectExpense {
  final int id;
  final String projectId;
  final double expenses;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectExpense({
    required this.id,
    required this.projectId,
    required this.expenses,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectExpense.fromJson(Map<String, dynamic> json) {
    return ProjectExpense(
      id: json['id'],
      projectId: json['project_id'].toString(),
      expenses: double.tryParse(json['expenses'].toString()) ?? 0.0,
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'expenses': expenses.toString(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
