import 'package:dartz/dartz.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/failure.dart';
import '../../presentation/controllers/stock_controller.dart';
import '../repositories/stock_repository.dart';

class AddCombinationUsecase {
  final StockRepository stockRepository;

  AddCombinationUsecase({required this.stockRepository});

  Future<Either<Failure, String>> call({
    required String productId,
    required RxList<NewCompositionModel> combination,
  }) async {
    return await stockRepository.addCombination(
      productId: productId,
      combinationId: combination,
    );
  }
}
