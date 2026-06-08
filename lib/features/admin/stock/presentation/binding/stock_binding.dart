import 'package:doctorbike/core/services/app_dependency_registry.dart';
import 'package:get/get.dart';

import '../../data/datasources/stock_datasource.dart';
import '../../data/repositories/stock_implement.dart';
import '../../domain/usecases/add_combination_usecase.dart';
import '../../domain/usecases/get_all_stock_usecase.dart';
import '../../domain/usecases/get_archived_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_main_categories_usecase.dart';
import '../../domain/usecases/get_product_details_usecase.dart';
import '../../domain/usecases/get_product_size_options_usecase.dart';
import '../../domain/usecases/move_to_archive_usecase.dart';
import '../../domain/usecases/save_product_full_usecase.dart';
import '../../domain/usecases/search_products_usecase.dart';
import '../../domain/stock_location_interactor.dart';
import '../controllers/offer_packages_controller.dart';
import '../controllers/stock_controller.dart';

class StockBinding extends Bindings {
  @override
  void dependencies() {
    AppDependencyRegistry.ensureStock();

    if (!Get.isRegistered<OfferPackagesController>()) {
      Get.lazyPut<OfferPackagesController>(
        () => OfferPackagesController(
          stockDatasource: Get.find<StockDatasource>(),
          searchProductsUsecase: SearchProductsUsecase(
            stockRepository: Get.find<StockImplement>(),
          ),
        ),
      );
    }

    if (!Get.isRegistered<StockLocationInteractor>()) {
      Get.lazyPut<StockLocationInteractor>(
        () => StockLocationInteractor(Get.find<StockDatasource>()),
      );
    }
    if (!Get.isRegistered<StockController>()) {
      Get.lazyPut<StockController>(
        () => StockController(
          getAllStockUsecase: GetAllStockUsecase(
            stockRepository: Get.find<StockImplement>(),
          ),
          getProductDetailsUsecase: GetProductDetailsUsecase(
            stockRepository: Get.find<StockImplement>(),
          ),
          moveToArchiveUsecase: MoveToArchiveUsecase(
            stockRepository: Get.find<StockImplement>(),
          ),
          getArchivedUsecase: GetArchivedUsecase(
            stockRepository: Get.find<StockImplement>(),
          ),
          getCategoriesUsecase: GetCategoriesUsecase(
            stockRepository: Get.find<StockImplement>(),
          ),
          getMainCategoriesUsecase: GetMainCategoriesUsecase(
            stockRepository: Get.find<StockImplement>(),
          ),
          searchProductsUsecase: SearchProductsUsecase(
            stockRepository: Get.find<StockImplement>(),
          ),
          addCombinationUsecase: AddCombinationUsecase(
            stockRepository: Get.find<StockImplement>(),
          ),
          saveProductFullUsecase: SaveProductFullUsecase(
            stockRepository: Get.find<StockImplement>(),
          ),
          getProductSizeOptionsUsecase: GetProductSizeOptionsUsecase(
            stockRepository: Get.find<StockImplement>(),
          ),
          stockLocationInteractor: Get.find<StockLocationInteractor>(),
          stockDatasource: Get.find<StockDatasource>(),
        ),
      );
    }
  }
}
