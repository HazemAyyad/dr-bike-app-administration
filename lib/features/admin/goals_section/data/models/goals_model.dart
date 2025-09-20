class GoalsModel {
  final int id;
  final String type;
  final String name;
  final String achievementPercentage;
  final String targetValue;
  final String currentValue;
  final bool isCanceled;
  final DateTime createdAt;

  GoalsModel({
    required this.id,
    required this.type,
    required this.name,
    required this.achievementPercentage,
    required this.targetValue,
    required this.currentValue,
    required this.isCanceled,
    required this.createdAt,
  });

  factory GoalsModel.fromJson(Map<String, dynamic> json) {
    return GoalsModel(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      achievementPercentage: json['achievement_percentage']?.toString() ?? '0',
      targetValue: json['targeted_value']?.toString() ?? '0',
      currentValue: json['current_value']?.toString() ?? '0',
      isCanceled: json['is_canceled'].toString() == "1",
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "type": type,
      "name": name,
      "achievement_percentage": achievementPercentage,
      "targeted_value": targetValue,
      "current_value": currentValue,
      "is_canceled": isCanceled ? "1" : "0",
      "created_at": createdAt.toIso8601String(),
    };
  }
}
