import 'package:get/get.dart';

class OfficialPapersController extends GetxController {
  final RxInt currentTab = 0.obs;
  final tabs = ['generalAdministrativeExpenses', 'DestructionProducts'].obs;

  void changeTab(int index) {
    currentTab.value = index;
    update();
  }
}
