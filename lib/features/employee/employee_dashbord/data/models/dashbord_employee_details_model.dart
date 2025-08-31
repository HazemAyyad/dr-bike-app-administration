class DashbordEmployeeDetailsModel {
  final int id;
  final int userId;
  final String numberOfWorkHours;
  final String hourWorkPrice;
  final String debts;
  final String salary;
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
    required this.permissions,
    required this.user,
    required this.tasks,
  });

  factory DashbordEmployeeDetailsModel.fromJson(Map<String, dynamic> json) {
    return DashbordEmployeeDetailsModel(
      id: json['id'],
      userId: int.parse(json['user_id']),
      numberOfWorkHours: json['number_of_work_hours'] ?? '',
      hourWorkPrice: json['hour_work_price'] ?? '',
      debts: json['debts'] ?? '',
      salary: json['salary'] ?? '',
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

  Task({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      employeeId: int.parse(json['employee_id']),
      name: json['name'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
    );
  }
}
