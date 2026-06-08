import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/task_details_debug.dart';
import '../../../../../core/helpers/task_nav_debug.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/task_details_model.dart';
import '../controllers/employee_tasks_controller.dart';
import '../../../../../routes/app_routes.dart';
import 'employee_task_completion_screen.dart';
import 'employee_task_details_operational_screen.dart';

/// Routes task details to admin review UI or employee completion UI.
class TaskDetailsEntryScreen extends StatefulWidget {
  const TaskDetailsEntryScreen({Key? key}) : super(key: key);

  @override
  State<TaskDetailsEntryScreen> createState() => _TaskDetailsEntryScreenState();
}

class _TaskDetailsEntryScreenState extends State<TaskDetailsEntryScreen> {
  String? _taskId;
  String? _occurrenceId;
  String? _taskDate;
  bool _loadStarted = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments is Map<String, dynamic>
        ? Get.arguments as Map<String, dynamic>
        : <String, dynamic>{};
    _taskId = args['taskId']?.toString();
    _occurrenceId = args['occurrence_id']?.toString();
    _taskDate = args['task_date']?.toString();
    _startLoad();
  }

  Future<void> _startLoad() async {
    if (_loadStarted) return;
    _loadStarted = true;

    final hasId = (_taskId != null && _taskId!.isNotEmpty) ||
        (_occurrenceId != null && _occurrenceId!.isNotEmpty);

    if (!hasId || !Get.isRegistered<EmployeeTasksController>()) {
      TaskDetailsDebug.fail(
        'entry_screen_missing_context',
        detail: {'taskId': _taskId, 'occurrenceId': _occurrenceId},
      );
      return;
    }

    TaskDetailsDebug.screen(
      phase: 'entry_load_start',
      taskId: _taskId,
      occurrenceId: _occurrenceId,
    );
    final c = Get.find<EmployeeTasksController>();
    try {
      await c.getTaskDetails(
        taskId: _taskId ?? '',
        occurrenceId: _occurrenceId,
        taskDate: _taskDate,
      );
    } catch (e, st) {
      TaskDetailsDebug.parseError(e, st);
      if (mounted) setState(() {});
    }
    TaskDetailsDebug.screen(
      phase: 'entry_load_done',
      taskId: _taskId,
      occurrenceId: _occurrenceId,
      note: c.employeeTaskService.taskDetails.value == null
          ? 'details=null'
          : 'details=loaded',
    );
    if (mounted) setState(() {});
  }

  bool _detailsMatchRequest(TaskDetailsModel? data) {
    if (data == null) return false;
    if (_occurrenceId != null && _occurrenceId!.isNotEmpty) {
      return data.occurrenceId?.toString() == _occurrenceId;
    }
    if (_taskId != null && _taskId!.isNotEmpty) {
      return data.taskId.toString() == _taskId;
    }
    return false;
  }

  bool get _loadFailed =>
      _loadStarted &&
      !Get.find<EmployeeTasksController>().isTaskDetailsLoading.value &&
      Get.find<EmployeeTasksController>().employeeTaskService.taskDetails.value ==
          null;

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments is Map<String, dynamic>
        ? Get.arguments as Map<String, dynamic>
        : <String, dynamic>{};
    final viewMode = args['viewMode']?.toString();
    final role = sessionUserType.value.isNotEmpty
        ? sessionUserType.value
        : userType;
    final useCompletion =
        viewMode == 'complete' || (viewMode == null && role != 'admin');

    if (!Get.isRegistered<EmployeeTasksController>()) {
      return Scaffold(
        body: Center(child: Text('errorLoadingTaskDetails'.tr)),
      );
    }

    final c = Get.find<EmployeeTasksController>();

    return Obx(() {
      final loading = c.isTaskDetailsLoading.value;
      final data = c.employeeTaskService.taskDetails.value;
      final ready = !loading && _detailsMatchRequest(data);

      if (!ready && _loadFailed) {
        return Scaffold(
          backgroundColor: AppColors.operationalSurface,
          body: Center(child: Text('errorLoadingTaskDetails'.tr)),
        );
      }

      if (!ready) {
        return const Scaffold(
          backgroundColor: AppColors.operationalSurface,
          body: Center(
            child: CircularProgressIndicator(
              color: AppColors.operationalPurple,
            ),
          ),
        );
      }

      if (useCompletion) {
        TaskNavDebug.log(
          'TaskDetailsEntryScreen',
          AppRoutes.TASKDETAILS,
          screen: 'EmployeeTaskCompletionScreen',
          extra: args,
        );
        return const EmployeeTaskCompletionScreen();
      }

      TaskNavDebug.log(
        'TaskDetailsEntryScreen',
        AppRoutes.TASKDETAILS,
        screen: 'EmployeeTaskDetailsOperationalScreen',
        extra: args,
      );
      return const EmployeeTaskDetailsOperationalScreen();
    });
  }
}
