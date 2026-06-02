import 'package:flutter/material.dart';

import '../../data/models/dashbord_employee_details_model.dart';
import 'employee_operational_task_card.dart';

/// Legacy export — uses operational card UI.
class EmployeeDashbordTasks extends StatelessWidget {
  const EmployeeDashbordTasks({Key? key, required this.task}) : super(key: key);

  final Task task;

  @override
  Widget build(BuildContext context) {
    return EmployeeOperationalTaskCard(task: task, showCheckbox: false);
  }
}
