import '../../data/models/all_stock_products_model.dart';
import '../repositories/stock_repository.dart';
import '../stock_product_filters.dart';

class GetAllStockUsecase {
  final StockRepository stockRepository;

  GetAllStockUsecase({required this.stockRepository});

  Future<List<AllStockProductsModel>> call({
    required int page,
    required bool ifCombinations,
    required bool ifCloseouts,
    StockProductFilters? filters,
    int perPage = 15,
  }) async {
    return await stockRepository.getAllStock(
      page: page,
      ifCombinations: ifCombinations,
      ifCloseouts: ifCloseouts,
      filters: filters,
      perPage: perPage,
    );
  }
}
