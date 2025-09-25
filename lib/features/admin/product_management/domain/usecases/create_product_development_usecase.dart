import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/product_management_repository.dart';

class CreateProductDevelopmentUsecase {
  final ProductManagementRepository productManagementRepository;

  CreateProductDevelopmentUsecase({required this.productManagementRepository});

  Future<Either<Failure, String>> call({
    required String productId,
    required String description,
    required String step,
  }) {
    return productManagementRepository.createProductDevelopment(
      productId: productId,
      description: description,
      step: step,
    );
  }
}
