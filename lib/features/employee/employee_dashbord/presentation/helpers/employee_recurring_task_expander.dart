import '../../../../../core/helpers/task_recurrence_rules.dart';
import '../../data/models/dashbord_employee_details_model.dart';
import '../controllers/employee_dashbord_controller.dart';

class EmployeeRecurringTaskExpander {
  static Map<String, List<Task>> expand({
    required Map<String, List<Task>> source,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    List<String> weeklyDaysOff = const [],
  }) {
    final flat = source.values.expand((e) => e).toList();
    final start = TaskRecurrenceRules.dayStart(rangeStart);
    final end = TaskRecurrenceRules.dayStart(rangeEnd);
    final result = <String, List<Task>>{};

    void add(Task task, DateTime day) {
      final key = EmployeeDashbordController.dateKeyFrom(day);
      final list = result.putIfAbsent(key, () => []);
      final logicalId = task.isRepeatedCopy ? task.id : task.taskId;
      final exists = list.any(
        (t) {
          final existingId = t.isRepeatedCopy ? t.id : t.taskId;
          return existingId == logicalId &&
              TaskRecurrenceRules.sameDay(t.startTime, day);
        },
      );
      if (!exists) list.add(task);
    }

    for (final task in flat) {
      if (_shouldExpand(task)) continue;
      add(task, task.startTime);
    }

    for (final parent in flat.where(_shouldExpand)) {
      for (var day = start;
          !day.isAfter(end);
          day = day.add(const Duration(days: 1))) {
        if (!_matches(parent, day, weeklyDaysOff)) continue;
        add(resolveDayInstance(flat, parent, day), day);
      }
    }

    return result;
  }

  /// Prefer the DB child row for [day]; otherwise a fresh virtual instance.
  static Task resolveDayInstance(List<Task> flat, Task parent, DateTime day) {
    final child = findChildForDay(flat, parent.taskId, day);
    if (child != null) {
      return child;
    }
    if (TaskRecurrenceRules.sameDay(parent.startTime, day)) {
      return parent;
    }
    return parent.virtualDayInstance(day);
  }

  static Task? findChildForDay(List<Task> flat, int parentId, DateTime day) {
    final parentKey = '$parentId';
    for (final task in flat) {
      if (task.parentId == parentKey &&
          TaskRecurrenceRules.sameDay(task.startTime, day)) {
        return task;
      }
    }
    return null;
  }

  static bool _shouldExpand(Task task) => TaskRecurrenceRules.shouldExpand(
        source: task.source,
        parentId: task.parentId,
        recurrence: task.taskRecurrence,
      );

  static bool _matches(Task task, DateTime day, List<String> weeklyDaysOff) =>
      TaskRecurrenceRules.matchesRecurrenceOnDate(
        taskStart: task.startTime,
        recurrence: task.taskRecurrence,
        recurrenceTimes: task.taskRecurrenceTime,
        day: day,
        taskEnd: task.endTime,
        weeklyDaysOff: weeklyDaysOff,
      );
}
