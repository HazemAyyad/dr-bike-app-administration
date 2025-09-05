import '../../data/models/all_stock_products_model.dart';
import '../repositories/stock_repository.dart';

class GetArchivedUsecase {
  final StockRepository stockRepository;

  GetArchivedUsecase({required this.stockRepository});

  Future<List<AllStockProductsModel>> call() async {
    return await stockRepository.getArchived();
  }
}
