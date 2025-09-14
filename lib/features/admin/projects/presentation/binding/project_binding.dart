import 'package:get/get.dart';

import '../../../checks/data/repositories/checks_implement.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../../sales/data/repositories/sales_implement.dart';
import '../../../sales/domain/usecases/get_all_products_usecase.dart';
import '../../data/repositories/project_implement.dart';
import '../../domain/usecases/create_project_usecase.dart';
import '../../domain/usecases/get_project_details_usecase.dart';
import '../../domain/usecases/get_usecase.dart';
import '../controllers/project_controller.dart';

class ProjectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ProjectController(
        getProjectsUsecase: GetProjectsUsecase(
          projectRepository: Get.find<ProjectImplement>(),
        ),
        getAllProductsUsecase: GetAllProductsUsecase(
          salesRepository: Get.find<SalesImplement>(),
        ),
        allCustomersSellersUsecase: AllCustomersSellersUsecase(
          checksRepository: Get.find<ChecksImplement>(),
        ),
        createProjectUsecase: CreateProjectUsecase(
          projectRepository: Get.find<ProjectImplement>(),
        ),
        getProjectDetailsUsecase: GetProjectDetailsUsecase(
          projectRepository: Get.find<ProjectImplement>(),
        ),
      ),
    );
  }
}
