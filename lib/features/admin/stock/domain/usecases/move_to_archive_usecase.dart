import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/stock_repository.dart';

class MoveToArchiveUsecase {
  final StockRepository stockRepository;

  MoveToArchiveUsecase({required this.stockRepository});

  Future<Either<Failure, String>> call({
    required String productId,
    required bool isMove,
  }) async {
    return await stockRepository.moveToArchive(
      productId: productId,
      isMove: isMove,
    );
  }
}
