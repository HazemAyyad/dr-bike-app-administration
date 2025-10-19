import 'package:get/get.dart';

import '../../../sales/data/repositories/sales_implement.dart';
import '../../../sales/domain/usecases/get_all_products_usecase.dart';
import '../../data/repositories/product_management_implement.dart';
import '../../domain/usecases/create_product_development_usecase.dart';
import '../../domain/usecases/get_product_developments_usecase.dart';
import '../controllers/product_management_controller.dart';

class ProductManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ProductManagementController(
        getProductDevelopmentsUsecase: GetProductDevelopmentsUsecase(
          productManagementRepository: Get.find<ProductManagementImplement>(),
        ),
        getAllProductsUsecase: GetAllProductsUsecase(
          salesRepository: Get.find<SalesImplement>(),
        ),
        createProductDevelopmentUsecase: CreateProductDevelopmentUsecase(
          productManagementRepository: Get.find<ProductManagementImplement>(),
        ),
      ),
    );
  }
}
