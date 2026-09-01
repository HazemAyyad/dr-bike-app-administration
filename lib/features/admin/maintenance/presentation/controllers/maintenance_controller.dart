import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../../checks/data/models/check_model.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../../sales/presentation/binding/sales_binding.dart';
import '../../../sales/presentation/controllers/sales_controller.dart';
import '../../../sales/presentation/models/instant_sale_cart_line.dart';
import '../../../sales/presentation/utils/sales_amount_format.dart';
import '../../../create_tasks/presentation/widgets/horizontal_time_picker_sheet.dart';
import '../../data/repositories/maintenance_implement.dart';
import '../../data/models/maintenance_product_model.dart';
import '../../data/models/maintenance_service_model.dart';
import '../../data/models/maintenances_model.dart';
import '../../domain/usecases/creat_maintenance_usecase.dart';
import '../../domain/usecases/delete_maintenance_usecase.dart';
import '../../domain/usecases/deliver_maintenance_usecase.dart';
import '../../domain/usecases/add_maintenance_payment_usecase.dart';
import '../../domain/usecases/get_maintenance_activity_log_usecase.dart';
import '../../domain/usecases/get_maintenance_daily_session_usecase.dart';
import '../../domain/usecases/get_maintenance_invoice_usecase.dart';
import '../../domain/usecases/get_maintenances_details_usecase.dart';
import '../../domain/usecases/maintenance_usecase.dart';
import '../../domain/usecases/open_maintenance_daily_session_usecase.dart';
import '../../domain/usecases/request_maintenance_daily_session_closing_usecase.dart';
import '../../domain/usecases/sync_maintenance_products_usecase.dart';
import 'maintenance_serves.dart';
import '../widgets/maintenance_activity_log_sheet.dart';
import '../widgets/maintenance_delivery_dialog.dart';
import '../widgets/maintenance_invoice_sheet.dart';

class MaintenanceController extends GetxController {
  static const _localDraftKey = 'maintenance_local_draft_v1';
  static const maintenanceFilterAll = 'all';
  static const maintenanceFilterNew = 'new';
  static const maintenanceFilterOngoing = 'ongoing';
  static const maintenanceFilterReady = 'ready';
  static const maintenanceFilterDelivered = 'delivered';
  static const maintenanceFilterArchived = 'archived';

  final MaintenanceUsecase maintenanceUsecase;
  final CreatMaintenanceUsecase creatMaintenanceUsecase;
  final DeleteMaintenanceUsecase deleteMaintenanceUsecase;
  final AllCustomersSellersUsecase allCustomersSellersUsecase;
  final GetMaintenancesDetailsUsecase getMaintenancesDetailsUsecase;
  final SyncMaintenanceProductsUsecase syncMaintenanceProductsUsecase;
  final DeliverMaintenanceUsecase deliverMaintenanceUsecase;
  final AddMaintenancePaymentUsecase addMaintenancePaymentUsecase;
  final GetMaintenanceActivityLogUsecase getMaintenanceActivityLogUsecase;
  final GetMaintenanceInvoiceUsecase getMaintenanceInvoiceUsecase;
  final GetMaintenanceDailySessionUsecase getMaintenanceDailySessionUsecase;
  final OpenMaintenanceDailySessionUsecase openMaintenanceDailySessionUsecase;
  final RequestMaintenanceDailySessionClosingUsecase
      requestMaintenanceDailySessionClosingUsecase;
  final GetShownBoxUsecase getShownBoxUsecase;

  MaintenanceController({
    required this.maintenanceUsecase,
    required this.creatMaintenanceUsecase,
    required this.deleteMaintenanceUsecase,
    required this.allCustomersSellersUsecase,
    required this.getMaintenancesDetailsUsecase,
    required this.syncMaintenanceProductsUsecase,
    required this.deliverMaintenanceUsecase,
    required this.addMaintenancePaymentUsecase,
    required this.getMaintenanceActivityLogUsecase,
    required this.getMaintenanceInvoiceUsecase,
    required this.getMaintenanceDailySessionUsecase,
    required this.openMaintenanceDailySessionUsecase,
    required this.requestMaintenanceDailySessionClosingUsecase,
    required this.getShownBoxUsecase,
  });

  final formKey = GlobalKey<FormState>();
  TextEditingController searchController = TextEditingController();
  TextEditingController partnerIdController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController laborCostController = TextEditingController();
  TextEditingController discountController = TextEditingController();

  RxInt currentTab = 0.obs;
  final RxString maintenanceViewFilter = maintenanceFilterAll.obs;
  final RxBool maintenanceBulkMode = false.obs;
  final RxSet<int> selectedMaintenanceIds = <int>{}.obs;
  final RxBool isSearchVisible = false.obs;
  RxBool selectedSellers = false.obs;
  RxBool isCalendarVisible = false.obs;
  RxBool isTimeVisible = false.obs;
  RxInt selectedStep = 1.obs;
  RxBool isEditLoading = false.obs;
  RxBool isEdit = false.obs;
  RxBool isDelivered = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isAutoSaving = false.obs;
  final RxBool hasAutoSaveError = false.obs;
  final RxBool isDailyBoxLoading = false.obs;
  final RxBool isDailyClosingReviewLoading = false.obs;
  final RxList<Map<String, dynamic>> dailyOpenSessions =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> dailyClosingRequests =
      <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> dailyBoxPayload = <String, dynamic>{}.obs;
  final RxList<MaintenanceProductModel> maintenanceProducts =
      <MaintenanceProductModel>[].obs;
  final RxList<MaintenanceServiceModel> maintenanceServices =
      <MaintenanceServiceModel>[].obs;
  final RxList<MaintenanceServiceModel> selectedMaintenanceServices =
      <MaintenanceServiceModel>[].obs;
  final RxMap<int, double> maintenanceServicePrices = <int, double>{}.obs;
  final RxList<Map<String, dynamic>> additionalCharges =
      <Map<String, dynamic>>[].obs;
  final RxList<MaintenanceServiceModel> serviceSuggestions =
      <MaintenanceServiceModel>[].obs;
  final RxList<ShownBoxesModel> paymentBoxes = <ShownBoxesModel>[].obs;
  final RxDouble maintenancePaidAmount = 0.0.obs;
  final RxList<Map<String, dynamic>> maintenancePayments =
      <Map<String, dynamic>>[].obs;
  final RxBool isServicesLoading = false.obs;

  String? maintenanceId;
  Timer? _autoSaveDebounce;
  Timer? _localDraftDebounce;
  bool _restoringLocalDraft = false;
  bool _isHydratingMaintenanceForm = false;
  bool _autoSaveQueued = false;
  int? _queuedAutoSaveStep;

  final List<Map<int, String>> timeLineSteps = [
    {1: 'newMaintenance'},
    {2: 'inProgress'},
    {3: 'readyToDeliver'},
  ];

  List<String> tabs = [
    'newRequest',
    'inProgress',
    'readyToDeliver',
    'delivered',
    'archive',
  ];

  double get laborCost => SalesAmountFormat.parse(laborCostController.text);
  double get discount => SalesAmountFormat.parse(discountController.text);
  double get partsTotal => maintenanceProducts.fold(
        0.0,
        (sum, item) => sum + item.lineTotal,
      );
  double get selectedServicesTotal => selectedMaintenanceServices.fold(
        0.0,
        (sum, item) => sum + (maintenanceServicePrices[item.id] ?? item.price),
      );
  double get additionalChargesTotal => additionalCharges.fold(
        0.0,
        (sum, item) => sum + SalesAmountFormat.parse('${item['amount'] ?? 0}'),
      );
  double get invoiceTotal => (partsTotal +
          selectedServicesTotal +
          laborCost +
          additionalChargesTotal -
          discount)
      .clamp(0, double.infinity);

  Map<String, dynamic>? get dailyBoxSession {
    final session = dailyBoxPayload['session'];
    return session is Map ? Map<String, dynamic>.from(session) : null;
  }

  Map<String, dynamic>? get dailyBoxInfo {
    final box = dailyBoxPayload['box'];
    return box is Map ? Map<String, dynamic>.from(box) : null;
  }

  bool get isMaintenanceDailyBoxOpen =>
      dailyBoxSession?['status']?.toString() == 'open';

  bool get isMaintenanceDailyBoxClosingRequested =>
      dailyBoxSession?['status']?.toString() == 'closing_requested';

  bool get canRequestMaintenanceDailyOpen =>
      dailyBoxPayload['can_request_open'] == true ||
      dailyBoxPayload['can_request_open'] == 1;

  bool get canRequestMaintenanceDailyClosing =>
      dailyBoxSession?['can_request_closing'] == true ||
      dailyBoxSession?['can_request_closing'] == 1;

  bool get canFinalizeMaintenanceDailyClosing =>
      dailyBoxPayload['can_finalize_closing'] == true ||
      dailyBoxPayload['can_finalize_closing'] == 1;

  bool get isMaintenanceDailyBlockedByOther =>
      dailyBoxPayload['blocked_by_other_session'] == true ||
      dailyBoxPayload['blocked_by_other_session'] == 1;

  String? get maintenanceDailyBlockedByEmployeeName =>
      dailyBoxPayload['blocked_by_employee_name']?.toString();

  double get maintenanceDailyOpeningBalance =>
      _numFrom(dailyBoxSession?['opening_balance']);

  double get maintenanceDailyCashTotal =>
      _numFrom(dailyBoxPayload['cash_total']);

  double get maintenanceDailyVisaTotal =>
      _numFrom(dailyBoxPayload['visa_total']);

  double get maintenanceDailyTransferTotal =>
      _numFrom(dailyBoxPayload['transfer_total']);

  double get maintenanceDailyDebtTotal =>
      _numFrom(dailyBoxPayload['debt_total']);

  double get maintenanceDailyExpectedClosingBalance => _numFrom(
        dailyBoxPayload['expected_closing_balance'] ??
            dailyBoxSession?['expected_closing_balance'],
      );

  Future<void>? _maintenanceDailySessionLoad;

  String get maintenanceDailyBoxName =>
      dailyBoxInfo?['name']?.toString() ?? 'صندوق الصيانة اليومي';

  void changeTab(int index) {
    currentTab.value = index;
    maintenanceViewFilter.value = _filterForIndex(index);
    update();
  }

  String _filterForIndex(int index) {
    switch (index) {
      case 1:
        return maintenanceFilterOngoing;
      case 2:
        return maintenanceFilterReady;
      case 3:
        return maintenanceFilterDelivered;
      case 4:
        return maintenanceFilterArchived;
      default:
        return maintenanceFilterNew;
    }
  }

  void setMaintenanceViewFilter(String value) {
    maintenanceViewFilter.value = value;
    if (value != maintenanceFilterReady) {
      toggleMaintenanceBulkMode(false);
    } else {
      selectedMaintenanceIds.clear();
    }
    if (value == maintenanceFilterOngoing) {
      currentTab.value = 1;
    } else if (value == maintenanceFilterReady) {
      currentTab.value = 2;
    } else if (value == maintenanceFilterDelivered) {
      currentTab.value = 3;
    } else if (value == maintenanceFilterArchived) {
      currentTab.value = 4;
    } else {
      currentTab.value = 0;
    }
    update();
  }

  void toggleMaintenanceBulkMode([bool? value]) {
    maintenanceBulkMode.value = value ?? !maintenanceBulkMode.value;
    if (!maintenanceBulkMode.value) selectedMaintenanceIds.clear();
    update();
  }

  void toggleMaintenanceSelection(int id, bool selected) {
    if (selected) {
      selectedMaintenanceIds.add(id);
    } else {
      selectedMaintenanceIds.remove(id);
    }
    selectedMaintenanceIds.refresh();
    update();
  }

  void selectAllReadyMaintenances() {
    selectedMaintenanceIds
      ..clear()
      ..addAll(
        readyMaintenancesSearch.values
            .expand((items) => items)
            .map((e) => e.id),
      );
    selectedMaintenanceIds.refresh();
    update();
  }

  void changeSelected(int index) => selectedStep.value = index;

  void recalculateTotals() => maintenanceProducts.refresh();

  Future<void> loadMaintenanceDailySession() {
    final activeLoad = _maintenanceDailySessionLoad;
    if (activeLoad != null) return activeLoad;

    late final Future<void> load;
    load = _loadMaintenanceDailySession().whenComplete(() {
      if (identical(_maintenanceDailySessionLoad, load)) {
        _maintenanceDailySessionLoad = null;
      }
    });
    _maintenanceDailySessionLoad = load;
    return load;
  }

  Future<void> _loadMaintenanceDailySession() async {
    isDailyBoxLoading(true);
    final result = await getMaintenanceDailySessionUsecase.call();
    result.fold(
      (failure) => dailyBoxPayload.clear(),
      (payload) => dailyBoxPayload.assignAll(payload),
    );
    isDailyBoxLoading(false);
    update();
  }

  double _numFrom(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<bool> openMaintenanceDailySession({double openingBalance = 0}) async {
    isDailyBoxLoading(true);
    update();

    final result = await openMaintenanceDailySessionUsecase.call(
      openingBalance: openingBalance,
    );
    var opened = false;
    result.fold(
      (failure) {
        Get.snackbar(
          'error'.tr,
          failure.errMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
      (payload) {
        opened = true;
        dailyBoxPayload.assignAll(payload);
        Get.snackbar(
          'success'.tr,
          'تم فتح صندوق الصيانة اليومي',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );

    isDailyBoxLoading(false);
    update();
    return opened;
  }

  Future<bool> requestMaintenanceDailySessionClosing({
    String? note,
    double? physicalCount,
    double? floatToKeep,
  }) async {
    isDailyBoxLoading(true);
    update();

    final result = await requestMaintenanceDailySessionClosingUsecase.call(
      note: note,
      physicalCount: physicalCount,
      floatToKeep: floatToKeep,
    );
    var requested = false;
    result.fold(
      (failure) {
        Get.snackbar(
          'error'.tr,
          failure.errMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
      (payload) {
        requested = true;
        dailyBoxPayload.assignAll(payload);
        Get.snackbar(
          'success'.tr,
          'تم إرسال طلب إغلاق صندوق الصيانة',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );

    isDailyBoxLoading(false);
    update();
    return requested;
  }

  Future<void> loadMaintenanceDailyClosingRequests() async {
    isDailyClosingReviewLoading(true);
    update();
    try {
      if (paymentBoxes.isEmpty) {
        paymentBoxes.assignAll(await getShownBoxUsecase.call(screen: 0));
      }
      final response = await Get.find<MaintenanceImplement>()
          .maintenanceDatasource
          .getPendingDailyClosing();
      if (response['status'] == 'success') {
        final rows = response['closing_requests'];
        dailyClosingRequests.assignAll(
          rows is List
              ? rows
                  .whereType<Map>()
                  .map((row) => Map<String, dynamic>.from(row))
                  .toList()
              : <Map<String, dynamic>>[],
        );
      } else {
        Get.snackbar(
          'error'.tr,
          response['message']?.toString() ?? 'tryAgain'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isDailyClosingReviewLoading(false);
      update();
    }
  }

  Future<void> loadMaintenanceDailyAdminData() async {
    isDailyClosingReviewLoading(true);
    update();
    try {
      if (paymentBoxes.isEmpty) {
        paymentBoxes.assignAll(await getShownBoxUsecase.call(screen: 0));
      }
      final datasource = Get.find<MaintenanceImplement>().maintenanceDatasource;
      final openResponse = await datasource.getOpenDailySessions();
      final closingResponse = await datasource.getPendingDailyClosing();

      if (openResponse['status'] == 'success') {
        final rows = openResponse['sessions'];
        dailyOpenSessions.assignAll(
          rows is List
              ? rows
                  .whereType<Map>()
                  .map((row) => Map<String, dynamic>.from(row))
                  .toList()
              : <Map<String, dynamic>>[],
        );
      } else {
        throw Exception(openResponse['message']?.toString() ?? 'tryAgain'.tr);
      }

      if (closingResponse['status'] == 'success') {
        final rows = closingResponse['closing_requests'];
        dailyClosingRequests.assignAll(
          rows is List
              ? rows
                  .whereType<Map>()
                  .map((row) => Map<String, dynamic>.from(row))
                  .toList()
              : <Map<String, dynamic>>[],
        );
      } else {
        throw Exception(
          closingResponse['message']?.toString() ?? 'tryAgain'.tr,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isDailyClosingReviewLoading(false);
      update();
    }
  }

  Future<bool> approveMaintenanceDailyClosing(
    int closingRequestId, {
    int? toBoxId,
    String? note,
  }) async {
    return _reviewMaintenanceDailyClosing(
      closingRequestId,
      approve: true,
      toBoxId: toBoxId,
      note: note,
    );
  }

  Future<bool> rejectMaintenanceDailyClosing(
    int closingRequestId, {
    String? note,
  }) async {
    return _reviewMaintenanceDailyClosing(
      closingRequestId,
      approve: false,
      note: note,
    );
  }

  Future<bool> directCloseMaintenanceDailySession(
    int sessionId, {
    int? toBoxId,
    String? note,
    double? physicalCount,
    double? floatToKeep,
  }) async {
    isDailyClosingReviewLoading(true);
    update();
    try {
      final datasource = Get.find<MaintenanceImplement>().maintenanceDatasource;
      final response = await datasource.directCloseDailySession(
        sessionId: sessionId,
        toBoxId: toBoxId,
        reviewNote: note,
        physicalCount: physicalCount,
        floatToKeep: floatToKeep,
      );
      if (response['status'] == 'success') {
        Get.snackbar(
          'success'.tr,
          response['message']?.toString() ?? 'تم إغلاق صندوق الصيانة مباشرة',
          snackPosition: SnackPosition.BOTTOM,
        );
        await loadMaintenanceDailyAdminData();
        await loadMaintenanceDailySession();
        return true;
      }
      Get.snackbar(
        'error'.tr,
        response['message']?.toString() ?? 'tryAgain'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isDailyClosingReviewLoading(false);
      update();
    }
  }

  Future<bool> _reviewMaintenanceDailyClosing(
    int closingRequestId, {
    required bool approve,
    int? toBoxId,
    String? note,
  }) async {
    isDailyClosingReviewLoading(true);
    update();
    try {
      final datasource = Get.find<MaintenanceImplement>().maintenanceDatasource;
      final response = approve
          ? await datasource.approveDailyClosing(
              closingRequestId: closingRequestId,
              toBoxId: toBoxId,
              reviewNote: note,
            )
          : await datasource.rejectDailyClosing(
              closingRequestId: closingRequestId,
              reviewNote: note,
            );
      if (response['status'] == 'success') {
        Get.snackbar(
          'success'.tr,
          response['message']?.toString() ??
              (approve
                  ? 'تم اعتماد إغلاق صندوق الصيانة'
                  : 'تم رفض طلب إغلاق صندوق الصيانة'),
          snackPosition: SnackPosition.BOTTOM,
        );
        await loadMaintenanceDailyClosingRequests();
        await loadMaintenanceDailySession();
        return true;
      }
      Get.snackbar(
        'error'.tr,
        response['message']?.toString() ?? 'tryAgain'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isDailyClosingReviewLoading(false);
      update();
    }
  }

  @override
  void onClose() {
    _autoSaveDebounce?.cancel();
    _localDraftDebounce?.cancel();
    searchController.dispose();
    partnerIdController.dispose();
    descriptionController.dispose();
    laborCostController.dispose();
    discountController.dispose();
    super.onClose();
  }

  void nextStep() async {
    if (!formKey.currentState!.validate()) return;

    if (maintenanceId == null || maintenanceId!.isEmpty) {
      if (selectedStep.value < timeLineSteps.length) {
        selectedStep.value += 1;
        scheduleAutoSave(step: selectedStep.value);
        update();
      } else {
        Get.snackbar(
          'تنبيه',
          'احفظ طلب الصيانة أولاً قبل التسليم',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return;
    }

    if (selectedStep.value >= timeLineSteps.length) {
      await _handleDeliver();
      return;
    }

    if (!isEdit.value) {
      await createMaintenance(step: selectedStep.value);
    } else {
      await createMaintenance(
        step: selectedStep.value,
        maintenanceId: maintenanceId,
      );
    }

    if (selectedStep.value < timeLineSteps.length) {
      selectedStep.value += 1;
      if (isEdit.value) {
        await createMaintenance(
          step: selectedStep.value,
          maintenanceId: maintenanceId,
        );
      }
    }
    update();
  }

  Future<void> _handleDeliver() async {
    if (maintenanceId == null || maintenanceId!.isEmpty) {
      await createMaintenance(step: 3, maintenanceId: maintenanceId);
    }
    await syncProductsIfPossible();
    await showMaintenanceDeliveryDialog(this);
  }

  Future<void> deliverFromList(
    BuildContext context, {
    required String maintenanceId,
  }) async {
    await getMaintenancesDetails(maintenanceId: maintenanceId);
    if (!context.mounted || this.maintenanceId != maintenanceId) return;
    await syncProductsIfPossible();
    if (!context.mounted) return;
    await showMaintenanceDeliveryDialog(this);
  }

  void prevStep() {
    if (selectedStep.value <= 1) return;
    selectedStep.value -= 1;
    if (maintenanceId == null || maintenanceId!.isEmpty) {
      scheduleAutoSave(step: selectedStep.value);
      update();
      return;
    }
    createMaintenance(step: selectedStep.value, maintenanceId: maintenanceId);
  }

  void scheduleAutoSave({int? step}) {
    if (_isHydratingMaintenanceForm) return;
    if (!isEdit.value) {
      _scheduleLocalDraftSave();
      return;
    }
    if (isDelivered.value || maintenanceId == null || maintenanceId!.isEmpty) {
      return;
    }
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(
      const Duration(milliseconds: 650),
      () => autoSaveMaintenance(step: step),
    );
  }

  void _scheduleLocalDraftSave() {
    if (_restoringLocalDraft || maintenanceId != null) return;
    _localDraftDebounce?.cancel();
    _localDraftDebounce = Timer(
      const Duration(milliseconds: 500),
      saveLocalMaintenanceDraft,
    );
  }

  Future<void> saveLocalMaintenanceDraft() async {
    if (_restoringLocalDraft || maintenanceId != null) return;
    final hasContent = partnerIdController.text.trim().isNotEmpty ||
        descriptionController.text.trim().isNotEmpty ||
        maintenanceProducts.isNotEmpty ||
        selectedMaintenanceServices.isNotEmpty ||
        additionalCharges.isNotEmpty ||
        laborCost > 0 ||
        discount > 0;
    if (!hasContent) return;
    await GetStorage().write(
      _localDraftKey,
      jsonEncode({
        'saved_at': DateTime.now().toIso8601String(),
        'partner_id': partnerIdController.text,
        'is_seller': selectedSellers.value,
        'description': descriptionController.text,
        'labor_cost': laborCostController.text,
        'discount': discountController.text,
        'selected_step': selectedStep.value,
        'show_delivery_schedule': showDeliverySchedule.value,
        'delivery_date': deliveryDate.value.toIso8601String(),
        'delivery_hour': deliveryTime.value.hour,
        'delivery_minute': deliveryTime.value.minute,
        'products': maintenanceProducts
            .map((item) => {
                  ...item.toApiJson(),
                  'product_name': item.productName,
                  'image_url': item.imageUrl,
                  'line_total': item.lineTotal,
                })
            .toList(),
        'services': selectedMaintenanceServices
            .map((service) => {
                  'id': service.id,
                  'name': service.name,
                  'description': service.description,
                  'price': service.price,
                  'is_active': service.isActive,
                  'media': service.media
                      .map((media) => {
                            'id': media.id,
                            'url': media.url,
                            'file_type': media.fileType,
                          })
                      .toList(),
                })
            .toList(),
        'service_prices': maintenanceServicePrices.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
        'additional_charges': additionalCharges.toList(),
        'selected_media': selectedMedia.map((file) => file.path).toList(),
      }),
    );
  }

  Future<void> clearLocalMaintenanceDraft() async {
    _localDraftDebounce?.cancel();
    await GetStorage().remove(_localDraftKey);
  }

  Future<void> autoSaveMaintenance({int? step}) async {
    if (!isEdit.value ||
        isDelivered.value ||
        maintenanceId == null ||
        maintenanceId!.isEmpty) {
      return;
    }
    if (isAutoSaving.value) {
      _autoSaveQueued = true;
      _queuedAutoSaveStep = step;
      return;
    }

    isAutoSaving(true);
    hasAutoSaveError(false);
    update(['maintenanceAutoSaveStatus']);

    final ok = await createMaintenance(
      step: step ?? selectedStep.value,
      maintenanceId: maintenanceId,
      silent: true,
    );

    hasAutoSaveError(!ok);
    isAutoSaving(false);
    update(['maintenanceAutoSaveStatus']);

    if (_autoSaveQueued) {
      final queuedStep = _queuedAutoSaveStep;
      _autoSaveQueued = false;
      _queuedAutoSaveStep = null;
      await autoSaveMaintenance(step: queuedStep);
    }
  }

  final Rx<DateTime> deliveryDate = DateTime.now().obs;
  final Rx<TimeOfDay> deliveryTime = TimeOfDay.now().obs;
  final RxBool showDeliverySchedule = false.obs;
  List<File> selectedMedia = [];

  void toggleDeliverySchedule(bool value) {
    showDeliverySchedule.value = value;
    scheduleAutoSave();
    update();
  }

  Future<void> pickDeliveryDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: deliveryDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'اختر موعد التسليم',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primaryColor,
                secondary: AppColors.operationalPurple,
              ),
          datePickerTheme: DatePickerThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        child: Directionality(
          textDirection: Directionality.of(context),
          child: child!,
        ),
      ),
    );
    if (picked == null) return;
    deliveryDate.value = DateTime(
      picked.year,
      picked.month,
      picked.day,
      deliveryTime.value.hour,
      deliveryTime.value.minute,
    );
    scheduleAutoSave();
  }

  Future<void> pickDeliveryTime(BuildContext context) async {
    final picked = await HorizontalTimePickerSheet.show(
      context,
      initial: deliveryTime.value,
    );
    if (picked == null) return;
    deliveryTime.value = picked;
    scheduleAutoSave();
  }

  Future<void> openProductPicker(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    if (maintenanceId == null || maintenanceId!.isEmpty) {
      await createMaintenance(
          step: selectedStep.value, maintenanceId: maintenanceId);
      if (maintenanceId == null || maintenanceId!.isEmpty) return;
    }

    AppDependencyRegistry.ensureSales();
    if (!Get.isRegistered<SalesController>() &&
        !Get.isPrepared<SalesController>()) {
      SalesBinding().dependencies();
    }

    final sales = Get.find<SalesController>();
    sales.resetInstantSaleForm();
    sales.setMaintenancePickerFlow(true);
    _hydrateSalesCart(sales);
    sales.enablePickerReservedStock();
    if (sales.products.isEmpty) {
      sales.getAllProducts();
    }

    final confirmed = await Get.toNamed(
      AppRoutes.INSTANTSALEPRODUCTPICKER,
      arguments: {'maintenanceFlow': true},
    );

    sales.disablePickerReservedStock();

    if (confirmed == true) {
      _importProductsFromSalesCart(sales);
    }
    update();
  }

  Future<void> loadMaintenanceServices({String? search}) async {
    isServicesLoading(true);
    update();
    try {
      final datasource = Get.find<MaintenanceImplement>().maintenanceDatasource;
      final services = await datasource.getMaintenanceServices(search: search);
      maintenanceServices.assignAll(services);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isServicesLoading(false);
      update();
    }
  }

  Future<void> searchServiceSuggestions(String value) async {
    final query = _serviceSearchTerm(value);
    if (query.length < 2) {
      serviceSuggestions.clear();
      update(['maintenanceServiceSuggestions']);
      return;
    }

    final datasource = Get.find<MaintenanceImplement>().maintenanceDatasource;
    final suggestions = await datasource.searchMaintenanceServices(query);
    serviceSuggestions.assignAll(suggestions);
    update(['maintenanceServiceSuggestions']);
  }

  String _serviceSearchTerm(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return '';
    final parts = clean.split(RegExp(r'[\n،,]+'));
    return parts.isEmpty ? clean : parts.last.trim();
  }

  void addMaintenanceServiceToDetails(MaintenanceServiceModel service) {
    final alreadySelected = selectedMaintenanceServices.any(
      (item) => item.id == service.id,
    );
    if (!alreadySelected) {
      selectedMaintenanceServices.add(service);
      maintenanceServicePrices[service.id] = service.price;
    }

    final line =
        '${service.name} - ${SalesAmountFormat.display(service.price)}';
    final current = descriptionController.text.trimRight();
    final hasServiceLine = current.split('\n').any(
          (candidate) => candidate.trim() == line.trim(),
        );
    if (!hasServiceLine) {
      descriptionController.text = current.isEmpty ? line : '$current\n$line';
    }

    serviceSuggestions.clear();
    recalculateTotals();
    syncProductsIfPossible();
    scheduleAutoSave();
    update(['maintenanceServiceSuggestions']);
    update();
  }

  void removeMaintenanceService(int index) {
    if (index < 0 || index >= selectedMaintenanceServices.length) return;
    final service = selectedMaintenanceServices.removeAt(index);
    maintenanceServicePrices.remove(service.id);

    final line =
        '${service.name} - ${SalesAmountFormat.display(service.price)}';
    final lines = descriptionController.text
        .split('\n')
        .where((item) => item.trim() != line.trim())
        .toList();
    descriptionController.text = lines.join('\n');

    recalculateTotals();
    syncProductsIfPossible();
    scheduleAutoSave();
    update();
  }

  void updateMaintenanceServicePrice(int index, double price) {
    if (index < 0 || index >= selectedMaintenanceServices.length) return;
    final service = selectedMaintenanceServices[index];
    maintenanceServicePrices[service.id] = price.clamp(0, double.infinity);
    syncProductsIfPossible();
    scheduleAutoSave();
    update();
  }

  void addAdditionalCharge() {
    additionalCharges.add({'label': '', 'amount': 0.0});
    scheduleAutoSave();
    update();
  }

  void updateAdditionalCharge(int index, {String? label, double? amount}) {
    if (index < 0 || index >= additionalCharges.length) return;
    final line = Map<String, dynamic>.from(additionalCharges[index]);
    if (label != null) line['label'] = label;
    if (amount != null) line['amount'] = amount.clamp(0, double.infinity);
    additionalCharges[index] = line;
    additionalCharges.refresh();
    syncProductsIfPossible();
    scheduleAutoSave();
    update();
  }

  void removeAdditionalCharge(int index) {
    if (index < 0 || index >= additionalCharges.length) return;
    additionalCharges.removeAt(index);
    syncProductsIfPossible();
    scheduleAutoSave();
    update();
  }

  void _hydrateSalesCart(SalesController sales) {
    sales.clearCartLines(deferDispose: false);
    for (final item in maintenanceProducts) {
      dynamic product;
      if (sales.products.isNotEmpty) {
        for (final p in sales.products) {
          if (p.id == item.productId.toString()) {
            product = p;
            break;
          }
        }
      }
      final stock = product != null
          ? (int.tryParse(product.stock.toString()) ?? 0)
          : 9999;
      sales.addCartLine(
        InstantSaleCartLine(
          productId: item.productId.toString(),
          productName: item.productName.isNotEmpty
              ? item.productName
              : (product?.nameAr?.toString() ?? '-'),
          imageUrl: item.imageUrl.isNotEmpty
              ? item.imageUrl
              : product?.preferredImageUrl?.toString() ?? '',
          stock: stock,
          sizeColorId: item.sizeColorId?.toString(),
          sizeId: item.sizeId?.toString(),
          initialQuantity: item.quantity.toString(),
          initialPrice: item.unitPrice.toString(),
        ),
      );
    }
    sales.bumpCartRevision();
  }

  void _importProductsFromSalesCart(SalesController sales) {
    maintenanceProducts.assignAll(
      sales.cartLines.where((line) => !line.isDisposed).map(
        (line) {
          final qty = int.tryParse(line.quantityText) ?? 1;
          final unit = SalesAmountFormat.parse(line.priceText);
          return MaintenanceProductModel(
            productId: int.parse(line.productId),
            productName: line.displayName,
            imageUrl: line.imageUrl,
            sizeId: line.sizeId != null ? int.tryParse(line.sizeId!) : null,
            sizeColorId: line.sizeColorId != null
                ? int.tryParse(line.sizeColorId!)
                : null,
            quantity: qty,
            unitPrice: unit,
            lineTotal: qty * unit,
          );
        },
      ),
    );
    syncProductsIfPossible();
    scheduleAutoSave();
  }

  Future<List<ShownBoxesModel>> loadPaymentBoxes() async {
    try {
      final boxes = await getShownBoxUsecase.call(screen: 0);
      paymentBoxes.assignAll(boxes);
      return boxes;
    } catch (_) {
      return [];
    }
  }

  void removeProduct(int index) {
    if (index < 0 || index >= maintenanceProducts.length) return;
    maintenanceProducts.removeAt(index);
    syncProductsIfPossible();
    scheduleAutoSave();
    update();
  }

  void updateProductLine(
    int index, {
    int? quantity,
    double? unitPrice,
  }) {
    if (index < 0 || index >= maintenanceProducts.length) return;
    maintenanceProducts[index] = maintenanceProducts[index].copyWith(
      quantity: quantity,
      unitPrice: unitPrice,
    );
    maintenanceProducts.refresh();
    syncProductsIfPossible();
    scheduleAutoSave();
    update();
  }

  Future<void> syncProductsIfPossible({String? editReason}) async {
    if (maintenanceId == null || maintenanceId!.isEmpty) return;
    if (isDelivered.value &&
        (editReason == null || editReason.trim().isEmpty)) {
      return;
    }

    await syncMaintenanceProductsUsecase.call(
      maintenanceId: maintenanceId!,
      products: maintenanceProducts.toList(),
      laborCost: laborCost,
      discount: discount,
      editReason: editReason,
      serviceLines: selectedMaintenanceServices
          .map((service) => {
                'service_id': service.id,
                'name': service.name,
                'price': maintenanceServicePrices[service.id] ?? service.price,
              })
          .toList(),
      additionalCharges: additionalCharges.toList(),
    );
  }

  Future<bool> deliverMaintenance({
    required double paymentAmount,
    int? paymentBoxId,
    List<Map<String, dynamic>> payments = const [],
    bool batchMode = false,
  }) async {
    if (maintenanceId == null || maintenanceId!.isEmpty) return false;

    final effectivePaid = payments.isNotEmpty
        ? payments.fold<double>(
            0,
            (sum, item) => sum + SalesAmountFormat.parse('${item['amount']}'),
          )
        : paymentAmount;

    if (effectivePaid > 0 && !isMaintenanceDailyBoxOpen) {
      await loadMaintenanceDailySession();
      if (!isMaintenanceDailyBoxOpen) {
        Get.snackbar(
          'error'.tr,
          'يجب فتح صندوق الصيانة اليومي قبل تسليم الصيانة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    }

    isLoading(true);
    update();

    final result = await deliverMaintenanceUsecase.call(
      maintenanceId: maintenanceId!,
      laborCost: laborCost,
      discount: discount,
      paymentAmount: payments.isEmpty ? paymentAmount : null,
      paymentBoxId: paymentBoxId,
      payments: payments,
    );

    var ok = false;
    result.fold(
      (failure) {
        if (!batchMode) {
          Get.snackbar(
            failure.data['message']?.toString() ?? 'error'.tr,
            '',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
      (success) async {
        ok = true;
        isDelivered(true);
        selectedStep(4);
        if (!batchMode) {
          getMaintenancesData();
          Get.back();
          Get.snackbar(
            'success'.tr,
            success['message']?.toString() ?? '',
            snackPosition: SnackPosition.BOTTOM,
          );
          if (maintenanceId != null &&
              maintenanceId!.isNotEmpty &&
              Get.context != null) {
            await openMaintenanceInvoice(
              context: Get.context!,
              maintenanceId: maintenanceId!,
            );
          }
        }
      },
    );

    isLoading(false);
    update();
    return ok;
  }

  Future<void> deliverSelectedMaintenances(BuildContext context) async {
    final ids = selectedMaintenanceIds.toList();
    if (ids.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('تسليم ${ids.length} طلبات صيانة'),
        content: const Text(
          'سيتم احتساب العربون والدفعات المثبتة لكل طلب، وأي مبلغ متبقٍ سيسجل ديناً على الزبون أو التاجر.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delivery_dining_outlined),
            label: const Text('تسليم المحدد'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await loadMaintenanceDailySession();
    if (!isMaintenanceDailyBoxOpen) {
      Get.snackbar(
        'تنبيه',
        'يجب فتح صندوق الصيانة اليومي قبل التسليم الجماعي',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    var delivered = 0;
    for (final id in ids) {
      await getMaintenancesDetails(maintenanceId: '$id');
      if (maintenanceId != '$id') continue;
      await syncProductsIfPossible();
      final ok = await deliverMaintenance(
        paymentAmount: 0,
        batchMode: true,
      );
      if (ok) delivered++;
    }
    toggleMaintenanceBulkMode(false);
    await getMaintenancesData();
    Get.snackbar(
      delivered == ids.length ? 'تم التسليم' : 'اكتمل التسليم جزئياً',
      'تم تسليم $delivered من أصل ${ids.length}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: delivered == ids.length ? Colors.green : Colors.orange,
      colorText: Colors.white,
    );
  }

  Future<bool> addMaintenancePayment({
    required double amount,
    String? note,
  }) async {
    if (maintenanceId == null || maintenanceId!.isEmpty) return false;
    if (!isMaintenanceDailyBoxOpen) {
      await loadMaintenanceDailySession();
      if (!isMaintenanceDailyBoxOpen) {
        Get.snackbar(
          'error'.tr,
          'يجب فتح صندوق الصيانة اليومي قبل إضافة العربون',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    }

    isLoading(true);
    update();
    final result = await addMaintenancePaymentUsecase.call(
      maintenanceId: maintenanceId!,
      amount: amount,
      note: note,
    );
    var ok = false;
    await result.fold(
      (failure) async {
        Get.snackbar(
          'error'.tr,
          failure.errMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
      (success) async {
        ok = true;
        final billing = success['billing'];
        if (billing is Map) {
          maintenancePaidAmount.value =
              SalesAmountFormat.parse('${billing['paid_amount']}');
          final payments = billing['payments'];
          maintenancePayments.assignAll(
            payments is List
                ? payments
                    .whereType<Map>()
                    .map((item) => Map<String, dynamic>.from(item))
                : const <Map<String, dynamic>>[],
          );
        }
        await loadMaintenanceDailySession();
        await getMaintenancesData();
        Get.snackbar(
          'success'.tr,
          success['message']?.toString() ?? 'تم تثبيت العربون',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
    isLoading(false);
    update();
    return ok;
  }

  Future<void> openActivityLog({
    required BuildContext context,
    required String maintenanceId,
  }) async {
    final result = await getMaintenanceActivityLogUsecase.call(
      maintenanceId: maintenanceId,
    );
    result.fold(
      (failure) => Get.snackbar(
        'error'.tr,
        failure.errMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      ),
      (logs) => showMaintenanceActivityLogSheet(context, logs),
    );
  }

  Future<void> openMaintenanceInvoice({
    required BuildContext context,
    required String maintenanceId,
  }) async {
    final result = await getMaintenanceInvoiceUsecase.call(
      maintenanceId: maintenanceId,
    );
    result.fold(
      (failure) => Get.snackbar(
        'error'.tr,
        failure.errMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      ),
      (invoice) => showMaintenanceInvoiceSheet(context, invoice),
    );
  }

  Future<bool> deleteMaintenance({
    required String maintenanceId,
  }) async {
    isLoading(true);
    update();

    final result = await deleteMaintenanceUsecase.call(
      maintenanceId: maintenanceId,
    );

    var deleted = false;
    await result.fold(
      (failure) async {
        Get.snackbar(
          'error'.tr,
          failure.errMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
      (message) async {
        deleted = true;
        await getMaintenancesData();
        Get.snackbar(
          'success'.tr,
          message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );

    isLoading(false);
    update();
    return deleted;
  }

  Future<void> getMaintenancesData() async {
    if (MaintenanceServes().maintenancesList.isEmpty) isLoading(true);
    update();

    final maintenancesData = await maintenanceUsecase.call(tab: 0);
    final maintenances = (maintenancesData['maintenance_details'] as List)
        .map((e) => MaintenanceDataModel.fromJson(e))
        .toList();
    MaintenanceServes().maintenancesList.assignAll(maintenances);
    MaintenanceServes().maintenancesTasks.value =
        _groupMaintenancesByDate(maintenances);

    final ongoingData = await maintenanceUsecase.call(tab: 1);
    final ongoing = (ongoingData['maintenance_details'] as List)
        .map((e) => MaintenanceDataModel.fromJson(e))
        .toList();
    MaintenanceServes().ongoingMaintenancesList.assignAll(ongoing);
    MaintenanceServes().ongoingMaintenancesTasks.value =
        _groupMaintenancesByDate(ongoing);

    final readyData = await maintenanceUsecase.call(tab: 2);
    final ready = (readyData['maintenance_details'] as List)
        .map((e) => MaintenanceDataModel.fromJson(e))
        .toList();
    MaintenanceServes().readyMaintenancesList.assignAll(ready);
    MaintenanceServes().readyMaintenancesTasks.value =
        _groupMaintenancesByDate(ready);

    final deliveredData = await maintenanceUsecase.call(tab: 3);
    final delivered = (deliveredData['maintenance_details'] as List)
        .map((e) => MaintenanceDataModel.fromJson(e))
        .toList();
    MaintenanceServes().deliveredMaintenancesList.assignAll(delivered);
    MaintenanceServes().deliveredMaintenancesTasks.value =
        _groupMaintenancesByDate(delivered);

    final archiveData = await maintenanceUsecase.call(tab: 4);
    final archive = (archiveData['maintenance_details'] as List)
        .map((e) => MaintenanceDataModel.fromJson(e))
        .toList();
    MaintenanceServes().archiveMaintenancesList.assignAll(archive);
    MaintenanceServes().archiveMaintenancesTasks.value =
        _groupMaintenancesByDate(archive);
    filterMaintenances();

    isLoading(false);
    update();
  }

  Future<void> getMaintenancesDetails({required String maintenanceId}) async {
    isEdit(true);
    isEditLoading(true);
    _isHydratingMaintenanceForm = true;
    update();

    try {
      final maintenancesData = await getMaintenancesDetailsUsecase.call(
        maintenanceId: maintenanceId,
      );
      final maintenances = maintenancesData['maintenance'];
      if (maintenances == null) {
        Get.back();
        Get.snackbar(
          'error'.tr,
          maintenancesData['message']?.toString() ?? 'tryAgain'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      this.maintenanceId = maintenances['id'].toString();
      final receiptDate = maintenances['receipt_date']?.toString() ?? '';
      final receiptTime = maintenances['receipt_time']?.toString() ?? '';
      final hasSchedule = receiptDate.isNotEmpty && receiptTime.isNotEmpty;
      showDeliverySchedule.value = hasSchedule;
      final parsedDate = DateTime.tryParse(receiptDate);
      if (parsedDate != null) {
        deliveryDate.value = parsedDate;
      } else {
        deliveryDate.value = DateTime.now();
      }

      final receiptDateTime =
          hasSchedule ? DateTime.tryParse('$receiptDate $receiptTime') : null;
      if (receiptDateTime != null) {
        deliveryTime.value = TimeOfDay.fromDateTime(receiptDateTime);
      } else {
        deliveryTime.value = TimeOfDay.now();
      }

      descriptionController.text =
          maintenances['description']?.toString() ?? '';

      final customer = maintenances['customer'];
      final seller = maintenances['seller'];
      final hasCustomer = customer is Map && customer.isNotEmpty;
      final hasSeller = seller is Map && seller.isNotEmpty;
      partnerIdController.text = hasCustomer
          ? customer['id'].toString()
          : hasSeller
              ? seller['id'].toString()
              : '';
      selectedSellers.value = hasSeller;

      final status = maintenances['status']?.toString();
      selectedStep.value = status == 'new'
          ? 1
          : status == 'ongoing'
              ? 2
              : status == 'ready'
                  ? 3
                  : 4;
      isDelivered.value = status == 'delivered';

      final billing = MaintenanceBillingModel.fromJson(
        maintenances['billing'] is Map
            ? Map<String, dynamic>.from(maintenances['billing'])
            : null,
      );
      maintenanceProducts.assignAll(billing.items);
      maintenancePaidAmount.value = billing.paidAmount;
      final rawPayments = maintenances['billing'] is Map
          ? (maintenances['billing']['payments'] as List?)
          : null;
      maintenancePayments.assignAll(
        (rawPayments ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item)),
      );
      laborCostController.text =
          billing.laborCost > 0 ? billing.laborCost.toString() : '';
      discountController.text =
          billing.discount > 0 ? billing.discount.toString() : '';
      await _hydrateSelectedServicesFromDescription();
      maintenanceServicePrices.clear();
      for (final line in billing.serviceLines) {
        final serviceId = int.tryParse('${line['service_id'] ?? ''}');
        if (serviceId != null) {
          maintenanceServicePrices[serviceId] =
              SalesAmountFormat.parse('${line['price'] ?? 0}');
        }
      }
      additionalCharges.assignAll(billing.additionalCharges);

      final files = maintenances['files'];
      if (files is List) {
        selectedMedia = List<File>.from(
          files.map((file) => File(ShowNetImage.getPhoto(file))),
        );
      } else {
        selectedMedia = [];
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'error'.tr,
        'tryAgain'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isHydratingMaintenanceForm = false;
      isEditLoading(false);
      update();
    }
  }

  Future<void> _hydrateSelectedServicesFromDescription() async {
    final description = descriptionController.text;
    if (description.trim().isEmpty) {
      selectedMaintenanceServices.clear();
      return;
    }

    try {
      final datasource = Get.find<MaintenanceImplement>().maintenanceDatasource;
      final services = await datasource.getMaintenanceServices(
        search: null,
        activeOnly: false,
      );
      selectedMaintenanceServices.assignAll(
        services.where((service) => description.contains(service.name)),
      );
    } catch (_) {
      selectedMaintenanceServices.clear();
    }
  }

  void clearControllers() {
    isEdit(false);
    isDelivered(false);
    isAutoSaving(false);
    hasAutoSaveError(false);
    _autoSaveDebounce?.cancel();
    _autoSaveQueued = false;
    _queuedAutoSaveStep = null;
    maintenanceId = null;
    partnerIdController.clear();
    descriptionController.clear();
    laborCostController.clear();
    discountController.clear();
    maintenanceProducts.clear();
    maintenancePaidAmount.value = 0;
    maintenancePayments.clear();
    selectedMaintenanceServices.clear();
    maintenanceServicePrices.clear();
    additionalCharges.clear();
    deliveryDate.value = DateTime.now();
    deliveryTime.value = TimeOfDay.now();
    showDeliverySchedule(false);
    selectedMedia = [];
    selectedSellers(false);
    selectedStep(1);
    update();
  }

  Future<void> startNewMaintenanceFlow(BuildContext context) async {
    clearControllers();
    final raw = GetStorage().read(_localDraftKey);
    if (raw is String && raw.trim().isNotEmpty) {
      final restore = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('يوجد طلب صيانة سابق'),
          content: const Text('هل تريد استرجاع الطلب السابق غير المحفوظ؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('بدء طلب جديد'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('استرجاع'),
            ),
          ],
        ),
      );
      if (restore == true) {
        _restoreLocalMaintenanceDraft(raw);
      } else {
        await clearLocalMaintenanceDraft();
      }
    }
    if (context.mounted) {
      await Get.toNamed(AppRoutes.NEWMAINTENANCESCREEN);
    }
  }

  void _restoreLocalMaintenanceDraft(String raw) {
    _restoringLocalDraft = true;
    try {
      final draft = jsonDecode(raw);
      if (draft is! Map) return;
      partnerIdController.text = '${draft['partner_id'] ?? ''}';
      selectedSellers.value = draft['is_seller'] == true;
      descriptionController.text = '${draft['description'] ?? ''}';
      laborCostController.text = '${draft['labor_cost'] ?? ''}';
      discountController.text = '${draft['discount'] ?? ''}';
      selectedStep.value = int.tryParse('${draft['selected_step']}') ?? 1;
      showDeliverySchedule.value = draft['show_delivery_schedule'] == true;
      deliveryDate.value =
          DateTime.tryParse('${draft['delivery_date']}') ?? DateTime.now();
      deliveryTime.value = TimeOfDay(
        hour: int.tryParse('${draft['delivery_hour']}') ?? 0,
        minute: int.tryParse('${draft['delivery_minute']}') ?? 0,
      );
      maintenanceProducts.assignAll(
        ((draft['products'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => MaintenanceProductModel.fromJson(
                  Map<String, dynamic>.from(item),
                )),
      );
      selectedMaintenanceServices.assignAll(
        ((draft['services'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => MaintenanceServiceModel.fromJson(
                  Map<String, dynamic>.from(item),
                )),
      );
      maintenanceServicePrices.clear();
      final prices = draft['service_prices'];
      if (prices is Map) {
        for (final entry in prices.entries) {
          final id = int.tryParse('${entry.key}');
          final price = double.tryParse('${entry.value}');
          if (id != null && price != null) {
            maintenanceServicePrices[id] = price;
          }
        }
      }
      additionalCharges.assignAll(
        ((draft['additional_charges'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item)),
      );
      selectedMedia = ((draft['selected_media'] as List?) ?? const [])
          .map((path) => File('$path'))
          .where((file) => file.existsSync())
          .toList();
      update();
    } finally {
      _restoringLocalDraft = false;
    }
  }

  final RxList<SellerModel> allCustomersList = <SellerModel>[].obs;
  final RxList<SellerModel> allSellersList = <SellerModel>[].obs;

  void getAllCustomersAndSellers() async {
    final resultCustomers = await allCustomersSellersUsecase.call(
        endPoint: EndPoints.all_customers);
    allCustomersList.assignAll(resultCustomers);
    final resultSellers =
        await allCustomersSellersUsecase.call(endPoint: EndPoints.all_sellers);
    allSellersList.assignAll(resultSellers);
  }

  Future<bool> createMaintenance({
    required int step,
    String? maintenanceId,
    bool isSave = false,
    bool silent = false,
    String? editReason,
  }) async {
    if (!formKey.currentState!.validate()) return false;

    final deliveredEditReason =
        editReason ?? await _resolveDeliveredEditReason(silent);
    if (isDelivered.value && deliveredEditReason == null) return false;

    if (!silent) {
      isLoading(true);
      update();
    }

    try {
      final status = step == 1
          ? 'new'
          : step == 2
              ? 'ongoing'
              : step == 3
                  ? 'ready'
                  : 'delivered';

      final result = await creatMaintenanceUsecase.call(
        maintenanceId: this.maintenanceId ?? maintenanceId,
        customerId: !selectedSellers.value ? partnerIdController.text : '',
        sellerId: selectedSellers.value ? partnerIdController.text : '',
        description: descriptionController.text,
        receipDate: showDeliverySchedule.value
            ? deliveryDate.value.toIso8601String().split('T').first
            : '',
        receiptTime: showDeliverySchedule.value
            ? '${deliveryTime.value.hour.toString().padLeft(2, '0')}:${deliveryTime.value.minute.toString().padLeft(2, '0')}'
            : '',
        files: selectedMedia,
        status: status,
        laborCost: laborCost,
        discount: discount,
        editReason: deliveredEditReason,
      );

      await result.fold(
        (failure) async {
          final errors = failure.data['errors'];
          String errorMessage = '';
          if (errors is Map) {
            errorMessage = errors.entries
                .map((e) => "${e.key}: ${(e.value as List).join(', ')}")
                .join("\n");
          } else {
            errorMessage = errors?.toString() ?? '';
          }
          if (!silent) {
            Get.snackbar(
              failure.data['message'] ?? 'error'.tr,
              errorMessage,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
        (success) async {
          final newId = success['maintenance_id'];
          if (newId != null && newId.isNotEmpty) {
            this.maintenanceId = newId;
            isEdit(true);
            await clearLocalMaintenanceDraft();
          }
          await syncProductsIfPossible(editReason: deliveredEditReason);
          if (!silent) {
            getMaintenancesData();
          }
          if (isSave) Get.back();
          if (!silent) {
            Get.snackbar(
              'success'.tr,
              success['message'] ?? '',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
      );
      return result.isRight();
    } catch (e) {
      if (!silent) {
        Get.snackbar(
          'error'.tr,
          e.toString(),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return false;
    } finally {
      if (!silent) {
        isLoading(false);
        update();
      } else {
        update();
      }
    }
  }

  Future<String?> _resolveDeliveredEditReason(bool silent) async {
    if (!isDelivered.value) return null;
    if (silent) return null;

    final controller = TextEditingController();
    final reason = await Get.dialog<String>(
      AlertDialog(
        title: const Text('سبب تعديل الصيانة المسلّمة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'سبب التعديل',
            hintText: 'مثال: تصحيح تكلفة قطعة / تعديل موعد / ملاحظة',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<String>(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) {
                Get.snackbar('error'.tr, 'يجب إدخال سبب التعديل');
                return;
              }
              Get.back<String>(result: value);
            },
            child: Text('save'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    controller.dispose();
    return reason?.trim().isEmpty == true ? null : reason;
  }

  final Map<String, List<MaintenanceDataModel>> maintenancesSearch = {};
  final Map<String, List<MaintenanceDataModel>> ongoingMaintenancesSearch = {};
  final Map<String, List<MaintenanceDataModel>> readyMaintenancesSearch = {};
  final Map<String, List<MaintenanceDataModel>> deliveredMaintenancesSearch =
      {};
  final Map<String, List<MaintenanceDataModel>> archiveMaintenancesSearch = {};

  List<int> get tabCounts => [
        _groupedCount(maintenancesSearch),
        _groupedCount(ongoingMaintenancesSearch),
        _groupedCount(readyMaintenancesSearch),
        _groupedCount(deliveredMaintenancesSearch),
        _groupedCount(archiveMaintenancesSearch),
      ];

  int get newCount => _groupedCount(maintenancesSearch);
  int get ongoingCount => _groupedCount(ongoingMaintenancesSearch);
  int get readyCount => _groupedCount(readyMaintenancesSearch);
  int get deliveredCount => _groupedCount(deliveredMaintenancesSearch);
  int get archivedCount => _groupedCount(archiveMaintenancesSearch);
  int get totalFilteredCount => newCount + ongoingCount + readyCount;

  int get visibleFilteredCount {
    switch (maintenanceViewFilter.value) {
      case maintenanceFilterNew:
        return newCount;
      case maintenanceFilterOngoing:
        return ongoingCount;
      case maintenanceFilterReady:
        return readyCount;
      case maintenanceFilterDelivered:
        return deliveredCount;
      case maintenanceFilterArchived:
        return archivedCount;
      default:
        return totalFilteredCount;
    }
  }

  bool get showNewMaintenanceSection =>
      maintenanceViewFilter.value == maintenanceFilterAll ||
      maintenanceViewFilter.value == maintenanceFilterNew;

  bool get showOngoingMaintenanceSection =>
      maintenanceViewFilter.value == maintenanceFilterAll ||
      maintenanceViewFilter.value == maintenanceFilterOngoing;

  bool get showReadyMaintenanceSection =>
      maintenanceViewFilter.value == maintenanceFilterAll ||
      maintenanceViewFilter.value == maintenanceFilterReady;

  bool get showDeliveredMaintenanceSection =>
      maintenanceViewFilter.value == maintenanceFilterDelivered;

  bool get showArchivedMaintenanceSection =>
      maintenanceViewFilter.value == maintenanceFilterArchived;

  int _groupedCount(Map<String, List<MaintenanceDataModel>> grouped) {
    return grouped.values.fold(0, (sum, list) => sum + list.length);
  }

  Map<String, List<MaintenanceDataModel>> _groupMaintenancesByDate(
      List<MaintenanceDataModel> list) {
    final Map<String, List<MaintenanceDataModel>> grouped = {};
    for (var task in list) {
      final receiptDateObj =
          DateTime.tryParse(task.receiptDate) ?? DateTime.now();
      final dayName =
          DateFormat.EEEE(Get.locale!.languageCode).format(receiptDateObj);
      final dateKey =
          "$dayName ${receiptDateObj.year}-${receiptDateObj.month}-${receiptDateObj.day}";
      grouped.putIfAbsent(dateKey, () => []);
      if (!grouped[dateKey]!.any((a) => a.id == task.id)) {
        grouped[dateKey]!.add(task);
      }
    }
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a.value.first.receiptDate) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(b.value.first.receiptDate) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });
    return Map.fromEntries(sortedEntries);
  }

  void toggleSearch() {
    isSearchVisible.value = !isSearchVisible.value;
    if (!isSearchVisible.value) {
      searchController.clear();
      filterMaintenances();
    }
    update(['maintenanceSearchBar']);
  }

  void closeSearch() {
    isSearchVisible.value = false;
    searchController.clear();
    filterMaintenances();
    update(['maintenanceSearchBar']);
  }

  void filterMaintenances() {
    final query = searchController.text.trim().toLowerCase();

    List<MaintenanceDataModel> applyFilter(
      List<MaintenanceDataModel> sourceList,
    ) {
      if (query.isEmpty) return List<MaintenanceDataModel>.from(sourceList);
      return sourceList.where((item) {
        final fields = [
          item.id.toString(),
          item.customerName,
          item.sellerName ?? '',
          item.contactPhone ?? '',
          item.status,
        ].join(' ').toLowerCase();
        return fields.contains(query);
      }).toList();
    }

    maintenancesSearch
      ..clear()
      ..addAll(_groupMaintenancesByDate(
          applyFilter(MaintenanceServes().maintenancesList)));
    ongoingMaintenancesSearch
      ..clear()
      ..addAll(_groupMaintenancesByDate(
          applyFilter(MaintenanceServes().ongoingMaintenancesList)));
    readyMaintenancesSearch
      ..clear()
      ..addAll(_groupMaintenancesByDate(
          applyFilter(MaintenanceServes().readyMaintenancesList)));
    deliveredMaintenancesSearch
      ..clear()
      ..addAll(_groupMaintenancesByDate(
          applyFilter(MaintenanceServes().deliveredMaintenancesList)));
    archiveMaintenancesSearch
      ..clear()
      ..addAll(_groupMaintenancesByDate(
          applyFilter(MaintenanceServes().archiveMaintenancesList)));
    update();
  }

  @override
  void onInit() {
    super.onInit();
    loadMaintenanceDailySession();
    getMaintenancesData();
    getAllCustomersAndSellers();
    maintenancesSearch.assignAll(MaintenanceServes().maintenancesTasks);
    ongoingMaintenancesSearch
        .assignAll(MaintenanceServes().ongoingMaintenancesTasks);
    readyMaintenancesSearch
        .assignAll(MaintenanceServes().readyMaintenancesTasks);
    deliveredMaintenancesSearch
        .assignAll(MaintenanceServes().deliveredMaintenancesTasks);
    archiveMaintenancesSearch
        .assignAll(MaintenanceServes().archiveMaintenancesTasks);
  }
}

Color getStatusColor({
  required String receiptDate,
  required String receiptTime,
  required int currentTab,
}) {
  if (currentTab == 3) return AppColors.customGreen1;
  if (currentTab == 4) return AppColors.operationalPurple;
  final DateTime receiptDateTime = DateTime.parse("$receiptDate $receiptTime");
  final Duration diff = receiptDateTime.difference(DateTime.now());
  if (diff.inHours > 1) return AppColors.customGreen1;
  if (diff.inMinutes > 0) return AppColors.customOrange3;
  return AppColors.redColor;
}

String getStatusText({
  required String receiptDate,
  required String receiptTime,
}) {
  final DateTime receiptDateTime = DateTime.parse("$receiptDate $receiptTime");
  final Duration diff = receiptDateTime.difference(DateTime.now());
  final int hours = diff.inHours;
  if (hours < 0 && hours <= -100) return 'late'.tr;
  if (hours > 0) return "$hours ${hours > 1 ? 'hour'.tr : 'hours'.tr}";
  if (hours < 0) return "$hours ${hours > 10 ? 'hour'.tr : 'hours'.tr}";
  return hours == 0 ? 'now'.tr : '';
}
