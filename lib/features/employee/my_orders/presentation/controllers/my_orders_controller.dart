import 'package:get/get.dart';

import '../../domain/usecases/get_my_orders_usecase.dart';
import 'my_orders_service.dart';

class MyOrdersController extends GetxController {
  final GetMyOrdersUsecase getMyOrdersUsecase;

  MyOrdersController({required this.getMyOrdersUsecase});

  var currentTab = 0.obs;
  List<String> tabs = ['loanRequests', 'overtimeRequests'];

  void changeTab(int index) {
    currentTab.value = index;
    update();
  }

  final RxBool isLoading = false.obs;
  // get my orders

  Future<void> getMyOrders() async {
    MyOrdersService().loansList.isEmpty ? isLoading(true) : null;
    final result = await getMyOrdersUsecase.call();
    MyOrdersService().loansList.value =
        result.where((element) => element.type == 'loan').toList();
    MyOrdersService().overtimeList.value =
        result.where((element) => element.type == 'overtime').toList();
    isLoading(false);
    update();
  }

  @override
  void onInit() {
    super.onInit();
    getMyOrders();
  }
}
