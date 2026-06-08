import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/product_development_model.dart';

abstract class ProductManagementRepository {
  Future<List<ProductDevelopmentModel>> getProductDevelopments();

  Future<Either<Failure, ProductDevelopmentActionResult>>
      createProductDevelopment({
    required String productId,
    required String description,
    required String step,
  });

  Future<Either<Failure, String>> deleteProductDevelopment({
    required String productDevelopmentId,
  });
}
