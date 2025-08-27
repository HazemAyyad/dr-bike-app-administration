import '../repositories/stock_repository.dart';

class GetAllStockUsecase {
  final StockRepository stockRepository;

  GetAllStockUsecase({required this.stockRepository});

  Future<dynamic> call({required int page}) async {
    return await stockRepository.getAllStock(page: page);
  }
}
