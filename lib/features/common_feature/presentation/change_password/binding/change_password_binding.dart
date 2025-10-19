import 'package:doctorbike/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:get/get.dart';

import '../../../../auth/data/repositories/auth_repo_impl.dart';
import '../controllers/change_password_controller.dart';

class ChangePasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ChangePasswordController(
        changePassword: ChangePassword(
          authRepository: Get.find<AuthImplement>(),
        ),
      ),
    );
  }
}
