import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class ProjectExpensesModel {
  final List<ProjectExpense> projectExpenses;
  final double totalExpenses;

  ProjectExpensesModel({
    required this.projectExpenses,
    required this.totalExpenses,
  });

  factory ProjectExpensesModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ProjectExpensesModel(
      projectExpenses:
          mapList(j['project_expenses'], (m) => ProjectExpense.fromJson(m)),
      totalExpenses: asDouble(j['total_expenses']),
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
    final j = Map<String, dynamic>.from(json);
    return ProjectExpense(
      id: asInt(j['id']),
      projectId: asString(j['project_id']),
      expenses: asDouble(j['expenses']),
      notes: asString(j['notes']),
      createdAt: parseApiDateTime(j['created_at']),
      updatedAt: parseApiDateTime(j['updated_at']),
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
