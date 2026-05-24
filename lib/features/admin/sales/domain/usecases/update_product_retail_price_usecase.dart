import 'package:dartz/dartz.dart';
import 'package:doctorbike/core/errors/failure.dart';

import '../../data/models/product_price_update_result.dart';
import '../repositories/sales_repositores.dart';

class UpdateProductRetailPriceUsecase {
  final SalesRepository salesRepository;

  UpdateProductRetailPriceUsecase({required this.salesRepository});

  Future<Either<Failure, ProductPriceUpdateResult>> call({
    required String productId,
    required double normailPrice,
    double? wholesalePrice,
  }) {
    return salesRepository.updateProductRetailPrice(
      productId: productId,
      normailPrice: normailPrice,
      wholesalePrice: wholesalePrice,
    );
  }
}
