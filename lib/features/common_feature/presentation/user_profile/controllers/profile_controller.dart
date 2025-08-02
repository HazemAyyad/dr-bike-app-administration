import 'package:get/get.dart';

import '../../../../../core/services/languague_service.dart';
import '../../../../auth/data/repositories/auth_repo_impl.dart';
import '../../../../auth/domain/usecases/logout_usecase.dart';
import 'log_out_coontroller.dart';

class ProfileController extends GetxController {
  LogOutController logOutController = Get.put(
    LogOutController(
      logout: Logout(
        authRepository: Get.find<AuthImplement>(),
      ),
    ),
  );
  LanguageController languageController = Get.put(LanguageController());
}
