import '../../data/models/customer_product_price_history_model.dart';
import '../repositories/sales_repositores.dart';

class GetCustomerProductPriceHistoryUsecase {
  final SalesRepository salesRepository;

  GetCustomerProductPriceHistoryUsecase({required this.salesRepository});

  Future<CustomerProductPriceHistory> call({
    String? personType,
    String? personId,
    required String productId,
    String? sizeColorId,
    int limit = 5,
  }) {
    return salesRepository.getCustomerProductPriceHistory(
      personType: personType,
      personId: personId,
      productId: productId,
      sizeColorId: sizeColorId,
      limit: limit,
    );
  }
}
