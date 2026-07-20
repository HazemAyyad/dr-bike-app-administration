import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/proof_media_type.dart';
import 'package:doctorbike/core/helpers/task_recurrence_rules.dart';

class DashbordEmployeeDetailsModel {
  final int id;
  final String userId;
  final String numberOfWorkHours;
  final String hourWorkPrice;
  final String debts;
  final String salary;
  final String points;
  final String startWorkTime;
  final String endWorkTime;
  final String totalWorkHours;
  final List<Permission> permissions;
  final User user;
  final List<Task> tasks;
  final TodayTasksSummary todayTasksSummary;
  final List<String> weeklyDaysOff;
  final Map<String, int> dashboardBadges;

  DashbordEmployeeDetailsModel({
    required this.id,
    required this.userId,
    required this.numberOfWorkHours,
    required this.hourWorkPrice,
    required this.debts,
    required this.salary,
    required this.points,
    required this.startWorkTime,
    required this.endWorkTime,
    required this.totalWorkHours,
    required this.permissions,
    required this.user,
    required this.tasks,
    this.todayTasksSummary = const TodayTasksSummary(),
    this.weeklyDaysOff = const [],
    this.dashboardBadges = const {},
  });

  factory DashbordEmployeeDetailsModel.fromJson(Map<String, dynamic> json) {
    return DashbordEmployeeDetailsModel(
      id: asInt(json['id']),
      userId: asString(json['user_id'], '0'),
      numberOfWorkHours: asString(json['number_of_work_hours'], '0'),
      hourWorkPrice: asString(json['hour_work_price'], '0'),
      debts: asString(json['debts'], '0'),
      salary: asString(json['salary'], '0'),
      points: asString(json['points'], '0'),
      startWorkTime: asString(json['start_work_time'], '0'),
      endWorkTime: asString(json['end_work_time'], '0'),
      totalWorkHours: asString(json['total_work_hours'], '0'),
      permissions: mapList(
        json['permissions'],
        (Map<String, dynamic> m) => Permission.fromJson(m),
      ),
      user: User.fromJson(asMap(json['user'])),
      tasks: mapList(
        json['tasks'],
        (Map<String, dynamic> m) => Task.fromJson(m),
      ),
      todayTasksSummary: TodayTasksSummary.fromJson(
        asMap(json['today_tasks_summary']),
      ),
      weeklyDaysOff: asStringList(json['weekly_days_off']),
      dashboardBadges: _parseDashboardBadges(json['dashboard_badges']),
    );
  }
}

Map<String, int> _parseDashboardBadges(dynamic raw) {
  if (raw is! Map) return const {};
  return raw.map(
    (key, value) => MapEntry(
      key.toString(),
      asInt(value),
    ),
  );
}

class TodayTasksSummary {
  final int total;
  final int completed;
  final int progressPercent;

  const TodayTasksSummary({
    this.total = 0,
    this.completed = 0,
    this.progressPercent = 0,
  });

  factory TodayTasksSummary.fromJson(Map<String, dynamic> json) {
    return TodayTasksSummary(
      total: asInt(json['total']),
      completed: asInt(json['completed']),
      progressPercent: asInt(json['progress_percent']),
    );
  }

  /// Fallback when API has not deployed [today_tasks_summary] yet.
  factory TodayTasksSummary.fromTasks(
    List<Task> tasks, {
    List<String> weeklyDaysOff = const [],
  }) {
    final now = DateTime.now();
    final todayTasks = tasks.where((t) {
      if (t.taskRecurrence == TaskRecurrenceRules.oneTimePersistent &&
          _isSummaryActive(t.status)) {
        return true;
      }
      if (TaskRecurrenceRules.sameDay(t.startTime, now)) {
        if (t.taskRecurrence == 'daily' &&
            !TaskRecurrenceRules.isEmployeeWorkingDay(now, weeklyDaysOff)) {
          return false;
        }
        return true;
      }
      return TaskRecurrenceRules.shouldExpand(
            source: t.source,
            parentId: t.parentId,
            recurrence: t.taskRecurrence,
          ) &&
          TaskRecurrenceRules.matchesRecurrenceOnDate(
            taskStart: t.startTime,
            recurrence: t.taskRecurrence,
            recurrenceTimes: t.taskRecurrenceTime,
            day: now,
            taskEnd: t.endTime,
            weeklyDaysOff: weeklyDaysOff,
          );
    }).toList();
    if (todayTasks.isEmpty) {
      return const TodayTasksSummary();
    }
    final completed = todayTasks
        .where((t) => t.status == 'completed' || t.status == 'waiting_review')
        .length;
    final progressSum = todayTasks.fold<int>(0, (s, t) {
      return s + _summaryProgress(t, now);
    });
    return TodayTasksSummary(
      total: todayTasks.length,
      completed: completed,
      progressPercent: (progressSum / todayTasks.length).round(),
    );
  }

  static int _summaryProgress(Task task, DateTime day) {
    if (TaskRecurrenceRules.isRecurringParent(
          source: task.source,
          parentId: task.parentId,
          recurrence: task.taskRecurrence,
        ) &&
        !TaskRecurrenceRules.sameDay(task.startTime, day)) {
      return 0;
    }
    return task.displayProgress;
  }

  static bool _isSummaryActive(String status) {
    const active = {
      'ongoing',
      'pending',
      'in_progress',
      'waiting_review',
      'overdue',
    };
    return active.contains(status);
  }
}

class Permission {
  final int id;
  final String name;

  Permission({required this.id, required this.name});

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: asInt(json['id']),
      name: asString(json['name']),
    );
  }
}

class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: asInt(json['id']),
      name: asString(json['name']),
    );
  }
}

class Task {
  final int id;

  /// Legacy [employee_tasks.id] for API calls (details, complete). For occurrences, may differ from [id].
  final int taskId;
  final int employeeId;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final bool isForcedToUploadImg;
  final String proofMediaType;
  final int? occurrenceId;
  final String source;
  final bool hasSubTasks;
  final int subTasksCount;
  final int progress;
  final int? completedByEmployeeId;
  final String? completedByName;
  final bool canExecute;
  final String? parentId;
  final String taskRecurrence;
  final List<String> taskRecurrenceTime;
  final int? templateId;

  Task({
    required this.id,
    required this.taskId,
    required this.employeeId,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.isForcedToUploadImg,
    this.proofMediaType = ProofMediaType.none,
    this.occurrenceId,
    this.source = 'legacy',
    this.hasSubTasks = false,
    this.subTasksCount = 0,
    this.progress = 0,
    this.completedByEmployeeId,
    this.completedByName,
    this.canExecute = true,
    this.parentId,
    this.taskRecurrence = 'noRepeat',
    this.taskRecurrenceTime = const [],
    this.templateId,
  });

  bool get isRepeatedCopy => TaskRecurrenceRules.isRepeatedCopy(parentId);

  bool get isOccurrence => source == 'occurrence';

  /// Prefer API [progress] when the task has subtasks; otherwise estimate from status.
  int get displayProgress {
    if (hasSubTasks || subTasksCount > 0) {
      return progress.clamp(0, 100);
    }
    if (progress > 0) return progress.clamp(0, 100);
    if (status == 'completed') return 100;
    if (status == 'waiting_review') return 90;
    if (status == 'in_progress' || status == 'started') return 50;
    return 0;
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final trt = json['task_recurrence_time'];
    final List<String> recurrenceTimes =
        trt is List ? trt.map((e) => e.toString()).toList() : const [];

    return Task(
      id: asInt(json['id']),
      taskId:
          json['task_id'] != null ? asInt(json['task_id']) : asInt(json['id']),
      employeeId: asInt(json['employee_id']),
      name: asString(json['name']),
      startTime: parseApiDateTime(json['start_time']),
      endTime: parseApiDateTime(json['end_time']),
      status: asString(json['status']),
      isForcedToUploadImg: asBool(json['is_forced_to_upload_img']),
      proofMediaType: ProofMediaType.normalize(
        asNullableString(json['proof_media_type']),
        required: asBool(json['is_forced_to_upload_img']),
      ),
      occurrenceId:
          json['occurrence_id'] != null ? asInt(json['occurrence_id']) : null,
      source: asString(json['source'], 'legacy'),
      hasSubTasks: asBool(json['has_sub_tasks']),
      subTasksCount: asInt(json['sub_tasks_count']),
      progress: asInt(json['progress']),
      completedByEmployeeId: json['completed_by_employee_id'] != null
          ? asInt(json['completed_by_employee_id'])
          : null,
      completedByName: asNullableString(json['completed_by_name']),
      canExecute:
          json['can_execute'] == null ? true : asBool(json['can_execute']),
      parentId: asNullableString(json['parent_id']),
      taskRecurrence: asString(json['task_recurrence'], 'noRepeat'),
      taskRecurrenceTime: recurrenceTimes,
      templateId:
          json['template_id'] != null ? asInt(json['template_id']) : null,
    );
  }

  Task copyWithDisplayDate(DateTime day) {
    final start = DateTime(
      day.year,
      day.month,
      day.day,
      startTime.hour,
      startTime.minute,
      startTime.second,
      startTime.millisecond,
      startTime.microsecond,
    );
    var end = DateTime(
      day.year,
      day.month,
      day.day,
      endTime.hour,
      endTime.minute,
      endTime.second,
      endTime.millisecond,
      endTime.microsecond,
    );
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }
    return Task(
      id: id,
      taskId: taskId,
      employeeId: employeeId,
      name: name,
      startTime: start,
      endTime: end,
      status: status,
      isForcedToUploadImg: isForcedToUploadImg,
      proofMediaType: proofMediaType,
      occurrenceId: occurrenceId,
      source: source,
      hasSubTasks: hasSubTasks,
      subTasksCount: subTasksCount,
      progress: progress,
      completedByEmployeeId: completedByEmployeeId,
      completedByName: completedByName,
      canExecute: canExecute,
      parentId: parentId,
      taskRecurrence: taskRecurrence,
      taskRecurrenceTime: taskRecurrenceTime,
      templateId: templateId,
    );
  }

  /// Calendar-day view for legacy recurring parents (fresh instance per day).
  Task virtualDayInstance(DateTime day) {
    final displayed = copyWithDisplayDate(day);
    final isAnchorDay = TaskRecurrenceRules.sameDay(startTime, day);
    final isRecurringParent = TaskRecurrenceRules.isRecurringParent(
      source: source,
      parentId: parentId,
      recurrence: taskRecurrence,
    );
    if (!isRecurringParent || isAnchorDay) {
      return displayed;
    }
    return Task(
      id: displayed.id,
      taskId: displayed.taskId,
      employeeId: displayed.employeeId,
      name: displayed.name,
      startTime: displayed.startTime,
      endTime: displayed.endTime,
      status: 'ongoing',
      isForcedToUploadImg: displayed.isForcedToUploadImg,
      proofMediaType: displayed.proofMediaType,
      occurrenceId: displayed.occurrenceId,
      source: displayed.source,
      hasSubTasks: displayed.hasSubTasks,
      subTasksCount: displayed.subTasksCount,
      progress: 0,
      completedByEmployeeId: null,
      completedByName: null,
      canExecute: true,
      parentId: displayed.parentId,
      taskRecurrence: displayed.taskRecurrence,
      taskRecurrenceTime: displayed.taskRecurrenceTime,
      templateId: displayed.templateId,
    );
  }

  String get calendarDayKey => TaskRecurrenceRules.dateKeyFrom(startTime);
}
