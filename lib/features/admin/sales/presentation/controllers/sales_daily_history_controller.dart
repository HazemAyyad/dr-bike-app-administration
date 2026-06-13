import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/datasources/sales_datasources.dart';
import '../../data/models/daily_session_model.dart';

class SalesDailyHistoryController extends GetxController {
  final SalesDatasource datasource;

  SalesDailyHistoryController({required this.datasource});

  final isLoading = false.obs;
  final todayOverview = Rxn<DailyTodayOverviewModel>();
  final historySessions = <DailySessionSummaryModel>[].obs;
  final canViewAll = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading(true);
    try {
      final overview = await datasource.getDailySessionsTodayOverview();
      todayOverview.value = overview;
      final history = await datasource.getDailySessionsHistory(page: 1);
      historySessions.assignAll(
        history
            .where((session) => session.businessDate != overview.businessDate)
            .toList(),
      );
    } catch (e) {
      Helpers.showCustomDialogError(
        context: Get.context!,
        title: 'error'.tr,
        message: e.toString(),
      );
    } finally {
      isLoading(false);
    }
  }

  void openSessionDetail(int sessionId) {
    Get.toNamed(
      AppRoutes.SALESDAILYSESSIONDETAILSCREEN,
      arguments: sessionId,
    );
  }
}

class SalesDailyHistoryBinding extends Bindings {
  @override
  void dependencies() {
    AppDependencyRegistry.ensureSales();
    Get.lazyPut(
      () => SalesDailyHistoryController(
        datasource: Get.find<SalesDatasource>(),
      ),
    );
  }
}
