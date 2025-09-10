import 'package:get/get.dart';

class BuyingController extends GetxController {
  var tabs = [
    'bills',
    'archive',
  ];

  var currentTab = 0.obs;

  void changeTab(int index) {
    currentTab.value = index;
  }
}
