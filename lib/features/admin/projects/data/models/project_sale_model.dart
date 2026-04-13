import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class ProjectSaleModel {
  final List<ProjectSale> projectSales;
  final double totalCosts;

  ProjectSaleModel({
    required this.projectSales,
    required this.totalCosts,
  });

  factory ProjectSaleModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ProjectSaleModel(
      projectSales: mapList(
        j['project_sales'],
        (Map<String, dynamic> m) => ProjectSale.fromJson(m),
      ),
      totalCosts: asDouble(j['total_costs']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_sales': projectSales.map((e) => e.toJson()).toList(),
      'total_costs': totalCosts,
    };
  }
}

class ProjectSale {
  final String productName;
  final String productCost;
  final String productQuantity;

  ProjectSale({
    required this.productName,
    required this.productCost,
    required this.productQuantity,
  });

  factory ProjectSale.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ProjectSale(
      productName: asString(j['product_name']),
      productCost: asString(j['product_cost'], '0'),
      productQuantity: asString(j['product_quantity'], '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'product_cost': productCost,
      'product_quantity': productQuantity,
    };
  }
}
