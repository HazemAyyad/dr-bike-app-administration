class OngoingProject {
  final int id;
  final String name;

  OngoingProject({
    required this.id,
    required this.name,
  });

  factory OngoingProject.fromJson(Map<String, dynamic> json) {
    return OngoingProject(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
