import 'package:get/get.dart';

import '../../../data/repositories/auth_repo_impl.dart';
import '../../../domain/usecases/register_usecase.dart';
import '../controllers/sign_up_controller.dart';

class SignUpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SignUpController(
        registerCase: Register(
          authRepository: Get.find<AuthImplement>(),
        ),
      ),
    );
  }
}
