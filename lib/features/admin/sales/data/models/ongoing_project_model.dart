import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class OngoingProject {
  final int id;
  final String name;

  OngoingProject({
    required this.id,
    required this.name,
  });

  factory OngoingProject.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return OngoingProject(
      id: asInt(j['id']),
      name: asString(j['name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
