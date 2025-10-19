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
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? '0',
      numberOfWorkHours: json['number_of_work_hours'] ?? '0',
      hourWorkPrice: json['hour_work_price'] ?? '0',
      debts: json['debts'] ?? '0',
      salary: json['salary'] ?? '0',
      points: json['points'] ?? '0',
      startWorkTime: json['start_work_time'] ?? '0',
      endWorkTime: json['end_work_time'] ?? '0',
      totalWorkHours: json['total_work_hours'] ?? '0',
      permissions: (json['permissions'] as List<dynamic>)
          .map((e) => Permission.fromJson(e))
          .toList(),
      user: User.fromJson(json['user']),
      tasks: (json['tasks'] as List<dynamic>)
          .map((e) => Task.fromJson(e))
          .toList(),
    );
  }
}

class Permission {
  final int id;
  final String name;

  Permission({required this.id, required this.name});

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'],
      name: json['name'],
    );
  }
}

class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
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
      id: json['id'],
      employeeId: int.parse(json['employee_id']),
      name: json['name'],
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : DateTime.now(),
      status: json['status'],
    );
  }
}
