import 'package:get/get.dart';

import '../../../data/repositories/auth_repo_impl.dart';
import '../../../domain/usecases/send_otp_to_email_usecase.dart';
import '../controllers/sginup_verify_controller.dart';

class SginupVerifyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SginupVerifyController(
        sendOtpToEmail: SendOtpToEmail(
          authRepository: Get.find<AuthImplement>(),
        ),
      ),
    );
  }
}
