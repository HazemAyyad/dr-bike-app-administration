import '../../../../../core/helpers/json_safe_parser.dart';

class ProductAssemblyRecipeModel {
  const ProductAssemblyRecipeModel({
    required this.id,
    required this.targetProductId,
    required this.targetProductName,
    required this.targetProductStock,
    required this.unitCost,
    required this.items,
    this.targetProductCode,
    this.createdAt,
  });

  final int id;
  final String targetProductId;
  final String targetProductName;
  final int targetProductStock;
  final double unitCost;
  final String? targetProductCode;
  final String? createdAt;
  final List<ProductAssemblyRecipeItemModel> items;

  factory ProductAssemblyRecipeModel.fromJson(Map<String, dynamic> json) {
    return ProductAssemblyRecipeModel(
      id: asInt(json['id']),
      targetProductId: asString(json['target_product_id']),
      targetProductName: asString(json['target_product_name']),
      targetProductStock: asInt(json['target_product_stock']),
      targetProductCode: asNullableString(json['target_product_code']),
      unitCost: asDouble(json['unit_cost']),
      createdAt: asNullableString(json['created_at']),
      items: mapList(
        json['items'],
        (m) => ProductAssemblyRecipeItemModel.fromJson(m),
      ),
    );
  }
}

class ProductAssemblyRecipeItemModel {
  const ProductAssemblyRecipeItemModel({
    required this.componentProductId,
    required this.componentProductName,
    required this.componentProductStock,
    required this.quantityPerUnit,
    required this.unitCost,
    this.componentProductCode,
  });

  final String componentProductId;
  final String componentProductName;
  final int componentProductStock;
  final double quantityPerUnit;
  final double unitCost;
  final String? componentProductCode;

  factory ProductAssemblyRecipeItemModel.fromJson(Map<String, dynamic> json) {
    return ProductAssemblyRecipeItemModel(
      componentProductId: asString(json['component_product_id']),
      componentProductName: asString(json['component_product_name']),
      componentProductStock: asInt(json['component_product_stock']),
      componentProductCode: asNullableString(json['component_product_code']),
      quantityPerUnit: asDouble(json['quantity_per_unit']),
      unitCost: asDouble(json['unit_cost']),
    );
  }
}

class ProductAssemblyOperationModel {
  const ProductAssemblyOperationModel({
    required this.id,
    required this.recipeId,
    required this.operationType,
    required this.targetProductName,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
  });

  final int id;
  final int recipeId;
  final String operationType;
  final String targetProductName;
  final int quantity;
  final double unitCost;
  final double totalCost;

  factory ProductAssemblyOperationModel.fromJson(Map<String, dynamic> json) {
    return ProductAssemblyOperationModel(
      id: asInt(json['id']),
      recipeId: asInt(json['recipe_id']),
      operationType: asString(json['operation_type']),
      targetProductName: asString(json['target_product_name']),
      quantity: asInt(json['quantity']),
      unitCost: asDouble(json['unit_cost']),
      totalCost: asDouble(json['total_cost']),
    );
  }
}
