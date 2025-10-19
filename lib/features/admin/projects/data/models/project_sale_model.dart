class ProjectSaleModel {
  final List<ProjectSale> projectSales;
  final double totalCosts;

  ProjectSaleModel({
    required this.projectSales,
    required this.totalCosts,
  });

  factory ProjectSaleModel.fromJson(Map<String, dynamic> json) {
    return ProjectSaleModel(
      projectSales: (json['project_sales'] as List<dynamic>? ?? [])
          .map((e) => ProjectSale.fromJson(e))
          .toList(),
      totalCosts: double.tryParse(json['total_costs'].toString()) ?? 0.0,
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
    return ProjectSale(
      productName: json['product_name'] ?? '',
      productCost: json['product_cost'] ?? '0',
      productQuantity: json['product_quantity'] ?? '0',
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
