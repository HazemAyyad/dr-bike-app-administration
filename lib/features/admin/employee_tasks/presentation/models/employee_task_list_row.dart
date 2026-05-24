import '../../data/models/employee_task_model.dart';

/// Flat list row: day header or single task (for lazy SliverList).
class EmployeeTaskListRow {
  const EmployeeTaskListRow.header(this.dayKey, {this.isFirstHeader = false})
      : task = null,
        isHeader = true;

  const EmployeeTaskListRow.task(this.task)
      : dayKey = null,
        isHeader = false,
        isFirstHeader = false;

  final bool isHeader;
  final bool isFirstHeader;
  final String? dayKey;
  final EmployeeTaskModel? task;
}
