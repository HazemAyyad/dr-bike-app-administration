import '../../../../../core/helpers/json_safe_parser.dart';

class ProductAssemblyRecipeModel {
  const ProductAssemblyRecipeModel({
    required this.id,
    required this.targetProductId,
    required this.targetProductName,
    required this.targetProductStock,
    required this.unitCost,
    required this.additionalCost,
    required this.items,
    this.targetProductCode,
    this.targetSize,
    this.targetColorAr,
    this.createdAt,
  });

  final int id;
  final String targetProductId;
  final String targetProductName;
  final int targetProductStock;
  final double unitCost;
  final double additionalCost;
  final String? targetProductCode;
  final String? targetSize;
  final String? targetColorAr;
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
      additionalCost: asDouble(json['additional_cost']),
      targetSize: asNullableString(json['target_size']),
      targetColorAr: asNullableString(json['target_color_ar']),
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
    this.componentSize,
    this.componentColorAr,
  });

  final String componentProductId;
  final String componentProductName;
  final int componentProductStock;
  final double quantityPerUnit;
  final double unitCost;
  final String? componentProductCode;
  final String? componentSize;
  final String? componentColorAr;

  factory ProductAssemblyRecipeItemModel.fromJson(Map<String, dynamic> json) {
    return ProductAssemblyRecipeItemModel(
      componentProductId: asString(json['component_product_id']),
      componentProductName: asString(json['component_product_name']),
      componentProductStock: asInt(json['component_product_stock']),
      componentProductCode: asNullableString(json['component_product_code']),
      componentSize: asNullableString(json['component_size']),
      componentColorAr: asNullableString(json['component_color_ar']),
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
    required this.additionalCost,
    required this.items,
    this.targetSize,
    this.targetColorAr,
    this.createdAt,
  });

  final int id;
  final int recipeId;
  final String operationType;
  final String targetProductName;
  final int quantity;
  final double unitCost;
  final double totalCost;
  final double additionalCost;
  final List<ProductAssemblyOperationItemModel> items;
  final String? targetSize;
  final String? targetColorAr;
  final String? createdAt;

  factory ProductAssemblyOperationModel.fromJson(Map<String, dynamic> json) {
    return ProductAssemblyOperationModel(
      id: asInt(json['id']),
      recipeId: asInt(json['recipe_id']),
      operationType: asString(json['operation_type']),
      targetProductName: asString(json['target_product_name']),
      quantity: asInt(json['quantity']),
      unitCost: asDouble(json['unit_cost']),
      totalCost: asDouble(json['total_cost']),
      additionalCost: asDouble(json['additional_cost']),
      targetSize: asNullableString(json['target_size']),
      targetColorAr: asNullableString(json['target_color_ar']),
      createdAt: asNullableString(json['created_at']),
      items: mapList(
        json['items'],
        (m) => ProductAssemblyOperationItemModel.fromJson(m),
      ),
    );
  }
}

class ProductAssemblyOperationItemModel {
  const ProductAssemblyOperationItemModel({
    required this.componentProductId,
    required this.componentProductName,
    required this.quantityPerUnit,
    required this.totalQuantity,
    required this.unitCost,
    required this.totalCost,
    this.componentProductCode,
    this.componentSize,
    this.componentColorAr,
  });

  final String componentProductId;
  final String componentProductName;
  final double quantityPerUnit;
  final double totalQuantity;
  final double unitCost;
  final double totalCost;
  final String? componentProductCode;
  final String? componentSize;
  final String? componentColorAr;

  factory ProductAssemblyOperationItemModel.fromJson(
      Map<String, dynamic> json) {
    return ProductAssemblyOperationItemModel(
      componentProductId: asString(json['component_product_id']),
      componentProductName: asString(json['component_product_name']),
      componentProductCode: asNullableString(json['component_product_code']),
      componentSize: asNullableString(json['component_size']),
      componentColorAr: asNullableString(json['component_color_ar']),
      quantityPerUnit: asDouble(json['quantity_per_unit']),
      totalQuantity: asDouble(json['total_quantity']),
      unitCost: asDouble(json['unit_cost']),
      totalCost: asDouble(json['total_cost']),
    );
  }
}
