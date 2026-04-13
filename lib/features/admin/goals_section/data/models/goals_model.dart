import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class GoalsModel {
  final int id;
  final String scope;
  final String name;
  final String achievementPercentage;
  final String targetValue;
  final String currentValue;
  final bool isCanceled;
  final DateTime createdAt;
  final DateTime dueDate;

  GoalsModel({
    required this.id,
    required this.scope,
    required this.name,
    required this.achievementPercentage,
    required this.targetValue,
    required this.currentValue,
    required this.isCanceled,
    required this.createdAt,
    required this.dueDate,
  });

  factory GoalsModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return GoalsModel(
      id: asInt(j['id']),
      scope: asString(j['scope']),
      name: asString(j['name']),
      achievementPercentage: asString(j['achievement_percentage'], '0'),
      targetValue: asString(j['targeted_value'], '0'),
      currentValue: asString(j['current_value'], '0'),
      isCanceled: asBool(j['is_canceled']),
      createdAt: parseApiDateTime(j['created_at']),
      dueDate: parseApiDateTime(j['due_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scope': scope,
      'name': name,
      'achievement_percentage': achievementPercentage,
      'targeted_value': targetValue,
      'current_value': currentValue,
      'is_canceled': isCanceled ? '1' : '0',
      'created_at': createdAt.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
    };
  }
}
