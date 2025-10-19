import '../../data/models/all_stock_products_model.dart';
import '../repositories/stock_repository.dart';

class SearchProductsUsecase {
  final StockRepository stockRepository;

  SearchProductsUsecase({required this.stockRepository});

  Future<List<AllStockProductsModel>> call({
    required String name,
  }) async {
    return await stockRepository.searchProducts(name: name);
  }
}
