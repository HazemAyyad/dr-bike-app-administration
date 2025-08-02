import 'package:doctorbike/features/admin/debts/data/repositories/debts_implement.dart';
import 'package:doctorbike/features/admin/debts/domain/usecases/total_debts_we_owe_usecase.dart';
import 'package:get/get.dart';


import '../../domain/usecases/debts_owed_to_us_usecase.dart';
import '../../domain/usecases/debts_we_owe_usecase.dart';
import '../../domain/usecases/total_debts_owed_to_us_usecase.dart';
import '../../domain/usecases/user_debts_data_usecase.dart';
import '../controllers/debts_controller.dart';
import '../controllers/debts_data_service.dart';

class DebtsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => DebtsController(
        totalDebtsOwedToUs: TotalDebtsOwedToUsUsecase(
          debtsRepository: Get.find<DebtsImplement>(),
        ),
        totalDebtsWeOwe: TotalDebtsWeOweUsecase(
          debtsRepository: Get.find<DebtsImplement>(),
        ),
        debtsOwedToUs: DebtsOwedToUsUsecase(
          debtsRepository: Get.find<DebtsImplement>(),
        ),
        debtsWeOwe: DebtsWeOweUsecase(
          debtsRepository: Get.find<DebtsImplement>(),
        ),
        userTransactionsData: UserTransactionsUsecase(
          debtsRepository: Get.find<DebtsImplement>(),
        ),
        dataService: Get.find<DebtsDataService>(),
      ),
    );
    Future.delayed(Duration.zero, () {
      Get.find<DebtsController>().getTotalDebtsOwedToUs();
      Get.find<DebtsController>().getTotalDebtsWeOwe();
      Get.find<DebtsController>().getDebtsWeOwe();
      Get.find<DebtsController>().getDebtsOwedToUs();
    });
  }
}
