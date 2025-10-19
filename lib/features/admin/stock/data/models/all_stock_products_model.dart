class AllStockProductsModel {
  final int closeoutId;
  final String closeoutStatus;
  final String productId;
  final String name;
  final String stock;
  final String productMinSalePrice;
  final String image;
  final String numberOfUsedProducts;

  AllStockProductsModel({
    required this.closeoutId,
    required this.closeoutStatus,
    required this.productId,
    required this.name,
    required this.stock,
    required this.productMinSalePrice,
    required this.image,
    required this.numberOfUsedProducts,
  });

  factory AllStockProductsModel.fromJson(Map<String, dynamic> json) {
    return AllStockProductsModel(
      closeoutId: json['closeout_id'] ?? 0,
      closeoutStatus: json['closeout_status'] ?? 'unarchived',
      productId: json['product_id'] ?? '0',
      name: json['product_name'] ?? 'Unknown',
      stock: json['product_stock'] ?? '0',
      productMinSalePrice: json['product_min_sale_price'] ?? '0',
      image: json['product_image'] ?? '',
      numberOfUsedProducts: json['number_of_used_products'] ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'closeout_id': closeoutId,
      'closeout_status': closeoutStatus,
      'product_id': productId,
      'product_name': name,
      'product_stock': stock,
      'product_min_sale_price': productMinSalePrice,
      'product_image': image,
      'number_of_used_products': numberOfUsedProducts,
    };
  }
}
