import 'package:doctorbike/features/admin/sales/data/models/product_model.dart';

import '../repositories/sales_repositores.dart';

class GetAllProductsUsecase {
  final SalesRepository salesRepository;

  GetAllProductsUsecase({required this.salesRepository});

  Future<List<ProductModel>> call({
    String endPoint = '',
    String? customerId,
    String? sellerId,
  }) async {
    return await salesRepository.getAllProducts(
      endPoint: endPoint,
      customerId: customerId,
      sellerId: sellerId,
    );
  }
}
