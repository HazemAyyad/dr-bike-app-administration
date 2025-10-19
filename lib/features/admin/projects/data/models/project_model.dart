class ProjectModel {
  final int id;
  final String name;
  final double achievementPercentage;
  final double projectCost;
  final String status;

  ProjectModel({
    required this.id,
    required this.name,
    required this.achievementPercentage,
    required this.projectCost,
    required this.status,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      name: json['name'],
      achievementPercentage:
          double.tryParse(json['achievement_percentage'].toString()) ?? 0.0,
      projectCost: double.tryParse(json['project_cost'].toString()) ?? 0.0,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'achievement_percentage': achievementPercentage.toString(),
      'project_cost': projectCost.toString(),
      'status': status,
    };
  }
}
