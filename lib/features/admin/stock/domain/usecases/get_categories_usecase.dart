import '../../../sales/data/models/product_model.dart';
import '../repositories/stock_repository.dart';

class GetCategoriesUsecase {
  final StockRepository stockRepository;

  GetCategoriesUsecase({required this.stockRepository});

  Future<List<ProductModel>> call({required bool isProject}) async {
    return await stockRepository.getCategories(isProject: isProject);
  }
}
