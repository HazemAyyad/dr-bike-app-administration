import 'package:get/get.dart';

import '../../data/models/project_details_model.dart';
import '../../data/models/project_model.dart';

class ProjectService {
  // assets
  final List<ProjectModel> ongoingProjects = [];

  final List<ProjectModel> completedProjects = [];

  final Rxn<ProjectDetailsModel> projectDetails = Rxn<ProjectDetailsModel>();

  // singleton pattern
  static final ProjectService _instance = ProjectService._internal();
  factory ProjectService() => _instance;
  ProjectService._internal();
}
