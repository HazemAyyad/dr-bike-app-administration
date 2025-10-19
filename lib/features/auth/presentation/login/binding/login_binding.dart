import 'package:get/get.dart';

import '../../../data/repositories/auth_repo_impl.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => LoginController(
        login: Login(
          authRepository: Get.find<AuthImplement>(),
        ),
      ),
    );
  }
}
