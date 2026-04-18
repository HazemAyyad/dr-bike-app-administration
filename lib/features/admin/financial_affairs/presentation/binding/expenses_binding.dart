import 'package:doctorbike/features/admin/stock/domain/usecases/get_product_details_usecase.dart';
import 'package:doctorbike/features/admin/stock/domain/usecases/get_product_size_options_usecase.dart';
import 'package:doctorbike/features/admin/stock/domain/usecases/save_product_full_usecase.dart';
import 'package:doctorbike/features/admin/stock/domain/usecases/search_products_usecase.dart';
import 'package:get/get.dart';

import '../../../boxes/data/repositories/boxes_implement.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../../stock/data/repositories/stock_implement.dart';
import '../../../stock/domain/usecases/add_combination_usecase.dart';
import '../../../stock/domain/usecases/get_all_stock_usecase.dart';
import '../../../stock/domain/usecases/get_archived_usecase.dart';
import '../../../stock/domain/usecases/get_categories_usecase.dart';
import '../../../stock/domain/usecases/move_to_archive_usecase.dart';
import '../../../stock/presentation/controllers/stock_controller.dart';
import '../../data/repositories/financial_affairs_implement.dart';
import '../../domain/usecases/get_all_dinancial_usecase.dart';
import '../../domain/usecases/expenses_usecases/add_destruction_usecase.dart';
import '../../domain/usecases/expenses_usecases/add_expense_usecase.dart';
import '../../domain/usecases/expenses_usecases/get_expenses_data_usecase.dart';
import '../controllers/expenses_controller.dart';

class ExpensesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ExpensesController(
        getAllFinancialUsecase: GetAllFinancialUsecase(
          financialAffairsRepository: Get.find<FinancialAffairsImplement>(),
        ),
        addDestructionUsecase: AddDestructionUsecase(
          financialAffairsRepository: Get.find<FinancialAffairsImplement>(),
        ),
        addExpenseUsecase: AddExpenseUsecase(
          financialAffairsRepository: Get.find<FinancialAffairsImplement>(),
        ),
        getExpensesDataUsecase: GetExpensesDataUsecase(
          financialAffairsRepository: Get.find<FinancialAffairsImplement>(),
        ),
        getShownBoxUsecase: GetShownBoxUsecase(
          boxesRepository: Get.find<BoxesImplement>(),
        ),
      ),
    );
    Get.lazyPut(
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
      ),
      fenix: true,
    );
  }
}
