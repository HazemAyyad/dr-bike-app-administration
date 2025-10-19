import 'package:doctorbike/features/admin/buying/domain/usecases/get_bills_usecase.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/all_customers_sellers_usecase.dart';
import 'package:doctorbike/features/admin/sales/data/repositories/sales_implement.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/get_all_products_usecase.dart';
import 'package:get/get.dart';

import '../../../checks/data/repositories/checks_implement.dart';
import '../../data/repositories/bills_implement.dart';
import '../../domain/usecases/bills_usecases/add_bill_usecase.dart';
import '../../domain/usecases/purchase_orders_usecases/cancel_bill_usecase.dart';
import '../../domain/usecases/get_billt_details_usecase.dart';
import '../../domain/usecases/purchase_orders_usecases/change_one_status_usecase.dart';
import '../../domain/usecases/purchase_orders_usecases/change_status_usecase.dart';
import '../../domain/usecases/return_purchases_usecases/change_return_to_delivered_usecase.dart';
import '../controllers/bills_controller.dart';
import '../controllers/purchase_orders_controller.dart';
import '../controllers/return_purchases_controller.dart';

class BuyingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => BillsController(
        getBillsUsecase: GetBillsUsecase(
          billsRepository: Get.find<BillsImplement>(),
        ),
        getAllProductsUsecase: GetAllProductsUsecase(
          salesRepository: Get.find<SalesImplement>(),
        ),
        allCustomersSellersUsecase: AllCustomersSellersUsecase(
          checksRepository: Get.find<ChecksImplement>(),
        ),
        addBillUsecase: AddBillUsecase(
          billsRepository: Get.find<BillsImplement>(),
        ),
        getBilltDetailsUsecase: GetBilltDetailsUsecase(
          billsRepository: Get.find<BillsImplement>(),
        ),
      ),
    );
    Get.lazyPut(
      () => PurchaseOrdersController(
        getBillsUsecase: GetBillsUsecase(
          billsRepository: Get.find<BillsImplement>(),
        ),
        cancelBillUsecase: CancelBillUsecase(
          billsRepository: Get.find<BillsImplement>(),
        ),
        changeStatusUsecase: ChangeStatusUsecase(
          billsRepository: Get.find<BillsImplement>(),
        ),
        changeOneStatusUsecase: ChangeOneStatusUsecase(
          billsRepository: Get.find<BillsImplement>(),
        ),
      ),
    );
    Get.lazyPut(
      () => ReturnPurchasesController(
        getBillsUsecase: GetBillsUsecase(
          billsRepository: Get.find<BillsImplement>(),
        ),
        changeReturnToDeliveredUsecase: ChangeReturnToDeliveredUsecase(
          billsRepository: Get.find<BillsImplement>(),
        ),
      ),
    );
  }
}
