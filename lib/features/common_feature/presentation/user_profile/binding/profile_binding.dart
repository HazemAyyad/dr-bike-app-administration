import 'package:get/get.dart';

import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../auth/data/repositories/auth_repo_impl.dart';
import '../../../../auth/domain/usecases/logout_usecase.dart';
import '../controllers/log_out_coontroller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/employee_signatures_controller.dart';

class ProfileScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ProfileController(),
    );
    Get.lazyPut(
      () => EmployeeSignaturesController(Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut(
      () => LogOutController(
        logout: Logout(
          authRepository: Get.find<AuthImplement>(),
        ),
      ),
      fenix: true,
    );
  }
}
