import '../../data/models/dashbord_employee_details_model.dart';

/// Active employee tasks (legacy ongoing + v2 workflow statuses).
bool isEmployeeTaskActive(String status) {
  const active = {
    'ongoing',
    'pending',
    'in_progress',
    'waiting_review',
    'overdue',
  };
  return active.contains(status);
}

bool isEmployeeTaskOnToday(DateTime dateTime) {
  final local = dateTime.toLocal();
  final now = DateTime.now();
  return local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
}

bool isDashboardTask(Task task) =>
    isEmployeeTaskActive(task.status) && isEmployeeTaskOnToday(task.startTime);
