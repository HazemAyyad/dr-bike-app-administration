import '../../data/models/stock_products_page_result.dart';
import '../repositories/stock_repository.dart';
import '../stock_product_filters.dart';

class GetAllStockUsecase {
  final StockRepository stockRepository;

  GetAllStockUsecase({required this.stockRepository});

  Future<StockProductsPageResult> call({
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
