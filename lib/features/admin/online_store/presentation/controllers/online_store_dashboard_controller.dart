import 'package:get/get.dart';

import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';
import '../../../../../../core/databases/api/end_points.dart';

class OnlineStoreDashboardController extends GetxController {
  OnlineStoreDashboardController(this.repository);
  final OnlineStoreRepository repository;
  final loading = false.obs;
  final error = RxnString();
  final summary = Rxn<OnlineStoreDashboardSummary>();
  final toolsGrid = false.obs;
  final periodDays = 30.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      summary.value = OnlineStoreDashboardSummary.fromJson(
        await repository.get(
          EndPoints.onlineStoreDashboard,
          query: {'days': periodDays.value},
        ),
      );
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading.value = false;
    }
  }

  Future<void> setPeriod(int days) async {
    if (periodDays.value == days) return;
    periodDays.value = days;
    await load();
  }
}
