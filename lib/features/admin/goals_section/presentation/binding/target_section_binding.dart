import 'package:doctorbike/features/admin/goals_section/data/repositories/goals_implement.dart';
import 'package:doctorbike/features/admin/goals_section/domain/usecases/get_goals_usecase.dart';
import 'package:get/get.dart';

import '../../../boxes/data/repositories/boxes_implement.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../../checks/data/repositories/checks_implement.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../../employee_section/data/repositorie_imp/employee_implement.dart';
import '../../../employee_section/domain/usecases/get_all_employee.dart';
import '../../../sales/data/repositories/sales_implement.dart';
import '../../../sales/domain/usecases/get_all_products_usecase.dart';
import '../../domain/usecases/add_goal_usecase.dart';
import '../../domain/usecases/get_goal_details_usecase.dart';
import '../controllers/target_section_controller.dart';

class TargetSectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => TargetSectionController(
        getGoalsUsecase: GetGoalsUsecase(
          goalsRepository: Get.find<GoalsImplement>(),
        ),
        getAllEmployeeUsecase: GetAllEmployeeUsecase(
          employeeRepository: Get.find<EmployeeImplement>(),
        ),
        allCustomersSellersUsecase: AllCustomersSellersUsecase(
          checksRepository: Get.find<ChecksImplement>(),
        ),
        getShownBoxUsecase: GetShownBoxUsecase(
          boxesRepository: Get.find<BoxesImplement>(),
        ),
        addGoalUsecase: AddGoalUsecase(
          goalsRepository: Get.find<GoalsImplement>(),
        ),
        getGoalDetailsUsecase: GetGoalDetailsUsecase(
          goalsRepository: Get.find<GoalsImplement>(),
        ),
        getAllProductsUsecase: GetAllProductsUsecase(
          salesRepository: Get.find<SalesImplement>(),
        ),
      ),
    );
  }
}
