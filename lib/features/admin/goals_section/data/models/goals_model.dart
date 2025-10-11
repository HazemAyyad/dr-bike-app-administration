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
    return GoalsModel(
      id: json['id'] ?? 0,
      scope: json['scope'] ?? '',
      name: json['name'] ?? '',
      achievementPercentage: json['achievement_percentage']?.toString() ?? '0',
      targetValue: json['targeted_value']?.toString() ?? '0',
      currentValue: json['current_value']?.toString() ?? '0',
      isCanceled: json['is_canceled'].toString() == "1",
      createdAt: DateTime.parse(json['created_at']),
      dueDate: DateTime.parse(json['due_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "scope": scope,
      "name": name,
      "achievement_percentage": achievementPercentage,
      "targeted_value": targetValue,
      "current_value": currentValue,
      "is_canceled": isCanceled ? "1" : "0",
      "created_at": createdAt.toIso8601String(),
      "due_date": dueDate.toIso8601String(),
    };
  }
}
