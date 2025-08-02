import 'package:get/get.dart';

import '../../../data/repositories/auth_repo_impl.dart';
import '../../../domain/usecases/verify_otp_usecase.dart';
import '../controllers/sign_up_otp_controller.dart';

class SignUpOtpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SignUpOtpController(
        verifyOtp: VerifyOtp(
          authRepository: Get.find<AuthImplement>(),
        ),
      ),
      fenix: true,
    );
  }
}
