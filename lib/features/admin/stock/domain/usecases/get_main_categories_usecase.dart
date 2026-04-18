import '../../../sales/data/models/product_model.dart';
import '../repositories/stock_repository.dart';

class GetMainCategoriesUsecase {
  final StockRepository stockRepository;

  GetMainCategoriesUsecase({required this.stockRepository});

  Future<List<ProductModel>> call() async {
    return stockRepository.getMainCategories();
  }
}
