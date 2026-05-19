import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/task_nav_debug.dart';
import '../../../../../routes/app_routes.dart';
import 'create_employee_task_screen.dart';
import 'create_task_screen.dart';

/// Routes create/edit flows to the correct UI (operational vs legacy special tasks).
class CreateTaskEntryScreen extends StatelessWidget {
  const CreateTaskEntryScreen({Key? key}) : super(key: key);

  static bool _isEmployeeTaskFlow(Map<String, dynamic>? args) {
    final title = args?['title']?.toString() ?? '';
    return title == 'createNewEmployeeTask' || title == 'editEmployeeTask';
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments is Map<String, dynamic>
        ? Get.arguments as Map<String, dynamic>
        : <String, dynamic>{};

    if (_isEmployeeTaskFlow(args)) {
      TaskNavDebug.log(
        'CreateTaskEntryScreen',
        AppRoutes.CREATETASKSCREEN,
        screen: 'CreateEmployeeTaskScreen',
        extra: args,
      );
      return const CreateEmployeeTaskScreen();
    }

    TaskNavDebug.log(
      'CreateTaskEntryScreen',
      AppRoutes.CREATETASKSCREEN,
      screen: 'CreateTaskScreen (legacy special tasks)',
      extra: args,
    );
    return const CreateTaskScreen();
  }
}
