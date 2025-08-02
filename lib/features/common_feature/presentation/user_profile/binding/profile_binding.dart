import 'package:get/get.dart';

import '../../../../auth/data/repositories/auth_repo_impl.dart';
import '../../../../auth/domain/usecases/logout_usecase.dart';
import '../controllers/log_out_coontroller.dart';
import '../controllers/profile_controller.dart';

class ProfileScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ProfileController(),
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
