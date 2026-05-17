import 'package:doctorbike/core/services/app_dependency_registry.dart';
import 'package:get/get.dart';

import '../../data/datasources/stock_datasource.dart';
import '../../domain/usecases/search_products_usecase.dart';
import '../../data/repositories/stock_implement.dart';
import '../controllers/offer_packages_controller.dart';

class OfferPackagesBinding extends Bindings {
  @override
  void dependencies() {
    AppDependencyRegistry.ensureStock();

    Get.lazyPut<OfferPackagesController>(
      () => OfferPackagesController(
        stockDatasource: Get.find<StockDatasource>(),
        searchProductsUsecase: SearchProductsUsecase(
          stockRepository: Get.find<StockImplement>(),
        ),
      ),
    );
  }
}
