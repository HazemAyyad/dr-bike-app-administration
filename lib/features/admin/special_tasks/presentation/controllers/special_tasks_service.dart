import 'package:get/get.dart';

import '../../data/models/special_task_details_model.dart';
import '../../data/models/special_task_model.dart';

class SpecialTasksService {
  Rxn<SpecialTaskDetailsModel> specialTaskDetails =
      Rxn<SpecialTaskDetailsModel>();

  final weeklyTasks = <String, List<SpecialTaskModel>>{}.obs;

  final noDateTasks = <String, List<SpecialTaskModel>>{}.obs;

  final archivedTasks = <String, List<SpecialTaskModel>>{}.obs;

  // singleton pattern
  static final SpecialTasksService _instance = SpecialTasksService._internal();
  factory SpecialTasksService() => _instance;
  SpecialTasksService._internal();
}
