import 'package:doctorbike/core/helpers/json_safe_parser.dart';

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
      permissions: mapList(json['permissions'], Permission.fromJson),
      user: User.fromJson(asMap(json['user'])),
      tasks: mapList(json['tasks'], Task.fromJson),
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
  final int employeeId;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final String status;

  Task({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: asInt(json['id']),
      employeeId: asInt(json['employee_id']),
      name: asString(json['name']),
      startTime: parseApiDateTime(json['start_time']),
      endTime: parseApiDateTime(json['end_time']),
      status: asString(json['status']),
    );
  }
}
