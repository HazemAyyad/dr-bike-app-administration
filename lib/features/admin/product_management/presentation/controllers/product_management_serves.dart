import '../../data/models/product_development_model.dart';

class ProductManagementServes {
  final List<ProductDevelopmentModel> productManagement = [];


  // singleton pattern
  static final ProductManagementServes _instance =
      ProductManagementServes._internal();
  factory ProductManagementServes() => _instance;
  ProductManagementServes._internal();
}
