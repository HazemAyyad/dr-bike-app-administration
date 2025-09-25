import '../../data/models/product_development_model.dart';
import '../repositories/product_management_repository.dart';

class GetProductDevelopmentsUsecase {
  final ProductManagementRepository productManagementRepository;

  GetProductDevelopmentsUsecase({required this.productManagementRepository});

  Future<List<ProductDevelopmentModel>> call() {
    return productManagementRepository.getProductDevelopments();
  }
}
