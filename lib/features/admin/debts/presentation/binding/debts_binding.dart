import 'package:doctorbike/core/services/app_dependency_registry.dart';
import 'package:get/get.dart';

import '../../data/repositories/debt_ledger_implement.dart';
import '../controllers/debt_ledger_controller.dart';

class DebtsBinding extends Bindings {
  @override
  void dependencies() {
    AppDependencyRegistry.ensureDebtsModule();
    AppDependencyRegistry.ensureDebtsLedgerModule();

    if (!Get.isRegistered<DebtLedgerController>()) {
      Get.put(
        DebtLedgerController(
          repository: Get.find<DebtLedgerImplement>(),
        ),
      );
    }
  }
}
