import '../../data/models/product_details_model.dart';
import '../repositories/stock_repository.dart';

class GetProductDetailsUsecase {
  final StockRepository stockRepository;

  GetProductDetailsUsecase({required this.stockRepository});

  Future<ProductDetailsModel> call({required String productId}) async {
    return await stockRepository.getProductDetails(
      productId: productId,
    );
  }
}
