import '../../data/models/all_stock_products_model.dart';
import '../repositories/stock_repository.dart';

class GetAllStockUsecase {
  final StockRepository stockRepository;

  GetAllStockUsecase({required this.stockRepository});

  Future<List<AllStockProductsModel>> call(
      {required int page,
      required bool ifCombinations,
      required bool ifCloseouts}) async {
    return await stockRepository.getAllStock(
      page: page,
      ifCombinations: ifCombinations,
      ifCloseouts: ifCloseouts,
    );
  }
}
