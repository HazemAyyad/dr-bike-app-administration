import 'package:doctorbike/features/admin/sales/domain/usecases/add_profit_sale.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/get_instant_sales_usecase.dart';
import 'package:get/get.dart';

import '../../data/repositories/sales_implement.dart';
import '../../domain/usecases/add_instant_sales_usecase.dart';
import '../../domain/usecases/get_all_products_usecase.dart';
import '../../domain/usecases/get_profit_sales_usecase.dart';
import '../../domain/usecases/invoice_model_usecase.dart';
import '../controllers/sales_controller.dart';
import '../controllers/sales_service.dart';

class SalesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SalesController(
        salesService: SalesService(),
        addProfitSaleUsecase: AddProfitSaleUsecase(
          salesRepository: Get.find<SalesImplement>(),
        ),
        getProfitSalesUsecase: GetProfitSalesUsecase(
          salesRepository: Get.find<SalesImplement>(),
        ),
        getInstantSalesUsecase: GetInstantSalesUsecase(
          salesRepository: Get.find<SalesImplement>(),
        ),
        getAllProductsUsecase: GetAllProductsUsecase(
          salesRepository: Get.find<SalesImplement>(),
        ),
        addInstantSalesUsecase: AddInstantSalesUsecase(
          salesRepository: Get.find<SalesImplement>(),
        ),
        invoiceModelUsecase: InvoiceModelUsecase(
          salesRepository: Get.find<SalesImplement>(),
        ),
      ),
    );
  }
}
