import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/proof_media_type.dart';

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
    );
  }
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
  factory TodayTasksSummary.fromTasks(List<Task> tasks) {
    final now = DateTime.now();
    final todayTasks = tasks.where((t) {
      return t.startTime.year == now.year &&
          t.startTime.month == now.month &&
          t.startTime.day == now.day;
    }).toList();
    if (todayTasks.isEmpty) {
      return const TodayTasksSummary();
    }
    final completed = todayTasks
        .where((t) => t.status == 'completed' || t.status == 'waiting_review')
        .length;
    final progressSum =
        todayTasks.fold<int>(0, (s, t) => s + t.displayProgress);
    return TodayTasksSummary(
      total: todayTasks.length,
      completed: completed,
      progressPercent: (progressSum / todayTasks.length).round(),
    );
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
  });

  bool get isOccurrence => source == 'occurrence';

  /// API [progress] or estimate from status when subtasks count unknown.
  int get displayProgress {
    if (progress > 0) return progress.clamp(0, 100);
    if (status == 'completed') return 100;
    if (status == 'waiting_review') return 90;
    if (status == 'in_progress' || status == 'started') return 50;
    return 0;
  }

  factory Task.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
