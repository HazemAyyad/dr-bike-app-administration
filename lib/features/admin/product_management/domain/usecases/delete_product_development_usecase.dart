import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/product_management_repository.dart';

class DeleteProductDevelopmentUsecase {
  final ProductManagementRepository productManagementRepository;

  DeleteProductDevelopmentUsecase({required this.productManagementRepository});

  Future<Either<Failure, String>> call({
    required String productDevelopmentId,
  }) {
    return productManagementRepository.deleteProductDevelopment(
      productDevelopmentId: productDevelopmentId,
    );
  }
}
