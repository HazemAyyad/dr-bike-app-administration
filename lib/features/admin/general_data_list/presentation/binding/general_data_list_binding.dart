import 'package:get/get.dart';

import '../controllers/general_data_list_controller.dart';


class GeneralDataListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GeneralDataListController());
  }
}
