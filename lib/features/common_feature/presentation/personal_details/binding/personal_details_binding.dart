import 'package:get/get.dart';

import '../../../data/repositories/common_repo_impl.dart';
import '../../../domain/usecases/user_profile_usecase.dart';
import '../controllers/personal_details_controller.dart';

class PersonalDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => PersonalDetailsController(
        userProfileUseCase: UserProfileUseCase(
          commonRepository: Get.find<CommonImplement>(),
        ),
      ),
    );
  }
}
