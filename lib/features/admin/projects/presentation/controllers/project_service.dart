import 'package:get/get.dart';

import '../../data/models/project_details_model.dart';
import '../../data/models/project_expenses_model.dart';
import '../../data/models/project_model.dart';
import '../../data/models/project_sale_model.dart';

class ProjectService {
  // assets
  final List<ProjectModel> ongoingProjects = [];

  final List<ProjectModel> completedProjects = [];

  final Rxn<ProjectDetailsModel> projectDetails = Rxn<ProjectDetailsModel>();

  final Rxn<ProjectExpensesModel> projectExpenses = Rxn<ProjectExpensesModel>();

  final Rxn<ProjectSaleModel> projectSales = Rxn<ProjectSaleModel>();

  // singleton pattern
  static final ProjectService _instance = ProjectService._internal();
  factory ProjectService() => _instance;
  ProjectService._internal();
}
