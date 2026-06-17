import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../controllers/sales_controller.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../boxes/data/repositories/boxes_implement.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../data/datasources/sales_datasources.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/daily_session_model.dart';

class SalesDailyAdminController extends GetxController {
  final SalesDatasource datasource;
  final GetShownBoxUsecase getShownBoxUsecase;

  SalesDailyAdminController({
    required this.datasource,
    required this.getShownBoxUsecase,
  });

  final isLoading = false.obs;
  final isProcessing = false.obs;
  final openSessions = <DailySessionSummaryModel>[].obs;
  final closingRequests = <DailyClosingRequestModel>[].obs;
  final reopenRequests = <DailyReopenRequestModel>[].obs;
  final cancellationRequests = <SalesCancellationRequestModel>[].obs;
  final shownBoxes = <ShownBoxesModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading(true);
    try {
      final boxes = await getShownBoxUsecase.call(screen: 0);
      shownBoxes.assignAll(boxes);
      openSessions.assignAll(await datasource.getOpenDailySessions());
      closingRequests.assignAll(await datasource.getPendingDailyClosing());
      reopenRequests.assignAll(await datasource.getPendingDailyReopen());
      cancellationRequests.assignAll(await datasource.getPendingCancellations());
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

  Future<void> _refreshSalesScreenIfOpen() async {
    if (Get.isRegistered<SalesController>()) {
      await Get.find<SalesController>().loadDailySession();
    }
  }

  void _showSuccess(String message) {
    final overlayContext = Get.overlayContext ?? Get.context;
    if (overlayContext != null) {
      Helpers.showCustomDialogSuccess(
        context: overlayContext,
        title: 'success'.tr,
        message: message,
        autoCloseAfter: const Duration(seconds: 2),
      );
      return;
    }
    Get.snackbar('success'.tr, message);
  }

  Future<void> approveClosing({
    required int requestId,
    required List<Map<String, dynamic>> transfers,
  }) async {
    isProcessing(true);
    try {
      final message = await datasource.approveDailyClosing(
        closingRequestId: requestId,
        transfers: transfers,
      );
      await loadAll();
      await _refreshSalesScreenIfOpen();
      _showSuccess(message);
    } catch (e) {
      Helpers.showCustomDialogError(
        context: Get.overlayContext ?? Get.context!,
        title: 'error'.tr,
        message: e.toString(),
      );
    } finally {
      isProcessing(false);
    }
  }

  Future<void> rejectClosing(int requestId) async {
    isProcessing(true);
    try {
      final message = await datasource.rejectDailyClosing(
        closingRequestId: requestId,
      );
      await loadAll();
      await _refreshSalesScreenIfOpen();
      _showSuccess(message);
    } catch (e) {
      Helpers.showCustomDialogError(
        context: Get.overlayContext ?? Get.context!,
        title: 'error'.tr,
        message: e.toString(),
      );
    } finally {
      isProcessing(false);
    }
  }

  Future<void> approveReopen(int requestId) async {
    isProcessing(true);
    try {
      final message = await datasource.approveDailyReopen(
        reopenRequestId: requestId,
      );
      await loadAll();
      await _refreshSalesScreenIfOpen();
      _showSuccess(message);
    } catch (e) {
      Helpers.showCustomDialogError(
        context: Get.overlayContext ?? Get.context!,
        title: 'error'.tr,
        message: e.toString(),
      );
    } finally {
      isProcessing(false);
    }
  }

  Future<void> rejectReopen(int requestId) async {
    isProcessing(true);
    try {
      final message = await datasource.rejectDailyReopen(
        reopenRequestId: requestId,
      );
      await loadAll();
      await _refreshSalesScreenIfOpen();
      _showSuccess(message);
    } catch (e) {
      Helpers.showCustomDialogError(
        context: Get.overlayContext ?? Get.context!,
        title: 'error'.tr,
        message: e.toString(),
      );
    } finally {
      isProcessing(false);
    }
  }

  Future<void> approveCancellation(int requestId) async {
    isLoading(true);
    try {
      await datasource.approveSalesCancellation(requestId);
      await loadAll();
      Helpers.showCustomDialogSuccess(
        context: Get.context!,
        title: 'success'.tr,
        message: 'salesDailyCancelApproved'.tr,
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

  Future<void> rejectCancellation(int requestId) async {
    isLoading(true);
    try {
      await datasource.rejectSalesCancellation(requestId);
      await loadAll();
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
  void openSessionClose(int sessionId) {
    Get.toNamed(
      AppRoutes.SALESDAILYCLOSESCREEN,
      arguments: sessionId,
    );
  }
}

class SalesDailyAdminBinding extends Bindings {
  @override
  void dependencies() {
    AppDependencyRegistry.ensureSales();
    AppDependencyRegistry.ensureBoxes();
    Get.lazyPut(
      () => SalesDailyAdminController(
        datasource: Get.find<SalesDatasource>(),
        getShownBoxUsecase: GetShownBoxUsecase(
          boxesRepository: Get.find<BoxesImplement>(),
        ),
      ),
    );
  }
}
