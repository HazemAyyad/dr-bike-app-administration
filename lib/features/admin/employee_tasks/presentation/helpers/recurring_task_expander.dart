import '../../../../../core/helpers/task_recurrence_rules.dart';

import '../../data/models/employee_task_model.dart';

import '../controllers/employee_tasks_controller.dart';



/// Expands legacy recurring parent tasks across calendar days in the visible range.

class RecurringTaskExpander {

  static Map<String, List<EmployeeTaskModel>> expand({

    required Map<String, List<EmployeeTaskModel>> source,

    required DateTime rangeStart,

    required DateTime rangeEnd,

  }) {

    final flat = source.values.expand((e) => e).toList();

    final start = _dayStart(rangeStart);

    final end = _dayStart(rangeEnd);

    final result = <String, List<EmployeeTaskModel>>{};



    void add(EmployeeTaskModel task, DateTime day) {

      final key = EmployeeTasksController.dateKeyFrom(day);

      final list = result.putIfAbsent(key, () => []);

      final duplicateIndex = list.indexWhere(

        (existing) => _isParallelDuplicate(existing, task, day),

      );

      if (duplicateIndex == -1) {

        list.add(task);

        return;

      }

      list[duplicateIndex] = _preferTask(list[duplicateIndex], task);

    }



    for (final task in flat) {

      if (!shouldExpand(task)) {

        add(task, task.startTime);

      }

    }



    for (final task in flat) {

      if (!shouldExpand(task)) continue;



      for (var day = start;

          !day.isAfter(end);

          day = day.add(const Duration(days: 1))) {

        if (_hasChildOnDate(flat, task.taskId, day)) continue;

        if (!matchesRecurrenceOnDate(task, day)) continue;

        add(resolveDayInstance(flat, task, day), day);
      }
    }

    return result;
  }

  static EmployeeTaskModel? findChildForDay(
    List<EmployeeTaskModel> flat,
    int parentId,
    DateTime day,
  ) {
    final parentKey = '$parentId';
    for (final task in flat) {
      if (task.parentId == parentKey && _sameDay(task.startTime, day)) {
        return task;
      }
    }
    return null;
  }

  static EmployeeTaskModel resolveDayInstance(
    List<EmployeeTaskModel> flat,
    EmployeeTaskModel parent,
    DateTime day,
  ) {
    final child = findChildForDay(flat, parent.taskId, day);
    if (child != null) {
      return child;
    }
    if (_sameDay(parent.startTime, day)) {
      return parent;
    }
    return parent.virtualDayInstance(day);
  }



  static bool shouldExpand(EmployeeTaskModel task) {

    if (task.isCanceled) return false;

    return TaskRecurrenceRules.shouldExpand(

      source: task.source,

      parentId: task.parentId,

      recurrence: task.taskRecurrence,

    );

  }



  static bool matchesRecurrenceOnDate(EmployeeTaskModel task, DateTime day) {

    return TaskRecurrenceRules.matchesRecurrenceOnDate(

      taskStart: task.startTime,

      recurrence: task.taskRecurrence,

      recurrenceTimes: task.taskRecurrenceTime,

      day: day,

      taskEnd: task.endTime,

    );

  }



  static bool _hasChildOnDate(

    List<EmployeeTaskModel> tasks,

    int parentId,

    DateTime day,

  ) {

    final parentKey = '$parentId';

    return tasks.any(

      (t) => t.parentId == parentKey && _sameDay(t.startTime, day),

    );

  }



  static bool _isParallelDuplicate(

    EmployeeTaskModel a,

    EmployeeTaskModel b,

    DateTime day,

  ) {

    if (a.employeeId != b.employeeId) return false;

    if (a.taskName.trim().toLowerCase() != b.taskName.trim().toLowerCase()) {

      return false;

    }

    if (!_sameDay(a.startTime, day) || !_sameDay(b.startTime, day)) {

      return false;

    }

    if (a.taskId == b.taskId && a.occurrenceId == b.occurrenceId) {

      return false;

    }

    return true;

  }



  static bool _isOccurrenceRow(EmployeeTaskModel task) {

    return task.source == 'occurrence' ||

        (task.occurrenceId != null && task.occurrenceId! > 0);

  }



  static int _displayPriority(EmployeeTaskModel task) {

    if (_isOccurrenceRow(task)) return 3;

    final parentId = task.parentId;

    if (parentId == null || parentId.isEmpty) return 2;

    return 1;

  }



  static EmployeeTaskModel _preferTask(

    EmployeeTaskModel a,

    EmployeeTaskModel b,

  ) {

    return _displayPriority(a) >= _displayPriority(b) ? a : b;

  }



  static DateTime _dayStart(DateTime d) => TaskRecurrenceRules.dayStart(d);

  static bool _sameDay(DateTime a, DateTime b) =>
      TaskRecurrenceRules.sameDay(a, b);

}

