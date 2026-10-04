import 'package:get/get.dart';

import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';

class OnlineStoreDashboardController extends GetxController {
  OnlineStoreDashboardController(this.repository);
  final OnlineStoreRepository repository;
  final loading = false.obs;
  final error = RxnString();
  final summary = Rxn<OnlineStoreDashboardSummary>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      summary.value = await repository.dashboard();
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading.value = false;
    }
  }
}
