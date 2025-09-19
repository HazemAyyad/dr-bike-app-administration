class GoalDetailsModel {
  final int id;
  final String name;
  final String type;
  final String achievementPercentage;
  final String currentValue;
  final String targetedValue;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String isCanceled;
  final String form;
  final String scope;
  final EmployeeModel? employee;
  final CustomerModel? customer;
  final SellerModel? seller;
  final BoxModel? box;

  GoalDetailsModel({
    required this.id,
    required this.name,
    required this.type,
    required this.achievementPercentage,
    required this.currentValue,
    required this.targetedValue,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.isCanceled,
    required this.form,
    required this.scope,
    this.employee,
    this.customer,
    this.seller,
    this.box,
  });

  factory GoalDetailsModel.fromJson(Map<String, dynamic> json) {
    return GoalDetailsModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      achievementPercentage: json['achievement_percentage'] ?? '',
      currentValue: json['current_value'] ?? '',
      targetedValue: json['targeted_value'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isCanceled: json['is_canceled'] ?? '',
      form: json['form'] ?? '',
      scope: json['scope'] ?? '',
      employee: json['employee'] != null
          ? EmployeeModel.fromJson(json['employee'])
          : null,
      customer: json['customer'] != null
          ? CustomerModel.fromJson(json['customer'])
          : null,
      seller:
          json['seller'] != null ? SellerModel.fromJson(json['seller']) : null,
      box: json['box'] != null ? BoxModel.fromJson(json['box']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'achievement_percentage': achievementPercentage,
      'current_value': currentValue,
      'targeted_value': targetedValue,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_canceled': isCanceled,
      'form': form,
      'scope': scope,
      'employee': employee?.toJson(),
      'customer': customer?.toJson(),
      'seller': seller?.toJson(),
      'box': box?.toJson(),
    };
  }
}

class EmployeeModel {
  final String id;
  final String name;

  EmployeeModel({
    required this.id,
    required this.name,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class CustomerModel {
  final int id;
  final String name;

  CustomerModel({
    required this.id,
    required this.name,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class SellerModel {
  final int id;
  final String name;

  SellerModel({
    required this.id,
    required this.name,
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class BoxModel {
  final int id;
  final String name;

  BoxModel({
    required this.id,
    required this.name,
  });

  factory BoxModel.fromJson(Map<String, dynamic> json) {
    return BoxModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
