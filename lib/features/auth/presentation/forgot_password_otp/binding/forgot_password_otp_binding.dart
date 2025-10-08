import 'package:get/get.dart';

import '../../../data/repositories/auth_repo_impl.dart';
import '../../../domain/usecases/verify_otp_usecase.dart';
import '../controllers/forgot_password_otp_controller.dart';

class ForgotPasswordOtpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ForgotPasswordController(
        verifyOtp: VerifyOtp(
          authRepository: Get.find<AuthImplement>(),
        ),
      ),
      fenix: true,
    );
  }
}
