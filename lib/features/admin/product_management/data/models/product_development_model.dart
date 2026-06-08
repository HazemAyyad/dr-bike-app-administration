import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class ProductDevelopmentModel {
  final int id;
  final String productId;
  final String productName;
  final String productImage;
  final String description;
  final String currentStep;
  final double rate;
  final String createdAt;
  final String updatedAt;
  final List<ProductDevelopmentActivityLogModel> activityLogs;

  ProductDevelopmentModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.description,
    required this.currentStep,
    required this.rate,
    required this.createdAt,
    required this.updatedAt,
    required this.activityLogs,
  });

  factory ProductDevelopmentModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ProductDevelopmentModel(
      id: asInt(j['id']),
      productId: asString(j['product_id']),
      productName: asString(j['product_name']),
      productImage: asString(j['product_image']),
      description: asString(j['description']),
      currentStep: asString(j['current_step']),
      rate: asDouble(j['rate'] ?? 0),
      createdAt: asString(j['created_at']),
      updatedAt: asString(j['updated_at']),
      activityLogs: mapList(
        j['activity_logs'],
        (Map<String, dynamic> m) =>
            ProductDevelopmentActivityLogModel.fromJson(m),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'description': description,
      'current_step': currentStep,
      'rate': rate,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'activity_logs': activityLogs.map((e) => e.toJson()).toList(),
    };
  }
}

class ProductDevelopmentActivityLogModel {
  final int id;
  final String action;
  final String description;
  final String userName;
  final String createdAt;

  ProductDevelopmentActivityLogModel({
    required this.id,
    required this.action,
    required this.description,
    required this.userName,
    required this.createdAt,
  });

  factory ProductDevelopmentActivityLogModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final j = Map<String, dynamic>.from(json);
    return ProductDevelopmentActivityLogModel(
      id: asInt(j['id']),
      action: asString(j['action']),
      description: asString(j['description']),
      userName: asString(j['user_name']),
      createdAt: asString(j['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'description': description,
      'user_name': userName,
      'created_at': createdAt,
    };
  }
}

class ProductDevelopmentActionResult {
  final String message;
  final String? developmentId;

  const ProductDevelopmentActionResult({
    required this.message,
    this.developmentId,
  });

  factory ProductDevelopmentActionResult.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ProductDevelopmentActionResult(
      message: asString(j['message']),
      developmentId: j['product_development_id']?.toString(),
    );
  }
}
