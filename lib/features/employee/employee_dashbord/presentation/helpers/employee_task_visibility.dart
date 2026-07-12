import '../../../../../core/helpers/task_recurrence_rules.dart';
import '../helpers/employee_recurring_task_expander.dart';
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
  return TaskRecurrenceRules.sameDay(dateTime.toLocal(), DateTime.now());
}

bool isPinnedPersistentTask(Task task) =>
    task.taskRecurrence == TaskRecurrenceRules.oneTimePersistent &&
    isEmployeeTaskActive(task.status);

bool _shouldExpandTask(Task task) => TaskRecurrenceRules.shouldExpand(
      source: task.source,
      parentId: task.parentId,
      recurrence: task.taskRecurrence,
    );

bool isTaskVisibleOnDay(
  Task task,
  DateTime day, {
  List<String> weeklyDaysOff = const [],
}) {
  if (isPinnedPersistentTask(task)) return true;

  if (TaskRecurrenceRules.sameDay(task.startTime, day)) {
    if (task.taskRecurrence == 'daily' &&
        !TaskRecurrenceRules.isEmployeeWorkingDay(day, weeklyDaysOff)) {
      return false;
    }
    return true;
  }
  if (TaskRecurrenceRules.isRepeatedCopy(task.parentId)) return false;
  if (!_shouldExpandTask(task)) return false;
  return TaskRecurrenceRules.matchesRecurrenceOnDate(
    taskStart: task.startTime,
    recurrence: task.taskRecurrence,
    recurrenceTimes: task.taskRecurrenceTime,
    day: day,
    taskEnd: task.endTime,
    weeklyDaysOff: weeklyDaysOff,
  );
}

bool isEmployeeTaskActiveForDay(
  Task task,
  DateTime day, {
  List<String> weeklyDaysOff = const [],
}) {
  if (isPinnedPersistentTask(task)) return true;

  if (TaskRecurrenceRules.isRepeatedCopy(task.parentId) || task.isOccurrence) {
    return isEmployeeTaskActive(task.status);
  }
  if (_shouldExpandTask(task) &&
      !TaskRecurrenceRules.sameDay(task.startTime, day) &&
      TaskRecurrenceRules.matchesRecurrenceOnDate(
        taskStart: task.startTime,
        recurrence: task.taskRecurrence,
        recurrenceTimes: task.taskRecurrenceTime,
        day: day,
        taskEnd: task.endTime,
        weeklyDaysOff: weeklyDaysOff,
      )) {
    return true;
  }
  return isEmployeeTaskActive(task.status);
}

bool isDashboardTask(
  Task task, {
  List<String> weeklyDaysOff = const [],
}) =>
    isEmployeeTaskActiveForDay(task, DateTime.now(),
        weeklyDaysOff: weeklyDaysOff) &&
    isTaskVisibleOnDay(task, DateTime.now(), weeklyDaysOff: weeklyDaysOff);

/// One card per logical task on the home screen, with today's start/end times.
List<Task> dashboardTasksForToday(
  List<Task> tasks, {
  List<String> weeklyDaysOff = const [],
}) {
  final today = DateTime.now();
  final bestByGroup = <String, Task>{};

  for (final task in tasks) {
    if (!isDashboardTask(task, weeklyDaysOff: weeklyDaysOff)) continue;
    final key = _dashboardGroupKey(task);
    final normalized = _normalizeTaskForToday(task, today, tasks);
    final existing = bestByGroup[key];
    if (existing == null || _isBetterDashboardInstance(normalized, existing)) {
      bestByGroup[key] = normalized;
    }
  }

  final result = bestByGroup.values.toList()..sort(_comparePinnedThenDue);
  return result;
}

int _comparePinnedThenDue(Task a, Task b) {
  final aPinned = isPinnedPersistentTask(a);
  final bPinned = isPinnedPersistentTask(b);
  if (aPinned && !bPinned) return -1;
  if (!aPinned && bPinned) return 1;
  return a.endTime.compareTo(b.endTime);
}

String _dashboardGroupKey(Task task) {
  if (task.isOccurrence) {
    return 'occ_${task.occurrenceId ?? task.id}';
  }
  if (TaskRecurrenceRules.isRepeatedCopy(task.parentId)) {
    return 'legacy_${task.parentId}';
  }
  return 'legacy_${task.taskId}';
}

Task _normalizeTaskForToday(Task task, DateTime today, List<Task> allTasks) {
  if (task.isRepeatedCopy &&
      TaskRecurrenceRules.sameDay(task.startTime, today)) {
    return task;
  }
  if (task.isOccurrence && TaskRecurrenceRules.sameDay(task.startTime, today)) {
    return task;
  }
  if (_shouldExpandTask(task)) {
    return EmployeeRecurringTaskExpander.resolveDayInstance(
        allTasks, task, today);
  }
  if (!TaskRecurrenceRules.sameDay(task.startTime, today)) {
    return task.copyWithDisplayDate(today);
  }
  return task;
}

bool _isBetterDashboardInstance(Task candidate, Task existing) {
  if (candidate.isRepeatedCopy && !existing.isRepeatedCopy) return true;
  if (!candidate.isRepeatedCopy && existing.isRepeatedCopy) return false;
  if (candidate.isOccurrence && !existing.isOccurrence) return true;
  if (!candidate.isOccurrence && existing.isOccurrence) return false;

  const done = {'completed', 'waiting_review'};
  final candidateDone = done.contains(candidate.status);
  final existingDone = done.contains(existing.status);
  if (!candidateDone && existingDone) return true;
  if (candidateDone && !existingDone) return false;

  final now = DateTime.now();
  final cRemaining = candidate.endTime.difference(now).inSeconds;
  final eRemaining = existing.endTime.difference(now).inSeconds;
  if (cRemaining >= 0 && eRemaining < 0) return true;
  if (cRemaining < 0 && eRemaining >= 0) return false;
  return cRemaining.abs() < eRemaining.abs();
}
