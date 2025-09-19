import 'package:get/get.dart';

import '../../data/repositories/followup_implement.dart';
import '../../domain/usecases/get_followup_usecase.dart';
import '../controllers/follow_up_controller.dart';

class FollowUpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => FollowUpController(
        getFollowupUsecase: GetFollowupUsecase(
          followupRepository: Get.find<FollowupImplement>(),
        ),
      ),
    );
  }
}
