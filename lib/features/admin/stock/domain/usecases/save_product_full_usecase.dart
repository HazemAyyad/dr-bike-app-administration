import 'package:dio/dio.dart';

import '../repositories/stock_repository.dart';

class SaveProductFullUsecase {
  final StockRepository stockRepository;

  SaveProductFullUsecase({required this.stockRepository});

  Future<Map<String, dynamic>> call({
    required FormData formData,
    required bool isCreate,
  }) {
    return stockRepository.saveProductFull(
      formData: formData,
      isCreate: isCreate,
    );
  }
}
