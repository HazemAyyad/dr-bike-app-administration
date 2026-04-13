// class GoalDetailsModel {
//   final int id;
//   final String name;
//   final String type;
//   final String achievementPercentage;
//   final String currentValue;
//   final String targetedValue;
//   final String notes;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   final String isCanceled;
//   final String form;
//   final String scope;
//   final EmployeeModel? employee;
//   final CustomerModel? customer;
//   final SellerModel? seller;
//   final BoxModel? box;

//   GoalDetailsModel({
//     required this.id,
//     required this.name,
//     required this.type,
//     required this.achievementPercentage,
//     required this.currentValue,
//     required this.targetedValue,
//     required this.notes,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.isCanceled,
//     required this.form,
//     required this.scope,
//     this.employee,
//     this.customer,
//     this.seller,
//     this.box,
//   });

//   factory GoalDetailsModel.fromJson(Map<String, dynamic> json) {
//     return GoalDetailsModel(
//       id: json['id'] ?? 0,
//       name: json['name'] ?? '',
//       type: json['scope'] ?? '',
//       achievementPercentage: json['achievement_percentage'] ?? '',
//       currentValue: json['current_value'] ?? '',
//       targetedValue: json['targeted_value'] ?? '',
//       notes: json['notes'] ?? '',
//       createdAt: DateTime.parse(json['created_at']),
//       updatedAt: DateTime.parse(json['updated_at']),
//       isCanceled: json['is_canceled'] ?? '',
//       form: json['form'] ?? '',
//       scope: json['type'] ?? '',
//       employee: json['employee'] != null
//           ? EmployeeModel.fromJson(json['employee'])
//           : null,
//       customer: json['customer'] != null
//           ? CustomerModel.fromJson(json['customer'])
//           : null,
//       seller:
//           json['seller'] != null ? SellerModel.fromJson(json['seller']) : null,
//       box: json['box'] != null ? BoxModel.fromJson(json['box']) : null,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'type': type,
//       'achievement_percentage': achievementPercentage,
//       'current_value': currentValue,
//       'targeted_value': targetedValue,
//       'notes': notes,
//       'created_at': createdAt.toIso8601String(),
//       'updated_at': updatedAt.toIso8601String(),
//       'is_canceled': isCanceled,
//       'form': form,
//       'scope': scope,
//       'employee': employee?.toJson(),
//       'customer': customer?.toJson(),
//       'seller': seller?.toJson(),
//       'box': box?.toJson(),
//     };
//   }
// }

// class EmployeeModel {
//   final String id;
//   final String name;

//   EmployeeModel({
//     required this.id,
//     required this.name,
//   });

//   factory EmployeeModel.fromJson(Map<String, dynamic> json) {
//     return EmployeeModel(
//       id: json['id'].toString(),
//       name: json['name'] ?? '',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//     };
//   }
// }

// class CustomerModel {
//   final int id;
//   final String name;

//   CustomerModel({
//     required this.id,
//     required this.name,
//   });

//   factory CustomerModel.fromJson(Map<String, dynamic> json) {
//     return CustomerModel(
//       id: json['id'] ?? 0,
//       name: json['name'] ?? '',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//     };
//   }
// }

// class SellerModel {
//   final int id;
//   final String name;

//   SellerModel({
//     required this.id,
//     required this.name,
//   });

//   factory SellerModel.fromJson(Map<String, dynamic> json) {
//     return SellerModel(
//       id: json['id'] ?? 0,
//       name: json['name'] ?? '',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//     };
//   }
// }

// class BoxModel {
//   final int id;
//   final String name;

//   BoxModel({
//     required this.id,
//     required this.name,
//   });

//   factory BoxModel.fromJson(Map<String, dynamic> json) {
//     return BoxModel(
//       id: json['id'] ?? 0,
//       name: json['name'] ?? '',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//     };
//   }
// }

import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class GoalDetailsModel {
  final Goal goal;
  final List<GoalLog> goalLogs;

  GoalDetailsModel({
    required this.goal,
    required this.goalLogs,
  });

  factory GoalDetailsModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return GoalDetailsModel(
      goal: Goal.fromJson(asMap(j['goal'])),
      goalLogs: mapList(j['goal_logs'], (m) => GoalLog.fromJson(m)),
    );
  }

  Map<String, dynamic> toJson() => {
        'goal': goal.toJson(),
        'goal_logs': goalLogs.map((x) => x.toJson()).toList(),
      };
}

class Goal {
  final int id;
  final String name;
  final String type;
  final String achievementPercentage;
  final String currentValue;
  final String targetedValue;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String isCanceled;
  final String form;
  final String scope;
  final String dueDate;

  final List<Category>? mainCategories;
  final List<SubCategory>? subCategories;
  final List<Product>? products;
  final List<Person>? people;
  final Box? box;
  final Employee? employee;

  Goal({
    required this.id,
    required this.name,
    required this.type,
    required this.achievementPercentage,
    required this.currentValue,
    required this.targetedValue,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.isCanceled,
    required this.form,
    required this.scope,
    required this.dueDate,
    this.mainCategories,
    this.subCategories,
    this.products,
    this.people,
    this.box,
    this.employee,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return Goal(
      id: asInt(j['id']),
      name: asString(j['name']),
      type: asString(j['type']),
      achievementPercentage: asString(j['achievement_percentage']),
      currentValue: asString(j['current_value']),
      targetedValue: asString(j['targeted_value']),
      notes: asNullableString(j['notes']),
      createdAt: asString(j['created_at']),
      updatedAt: asString(j['updated_at']),
      isCanceled: asString(j['is_canceled']),
      form: asString(j['form']),
      scope: asString(j['scope']),
      dueDate: asString(j['due_date']),
      mainCategories: mapList(j['main_categories'], (m) => Category.fromJson(m)),
      subCategories:
          mapList(j['sub_categories'], (m) => SubCategory.fromJson(m)),
      products: mapList(j['products'], (m) => Product.fromJson(m)),
      people: mapList(j['people'], (m) => Person.fromJson(m)),
      box: j['box'] == null ? null : Box.fromJson(asMap(j['box'])),
      employee: j['employee'] == null
          ? null
          : Employee.fromJson(asMap(j['employee'])),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'achievement_percentage': achievementPercentage,
        'current_value': currentValue,
        'targeted_value': targetedValue,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'is_canceled': isCanceled,
        'form': form,
        'scope': scope,
        'due_date': dueDate,
        'main_categories': mainCategories?.map((x) => x.toJson()).toList(),
        'sub_categories': subCategories?.map((x) => x.toJson()).toList(),
        'products': products?.map((x) => x.toJson()).toList(),
        'people': people?.map((x) => x.toJson()).toList(),
        'box': box?.toJson(),
        'employee': employee?.toJson(),
      };
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return Category(
      id: asString(j['category_id']),
      name: asString(j['category_name']),
    );
  }

  Map<String, dynamic> toJson() => {
        'category_id': id,
        'category_name': name,
      };
}

class SubCategory {
  final String id;
  final String name;

  SubCategory({required this.id, required this.name});

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return SubCategory(
      id: asString(j['sub_category_id']),
      name: asString(j['sub_category_name']),
    );
  }

  Map<String, dynamic> toJson() => {
        'sub_category_id': id,
        'sub_category_name': name,
      };
}

class Product {
  final String id;
  final String name;

  Product({required this.id, required this.name});

  factory Product.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return Product(
      id: asString(j['product_id']),
      name: asString(j['product_name']),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': id,
        'product_name': name,
      };
}

class Person {
  final String customerId;
  final String customerName;
  final String sellerId;
  final String sellerName;

  Person({
    required this.customerId,
    required this.customerName,
    required this.sellerId,
    required this.sellerName,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return Person(
      customerId: asString(j['customer_id']),
      customerName: asString(j['customer_name']),
      sellerId: asString(j['seller_id']),
      sellerName: asString(j['seller_name']),
    );
  }

  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'customer_name': customerName,
        'seller_id': sellerId,
        'seller_name': sellerName,
      };
}

class Box {
  final int id;
  final String name;

  Box({required this.id, required this.name});

  factory Box.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return Box(
      id: asInt(j['id']),
      name: asString(j['name']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class Employee {
  final String id;
  final String name;

  Employee({required this.id, required this.name});

  factory Employee.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return Employee(
      id: asString(j['id']),
      name: asString(j['name']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class GoalLog {
  final String title;
  final String description;

  GoalLog({required this.title, required this.description});

  factory GoalLog.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return GoalLog(
      title: asString(j['title']),
      description: asString(j['description']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
      };
}
