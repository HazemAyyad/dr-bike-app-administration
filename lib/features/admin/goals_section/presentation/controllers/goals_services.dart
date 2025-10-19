import 'package:get/get.dart';

import '../../data/models/goals_model.dart';

class GoalsServices {
  final List<GoalsModel> globalGoalsList = <GoalsModel>[].obs;

  final RxList<GoalsModel> privateGoalsList = <GoalsModel>[].obs;

  final RxList<GoalsModel> archiveGoalsList = <GoalsModel>[].obs;

  // singleton pattern
  static final GoalsServices _instance = GoalsServices._internal();
  factory GoalsServices() => _instance;
  GoalsServices._internal();
}
