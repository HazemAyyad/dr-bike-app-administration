import '../repositories/stock_repository.dart';

class GetProductSizeOptionsUsecase {
  GetProductSizeOptionsUsecase({required this.stockRepository});

  final StockRepository stockRepository;

  Future<List<String>> call({String? productId}) {
    return stockRepository.getProductSizeOptions(productId: productId);
  }
}
