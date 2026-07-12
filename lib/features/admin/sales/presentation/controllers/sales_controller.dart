import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/features/admin/sales/data/models/product_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/profit_sale_model.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/add_instant_sales_usecase.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/get_instant_sales_usecase.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/helpers/phone_format_helper.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../../general_data_list/data/datasources/general_data_list_datasource.dart';
import '../../../general_data_list/domain/entity/add_person_entity.dart';
import '../../../stock/data/models/offer_package_model.dart';
import '../../../stock/data/datasources/stock_datasource.dart';
import '../../../stock/data/models/store_section_model.dart';
import '../../../stock/domain/product_location_utils.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../stock/presentation/controllers/offer_packages_controller.dart';
import '../../../sales_orders/data/models/sales_order_model.dart';
import '../../data/datasources/sales_datasources.dart';
import '../../../checks/data/models/check_model.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../data/models/customer_product_price_history_model.dart';
import '../../data/models/daily_session_model.dart';
import '../../data/models/instant_sales_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/ongoing_project_model.dart';
import '../../data/models/suspended_instant_sale_model.dart';
import '../../data/repositories/sales_implement.dart';
import '../../domain/usecases/add_profit_sale.dart';
import '../../domain/usecases/get_customer_product_price_history_usecase.dart';
import '../../domain/usecases/get_all_products_usecase.dart';
import '../../domain/usecases/get_profit_sales_usecase.dart';
import '../../domain/usecases/update_product_retail_price_usecase.dart';
import '../../domain/usecases/invoice_model_usecase.dart';
import '../models/instant_sale_cart_line.dart';
import '../utils/box_log_note_format.dart';
import '../utils/instant_sale_display.dart';
import '../utils/sales_amount_format.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../payment_method/presentation/controllers/payment_controller.dart';
import '../widgets/instant_sale_action_dialog.dart';
import '../widgets/instant_sale_actions_sheet.dart';
import '../widgets/new_instant_sale/sales_variant_picker_sheet.dart';
import '../widgets/new_instant_sale/instant_sale_price_dialog.dart';
import '../widgets/new_instant_sale/instant_sale_quantity_dialog.dart';
import '../../../sales_orders/presentation/controllers/sales_orders_controller.dart';
import '../../../sales_orders/presentation/utils/sales_order_stock_context.dart';
import 'sales_service.dart';

/// GetX tag for payment fields on the new instant sale screen.
const String kInstantSalePaymentTag = 'instant_sale_payment';
const String kSalesOrderPaymentTag = 'sales_order_payment';
const String kProfitSalePaymentTag = 'profit_sale_payment';
const String kInstantSaleLocalDraftKey = 'instant_sale_local_draft_v1';

void _instantSaleDebug(String message, [Object? details]) {
  assert(() {
    debugPrint(
      details == null
          ? '[InstantSaleDebug] $message'
          : '[InstantSaleDebug] $message | $details',
    );
    return true;
  }());
}

class SalesController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final AddProfitSaleUsecase addProfitSaleUsecase;
  final GetProfitSalesUsecase getProfitSalesUsecase;
  final GetInstantSalesUsecase getInstantSalesUsecase;
  final GetAllProductsUsecase getAllProductsUsecase;
  final UpdateProductRetailPriceUsecase updateProductRetailPriceUsecase;
  final AddInstantSalesUsecase addInstantSalesUsecase;
  final InvoiceModelUsecase invoiceModelUsecase;
  final GetCustomerProductPriceHistoryUsecase
      getCustomerProductPriceHistoryUsecase;
  final AllCustomersSellersUsecase allCustomersSellersUsecase;
  final SalesService salesService;

  SalesController({
    required this.salesService,
    required this.addProfitSaleUsecase,
    required this.getProfitSalesUsecase,
    required this.getInstantSalesUsecase,
    required this.getAllProductsUsecase,
    required this.updateProductRetailPriceUsecase,
    required this.addInstantSalesUsecase,
    required this.invoiceModelUsecase,
    required this.getCustomerProductPriceHistoryUsecase,
    required this.allCustomersSellersUsecase,
  });

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  GlobalKey<FormState> instantSaleFormKey = GlobalKey<FormState>();

  void _renewInstantSaleFormKey() {
    instantSaleFormKey = GlobalKey<FormState>();
  }

  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  final TextEditingController discountController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController totalCostController = TextEditingController();
  final Rx<XFile?> profitSaleImage = Rx<XFile?>(null);
  final Rx<XFile?> profitSaleVideo = Rx<XFile?>(null);
  final RxList<InstantSaleNoteLine> instantSaleNotes =
      <InstantSaleNoteLine>[].obs;

  // filters
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  final TextEditingController instantSalesSearchController =
      TextEditingController();
  final instantSalesSearchQuery = ''.obs;
  final instantSalesSortDescending = true.obs;
  Timer? _instantSalesSearchDebounce;
  final TextEditingController profitSalesSearchController =
      TextEditingController();
  final profitSalesSearchQuery = ''.obs;
  final profitSalesSortDescending = true.obs;
  Timer? _profitSalesSearchDebounce;

  String get instantSalesSortDirection =>
      instantSalesSortDescending.value ? 'desc' : 'asc';

  void onInstantSalesSearchChanged(String value) {
    instantSalesSearchQuery.value = value;
    _instantSalesSearchDebounce?.cancel();
    _instantSalesSearchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => getInstantSales(loding: true, clearCache: true),
    );
  }

  void onInstantSalesSearchSubmitted(String value) {
    _instantSalesSearchDebounce?.cancel();
    instantSalesSearchQuery.value = value;
    getInstantSales(loding: true, clearCache: true);
  }

  void clearInstantSalesSearch() {
    instantSalesSearchController.clear();
    instantSalesSearchQuery.value = '';
    getInstantSales(loding: true, clearCache: true);
  }

  void toggleInstantSalesSort() {
    instantSalesSortDescending.value = !instantSalesSortDescending.value;
    getInstantSales(loding: true, clearCache: true);
  }

  void onProfitSalesSearchChanged(String value) {
    profitSalesSearchQuery.value = value;
    _profitSalesSearchDebounce?.cancel();
    _profitSalesSearchDebounce = Timer(
      const Duration(milliseconds: 250),
      notifySalesListChanged,
    );
  }

  void onProfitSalesSearchSubmitted(String value) {
    _profitSalesSearchDebounce?.cancel();
    profitSalesSearchQuery.value = value;
    notifySalesListChanged();
  }

  void clearProfitSalesSearch() {
    profitSalesSearchController.clear();
    profitSalesSearchQuery.value = '';
    notifySalesListChanged();
  }

  void toggleProfitSalesSort() {
    profitSalesSortDescending.value = !profitSalesSortDescending.value;
    notifySalesListChanged();
  }

  /// Date groups for instant sales tab, newest dates first when sort is desc.
  List<MapEntry<String, List<InstantSalesModel>>>
      get orderedInstantSalesGroups {
    final map = salesService.filterInstantSalesTasks;
    final entries = map.entries.toList();

    int compareDateKeys(String a, String b) {
      final da = _parseDateGroupKey(a);
      final db = _parseDateGroupKey(b);
      if (da == null || db == null) {
        return instantSalesSortDescending.value
            ? b.compareTo(a)
            : a.compareTo(b);
      }
      return instantSalesSortDescending.value
          ? db.compareTo(da)
          : da.compareTo(db);
    }

    entries.sort((a, b) => compareDateKeys(a.key, b.key));

    for (final entry in entries) {
      entry.value.sort((a, b) {
        final aTime = a.createdAt ?? a.date;
        final bTime = b.createdAt ?? b.date;
        final cmp = bTime.compareTo(aTime);
        return instantSalesSortDescending.value ? cmp : -cmp;
      });
    }

    return entries;
  }

  DateTime? _parseDateGroupKey(String key) => parseInstantSaleDateGroupKey(key);

  void _groupInstantSalesIntoMaps(List<InstantSalesModel> sales) {
    salesService.instantSalesTasks.clear();
    for (final instantSale in sales) {
      final dateKey = instantSaleDateGroupKey(instantSale);
      salesService.instantSalesTasks
          .putIfAbsent(dateKey, () => [])
          .add(instantSale);
    }
    _syncFilteredInstantSales();
  }

  void _syncFilteredInstantSales() {
    final from = DateTime.tryParse(fromDateController.text);
    final to = DateTime.tryParse(toDateController.text);
    if (from == null && to == null) {
      salesService.filterInstantSalesTasks
          .assignAll(salesService.instantSalesTasks);
      return;
    }
    final filtered = Map<String, List<InstantSalesModel>>.fromEntries(
      salesService.instantSalesTasks.entries.map((entry) {
        final list = entry.value.where((task) {
          final d = task.date;
          if (from != null && to == null) {
            return d.isAtSameMomentAs(from) || d.isAfter(from);
          }
          if (to != null && from == null) {
            return d.isAtSameMomentAs(to) || d.isBefore(to);
          }
          if (from != null && to != null) {
            final okStart = d.isAtSameMomentAs(from) || d.isAfter(from);
            final okEnd = d.isAtSameMomentAs(to) || d.isBefore(to);
            return okStart && okEnd;
          }
          return true;
        }).toList();
        return MapEntry(entry.key, list);
      }).where((e) => e.value.isNotEmpty),
    );
    salesService.filterInstantSalesTasks.assignAll(filtered);
  }

  void _syncFilteredProfitSales() {
    final from = DateTime.tryParse(fromDateController.text);
    final to = DateTime.tryParse(toDateController.text);
    final query = profitSalesSearchQuery.value.trim().toLowerCase();

    final entries = salesService.profitSalesTasks.entries
        .map((entry) {
          final list = entry.value.where((task) {
            final start = task.createdAt;
            final end = task.updatedAt;
            if (from != null && to == null) {
              if (!(start.isAtSameMomentAs(from) || start.isAfter(from))) {
                return false;
              }
            }
            if (to != null && from == null) {
              if (!(end.isAtSameMomentAs(to) || end.isBefore(to))) {
                return false;
              }
            }
            if (from != null && to != null) {
              final okStart =
                  start.isAtSameMomentAs(from) || start.isAfter(from);
              final okEnd = end.isAtSameMomentAs(to) || end.isBefore(to);
              if (!(okStart && okEnd)) {
                return false;
              }
            }
            if (query.isNotEmpty) {
              final haystack = [
                task.id.toString(),
                task.notes,
                task.partnerDisplay,
                task.paymentDisplay,
                task.paymentBoxName ?? '',
                task.paymentBoxValue ?? '',
                task.totalCost,
                task.buyerType ?? '',
              ].join(' ').toLowerCase();
              return haystack.contains(query);
            }
            return true;
          }).toList();

          list.sort((a, b) {
            final cmp = b.createdAt.compareTo(a.createdAt);
            return profitSalesSortDescending.value ? cmp : -cmp;
          });

          return MapEntry(entry.key, list);
        })
        .where((e) => e.value.isNotEmpty)
        .toList();

    entries.sort((a, b) {
      final da = _parseDateGroupKey(a.key);
      final db = _parseDateGroupKey(b.key);
      if (da == null || db == null) {
        return profitSalesSortDescending.value
            ? b.key.compareTo(a.key)
            : a.key.compareTo(b.key);
      }
      return profitSalesSortDescending.value
          ? db.compareTo(da)
          : da.compareTo(db);
    });

    final filtered = Map<String, List<ProfitSale>>.fromEntries(entries);
    salesService.filterProfitSalesTasks.assignAll(filtered);
  }

  void notifySalesListChanged() {
    _syncFilteredInstantSales();
    _syncFilteredProfitSales();
    salesListRevision.value++;
  }

  final currentTab = 0.obs;

  final Rxn<DailySessionPayload> dailySessionPayload =
      Rxn<DailySessionPayload>();
  final isDailySessionLoading = false.obs;

  /// Bumped when sales lists change so [Obx] on [SalesScreen] rebuilds.
  final salesListRevision = 0.obs;

  List<String> tabs = ['spotSale', 'cashProfit', 'salesOrders'];

  /// 0 = all, 1 = package only, 2 = mixed, 3 = regular products.
  final instantSalesPackageFilter = 0.obs;

  final targets = <Map<String, dynamic>>[].obs;

  final isLoading = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
  }

  bool get canCreateSales => dailySessionPayload.value?.allowsSales ?? false;

  Future<void> loadDailySession() async {
    isDailySessionLoading(true);
    try {
      final ds = Get.find<SalesDatasource>();
      dailySessionPayload.value = await ds.getDailySessionCurrent();
    } catch (_) {
      dailySessionPayload.value = null;
    } finally {
      isDailySessionLoading(false);
    }
  }

  bool get hasInstantSalesData => salesService.instantSalesTasks.isNotEmpty;

  bool get hasProfitSalesData => salesService.filterProfitSalesTasks.isNotEmpty;

  void applyDailyBoxToPayment(
    PaymentController payment, {
    String currency = 'شيكل',
  }) {
    final row = dailySessionPayload.value?.rowForCurrency(currency);
    if (row == null) return;
    payment.applyDailySalesBox(
      boxId: row.dailyBoxId,
      boxName: row.dailyBoxName,
      currency: row.currency,
    );
  }

  List<ShownBoxesModel> get dailyBoxesForProfitPicker {
    final payload = dailySessionPayload.value;
    if (payload == null) return [];
    return payload.currencies
        .map(
          (row) => ShownBoxesModel(
            boxId: row.dailyBoxId,
            boxName: row.dailyBoxName,
            totalBalance: row.boxBalance,
            isShown: false,
            currency: row.currency,
            type: 'daily_sales',
          ),
        )
        .toList();
  }

  bool showSalesBlockedMessage() {
    final payload = dailySessionPayload.value;
    if (payload == null || payload.allowsSales) return false;

    final message = payload.isBlockingPreviousDay
        ? 'salesDailyPreviousDayOpen'.tr
        : payload.blockedByOtherSession
            ? 'salesDailyDrawerOpenByOther'.trParams({
                'employee': payload.blockedByEmployeeName ?? '',
              })
            : payload.needsManualOpen
                ? 'salesDailyNoSessionOpen'.tr
                : payload.isClosingRequested
                    ? 'salesDailyClosingPending'.tr
                    : payload.isReopenPending
                        ? 'salesDailyReopenPending'.tr
                        : 'salesDailyDayClosed'.tr;
    Get.snackbar('error'.tr, message, backgroundColor: Colors.red);
    return true;
  }

  Future<bool> confirmPreviousDaySaleIfNeeded() async {
    await loadDailySession();
    final payload = dailySessionPayload.value;

    if (payload == null || !payload.allowsSales) {
      showSalesBlockedMessage();
      return false;
    }

    if (!payload.shouldWarnPreviousDaySale) {
      return true;
    }

    final dialogContext = Get.overlayContext ?? Get.context;
    if (dialogContext == null) {
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Text('salesDailyPreviousDaySaleWarningTitle'.tr),
        content: Text(
          'salesDailyPreviousDaySaleWarningBody'.trParams({
            'date': payload.previousDayBusinessDate ?? '',
            'employee': payload.previousDayOwnerName ?? '',
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('continue'.tr),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<bool> ensureInstantSaleCanBeFinalized() async {
    await loadDailySession();
    final payload = dailySessionPayload.value;

    if (payload != null && payload.allowsSales) {
      if (!payload.shouldWarnPreviousDaySale) {
        return true;
      }
      final dialogContext = Get.overlayContext ?? Get.context;
      if (dialogContext == null) return false;
      final confirmed = await showDialog<bool>(
        context: dialogContext,
        builder: (ctx) => AlertDialog(
          title: Text('salesDailyPreviousDaySaleWarningTitle'.tr),
          content: Text(
            'salesDailyPreviousDaySaleWarningBody'.trParams({
              'date': payload.previousDayBusinessDate ?? '',
              'employee': payload.previousDayOwnerName ?? '',
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('continue'.tr),
            ),
          ],
        ),
      );
      return confirmed == true;
    }

    final suspended =
        await _saveCurrentInstantSaleAsHiddenSuspended(currentStep: 'checkout');
    if (!suspended) {
      return false;
    }
    await _showSuspendedBecauseNoDrawerDialog();
    return false;
  }

  Future<bool> _saveCurrentInstantSaleAsHiddenSuspended({
    required String currentStep,
  }) async {
    try {
      final result = await Get.find<SalesDatasource>().suspendInstantSale(
        currentStep: currentStep,
        payload: buildInstantSaleSuspendPayload(),
        suspendedInstantSaleId: activeSuspendedSaleId.value,
      );

      if (result['status'] == 'success') {
        final raw = result['suspended_instant_sale'];
        if (raw is Map) {
          final id = int.tryParse('${raw['id']}');
          if (id != null) {
            activeSuspendedSaleId.value = id;
            _activeSuspendedSaleIsAuto = true;
          }
        }
        final count = int.tryParse('${result['suspended_count']}');
        if (count != null) {
          suspendedInvoicesCount.value = count;
        }
        return true;
      }

      Get.snackbar(
        'error'.tr,
        result['message']?.toString() ?? 'Unknown error',
        backgroundColor: Colors.red,
      );
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(), backgroundColor: Colors.red);
      return false;
    }
  }

  Future<void> _showSuspendedBecauseNoDrawerDialog() async {
    final dialogContext = Get.overlayContext ?? Get.context;
    if (dialogContext == null) return;

    final openDrawer = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Text('salesDailyInvoiceSuspendedNoDrawerTitle'.tr),
        content: Text('salesDailyInvoiceSuspendedNoDrawerBody'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('salesDailyOpenDrawer'.tr),
          ),
        ],
      ),
    );

    if (openDrawer != true) return;

    try {
      await requestDailyOpen();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(), backgroundColor: Colors.red);
    }
  }

  Future<void> requestDailyOpen({
    List<Map<String, dynamic>> openingCounts = const [],
    bool confirmOpeningVariance = false,
  }) async {
    final ds = Get.find<SalesDatasource>();
    final message = await ds.openDailySession(
      openingCounts: openingCounts,
      confirmOpeningVariance: confirmOpeningVariance,
    );
    await loadDailySession();
    final overlayContext = Get.overlayContext ?? Get.context;
    if (overlayContext != null) {
      Helpers.showCustomDialogSuccess(
        context: overlayContext,
        title: 'success'.tr,
        message: message,
        autoCloseAfter: const Duration(seconds: 2),
      );
    }
  }

  Future<void> requestDailyReopen({required String reason}) async {
    final ds = Get.find<SalesDatasource>();
    final message = await ds.requestDailyReopen(reason: reason);
    await loadDailySession();
    final overlayContext = Get.overlayContext ?? Get.context;
    if (overlayContext != null) {
      Helpers.showCustomDialogSuccess(
        context: overlayContext,
        title: 'success'.tr,
        message: message,
        autoCloseAfter: const Duration(seconds: 2),
      );
    }
  }

  Future<String> submitDailyClosing({
    required List<Map<String, dynamic>> cashCounts,
    String? lateCloseReason,
    int? sessionId,
    List<Map<String, dynamic>>? transfers,
    String? reviewNotes,
  }) async {
    final ds = Get.find<SalesDatasource>();
    final message = await ds.requestDailyClosing(
      cashCounts: cashCounts,
      lateCloseReason: lateCloseReason,
      sessionId: sessionId,
      transfers: transfers,
      reviewNotes: reviewNotes,
    );
    await loadDailySession();
    return message;
  }

  Future<String> directCloseDailySession({
    required List<Map<String, dynamic>> cashCounts,
    required int sessionId,
    required List<Map<String, dynamic>> transfers,
    String? reviewNotes,
  }) async {
    final ds = Get.find<SalesDatasource>();
    final message = await ds.directCloseDailySession(
      cashCounts: cashCounts,
      sessionId: sessionId,
      transfers: transfers,
      reviewNotes: reviewNotes,
    );
    await loadDailySession();
    return message;
  }

  Future<void> requestSaleCancellation({
    required String saleType,
    required String saleId,
    required String reason,
  }) async {
    final ds = Get.find<SalesDatasource>();
    await ds.requestSalesCancellation(
      saleType: saleType,
      saleId: saleId,
      reason: reason,
    );
    Helpers.showCustomDialogSuccess(
      context: Get.context!,
      title: 'success'.tr,
      message: 'salesDailyCancelRequested'.tr,
    );
  }

  void setInstantSalesPackageFilter(int mode) {
    if (instantSalesPackageFilter.value == mode) return;
    instantSalesPackageFilter.value = mode;
    notifySalesListChanged();
  }

  /// Instant sales grouped by date, optionally filtered by package presence.
  List<MapEntry<String, List<InstantSalesModel>>>
      get orderedInstantSalesGroupsFiltered {
    final mode = instantSalesPackageFilter.value;
    return orderedInstantSalesGroups
        .map(
          (entry) => MapEntry(
            entry.key,
            entry.value.where((sale) {
              if (mode == 0) return true;
              final kind = sale.compositionKind;
              if (mode == 1) return kind == 'package';
              if (mode == 2) return kind == 'mixed';
              return kind == 'product';
            }).toList(),
          ),
        )
        .where((entry) => entry.value.isNotEmpty)
        .toList();
  }

  final items = <ItemModel>[ItemModel()].obs;
  final RxList<InstantSaleCartLine> cartLines = <InstantSaleCartLine>[].obs;
  final RxInt cartRevision = 0.obs;
  final RxString instantSaleProductSearch = ''.obs;
  final RxBool productsLoading = false.obs;
  final RxBool instantSalePickerSearchLoading = false.obs;
  Timer? _instantSalePickerSearchDebounce;
  int _productsFetchSerial = 0;
  final RxInt productsListVersion = 0.obs;

  /// عرض المحجوز على بطاقات المنتج (طلبية أو بيع فوري).
  final RxBool pickerReservedStockEnabled = false.obs;

  /// مودال التحذير عند الإضافة (تدفق الطلبية فقط).
  final RxBool salesOrderStockMode = false.obs;

  /// تدفق إضافة قطع من شاشة الصيانة.
  final RxBool maintenancePickerFlow = false.obs;

  void setMaintenancePickerFlow(bool enabled) {
    maintenancePickerFlow.value = enabled;
  }

  bool confirmMaintenancePickerAndPop() {
    if (!canContinueFromPicker) {
      Get.snackbar(
        'error'.tr,
        'instantSaleCartEmpty'.tr,
        backgroundColor: Colors.red,
      );
      return false;
    }
    Get.back(result: true);
    return true;
  }

  void enablePickerReservedStock({bool salesOrderFlow = false}) {
    pickerReservedStockEnabled.value = true;
    if (salesOrderFlow) {
      salesOrderStockMode.value = true;
    }
  }

  void disablePickerReservedStock() {
    pickerReservedStockEnabled.value = false;
    salesOrderStockMode.value = false;
    maintenancePickerFlow.value = false;
  }

  bool get shouldWarnReservedStock =>
      pickerReservedStockEnabled.value || salesOrderStockMode.value;

  final RxList<StoreSectionModel> pickerStoreSections =
      <StoreSectionModel>[].obs;
  final RxnString pickerLocationSectionId = RxnString();

  StockDatasource get _stockDatasource {
    AppDependencyRegistry.ensureStock();
    return Get.find<StockDatasource>();
  }

  Future<void> ensurePickerStoreSectionsLoaded({bool force = false}) async {
    if (!force && pickerStoreSections.isNotEmpty) return;
    try {
      final list = await _stockDatasource.getStoreSections();
      pickerStoreSections.assignAll(list);
    } catch (_) {}
  }

  bool productMatchesPickerLocation(ProductModel product) {
    final sectionId = pickerLocationSectionId.value;
    if (sectionId == null || sectionId.isEmpty) return true;
    if (isUnassignedStoreSectionFilter(sectionId)) {
      final productSection = product.storeSectionId?.trim();
      return productSection == null || productSection.isEmpty;
    }
    return (product.storeSectionId ?? '').trim() == sectionId.trim();
  }

  Future<void> applyPickerLocationFilter({
    String? sectionId,
  }) async {
    pickerLocationSectionId.value = sectionId;
    await getAllProducts(showLoading: false);
    update();
  }

  Future<void> clearPickerLocationFilter() async {
    pickerLocationSectionId.value = null;
    await getAllProducts(showLoading: false);
    update();
  }

  void clearPickerLocationFilterOnReset() {
    pickerLocationSectionId.value = null;
  }

  static const int _autoSuspendLineThreshold = 10;
  Timer? _autoSuspendDebounce;
  Timer? _localDraftDebounce;
  bool _isAutoSuspendingInstantSale = false;
  bool _activeSuspendedSaleIsAuto = false;
  bool _isRestoringLocalInstantSaleDraft = false;

  void bumpCartRevision() {
    cartRevision.value++;
    _scheduleAutoSuspendLargeInstantSale();
    _scheduleLocalInstantSaleDraftSave();
  }

  int get _instantSaleLineCount {
    if (cartLines.isNotEmpty) {
      return cartLines.length + (hasSelectedPackage ? 1 : 0);
    }
    return items.where((item) {
      final productId = item.selectedItem.value.toString().trim();
      return productId.isNotEmpty;
    }).length;
  }

  void _scheduleAutoSuspendLargeInstantSale() {
    _autoSuspendDebounce?.cancel();

    if (activeEditInstantSaleId.value != null) return;
    if (_instantSaleLineCount <= _autoSuspendLineThreshold) return;
    if (activeSuspendedSaleId.value != null && !_activeSuspendedSaleIsAuto) {
      return;
    }

    _autoSuspendDebounce = Timer(
      const Duration(milliseconds: 900),
      _autoSuspendLargeInstantSale,
    );
  }

  Future<void> _autoSuspendLargeInstantSale() async {
    if (_isAutoSuspendingInstantSale) return;
    if (activeEditInstantSaleId.value != null) return;
    if (_instantSaleLineCount <= _autoSuspendLineThreshold) return;
    if (!canContinueFromPicker) return;
    if (activeSuspendedSaleId.value != null && !_activeSuspendedSaleIsAuto) {
      return;
    }

    _isAutoSuspendingInstantSale = true;
    try {
      final result = await Get.find<SalesDatasource>().suspendInstantSale(
        currentStep: Get.currentRoute == AppRoutes.NEWINSTANTSALESCREEN
            ? 'checkout'
            : 'product_picker',
        payload: buildInstantSaleSuspendPayload(),
        suspendedInstantSaleId: activeSuspendedSaleId.value,
      );
      if (result['status'] == 'success') {
        final raw = result['suspended_instant_sale'];
        if (raw is Map) {
          final id = int.tryParse('${raw['id']}');
          if (id != null) {
            activeSuspendedSaleId.value = id;
            _activeSuspendedSaleIsAuto = true;
          }
        }
        final count = int.tryParse('${result['suspended_count']}');
        if (count != null) {
          suspendedInvoicesCount.value = count;
        }
      }
    } catch (e) {
      assert(() {
        debugPrint('[SalesController.autoSuspendLargeInstantSale] $e');
        return true;
      }());
    } finally {
      _isAutoSuspendingInstantSale = false;
    }
  }

  bool get _shouldKeepLocalInstantSaleDraft =>
      activeEditInstantSaleId.value == null &&
      activeSuspendedSaleId.value == null &&
      canContinueFromPicker &&
      _instantSaleLineCount <= _autoSuspendLineThreshold;

  void _scheduleLocalInstantSaleDraftSave() {
    _localDraftDebounce?.cancel();
    if (_isRestoringLocalInstantSaleDraft) return;

    if (!_shouldKeepLocalInstantSaleDraft) {
      if (_instantSaleLineCount > _autoSuspendLineThreshold) {
        clearLocalInstantSaleDraft();
      }
      return;
    }

    _localDraftDebounce = Timer(
      const Duration(milliseconds: 500),
      saveLocalInstantSaleDraft,
    );
  }

  Future<void> saveLocalInstantSaleDraft() async {
    if (_isRestoringLocalInstantSaleDraft) return;
    if (!_shouldKeepLocalInstantSaleDraft) return;

    final payload = buildInstantSaleSuspendPayload();
    if (payload['product_id'] == null && payload['offer_package_id'] == null) {
      return;
    }

    await GetStorage().write(
      kInstantSaleLocalDraftKey,
      jsonEncode({
        'saved_at': DateTime.now().toIso8601String(),
        'payload': payload,
      }),
    );
  }

  Future<void> clearLocalInstantSaleDraft() async {
    await GetStorage().remove(kInstantSaleLocalDraftKey);
  }

  Map<String, dynamic>? _readLocalInstantSaleDraftPayload() {
    final raw = GetStorage().read(kInstantSaleLocalDraftKey);
    if (raw == null) return null;

    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! Map) return null;
      final payload = decoded['payload'];
      if (payload is Map) {
        return Map<String, dynamic>.from(payload);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  bool get hasLocalInstantSaleDraft =>
      _readLocalInstantSaleDraftPayload() != null;

  bool get hasUnsavedInstantSaleWork =>
      activeEditInstantSaleId.value == null &&
      activeSuspendedSaleId.value == null &&
      canContinueFromPicker;

  Future<bool> promptRestoreLocalInstantSaleDraft(BuildContext context) async {
    if (activeSuspendedSaleId.value != null ||
        activeEditInstantSaleId.value != null ||
        canContinueFromPicker) {
      return false;
    }

    final payload = _readLocalInstantSaleDraftPayload();
    if (payload == null) return false;

    final restore = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('instantSaleDraftRestoreTitle'.tr),
        content: Text('instantSaleDraftRestoreBody'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('discard'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('restore'.tr),
          ),
        ],
      ),
    );

    if (restore != true) {
      await clearLocalInstantSaleDraft();
      return false;
    }

    _isRestoringLocalInstantSaleDraft = true;
    try {
      resetInstantSaleForm(renewFormKey: true);
      await loadOfferPackagesForSale();
      if (products.isEmpty) {
        final list = await getAllProductsUsecase.call();
        products
          ..clear()
          ..addAll(list);
      }
      await hydrateFromSuspendedPayload(payload);
      await clearLocalInstantSaleDraft();
      return true;
    } finally {
      _isRestoringLocalInstantSaleDraft = false;
    }
  }

  Future<bool> confirmLeaveInstantSaleFlow(BuildContext context) async {
    if (!hasUnsavedInstantSaleWork) return true;

    await saveLocalInstantSaleDraft();
    if (!context.mounted) return false;

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('instantSaleLeaveWarningTitle'.tr),
        content: Text('instantSaleLeaveWarningBody'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'stay'),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'leave'),
            child: Text('instantSaleLeaveKeepLocal'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'suspend'),
            child: Text('suspendInvoice'.tr),
          ),
        ],
      ),
    );

    if (action == 'suspend') {
      if (!context.mounted) return false;
      final saved = await suspendInstantSale(
        context,
        currentStep: Get.currentRoute == AppRoutes.NEWINSTANTSALESCREEN
            ? 'checkout'
            : 'product_picker',
      );
      if (saved) {
        await clearLocalInstantSaleDraft();
      }
      return false;
    }

    return action == 'leave';
  }

  void _bumpProductsList() => productsListVersion.value++;

  ProductModel? productById(String id) {
    final i = products.indexWhere((p) => p.id == id);
    return i >= 0 ? products[i] : null;
  }

  void patchProductPrices(
    String productId, {
    required double unitPrice,
    double? wholesalePrice,
  }) {
    final i = products.indexWhere((p) => p.id == productId);
    if (i >= 0) {
      products[i] = products[i].copyWith(
        unitPrice: unitPrice,
        wholesalePrice: wholesalePrice ?? products[i].wholesalePrice,
      );
      _bumpProductsList();
    }
  }

  final RxBool savingProductPrice = false.obs;

  /// يتأكد أن سعر المفرق معرّف قبل إضافة المنتج للسلة.
  Future<ProductModel?> ensureProductPricesForPicker(
      ProductModel product) async {
    if (product.hasCustomPrice &&
        product.customPrice != null &&
        product.customPrice! > 0) {
      return product;
    }
    if (product.unitPrice > 0) return product;

    final dialogResult = await showInstantSalePriceDialog(product);
    if (dialogResult == null) return null;

    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 120));

    if (!Get.isRegistered<SalesController>()) return null;

    savingProductPrice(true);
    final result = await updateProductRetailPriceUsecase.call(
      productId: product.id,
      normailPrice: dialogResult.retailPrice,
      wholesalePrice:
          dialogResult.wholesalePrice > 0 ? dialogResult.wholesalePrice : null,
    );
    savingProductPrice(false);

    return result.fold<ProductModel?>(
      (f) {
        Get.snackbar('error'.tr, f.errMessage);
        return null;
      },
      (prices) {
        patchProductPrices(
          product.id,
          unitPrice: prices.retail,
          wholesalePrice: prices.wholesale > 0 ? prices.wholesale : null,
        );
        Get.snackbar(
          'success'.tr,
          'instantSaleProductPricesSaved'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return productById(product.id) ??
            product.copyWith(
              unitPrice: prices.retail,
              wholesalePrice: prices.wholesale > 0
                  ? prices.wholesale
                  : product.wholesalePrice,
            );
      },
    );
  }

  int get cartDistinctCount => cartLines.length;

  int get cartTotalPieces {
    var n = 0;
    for (final line in cartLines) {
      n += int.tryParse(line.quantityText) ?? 0;
    }
    return n;
  }

  int cartQtyForProduct(String productId) {
    var sum = 0;
    for (final line in cartLines) {
      if (line.productId == productId && !line.isDisposed) {
        sum += int.tryParse(line.quantityText) ?? 0;
      }
    }
    return sum;
  }

  int? _cartIndexForVariantLine(String cartLineKey) {
    final i = cartLines.indexWhere((l) => l.cartLineKey == cartLineKey);
    return i >= 0 ? i : null;
  }

  void onInstantSaleProductSearchChanged(String value) {
    instantSaleProductSearch.value = value;
    _instantSalePickerSearchDebounce?.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      instantSalePickerSearchLoading(false);
      getAllProducts(showLoading: false);
      return;
    }

    instantSalePickerSearchLoading(true);
    _instantSalePickerSearchDebounce = Timer(
      const Duration(milliseconds: 180),
      () async {
        await getAllProducts(showLoading: false);
        instantSalePickerSearchLoading(false);
      },
    );
  }

  String _normalizePickerSearchText(String raw) {
    var s = raw.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    s = s.replaceAll(RegExp(r'[أإآ]'), 'ا');
    s = s.replaceAll('ى', 'ي');
    return s;
  }

  bool _pickerSearchMatches(String query, String haystack) {
    if (query.isEmpty) return true;
    final h = _normalizePickerSearchText(haystack);
    final q = _normalizePickerSearchText(query);
    if (h.isEmpty) return false;
    if (h.contains(q)) return true;

    var hi = 0;
    for (var i = 0; i < q.length; i++) {
      final c = q[i];
      var found = false;
      while (hi < h.length) {
        if (h[hi] == c) {
          found = true;
          hi++;
          break;
        }
        hi++;
      }
      if (!found) return false;
    }
    return true;
  }

  bool productMatchesPickerSearch(ProductModel product, String query) {
    if (query.isEmpty) return true;

    final fields = <String>[
      product.nameAr,
      product.displayProductCode,
      product.id,
      product.storeSectionName ?? '',
    ];
    for (final size in product.sizes) {
      fields.add(size.size);
      for (final color in size.colorSizes) {
        fields.add(color.colorAr);
        if (color.colorEn != null) fields.add(color.colorEn!);
        if (color.colorAbbr != null) fields.add(color.colorAbbr!);
      }
    }

    return fields.any((field) => _pickerSearchMatches(query, field));
  }

  bool packageMatchesPickerSearch(OfferPackageModel package, String query) {
    if (query.isEmpty) return true;
    return _pickerSearchMatches(query, package.name);
  }

  List<ProductModel> get filteredProductsForPicker {
    final q = instantSaleProductSearch.value.trim();
    final sectionId = pickerLocationSectionId.value;

    var list = products;
    if (sectionId != null && sectionId.isNotEmpty) {
      list = list.where(productMatchesPickerLocation).toList();
    }

    if (q.isEmpty) return list;
    return list.where((p) => productMatchesPickerSearch(p, q)).toList();
  }

  List<OfferPackageModel> get filteredPackagesForPicker {
    final q = instantSaleProductSearch.value.trim();
    final sellable = offerPackagesForSale.where(
      (p) => p.isActive && p.maxSellableQuantity > 0,
    );
    if (q.isEmpty) return sellable.toList();
    return sellable.where((p) => packageMatchesPickerSearch(p, q)).toList();
  }

  int get pickerGridItemCount {
    final hasLocationFilter = pickerLocationSectionId.value != null &&
        pickerLocationSectionId.value!.isNotEmpty;
    final packages = hasLocationFilter ? 0 : filteredPackagesForPicker.length;
    return packages + filteredProductsForPicker.length;
  }

  bool get canContinueFromPicker =>
      (isPackageSale.value && selectedPackageId.value != null) ||
      cartDistinctCount > 0;

  bool get hasSelectedPackage =>
      isPackageSale.value && selectedPackageId.value != null;

  int get pickerSelectionCount {
    var n = cartDistinctCount;
    if (hasSelectedPackage) n += 1;
    return n;
  }

  List<Map<String, dynamic>> buildCartOtherProductsPayload() {
    return cartLines.map((line) {
      final map = <String, dynamic>{
        'product_id': line.productId,
        'cost': line.priceText,
        'quantity': line.quantityText,
        'type': line.isProjectSale.value ? 'project' : 'normal',
      };
      final projectId = line.projectId.value;
      if (projectId != null && projectId.isNotEmpty) {
        map['project_id'] = projectId;
      }
      if (line.sizeColorId != null && line.sizeColorId!.isNotEmpty) {
        map['size_color_id'] = line.sizeColorId;
      }
      if (line.sizeId != null && line.sizeId!.isNotEmpty) {
        map['size_id'] = line.sizeId;
      }
      return map;
    }).toList();
  }

  void _clearPackageSelection() {
    isPackageSale.value = false;
    selectedPackageId.value = null;
    items.first.quantityController.text = '1';
    items.first.priceController.clear();
    calculateGrandTotal();
  }

  void selectPackageForPicker(OfferPackageModel package) {
    isPackageSale.value = true;
    onOfferPackageSelected(package);
    bumpCartRevision();
  }

  void togglePackageForPicker(OfferPackageModel package) {
    if (isPackageSale.value && selectedPackageId.value == package.id) {
      _clearPackageSelection();
      bumpCartRevision();
      return;
    }
    selectPackageForPicker(package);
  }

  void adjustPackagePickerQuantity(int delta) {
    if (!isPackageSale.value || selectedPackageId.value == null) return;
    final pkg = selectedOfferPackage;
    if (pkg == null) return;

    final current =
        int.tryParse(items.first.quantityController.text.trim()) ?? 1;
    final next = current + delta;
    if (next < 1) {
      _clearPackageSelection();
      bumpCartRevision();
      return;
    }
    if (next > pkg.maxSellableQuantity) {
      Get.snackbar(
        'error'.tr,
        'packageQtyExceedsAvailable'.trParams({
          'qty': '$next',
          'max': '${pkg.maxSellableQuantity}',
        }),
      );
      return;
    }
    items.first.quantityController.text = next.toString();
    calculateGrandTotal();
    bumpCartRevision();
  }

  /// ضغطة على البطاقة: منتج بسيط يُضاف/يُزال؛ منتج بألوان يفتح اختيار التركيبة.
  Future<void> toggleProductInCart(
    ProductModel product, {
    BuildContext? context,
  }) async {
    if (product.hasVariants && product.sizes.isNotEmpty) {
      await _pickVariantAndAddToCart(product, context: context);
      return;
    }

    final idx = cartLines.indexWhere((l) => l.productId == product.id);
    if (idx >= 0) {
      removeCartLine(idx);
      bumpCartRevision();
      return;
    }
    await _addProductToCartOnce(product);
  }

  Future<bool> _confirmSalesOrderReservedStock({
    required ProductModel product,
    int? sizeColorId,
    int requestedQty = 1,
  }) async {
    if (!shouldWarnReservedStock) return true;
    if (!Get.isRegistered<SalesOrdersController>()) return true;
    return Get.find<SalesOrdersController>().confirmReservedStockBeforeAdd(
      productId: product.id,
      productName: product.nameAr,
      sizeColorId: sizeColorId,
      requestedQty: requestedQty,
    );
  }

  Future<void> incrementProductInCart(
    ProductModel product, {
    BuildContext? context,
  }) async {
    if (product.hasVariants && product.sizes.isNotEmpty) {
      await _pickVariantAndAddToCart(product, context: context);
      return;
    }

    final idx = cartLines.indexWhere((l) => l.productId == product.id);
    if (idx < 0) {
      await _addProductToCartOnce(product);
      return;
    }

    final resolved = productById(product.id) ?? product;
    final stock = int.tryParse(resolved.stock) ?? 0;
    final line = cartLines[idx];
    final next = (int.tryParse(line.quantityController.text.trim()) ?? 0) + 1;
    if (!await _confirmSalesOrderReservedStock(
      product: resolved,
      requestedQty: next,
    )) {
      return;
    }
    if (next > stock) {
      Get.snackbar('error'.tr, 'out_of_stock_products'.tr,
          backgroundColor: Colors.red);
      return;
    }
    line.quantityController.text = next.toString();
    line.recalculateTotal();
    calculateGrandTotal();
    bumpCartRevision();
  }

  Future<void> _pickVariantAndAddToCart(
    ProductModel product, {
    BuildContext? context,
  }) async {
    final ctx = context ?? Get.context;
    if (ctx == null) return;

    var resolved = productById(product.id) ?? product;
    final priced = await ensureProductPricesForPicker(resolved);
    if (priced == null) return;
    resolved = productById(product.id) ?? priced;

    if (!resolved.hasVariants || resolved.sizes.isEmpty) {
      await _addProductToCartOnce(resolved);
      return;
    }

    final pick = await showSalesVariantPickerSheet(
      context: ctx,
      product: resolved,
    );
    if (pick == null) return;

    final sizeColorId = int.tryParse(pick.variant.id);
    final existingIdx = _cartIndexForVariantLine(
      '${resolved.id}::${pick.variant.id}',
    );
    if (existingIdx != null) {
      final line = cartLines[existingIdx];
      final next = (int.tryParse(line.quantityController.text.trim()) ?? 0) +
          pick.quantity;
      if (!await _confirmSalesOrderReservedStock(
        product: resolved,
        sizeColorId: sizeColorId,
        requestedQty: next,
      )) {
        return;
      }
      if (next > pick.variant.stock) {
        Get.snackbar('error'.tr, 'out_of_stock_products'.tr,
            backgroundColor: Colors.red);
        return;
      }
      line.quantityController.text = next.toString();
      line.recalculateTotal();
      calculateGrandTotal();
      bumpCartRevision();
      return;
    }

    if (!await _confirmSalesOrderReservedStock(
      product: resolved,
      sizeColorId: sizeColorId,
      requestedQty: pick.quantity,
    )) {
      return;
    }

    addCartLine(
      InstantSaleCartLine.fromProduct(
        resolved,
        quantity: pick.quantity.toString(),
        unitPrice: await resolveDefaultUnitPrice(
          resolved,
          sizeColorId: pick.variant.id,
          variantRetailPrice: pick.variant.normailPrice,
          variantWholesalePrice: pick.variant.wholesalePrice,
        ),
        sizeColorId: pick.variant.id,
        sizeId: pick.size.id,
        sizeLabel: pick.size.size,
        colorLabel: pick.variant.colorAr,
        variantStock: pick.variant.stock,
        variantImageUrl: pick.variant.imageUrl,
      ),
    );
    bumpCartRevision();
  }

  Future<void> _addProductToCartOnce(ProductModel product) async {
    final resolved = await ensureProductPricesForPicker(product);
    if (resolved == null) return;

    final stock = int.tryParse(resolved.stock) ?? 0;
    if (stock < 1) {
      Get.snackbar('error'.tr, 'out_of_stock_products'.tr,
          backgroundColor: Colors.red);
      return;
    }
    if (!await _confirmSalesOrderReservedStock(
      product: resolved,
      requestedQty: 1,
    )) {
      return;
    }
    final unitPrice = await resolveDefaultUnitPrice(resolved);
    addCartLine(
      InstantSaleCartLine.fromProduct(resolved, unitPrice: unitPrice),
    );
    bumpCartRevision();
  }

  void decrementProductInCart(String productId) {
    final idx = cartLines.lastIndexWhere((l) => l.productId == productId);
    if (idx < 0) return;
    final line = cartLines[idx];
    final current = int.tryParse(line.quantityController.text.trim()) ?? 1;
    if (current <= 1) {
      removeCartLine(idx);
    } else {
      line.quantityController.text = (current - 1).toString();
      line.recalculateTotal();
      calculateGrandTotal();
    }
    bumpCartRevision();
  }

  void setCartLineQuantity(int index, int qty) {
    if (index < 0 || index >= cartLines.length) return;
    final line = cartLines[index];
    final stock = line.stock;
    final safe = qty.clamp(1, stock > 0 ? stock : qty);
    line.quantityController.text = safe.toString();
    line.recalculateTotal();
    calculateGrandTotal();
    bumpCartRevision();
  }

  void adjustCartLineQuantity(int index, int delta) {
    if (index < 0 || index >= cartLines.length) return;
    final line = cartLines[index];
    final current = int.tryParse(line.quantityController.text.trim()) ?? 1;
    final next = current + delta;
    if (next < 1) {
      removeCartLine(index);
      bumpCartRevision();
      return;
    }
    if (next > line.stock) {
      Get.snackbar('error'.tr, 'out_of_stock_products'.tr,
          backgroundColor: Colors.red);
      return;
    }
    line.quantityController.text = next.toString();
    line.recalculateTotal();
    calculateGrandTotal();
    bumpCartRevision();
  }

  void openInstantSaleCheckout({bool fromResume = false}) {
    final hasPackage = hasSelectedPackage;
    final hasProducts = cartLines.isNotEmpty;

    if (!hasPackage && !hasProducts) {
      Get.snackbar('error'.tr, 'instantSaleCartEmpty'.tr,
          backgroundColor: Colors.red);
      return;
    }

    if (hasPackage) {
      final qtyError = validatePackageSaleQuantity(
        items.first.quantityController.text,
      );
      if (qtyError != null) {
        Get.snackbar('error'.tr, qtyError, backgroundColor: Colors.red);
        return;
      }
    }

    if (hasProducts) {
      for (final line in cartLines) {
        final qty = int.tryParse(line.quantityText) ?? 0;
        if (qty > line.stock) {
          Get.snackbar('error'.tr, 'out_of_stock_products'.tr,
              backgroundColor: Colors.red);
          return;
        }
      }
    }

    if (hasProducts && !hasPackage) {
      syncCartToItems();
    }

    Get.toNamed(AppRoutes.NEWINSTANTSALESCREEN);
  }

  void openSalesOrderCheckout() {
    final hasProducts = cartLines.where((l) => !l.isDisposed).isNotEmpty;

    if (!hasProducts) {
      Get.snackbar('error'.tr, 'instantSaleCartEmpty'.tr,
          backgroundColor: Colors.red);
      return;
    }

    for (final line in cartLines) {
      if (line.isDisposed) continue;
      final qty = int.tryParse(line.quantityText) ?? 0;
      if (qty > line.stock) {
        Get.snackbar('error'.tr, 'out_of_stock_products'.tr,
            backgroundColor: Colors.red);
        return;
      }
    }

    syncCartToItems();
    Get.toNamed(AppRoutes.SALESORDERCHECKOUTSCREEN);
  }

  void openInstantSaleProductPicker() {
    if (products.isEmpty) {
      getAllProducts();
    }
    Get.toNamed(AppRoutes.INSTANTSALEPRODUCTPICKER);
  }

  final RxInt suspendedInvoicesCount = 0.obs;
  final RxnInt activeSuspendedSaleId = RxnInt();
  final RxnInt activeEditInstantSaleId = RxnInt();

  String? get activeSuspendedReferenceCode =>
      activeSuspendedSaleId.value == null || _activeSuspendedSaleIsAuto
          ? null
          : 'ع-${activeSuspendedSaleId.value}';

  String? get activeEditInstantSaleReference =>
      activeEditInstantSaleId.value == null
          ? null
          : '${activeEditInstantSaleId.value}';

  bool get isEditingInstantSale => activeEditInstantSaleId.value != null;

  Future<void> loadSuspendedInvoicesCount() async {
    try {
      suspendedInvoicesCount.value =
          await Get.find<SalesImplement>().getSuspendedInstantSalesCount();
    } catch (_) {
      suspendedInvoicesCount.value = 0;
    }
  }

  void clearActiveSuspendedSale() {
    activeSuspendedSaleId.value = null;
    _activeSuspendedSaleIsAuto = false;
  }

  void clearActiveEditInstantSale() {
    activeEditInstantSaleId.value = null;
  }

  Map<String, dynamic> buildInstantSaleSuspendPayload() {
    final hasPackage = hasSelectedPackage;
    if (cartLines.isNotEmpty && !hasPackage) {
      syncCartToItems();
    }

    final List<Map<String, dynamic>> otherProductsList;
    final List<Map<String, dynamic>>? cartPayload =
        cartLines.isNotEmpty ? buildCartOtherProductsPayload() : null;

    if (hasPackage) {
      otherProductsList = cartPayload ?? <Map<String, dynamic>>[];
    } else if (cartPayload != null && cartPayload.isNotEmpty) {
      otherProductsList =
          cartPayload.length > 1 ? cartPayload.skip(1).toList() : [];
    } else if (items.length > 1) {
      otherProductsList = items.skip(1).map((item) {
        final map = <String, dynamic>{
          'product_id': item.selectedItem.value,
          'cost': item.priceController.text,
          'quantity': item.quantityController.text,
          'type': item.selectedCustomersSellers.value ? 'project' : 'normal',
        };
        final projectId = item.selectedValue.value;
        if (projectId != null && projectId.isNotEmpty) {
          map['project_id'] = projectId;
        }
        return map;
      }).toList();
    } else {
      otherProductsList = [];
    }

    final map = <String, dynamic>{
      'discount':
          discountController.text.isEmpty ? '0' : discountController.text,
      'total_cost': totalCost.value.toString(),
      'notes': instantSaleNotesText,
      'additional_notes': instantSaleNotesPayload(),
      'type': items.first.selectedCustomersSellers.value ? 'project' : 'normal',
      'buyer_type': _paymentBuyerType,
    };

    final projectId = items.first.selectedValue.value;
    if (items.first.selectedCustomersSellers.value &&
        projectId != null &&
        projectId.isNotEmpty) {
      map['project_id'] = projectId;
    }
    if (_paymentBuyerId != null && _paymentBuyerId!.isNotEmpty) {
      map['buyer_id'] = _paymentBuyerId;
    }
    if (_paymentSellerId != null && _paymentSellerId!.isNotEmpty) {
      map['seller_id'] = _paymentSellerId;
    }
    if (_paymentBuyerName != null && _paymentBuyerName!.isNotEmpty) {
      map['buyer_name'] = _paymentBuyerName;
    }
    if (_paymentBoxId != null && _paymentBoxId!.isNotEmpty) {
      map['payment_box_id'] = _paymentBoxId;
      map['payment_box_name'] = _paymentBoxName;
      map['payment_box_value'] = _paymentBoxValue ?? '0';
    }

    if (hasPackage) {
      map['offer_package_id'] = selectedPackageId.value;
      map['quantity'] = items.first.quantityController.text;
      map['cost'] = items.first.priceController.text;
      if (otherProductsList.isNotEmpty) {
        map['other_products'] = otherProductsList;
      }
    } else if ((cartPayload != null && cartPayload.isNotEmpty) ||
        (items.isNotEmpty &&
            items.first.selectedItem.value.toString().isNotEmpty)) {
      final mainLine = cartPayload?.isNotEmpty == true
          ? cartPayload!.first
          : <String, dynamic>{
              'product_id': items.first.selectedItem.value,
              'quantity': items.first.quantityController.text,
              'cost': items.first.priceController.text,
            };
      map['product_id'] = mainLine['product_id'];
      map['quantity'] = mainLine['quantity'];
      map['cost'] = mainLine['cost'];
      if (mainLine['size_color_id'] != null) {
        map['size_color_id'] = mainLine['size_color_id'];
      }
      if (mainLine['size_id'] != null) {
        map['size_id'] = mainLine['size_id'];
      }
      if (otherProductsList.isNotEmpty) {
        map['other_products'] = otherProductsList;
      }
    }

    _mergeLiveCheckoutPaymentIntoPayload(map);

    return map;
  }

  /// Reads payment form on checkout screen (before submit) into suspend payload.
  void _mergeLiveCheckoutPaymentIntoPayload(Map<String, dynamic> map) {
    final payment = _instantSalePayment;
    if (payment == null) return;

    final live = payment.buildInstantSaleBuyerPayload();

    final buyerType = live['buyer_type']?.toString();
    if (buyerType != null && buyerType.isNotEmpty) {
      map['buyer_type'] = buyerType;
    }

    final buyerId = live['buyer_id']?.toString();
    if (buyerId != null && buyerId.isNotEmpty) {
      map['buyer_id'] = buyerId;
      map.remove('seller_id');
    }

    final sellerId = live['seller_id']?.toString();
    if (sellerId != null && sellerId.isNotEmpty) {
      map['seller_id'] = sellerId;
      map.remove('buyer_id');
    }

    final buyerName = live['buyer_name']?.toString();
    if (buyerName != null && buyerName.isNotEmpty) {
      map['buyer_name'] = buyerName;
    }

    final boxId = live['payment_box_id']?.toString();
    if (boxId != null && boxId.isNotEmpty) {
      map['payment_box_id'] = boxId;
      final boxName = live['payment_box_name']?.toString();
      if (boxName != null && boxName.isNotEmpty) {
        map['payment_box_name'] = boxName;
      }
      final cash = live['payment_box_value']?.toString() ?? '0';
      map['payment_box_value'] = cash.replaceAll(',', '').replaceAll('،', '');
    }

    applyBuyerFromPayment(live);
  }

  Future<bool> suspendInstantSale(
    BuildContext context, {
    required String currentStep,
  }) async {
    _instantSaleDebug('suspend requested', {
      'currentStep': currentStep,
      'activeSuspendedSaleId': activeSuspendedSaleId.value,
      'activeEditInstantSaleId': activeEditInstantSaleId.value,
      'cartLines': cartLines.length,
      'items': items.length,
      'hasPackage': hasSelectedPackage,
      'totalCost': totalCost.value,
    });
    if (activeEditInstantSaleId.value != null) return false;

    if (!canContinueFromPicker) {
      Get.snackbar('error'.tr, 'instantSaleCartEmpty'.tr,
          backgroundColor: Colors.red);
      return false;
    }

    final suspendNote = await _askSuspendedInvoiceNote(context);

    isLoading(true);
    try {
      final payload = buildInstantSaleSuspendPayload();
      _instantSaleDebug('suspend payload built', {
        'keys': payload.keys.toList(),
        'productId': payload['product_id'],
        'offerPackageId': payload['offer_package_id'],
        'quantity': payload['quantity'],
        'totalCost': payload['total_cost'],
        'buyerType': payload['buyer_type'],
        'buyerId': payload['buyer_id'],
        'sellerId': payload['seller_id'],
        'paymentBoxId': payload['payment_box_id'],
        'otherProductsCount': payload['other_products'] is List
            ? (payload['other_products'] as List).length
            : 0,
      });
      final result = await Get.find<SalesImplement>().suspendInstantSale(
        currentStep: currentStep,
        payload: payload,
        suspendedInstantSaleId: activeSuspendedSaleId.value,
        note: suspendNote,
      );

      return await result.fold(
        (failure) async {
          _instantSaleDebug('suspend failed', {
            'message': failure.errMessage,
            'data': failure.data,
          });
          Helpers.showCustomDialogError(
            context: context,
            title: 'error'.tr,
            message: failure.errMessage,
          );
          return false;
        },
        (message) async {
          _instantSaleDebug('suspend success', message);
          await _leaveInstantSaleFlow();
          await clearLocalInstantSaleDraft();
          clearActiveSuspendedSale();
          resetInstantSaleForm();
          await loadSuspendedInvoicesCount();
          Helpers.showCustomDialogSuccess(
            context: Get.context ?? context,
            title: 'success'.tr,
            message: message,
          );
          return true;
        },
      );
    } finally {
      isLoading(false);
    }
  }

  Future<String?> _askSuspendedInvoiceNote(BuildContext context) async {
    final noteCtrl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'suspendedInvoiceNoteOnSuspendTitle'.tr,
          style: const TextStyle(color: Color(0xFF374151)),
        ),
        content: TextField(
          controller: noteCtrl,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'suspendedInvoiceNoteHint'.tr,
            hintStyle: const TextStyle(color: Color(0xFF6B7280)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          style: const TextStyle(color: Color(0xFF374151)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(
              'skip'.tr,
              style: const TextStyle(color: Color(0xFF374151)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, noteCtrl.text.trim()),
            child: Text(
              'save'.tr,
              style: const TextStyle(color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );

    return result == null || result.trim().isEmpty ? null : result.trim();
  }

  Future<bool> resumeSuspendedInstantSale(
    SuspendedInstantSaleModel sale,
  ) async {
    _instantSaleDebug('resume requested', {
      'suspendedId': sale.id,
      'currentStep': sale.currentStep,
      'payloadKeys': sale.payload.keys.toList(),
    });
    try {
      clearActiveEditInstantSale();
      activeSuspendedSaleId.value = sale.id;
      _activeSuspendedSaleIsAuto = false;
      resetInstantSaleForm(renewFormKey: true);
      await loadOfferPackagesForSale();
      if (products.isEmpty) {
        final list = await getAllProductsUsecase.call();
        products
          ..clear()
          ..addAll(list);
      }
      await hydrateFromSuspendedPayload(sale.payload);

      if (Get.currentRoute == AppRoutes.SUSPENDEDINVOICESSCREEN) {
        Get.back();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }

      if (sale.isCheckoutStep) {
        openInstantSaleCheckout(fromResume: true);
      } else {
        await Get.toNamed(AppRoutes.INSTANTSALEPRODUCTPICKER);
      }
      return true;
    } catch (e) {
      _instantSaleDebug('resume failed', e);
      Get.snackbar(
        'error'.tr,
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> hydrateFromSuspendedPayload(Map<String, dynamic> payload) async {
    discountController.text = payload['discount']?.toString() ?? '0';

    clearInstantSaleNotes(dispose: true);
    final additionalNotes = payload['additional_notes'];
    if (additionalNotes is List) {
      for (final raw in additionalNotes) {
        if (raw is Map) {
          addInstantSaleNoteLine();
          final idx = instantSaleNotes.length - 1;
          instantSaleNotes[idx].text.text = raw['text']?.toString() ?? '';
          instantSaleNotes[idx].amount.text = raw['amount']?.toString() ?? '0';
        }
      }
    }

    final offerPackageId = payload['offer_package_id'];
    if (offerPackageId != null && '$offerPackageId'.isNotEmpty) {
      isPackageSale.value = true;
      selectedPackageId.value = int.tryParse('$offerPackageId');
      items.first.quantityController.text =
          payload['quantity']?.toString() ?? '1';
      items.first.priceController.text = payload['cost']?.toString() ?? '';
      final pkg = selectedOfferPackage;
      if (pkg == null && offerPackagesForSale.isNotEmpty) {
        final match = offerPackagesForSale
            .firstWhereOrNull((p) => p.id == selectedPackageId.value);
        if (match != null) {
          items.first.priceController.text = _formatUnitPrice(match.price);
        }
      }
    } else {
      isPackageSale.value = false;
      selectedPackageId.value = null;
    }

    final lineMaps = <Map<String, dynamic>>[];
    if (offerPackageId == null && payload['product_id'] != null) {
      lineMaps.add({
        'product_id': payload['product_id'],
        'quantity': payload['quantity'] ?? '1',
        'cost': payload['cost'] ?? '0',
        'type': payload['type'] ?? 'normal',
        'project_id': payload['project_id'],
        'size_color_id': payload['size_color_id'],
        'size_id': payload['size_id'],
      });
    }
    final otherProducts = payload['other_products'];
    if (otherProducts is List) {
      for (final raw in otherProducts) {
        if (raw is Map) {
          lineMaps.add(Map<String, dynamic>.from(raw));
        }
      }
    }

    clearCartLines(deferDispose: false);
    for (final line in lineMaps) {
      _addHydratedCartLine(line);
    }

    if (!hasSelectedPackage && lineMaps.isNotEmpty) {
      syncCartToItems();
      final first = lineMaps.first;
      items.first.selectedCustomersSellers.value =
          first['type']?.toString() == 'project';
      final projectId = first['project_id']?.toString();
      if (projectId != null && projectId.isNotEmpty) {
        items.first.selectedValue.value = projectId;
      }
    } else if (payload['type']?.toString() == 'project') {
      items.first.selectedCustomersSellers.value = true;
      final projectId = payload['project_id']?.toString();
      if (projectId != null && projectId.isNotEmpty) {
        items.first.selectedValue.value = projectId;
      }
    }

    applyBuyerFromPayment({
      'buyer_type': payload['buyer_type'] ?? 'unknown',
      'buyer_id': payload['buyer_id'],
      'seller_id': payload['seller_id'],
      'buyer_name': payload['buyer_name'],
      'payment_box_id': payload['payment_box_id'],
      'payment_box_name': payload['payment_box_name'],
      'payment_box_value': payload['payment_box_value'],
    });

    calculateGrandTotal();
    bumpCartRevision();
  }

  void _addHydratedCartLine(Map<String, dynamic> line) {
    final productId = line['product_id']?.toString() ?? '';
    if (productId.isEmpty) return;

    final product = products.firstWhereOrNull((p) => p.id == productId) ??
        ProductModel(
          id: productId,
          nameAr: line['product_name']?.toString() ?? 'منتج',
          stock: '999',
          projects: const [],
        );

    addCartLine(
      InstantSaleCartLine.fromProduct(
        product,
        quantity: line['quantity']?.toString(),
        unitPrice: line['cost']?.toString(),
        projectSale: line['type']?.toString() == 'project',
        projectId: line['project_id']?.toString(),
        sizeColorId: line['size_color_id']?.toString(),
        sizeId: line['size_id']?.toString(),
        sizeLabel: line['size_label']?.toString(),
        colorLabel: line['color_label']?.toString(),
      ),
    );
  }

  Future<void> hydrateFromSalesOrder(SalesOrderDetailModel order) async {
    clearActiveSuspendedSale();
    clearActiveEditInstantSale();
    resetInstantSaleForm();

    if (products.isEmpty) {
      getAllProducts();
    }
    await ensurePickerPartnersLoaded();

    discountController.text = SalesAmountFormat.display(order.discount);

    applyBuyerFromPayment({
      'buyer_type': order.customerId != null ? 'customer' : 'unknown',
      if (order.customerId != null) 'buyer_id': order.customerId.toString(),
      'buyer_name': order.customerName,
      if (order.paymentBoxId != null)
        'payment_box_id': order.paymentBoxId.toString(),
      if (order.paymentAmount > 0)
        'payment_box_value': order.paymentAmount.toString(),
    });

    resolvePartnerFromOrderSnapshot(
      customerId: order.customerId,
      name: order.customerName,
      phone: order.customerPhone,
    );

    clearCartLines(deferDispose: false);
    for (final item in order.items) {
      _addHydratedCartLine({
        'product_id': item.productId.toString(),
        'quantity': item.quantity.toString(),
        'cost': item.unitPrice.toString(),
        'product_name': item.productName,
        'size_id': item.sizeId?.toString(),
        'size_color_id': item.sizeColorId?.toString(),
        'size_label': item.sizeLabel,
        'color_label': item.colorLabel,
      });
    }
    calculateGrandTotal();
    bumpCartRevision();
  }

  Future<void> hydrateFromInvoice(InvoiceModel invoice) async {
    discountController.text = invoice.discount;

    clearInstantSaleNotes(dispose: true);
    for (final note in invoice.additionalNotes) {
      addInstantSaleNoteLine();
      final idx = instantSaleNotes.length - 1;
      instantSaleNotes[idx].text.text = note.text;
      instantSaleNotes[idx].amount.text = note.amount;
    }

    if (invoice.isPackageSale && invoice.offerPackageId != null) {
      isPackageSale.value = true;
      selectedPackageId.value = invoice.offerPackageId;
      items.first.quantityController.text = invoice.quantity;
      items.first.priceController.text = invoice.cost;
    } else {
      isPackageSale.value = false;
      selectedPackageId.value = null;
    }

    final lineMaps = <Map<String, dynamic>>[];
    if (!invoice.isPackageSale &&
        invoice.productId != null &&
        invoice.productId!.isNotEmpty) {
      lineMaps.add({
        'product_id': invoice.productId,
        'quantity': invoice.quantity,
        'cost': invoice.cost,
        'type': invoice.lineType ??
            (invoice.saleStatus == 'project' ? 'project' : 'normal'),
        'project_id': invoice.projectId,
        'size_color_id': invoice.sizeColorId,
        'size_id': invoice.sizeId,
        'product_name': invoice.displayProductNameOnly,
        'size_label': invoice.sizeLabel,
        'color_label': invoice.colorLabel,
      });
    }

    final subLines = invoice.isPackageSale
        ? invoice.additionalProductLines
        : invoice.subProducts;

    for (final sub in subLines) {
      if (sub.productId == null || sub.productId!.isEmpty) continue;
      lineMaps.add({
        'product_id': sub.productId,
        'quantity': sub.quantity,
        'cost': sub.cost,
        'type': sub.lineType ?? 'normal',
        'project_id': sub.projectId,
        'size_color_id': sub.sizeColorId,
        'size_id': sub.sizeId,
        'product_name': sub.productNameBase ?? sub.productName,
        'size_label': sub.sizeLabel,
        'color_label': sub.colorLabel,
      });
    }

    clearCartLines(deferDispose: false);
    for (final line in lineMaps) {
      _addHydratedCartLine(line);
    }

    if (!hasSelectedPackage && lineMaps.isNotEmpty) {
      syncCartToItems();
      final first = lineMaps.first;
      items.first.selectedCustomersSellers.value =
          first['type']?.toString() == 'project';
      final projectId = first['project_id']?.toString();
      if (projectId != null && projectId.isNotEmpty) {
        items.first.selectedValue.value = projectId;
      }
    } else if (invoice.lineType == 'project' ||
        invoice.saleStatus == 'project') {
      items.first.selectedCustomersSellers.value = true;
      final projectId = invoice.projectId;
      if (projectId != null && projectId.isNotEmpty) {
        items.first.selectedValue.value = projectId;
      }
    }

    final buyerPayload = <String, dynamic>{
      'buyer_type': invoice.buyerType,
      'buyer_name': invoice.buyerName,
      'payment_box_id': invoice.paymentBoxId,
      'payment_box_name': invoice.paymentBoxName,
      'payment_box_value': invoice.paymentBoxValue ?? invoice.paidAmount,
    };
    if (invoice.sellerId != null) {
      buyerPayload['seller_id'] = invoice.sellerId;
    } else if (invoice.buyerId != null) {
      buyerPayload['buyer_id'] = invoice.buyerId;
    }
    applyBuyerFromPayment(buyerPayload);
    await ensurePickerPartnersLoaded();
    syncPickerPartnerFromPayment();

    calculateGrandTotal();
    bumpCartRevision();
  }

  Future<void> openEditInstantSaleFlow(
    BuildContext context,
    InstantSalesModel sale,
  ) async {
    if (sale.isCancelled) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'instantSaleAlreadyCancelled'.tr,
      );
      return;
    }
    if (showSalesBlockedMessage()) return;

    isLoading(true);
    try {
      clearActiveSuspendedSale();
      clearActiveEditInstantSale();
      resetInstantSaleForm();

      final invoice =
          await invoiceModelUsecase.call(invoiceId: sale.id.toString());
      if ((invoice.status ?? '').toLowerCase() == 'cancelled') {
        Helpers.showCustomDialogError(
          context: context,
          title: 'error'.tr,
          message: 'instantSaleAlreadyCancelled'.tr,
        );
        return;
      }

      if (products.isEmpty) {
        getAllProducts();
      }
      await loadOfferPackagesForSale();

      activeEditInstantSaleId.value = sale.id;
      await hydrateFromInvoice(invoice);

      await Get.toNamed(AppRoutes.INSTANTSALEPRODUCTPICKER);
    } catch (e) {
      clearActiveEditInstantSale();
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: e.toString(),
      );
    } finally {
      isLoading(false);
    }
  }

  void applySuspendedPaymentToController(PaymentController payment) {
    if (_paymentBoxId != null && _paymentBoxId!.isNotEmpty) {
      payment.boxIdController.text = _paymentBoxId!;
      if (_paymentBoxValue != null && _paymentBoxValue!.isNotEmpty) {
        payment.cashValueController.text =
            SalesAmountFormat.display(double.tryParse(_paymentBoxValue!) ?? 0);
      }
    }
    final buyerId = _paymentBuyerId;
    final sellerId = _paymentSellerId;
    if (buyerId != null && buyerId.isNotEmpty) {
      payment.selectedCustomersSellers.value = true;
      payment.partnerIdController.text = buyerId;
    } else if (sellerId != null && sellerId.isNotEmpty) {
      payment.selectedCustomersSellers.value = false;
      payment.partnerIdController.text = sellerId;
    } else if (_paymentBuyerName != null &&
        _paymentBuyerName!.isNotEmpty &&
        _paymentBuyerName != '-') {
      payment.selectedCustomersSellers.value =
          _paymentBuyerType == 'customer' || _paymentBuyerType == 'trader';
    }
    payment.restorePartnerSelectionFromId();
    refreshInstantSalePaymentSummary();
  }

  Future<void> startNewInstantSaleFlow() async {
    clearActiveSuspendedSale();
    clearActiveEditInstantSale();
    resetInstantSaleForm();
    isPackageSale.value = false;
    openInstantSaleProductPicker();
  }

  final RxBool isPackageSale = false.obs;
  final RxnInt selectedPackageId = RxnInt();
  final RxList<OfferPackageModel> offerPackagesForSale =
      <OfferPackageModel>[].obs;

  /// Filled from payment screen (طريقة القبض) after successful receipt.
  String _paymentBuyerType = 'unknown';
  String? _paymentBuyerId;
  String? _paymentSellerId;
  String? _paymentBuyerName;
  String? _paymentBoxId;
  String? _paymentBoxName;
  String? _paymentBoxValue;

  void applyBuyerFromPayment(Map<String, dynamic> result) {
    _paymentBuyerType = result['buyer_type']?.toString() ?? 'unknown';
    final id = result['buyer_id']?.toString();
    _paymentBuyerId = (id != null && id.isNotEmpty) ? id : null;
    final sellerId = result['seller_id']?.toString();
    _paymentSellerId =
        (sellerId != null && sellerId.isNotEmpty) ? sellerId : null;
    final name = result['buyer_name']?.toString();
    _paymentBuyerName = (name != null && name.isNotEmpty) ? name : null;
    final boxId = result['payment_box_id']?.toString();
    _paymentBoxId = (boxId != null && boxId.isNotEmpty) ? boxId : null;
    final boxName = result['payment_box_name']?.toString();
    _paymentBoxName = (boxName != null && boxName.isNotEmpty) ? boxName : null;
    final boxValue = result['payment_box_value']?.toString();
    if (_paymentBoxId != null && _paymentBoxId!.isNotEmpty) {
      _paymentBoxValue =
          (boxValue != null && boxValue.isNotEmpty) ? boxValue : '0';
    } else {
      _paymentBoxValue = null;
    }
    _syncPickerPartnerObservables();
    syncPickerPartnerFromPayment();
  }

  void _syncPickerPartnerObservables() {
    pickerBuyerIdRx.value = _paymentBuyerId;
    pickerSellerIdRx.value = _paymentSellerId;
  }

  void _clearPaymentBuyer() {
    _paymentBuyerType = 'unknown';
    _paymentBuyerId = null;
    _paymentSellerId = null;
    _paymentBuyerName = null;
    _paymentBoxId = null;
    _paymentBoxName = null;
    _paymentBoxValue = null;
    pickerSelectedPartner.value = null;
    _syncPickerPartnerObservables();
  }

  // --- Picker partner (optional buyer at product selection) ---

  final RxBool pickerPartnerIsCustomer = true.obs;
  final Rxn<SellerModel> pickerSelectedPartner = Rxn<SellerModel>();
  final RxnString pickerBuyerIdRx = RxnString();
  final RxnString pickerSellerIdRx = RxnString();
  final RxList<SellerModel> pickerCustomersList = <SellerModel>[].obs;
  final RxList<SellerModel> pickerSellersList = <SellerModel>[].obs;
  final RxBool pickerPartnersLoading = false.obs;

  bool get hasPickerPartner {
    final buyerId = pickerBuyerIdRx.value;
    final sellerId = pickerSellerIdRx.value;
    return (buyerId != null && buyerId.isNotEmpty) ||
        (sellerId != null && sellerId.isNotEmpty);
  }

  bool get hasPaymentSnapshot {
    return hasPickerPartner ||
        (_paymentBuyerName != null &&
            _paymentBuyerName!.isNotEmpty &&
            _paymentBuyerName != '-');
  }

  String? get pickerPersonType {
    if (_paymentSellerId != null && _paymentSellerId!.isNotEmpty) {
      return 'seller';
    }
    if (_paymentBuyerId != null && _paymentBuyerId!.isNotEmpty) {
      return 'customer';
    }
    return null;
  }

  String? get pickerPersonId => _paymentSellerId ?? _paymentBuyerId;

  Future<void> ensurePickerPartnersLoaded() async {
    if (pickerCustomersList.isNotEmpty && pickerSellersList.isNotEmpty) {
      return;
    }
    pickerPartnersLoading(true);
    try {
      final customers = await allCustomersSellersUsecase.call(
        endPoint: EndPoints.all_customers,
      );
      pickerCustomersList.assignAll(customers);
      final sellers = await allCustomersSellersUsecase.call(
        endPoint: EndPoints.all_sellers,
      );
      pickerSellersList.assignAll(sellers);
    } finally {
      pickerPartnersLoading(false);
    }
  }

  void setPickerPartnerTab({required bool isCustomer}) {
    pickerPartnerIsCustomer.value = isCustomer;
    pickerSelectedPartner.value = null;
    _clearPaymentBuyer();
    getAllProducts().then(
      (_) => refreshCartPricesForPartner().then((_) => bumpCartRevision()),
    );
  }

  Future<void> onPickerPartnerSelected(SellerModel? partner) async {
    if (partner == null) {
      await clearPickerPartner();
      return;
    }
    pickerSelectedPartner.value = partner;
    final isCustomer = pickerPartnerIsCustomer.value;
    if (isCustomer) {
      applyBuyerFromPayment({
        'buyer_type': 'customer',
        'buyer_id': partner.id.toString(),
        'buyer_name': partner.name,
      });
    } else {
      applyBuyerFromPayment({
        'buyer_type': 'seller',
        'seller_id': partner.id.toString(),
        'buyer_name': partner.name,
      });
    }
    await getAllProducts();
    await refreshCartPricesForPartner();
    bumpCartRevision();
  }

  Future<void> clearPickerPartner() async {
    pickerSelectedPartner.value = null;
    _clearPaymentBuyer();
    await getAllProducts();
    await refreshCartPricesForPartner();
    bumpCartRevision();
  }

  final RxBool pickerQuickAddLoading = false.obs;

  /// إضافة سريعة لزبون/تاجر من شاشة اختيار الطرف، ثم اختياره مباشرة.
  /// تُعيد true عند النجاح.
  Future<bool> quickAddPartner({
    required String name,
    required String phone,
    required bool isCustomer,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    final formattedPhone =
        phone.trim().isEmpty ? '' : PhoneFormatHelper.forApi(phone);

    pickerQuickAddLoading(true);
    try {
      final datasource = Get.find<GeneralDataListDatasource>();
      final response = await datasource.addPerson(
        data: AddPersonEntity(
          isEdit: false,
          name: trimmedName,
          personType: isCustomer ? 'customer' : 'seller',
          customerCategory: isCustomer ? 'retail' : 'wholesale',
          phone: formattedPhone,
          subPhone: '',
          address: '',
          jobTitle: '',
          facebookUsername: '',
          facebookLink: '',
          instagramUsername: '',
          instagramLink: '',
          relatedPeople: '',
          relativePhone: '',
          relativeJobTitle: '',
          workAddress: '',
          iDImage: const [],
          licenseImage: const [],
        ),
        customerId: '',
        sellerId: '',
      );

      if (response is Map && response['status'] == 'success') {
        final newId = isCustomer
            ? (response['customer_id'] as num?)?.toInt()
            : (response['seller_id'] as num?)?.toInt();
        if (newId == null) {
          _showQuickAddError('tryAgain'.tr);
          return false;
        }

        final model = SellerModel(
          id: newId,
          name: trimmedName,
          phone: formattedPhone,
        );
        pickerPartnerIsCustomer.value = isCustomer;
        if (isCustomer) {
          pickerCustomersList.insert(0, model);
        } else {
          pickerSellersList.insert(0, model);
        }
        await onPickerPartnerSelected(model);

        Get.snackbar(
          'success'.tr,
          response['message']?.toString() ?? 'success'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return true;
      }

      _showQuickAddError(_extractQuickAddError(response));
      return false;
    } on ServerException catch (e) {
      _showQuickAddError(e.errorModel.errorMessage);
      return false;
    } catch (_) {
      _showQuickAddError('tryAgain'.tr);
      return false;
    } finally {
      pickerQuickAddLoading(false);
    }
  }

  String _extractQuickAddError(dynamic response) {
    if (response is Map) {
      final errors = response['errors'];
      if (errors is Map) {
        final buffer = StringBuffer();
        errors.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            buffer.writeln('- ${value.first}');
          }
        });
        final text = buffer.toString().trim();
        if (text.isNotEmpty) return text;
      }
      final message = response['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return 'tryAgain'.tr;
  }

  void _showQuickAddError(String message) {
    Get.snackbar(
      'error'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void syncPickerPartnerFromPayment() {
    if (_paymentSellerId != null && _paymentSellerId!.isNotEmpty) {
      pickerPartnerIsCustomer.value = false;
      final match = pickerSellersList.firstWhereOrNull(
        (e) => e.id.toString() == _paymentSellerId,
      );
      pickerSelectedPartner.value = match;
      _syncPickerPartnerObservables();
      return;
    }
    if (_paymentBuyerId != null && _paymentBuyerId!.isNotEmpty) {
      pickerPartnerIsCustomer.value = true;
      final match = pickerCustomersList.firstWhereOrNull(
        (e) => e.id.toString() == _paymentBuyerId,
      );
      pickerSelectedPartner.value = match;
      _syncPickerPartnerObservables();
      return;
    }
    pickerSelectedPartner.value = null;
    _syncPickerPartnerObservables();
  }

  void resolvePartnerFromOrderSnapshot({
    int? customerId,
    String? name,
    String? phone,
  }) {
    SellerModel? match;

    if (customerId != null) {
      pickerPartnerIsCustomer.value = true;
      match = pickerCustomersList.firstWhereOrNull((e) => e.id == customerId);
    }

    final normalizedPhone = _normalizePhone(phone);
    if (match == null && normalizedPhone.isNotEmpty) {
      match = pickerCustomersList.firstWhereOrNull(
        (e) => _normalizePhone(e.phone) == normalizedPhone,
      );
      match ??= pickerSellersList.firstWhereOrNull(
        (e) => _normalizePhone(e.phone) == normalizedPhone,
      );
    }

    final trimmedName = name?.trim() ?? '';
    if (match == null && trimmedName.isNotEmpty) {
      match = pickerCustomersList.firstWhereOrNull(
        (e) => e.name.trim() == trimmedName,
      );
      match ??= pickerSellersList.firstWhereOrNull(
        (e) => e.name.trim() == trimmedName,
      );
    }

    if (match == null) return;

    final isCustomer = pickerCustomersList.any((e) => e.id == match!.id);
    pickerPartnerIsCustomer.value = isCustomer;
    pickerSelectedPartner.value = match;
    if (isCustomer) {
      _paymentBuyerType = 'customer';
      _paymentBuyerId = match.id.toString();
      _paymentSellerId = null;
    } else {
      _paymentBuyerType = 'seller';
      _paymentSellerId = match.id.toString();
      _paymentBuyerId = null;
    }
    _paymentBuyerName = match.name;
    _syncPickerPartnerObservables();
  }

  String _normalizePhone(String? phone) {
    if (phone == null) return '';
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  Future<CustomerProductPriceHistory?> fetchLinePriceHistory({
    required String productId,
    String? sizeColorId,
    int limit = 5,
  }) async {
    try {
      if (hasPickerPartner) {
        return await getCustomerProductPriceHistoryUsecase.call(
          personType: pickerPersonType,
          personId: pickerPersonId,
          productId: productId,
          sizeColorId: sizeColorId,
          limit: limit,
        );
      }
      return await getCustomerProductPriceHistoryUsecase.call(
        productId: productId,
        sizeColorId: sizeColorId,
        limit: limit,
      );
    } catch (_) {
      return null;
    }
  }

  bool get isWholesalePartner =>
      hasPickerPartner && pickerPersonType == 'seller';

  double catalogUnitPriceForProduct(
    ProductModel product, {
    double? variantRetailPrice,
    double? variantWholesalePrice,
  }) {
    if (product.hasCustomPrice &&
        product.customPrice != null &&
        product.customPrice! > 0) {
      return product.customPrice!;
    }
    if (isWholesalePartner) {
      final wholesale =
          (variantWholesalePrice != null && variantWholesalePrice > 0)
              ? variantWholesalePrice
              : product.wholesalePrice;
      return wholesale > 0 ? wholesale : 0;
    }
    final retail = (variantRetailPrice != null && variantRetailPrice > 0)
        ? variantRetailPrice
        : product.unitPrice;
    return retail > 0 ? retail : 0;
  }

  String displayPriceLabelForProduct(
    ProductModel product, {
    String? cartLinePrice,
    double? variantRetailPrice,
    double? variantWholesalePrice,
  }) {
    if (cartLinePrice != null && cartLinePrice.trim().isNotEmpty) {
      final parsed = SalesAmountFormat.parse(cartLinePrice);
      if (parsed > 0) return SalesAmountFormat.displayShekel(parsed);
    }
    final unit = catalogUnitPriceForProduct(
      product,
      variantRetailPrice: variantRetailPrice,
      variantWholesalePrice: variantWholesalePrice,
    );
    if (unit > 0) return SalesAmountFormat.displayShekel(unit);
    return isWholesalePartner
        ? 'instantSaleNoWholesalePrice'.tr
        : 'instantSaleNoRetailPrice'.tr;
  }

  double? variantRetailPriceForLine({
    required ProductModel product,
    String? sizeColorId,
  }) {
    if (sizeColorId == null || sizeColorId.isEmpty) return null;
    for (final size in product.sizes) {
      for (final color in size.colorSizes) {
        if (color.id == sizeColorId) return color.normailPrice;
      }
    }
    return null;
  }

  double? variantWholesalePriceForLine({
    required ProductModel product,
    String? sizeColorId,
  }) {
    if (sizeColorId == null || sizeColorId.isEmpty) return null;
    for (final size in product.sizes) {
      for (final color in size.colorSizes) {
        if (color.id == sizeColorId) return color.wholesalePrice;
      }
    }
    return null;
  }

  Future<void> refreshCartPricesForPartner() async {
    if (cartLines.isEmpty) return;
    for (final line in cartLines) {
      if (line.isDisposed) continue;
      final product = productById(line.productId);
      if (product == null) continue;
      final price = await resolveDefaultUnitPrice(
        product,
        sizeColorId: line.sizeColorId,
        variantRetailPrice: variantRetailPriceForLine(
          product: product,
          sizeColorId: line.sizeColorId,
        ),
        variantWholesalePrice: variantWholesalePriceForLine(
          product: product,
          sizeColorId: line.sizeColorId,
        ),
      );
      if (price != null && price.isNotEmpty) {
        line.priceController.text = price;
        line.recalculateTotal();
      }
    }
    calculateGrandTotal();
    syncCartToItems();
    bumpCartRevision();
  }

  Future<void> promptProductQuantity(
    BuildContext context,
    ProductModel product,
  ) async {
    if (product.hasVariants && product.sizes.isNotEmpty) return;

    final resolved = productById(product.id) ?? product;
    final stock = int.tryParse(resolved.stock) ?? 0;
    if (stock < 1) {
      Get.snackbar('error'.tr, 'out_of_stock_products'.tr,
          backgroundColor: Colors.red);
      return;
    }

    final idx = cartLines.indexWhere((l) => l.productId == product.id);
    final current =
        idx >= 0 ? (int.tryParse(cartLines[idx].quantityText) ?? 1) : 1;

    final result = await showInstantSaleQuantityDialog(
      context,
      initialQuantity: current,
      maxQuantity: stock,
      stockHint:
          SalesOrderStockContext.controller?.stockHintForProduct(resolved.id),
    );
    if (result == null) return;

    if (!await _confirmSalesOrderReservedStock(
      product: resolved,
      requestedQty: result,
    )) {
      return;
    }

    if (idx < 0) {
      final priced = await ensureProductPricesForPicker(resolved);
      if (priced == null) return;

      final unitPrice = await resolveDefaultUnitPrice(priced);
      addCartLine(
        InstantSaleCartLine.fromProduct(
          priced,
          quantity: result.toString(),
          unitPrice: unitPrice,
        ),
      );
      bumpCartRevision();
      return;
    }

    setCartLineQuantity(idx, result);
  }

  void setProductCartQuantity(String productId, int qty) {
    final idx = cartLines.indexWhere((l) => l.productId == productId);
    if (idx < 0) return;
    setCartLineQuantity(idx, qty);
  }

  Future<String?> resolveDefaultUnitPrice(
    ProductModel product, {
    String? sizeColorId,
    double? variantRetailPrice,
    double? variantWholesalePrice,
  }) async {
    final hasPartner = hasPickerPartner;
    final isSeller = hasPartner && pickerPersonType == 'seller';

    if (!hasPartner) {
      if (product.unitPrice > 0) return _formatUnitPrice(product.unitPrice);
      return null;
    }

    if (product.hasCustomPrice &&
        product.customPrice != null &&
        product.customPrice! > 0) {
      return _formatUnitPrice(product.customPrice!);
    }

    try {
      final history = await fetchLinePriceHistory(
        productId: product.id,
        sizeColorId: sizeColorId,
        limit: 1,
      );
      final last = history?.lastPrice;
      if (last != null && last > 0) {
        return _formatUnitPrice(last);
      }
    } catch (_) {
      // fall through to catalog price
    }

    if (isSeller) {
      final wholesale =
          (variantWholesalePrice != null && variantWholesalePrice > 0)
              ? variantWholesalePrice
              : product.wholesalePrice;
      if (wholesale > 0) return _formatUnitPrice(wholesale);
      return null;
    } else {
      final retail = (variantRetailPrice != null && variantRetailPrice > 0)
          ? variantRetailPrice
          : product.unitPrice;
      if (retail > 0) return _formatUnitPrice(retail);
      return null;
    }
  }

  void resetInstantSaleForm({bool renewFormKey = true}) {
    noteController.clear();
    clearInstantSaleNotes(dispose: false);
    totalCostController.clear();
    discountController.clear();
    totalController.clear();
    isPackageSale.value = false;
    selectedPackageId.value = null;
    packageLineTotal.value = 0;
    clearPickerLocationFilterOnReset();
    clearCartLines(deferDispose: false);
    for (final e in items) {
      e.quantityController.clear();
      e.priceController.clear();
      e.selectedItem.value = '';
    }
    while (items.length > 1) {
      items.removeLast();
    }
    totalCost.value = 0.0;
    instantSalePaidAmount.value = 0;
    pickerPartnerIsCustomer.value = true;
    _clearPaymentBuyer();
    if (renewFormKey) {
      _renewInstantSaleFormKey();
    }
    bumpCartRevision();
  }

  void clearCartLines({bool deferDispose = true}) {
    final oldLines = List<InstantSaleCartLine>.from(cartLines);
    cartLines.clear();
    bumpCartRevision();

    void disposeLines() {
      for (final line in oldLines) {
        line.dispose();
      }
    }

    if (deferDispose) {
      WidgetsBinding.instance.addPostFrameCallback((_) => disposeLines());
    } else {
      disposeLines();
    }
  }

  void addCartLine(InstantSaleCartLine line) {
    cartLines.add(line);
    calculateGrandTotal();
    bumpCartRevision();
  }

  void setCartLinePrice(int index, String price) {
    if (index < 0 || index >= cartLines.length) return;
    final line = cartLines[index];
    line.priceController.text = price;
    line.recalculateTotal();
    calculateGrandTotal();
    syncCartToItems();
    bumpCartRevision();
  }

  void applyHistoricalPriceToCartLine(int index, double price) {
    setCartLinePrice(index, _formatUnitPrice(price));
  }

  void updateCartLine(int index, InstantSaleCartLine line) {
    if (index < 0 || index >= cartLines.length) return;
    final old = cartLines[index];
    cartLines[index] = line;
    calculateGrandTotal();
    bumpCartRevision();
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  void removeCartLine(int index) {
    if (index < 0 || index >= cartLines.length) return;
    final old = cartLines.removeAt(index);
    calculateGrandTotal();
    bumpCartRevision();
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  void syncCartToItems() {
    while (items.length > 1) {
      items.removeLast();
    }
    if (cartLines.isEmpty) {
      items.first.selectedItem.value = '';
      items.first.quantityController.clear();
      items.first.priceController.clear();
      return;
    }
    for (var i = 0; i < cartLines.length; i++) {
      final line = cartLines[i];
      final ItemModel item;
      if (i == 0) {
        item = items.first;
      } else {
        item = ItemModel();
        items.add(item);
      }
      item.selectedItem.value = line.productId;
      item.quantityController.text = line.quantityText;
      item.priceController.text = line.priceText;
      item.selectedCustomersSellers.value = line.isProjectSale.value;
      item.selectedValue.value = line.projectId.value;
      item.recalculateTotal();
    }
  }

  PaymentController? get _instantSalePayment {
    if (!Get.isRegistered<PaymentController>(tag: kInstantSalePaymentTag)) {
      return null;
    }
    return Get.find<PaymentController>(tag: kInstantSalePaymentTag);
  }

  static void _releaseInstantSalePaymentController() {
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (Get.isRegistered<PaymentController>(tag: kInstantSalePaymentTag)) {
        Get.delete<PaymentController>(tag: kInstantSalePaymentTag);
      }
    });
  }

  /// إغلاق شاشة الدفع ثم اختيار المنتجات قبل تفريغ السلة (تجنّب disposed controllers).
  Future<void> _leaveInstantSaleFlow() async {
    const saleRoutes = {
      AppRoutes.NEWINSTANTSALESCREEN,
      AppRoutes.INSTANTSALEPRODUCTPICKER,
    };
    var guard = 0;
    while (guard < 4 && saleRoutes.contains(Get.currentRoute)) {
      Get.back();
      guard++;
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
  }

  /// يملأ المبلغ النقدي من الإجمالي فقط إذا الحقل فارغ (لا يمسح صفراً أدخله المستخدم).
  void refreshInstantSalePaymentSummary() {
    final payment = _instantSalePayment;
    if (payment == null) {
      instantSalePaidAmount.value = 0;
      return;
    }
    final raw = payment.cashValueController.text
        .replaceAll(',', '')
        .replaceAll('،', '')
        .trim();
    instantSalePaidAmount.value = double.tryParse(raw) ?? 0;
  }

  /// Same as [refreshInstantSalePaymentSummary] but for flows using a custom payment controller tag
  /// (e.g. sales orders checkout uses `kSalesOrderPaymentTag`).
  void refreshInstantSalePaymentSummaryForTag(String paymentTag) {
    if (!Get.isRegistered<PaymentController>(tag: paymentTag)) {
      instantSalePaidAmount.value = 0;
      return;
    }
    final payment = Get.find<PaymentController>(tag: paymentTag);
    final raw = payment.cashValueController.text
        .replaceAll(',', '')
        .replaceAll('،', '')
        .trim();
    instantSalePaidAmount.value = double.tryParse(raw) ?? 0;
  }

  void syncPaymentCashFromTotal({bool onlyIfCashEmpty = false}) {
    final payment = _instantSalePayment;
    if (payment == null) return;

    final current = payment.cashValueController.text
        .replaceAll(',', '')
        .replaceAll('،', '')
        .trim();
    if (onlyIfCashEmpty && current.isNotEmpty) {
      payment.instantSaleBoxLogNote = buildInstantSalePaymentBoxNote();
      refreshInstantSalePaymentSummary();
      return;
    }

    payment.cashValueController.text =
        SalesAmountFormat.display(totalCost.value);
    payment.instantSaleBoxLogNote = buildInstantSalePaymentBoxNote();
    refreshInstantSalePaymentSummary();
  }

  /// Single step: قبض then create instant sale.
  Future<void> submitInstantSaleWithPayment(BuildContext context) async {
    _instantSaleDebug('submit with payment requested', {
      'hasPackage': hasSelectedPackage,
      'cartLines': cartLines.length,
      'items': items.length,
      'activeSuspendedSaleId': activeSuspendedSaleId.value,
      'activeEditInstantSaleId': activeEditInstantSaleId.value,
      'totalCost': totalCost.value,
    });
    if (!(instantSaleFormKey.currentState?.validate() ?? false)) return;

    final hasPackage = hasSelectedPackage;
    final hasProducts = cartLines.isNotEmpty;

    if (!hasPackage && !hasProducts) {
      Get.snackbar('error'.tr, 'instantSaleCartEmpty'.tr,
          backgroundColor: Colors.red);
      return;
    }

    if (hasPackage) {
      final qtyError = validatePackageSaleQuantity(
        items.first.quantityController.text,
      );
      if (qtyError != null) {
        Get.snackbar('error'.tr, qtyError, backgroundColor: Colors.red);
        return;
      }
    }

    if (hasProducts) {
      for (final line in cartLines) {
        final qty = int.tryParse(line.quantityText) ?? 0;
        if (qty > line.stock) {
          Get.snackbar('error'.tr, 'out_of_stock_products'.tr,
              backgroundColor: Colors.red);
          return;
        }
      }
      if (!hasPackage) {
        syncCartToItems();
      }
    }

    if (!await ensureInstantSaleCanBeFinalized()) return;

    final payment = _instantSalePayment;
    if (payment == null) return;

    payment.instantSaleBoxLogNote = buildInstantSalePaymentBoxNote();

    isLoading(true);
    try {
      if (activeSuspendedSaleId.value != null) {
        final buyer = payment.buildInstantSaleBuyerPayload();
        _instantSaleDebug(
            'suspended payment payload without pre-receive', buyer);
        applyBuyerFromPayment(buyer);
        // ignore: use_build_context_synchronously
        await addInstantSale(context, previousDayWarningConfirmed: true);
        return;
      }

      final buyer = await payment.submitReceiveForInstantSale(context);
      _instantSaleDebug('payment result', buyer);
      if (buyer == null) return;

      applyBuyerFromPayment(buyer);
      // ignore: use_build_context_synchronously
      await addInstantSale(context, previousDayWarningConfirmed: true);
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadOfferPackagesForSale() async {
    try {
      final ds = Get.find<SalesDatasource>();
      final list = await ds.getOfferPackagesForSale();
      offerPackagesForSale.assignAll(list);
      _syncSelectedOfferPackageAfterReload(list);
    } catch (_) {
      offerPackagesForSale.clear();
    }
  }

  /// تحديث شاشة إدارة الباكيجات إن كانت مفتوحة في الذاكرة.
  Future<void> refreshOfferPackagesInventoryIfOpen() async {
    if (Get.isRegistered<OfferPackagesController>()) {
      await Get.find<OfferPackagesController>().loadPackages();
    }
  }

  void _syncSelectedOfferPackageAfterReload(List<OfferPackageModel> list) {
    final selectedId = selectedPackageId.value;
    if (selectedId == null) {
      return;
    }

    final pkg = list.firstWhereOrNull((p) => p.id == selectedId);
    if (pkg == null) {
      selectedPackageId.value = null;
      items.first.priceController.clear();
      items.first.quantityController.text = '1';
    } else {
      items.first.priceController.text = _formatUnitPrice(pkg.price);
    }
    calculateGrandTotal();
  }

  void setPackageSaleMode(bool value) {
    isPackageSale.value = value;
    if (value) {
      while (items.length > 1) {
        items.removeLast();
      }
      items.first.selectedItem.value = '';
      loadOfferPackagesForSale();
    } else {
      selectedPackageId.value = null;
    }
    calculateGrandTotal();
  }

  OfferPackageModel? get selectedOfferPackage => offerPackagesForSale
      .firstWhereOrNull((p) => p.id == selectedPackageId.value);

  void onOfferPackageSelected(OfferPackageModel? pkg) {
    if (pkg == null) {
      selectedPackageId.value = null;
      items.first.priceController.clear();
      items.first.quantityController.text = '1';
      calculateGrandTotal();
      return;
    }
    selectedPackageId.value = pkg.id;
    items.first.priceController.text = _formatUnitPrice(pkg.price);
    items.first.quantityController.text = '1';
    calculateGrandTotal();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      instantSaleFormKey.currentState?.validate();
    });
  }

  String _formatUnitPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2);
  }

  /// رسالة تحقق واضحة لكمية بيع الباكيج (تُستخدم في نموذج البيع الفوري).
  String? validatePackageSaleQuantity(String? value) {
    final pkg = selectedOfferPackage;
    if (pkg == null) {
      return 'packageSelectFirst'.tr;
    }

    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return 'packageSaleQtyRequired'.tr;
    }

    final qty = int.tryParse(raw);
    if (qty == null) {
      return 'packageSaleQtyInvalid'.tr;
    }
    if (qty < 1) {
      return 'packageSaleQtyRequired'.tr;
    }

    final max = pkg.maxSellableQuantity;
    if (max < 1) {
      return 'packageNotAvailableForSale'.tr;
    }
    if (qty > max) {
      return 'packageQtyExceedsAvailable'.trParams({
        'qty': '$qty',
        'max': '$max',
      });
    }
    return null;
  }

  String? packageSaleQuantityHelperText() {
    final pkg = selectedOfferPackage;
    if (pkg == null) {
      return null;
    }
    final max = pkg.maxSellableQuantity;
    if (max < 1) {
      return 'packageNotAvailableForSale'.tr;
    }
    return 'packageSaleMaxAvailable'.trParams({'max': '$max'});
  }

  void addItem() {
    ItemModel newItem = ItemModel();
    newItem.total.listen((_) => calculateGrandTotal());
    items.add(newItem);
    listKey.currentState?.insertItem(
      items.length - 1,
      duration: const Duration(milliseconds: 300),
    );
  }

  void removeItem(int index) {
    if (items.length > 1) {
      items.removeAt(index);
    }
    calculateGrandTotal();
  }

  final RxDouble totalCost = 0.0.obs;
  final RxDouble instantSalePaidAmount = 0.0.obs;

  double get instantSaleRemainingAmount =>
      (totalCost.value - instantSalePaidAmount.value).clamp(0, double.infinity);
  final RxDouble packageLineTotal = 0.0.obs;

  void calculateGrandTotal() {
    double total = 0;

    if (hasSelectedPackage) {
      final pkg = selectedOfferPackage;
      final unitPrice = pkg?.price ??
          SalesAmountFormat.parse(items.first.priceController.text);
      final qty = SalesAmountFormat.parse(items.first.quantityController.text);
      final lineTotal = unitPrice * qty;
      packageLineTotal.value = lineTotal;
      items.first.syncLineTotal(lineTotal);
      total += lineTotal;
    } else {
      packageLineTotal.value = 0;
    }

    if (cartLines.isNotEmpty) {
      for (final line in cartLines) {
        total += line.lineTotal.value;
      }
    } else if (!hasSelectedPackage) {
      for (final item in items) {
        total += item.total.value;
      }
    }
    final discount = SalesAmountFormat.parse(discountController.text);

    totalCost.value = total - discount + instantSaleNotesTotal;
    if (totalCost.value < 0) totalCost.value = 0;
    totalController.text = SalesAmountFormat.display(totalCost.value);
    syncPaymentCashFromTotal();
    refreshInstantSalePaymentSummary();
  }

  // متغير للتحكم في قائمة الإضافة
  final RxBool isAddMenuOpen = false.obs;

  late AnimationController animController;
  late Animation<double> opacityAnimation;
  late Animation<double> sizeAnimation;

  void toggleAddMenu() {
    isAddMenuOpen.value = !isAddMenuOpen.value;
  }

  List<Map<String, String>> addList = [
    {
      'title': 'newInstantSale',
      'icon': AssetsManager.invoiceIcon,
      'route': AppRoutes.INSTANTSALEPRODUCTPICKER,
      'freshInstantSale': 'true',
    },
    {
      'title': 'salesOrderNew',
      'icon': AssetsManager.invoiceIcon,
      'route': AppRoutes.NEWSALESORDERSCREEN,
      'freshSalesOrder': 'true',
    },
    {
      'title': 'newCashProfit',
      'icon': AssetsManager.moneyIcon,
      'route': AppRoutes.NEWCASHPROFITSCREEN,
    },
  ];

  // add profit sale
  Future<bool> addProfitSale(
    BuildContext context, {
    Map<String, dynamic>? paymentPayload,
    bool previousDayWarningConfirmed = false,
  }) async {
    if (formKey.currentState!.validate()) {
      if (!previousDayWarningConfirmed &&
          !await confirmPreviousDaySaleIfNeeded()) {
        return false;
      }
      isLoading(true);
      final result = await addProfitSaleUsecase.call(
        notes: noteController.text,
        totalCost: totalCostController.text,
        buyerType: paymentPayload?['buyer_type']?.toString(),
        buyerId: paymentPayload?['buyer_id']?.toString(),
        sellerId: paymentPayload?['seller_id']?.toString(),
        buyerName: paymentPayload?['buyer_name']?.toString(),
        paymentBoxId: paymentPayload?['payment_box_id']?.toString(),
        paymentBoxName: paymentPayload?['payment_box_name']?.toString(),
        paymentBoxValue: paymentPayload?['payment_box_value']?.toString(),
        image: profitSaleImage.value,
        video: profitSaleVideo.value,
      );
      final saved = await result.fold<Future<bool>>(
        (failure) {
          String errorMessages = '';
          bool permissionsAdded = false;
          final errors = failure.data?['errors'] as Map<String, dynamic>?;
          if (errors != null) {
            errors.forEach((key, value) {
              if (key.startsWith('permissions')) {
                if (!permissionsAdded) {
                  errorMessages += "Permissions: ${value.first}\n";
                  permissionsAdded = true;
                }
              } else {
                for (var msg in value) {
                  errorMessages += "- $key: $msg\n";
                }
              }
            });
          } else {
            errorMessages = failure.data?['message'] ?? failure.errMessage;
          }
          final serverError = failure.data?['error']?.toString();
          if (serverError != null && serverError.trim().isNotEmpty) {
            errorMessages += '\n$serverError';
          }
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: errorMessages,
          );
          return Future.value(false);
        },
        (success) async {
          noteController.clear();
          totalCostController.clear();
          profitSaleImage.value = null;
          profitSaleVideo.value = null;
          await refreshAllSalesData(showLoading: true);
          if (Get.currentRoute == AppRoutes.NEWCASHPROFITSCREEN) {
            Get.back();
          }
          Helpers.showCustomDialogSuccess(
            context: Get.context ?? context,
            title: 'success'.tr,
            message: success,
          );
          return true;
        },
      );
      isLoading(false);
      return saved;
    }
    isLoading(false);
    return false;
  }

  Future<bool> submitProfitSaleWithPayment(BuildContext context) async {
    if (!(formKey.currentState?.validate() ?? false)) return false;
    if (!await confirmPreviousDaySaleIfNeeded()) return false;
    if (!Get.isRegistered<PaymentController>(tag: kProfitSalePaymentTag)) {
      return false;
    }

    final payment = Get.find<PaymentController>(tag: kProfitSalePaymentTag);
    final total = SalesAmountFormat.parse(totalCostController.text);
    final paidAmount =
        SalesAmountFormat.parse(payment.cashValueController.text);
    if (paidAmount > total + 0.0001) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'instantSalePaidExceedsTotal'.tr,
      );
      return false;
    }
    payment.instantSaleBoxLogNote =
        'قبض بيع ربحي بقيمة ${totalCostController.text}';

    isLoading(true);
    try {
      final paymentPayload = payment.buildOptionalProfitSalePayload();
      final saved = await addProfitSale(
        context,
        paymentPayload: paymentPayload,
        previousDayWarningConfirmed: true,
      );
      if (saved) {
        payment.clearPaymentForm();
      }
      return saved;
    } finally {
      isLoading(false);
    }
  }

  Future<void> completeActiveSuspendedInstantSale(BuildContext context) async {
    final suspendedId = activeSuspendedSaleId.value;
    if (suspendedId == null) return;

    isLoading(true);
    try {
      final payload = buildInstantSaleSuspendPayload();
      _instantSaleDebug('complete suspended requested', {
        'suspendedId': suspendedId,
        'payloadKeys': payload.keys.toList(),
        'productId': payload['product_id'],
        'offerPackageId': payload['offer_package_id'],
        'quantity': payload['quantity'],
        'totalCost': payload['total_cost'],
        'buyerType': payload['buyer_type'],
        'buyerId': payload['buyer_id'],
        'sellerId': payload['seller_id'],
        'paymentBoxId': payload['payment_box_id'],
      });
      final result =
          await Get.find<SalesImplement>().completeSuspendedInstantSale(
        suspendedInstantSaleId: suspendedId,
        payload: payload,
      );

      await result.fold(
        (failure) async {
          _instantSaleDebug('complete suspended failed', {
            'message': failure.errMessage,
            'data': failure.data,
          });
          String errorMessages = failure.errMessage;
          final errors = failure.data?['errors'] as Map<String, dynamic>?;
          if (errors != null) {
            errors.forEach((key, value) {
              for (final msg in value) {
                errorMessages += '\n- $key: $msg';
              }
            });
          }
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: errorMessages,
          );
        },
        (success) async {
          _instantSaleDebug('complete suspended success', success);
          FocusManager.instance.primaryFocus?.unfocus();

          while (Get.isBottomSheetOpen == true) {
            Get.back();
          }

          await _leaveInstantSaleFlow();
          await Future<void>.delayed(const Duration(milliseconds: 350));
          await clearLocalInstantSaleDraft();

          if (!isClosed) {
            _instantSalePayment?.clearPaymentForm();
            _releaseInstantSalePaymentController();
            clearActiveSuspendedSale();
            resetInstantSaleForm();
          }

          await loadSuspendedInvoicesCount();
          await refreshAllSalesData(showLoading: false);

          if (!isClosed) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (isClosed) return;
              await loadOfferPackagesForSale();
              getAllProducts();
              final dialogContext = Get.overlayContext ?? Get.context;
              if (dialogContext != null && dialogContext.mounted) {
                Helpers.showCustomDialogSuccess(
                  context: dialogContext,
                  title: 'success'.tr,
                  message: success,
                );
              }
            });
          }
        },
      );
    } finally {
      isLoading(false);
    }
  }

  // add instant sale
  Future<void> addInstantSale(
    BuildContext context, {
    bool previousDayWarningConfirmed = false,
  }) async {
    if (!previousDayWarningConfirmed &&
        !await confirmPreviousDaySaleIfNeeded()) {
      return;
    }

    if (activeSuspendedSaleId.value != null) {
      _instantSaleDebug('addInstantSale redirected to complete suspended', {
        'activeSuspendedSaleId': activeSuspendedSaleId.value,
      });
      await completeActiveSuspendedInstantSale(context);
      return;
    }

    isLoading(true);
    try {
      final cartPayload = cartLines.isNotEmpty
          ? buildCartOtherProductsPayload()
          : (hasSelectedPackage ? buildCartOtherProductsPayload() : null);
      _instantSaleDebug('add instant sale requested', {
        'mode': activeEditInstantSaleId.value == null ? 'create' : 'edit',
        'activeEditInstantSaleId': activeEditInstantSaleId.value,
        'hasPackage': isPackageSale.value,
        'selectedPackageId': selectedPackageId.value,
        'productId': isPackageSale.value
            ? ''
            : items.first.selectedItem.value.toString(),
        'quantity': items.first.quantityController.text,
        'cost': items.first.priceController.text,
        'discount':
            discountController.text.isEmpty ? '0' : discountController.text,
        'totalCost': totalCost.value.toString(),
        'type':
            items.first.selectedCustomersSellers.value ? 'project' : 'normal',
        'projectId': items.first.selectedCustomersSellers.value
            ? items.first.selectedValue.value
            : '',
        'buyerType': _paymentBuyerType,
        'buyerId': _paymentBuyerId,
        'sellerId': _paymentSellerId,
        'buyerName': _paymentBuyerName,
        'paymentBoxId': _paymentBoxId,
        'paymentBoxValue': _paymentBoxValue,
        'cartPayloadCount': cartPayload?.length ?? 0,
        'itemsCount': items.length,
        'notesLength': instantSaleNotesText.length,
        'additionalNotesCount': instantSaleNotes.length,
      });
      final result = await addInstantSalesUsecase.call(
        productId: isPackageSale.value
            ? ''
            : items.first.selectedItem.value.toString(),
        quantity: items.first.quantityController.text,
        cost: items.first.priceController.text,
        discount:
            discountController.text.isEmpty ? '0' : discountController.text,
        totalCost: totalCost.value.toString(),
        note: instantSaleNotesText,
        additionalNotes: instantSaleNotesPayload(),
        type: items.first.selectedCustomersSellers.value ? 'project' : 'normal',
        projectId: items.first.selectedCustomersSellers.value
            ? items.first.selectedValue.value!
            : '',
        otherProducts: hasSelectedPackage ? RxList<ItemModel>() : items,
        cartOtherProducts: cartPayload,
        buyerType: _paymentBuyerType,
        buyerId: _paymentBuyerId,
        sellerId: _paymentSellerId,
        buyerName: _paymentBuyerName,
        paymentBoxId: _paymentBoxId,
        paymentBoxName: _paymentBoxName,
        paymentBoxValue: _paymentBoxValue,
        offerPackageId:
            isPackageSale.value ? selectedPackageId.value?.toString() : null,
        instantSaleId: activeEditInstantSaleId.value?.toString(),
      );
      await result.fold(
        (failure) async {
          _instantSaleDebug('add instant sale failed', {
            'message': failure.errMessage,
            'data': failure.data,
          });
          String errorMessages = '';
          bool permissionsAdded = false;
          final errors = failure.data?['errors'] as Map<String, dynamic>?;
          if (errors != null) {
            errors.forEach(
              (key, value) {
                if (key.startsWith('permissions')) {
                  if (!permissionsAdded) {
                    errorMessages += "Permissions: ${value.first}\n";
                    permissionsAdded = true;
                  }
                } else {
                  for (var msg in value) {
                    errorMessages += "- $key: $msg\n";
                  }
                }
              },
            );
          } else {
            errorMessages = failure.data?['message'] ?? failure.errMessage;
          }
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: errorMessages,
          );
        },
        (success) async {
          _instantSaleDebug('add instant sale success', success);
          FocusManager.instance.primaryFocus?.unfocus();

          while (Get.isBottomSheetOpen == true) {
            Get.back();
          }

          await _leaveInstantSaleFlow();
          await Future<void>.delayed(const Duration(milliseconds: 350));
          await clearLocalInstantSaleDraft();

          if (!isClosed) {
            _instantSalePayment?.clearPaymentForm();
            _releaseInstantSalePaymentController();
            clearActiveEditInstantSale();
            isPackageSale.value = false;
            selectedPackageId.value = null;
            packageLineTotal.value = 0;
            bumpCartRevision();
          }

          await refreshAllSalesData(showLoading: false);

          if (!isClosed) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (isClosed) return;
              await loadOfferPackagesForSale();
              getAllProducts();
              final dialogContext = Get.overlayContext ?? Get.context;
              if (dialogContext != null && dialogContext.mounted) {
                Helpers.showCustomDialogSuccess(
                  context: dialogContext,
                  title: 'success'.tr,
                  message: 'operationCompletedSuccessfully'.tr,
                );
              }
            });
          }
        },
      );
    } finally {
      isLoading(false);
    }
  }

  // get profit sales
  void getProfitSales({bool loding = false}) {
    fetchProfitSales(clearCache: false, showLoading: loding);
  }

  /// Reload instant + profit sales (after create / edit / cancel or pull-to-refresh).
  Future<void> refreshAllSalesData({bool showLoading = false}) async {
    await Future.wait([
      fetchInstantSales(clearCache: true, showLoading: showLoading),
      fetchProfitSales(clearCache: true, showLoading: showLoading),
      loadOfferPackagesForSale(),
      refreshOfferPackagesInventoryIfOpen(),
      loadDailySession(),
      loadSuspendedInvoicesCount(),
    ]);
    notifySalesListChanged();
  }

  Future<void> refreshSales() => refreshAllSalesData(showLoading: false);

  Future<void> fetchInstantSales({
    bool clearCache = true,
    bool showLoading = false,
  }) async {
    if (clearCache) {
      salesService.instantSalesTasks.clear();
      salesService.filterInstantSalesTasks.clear();
    }
    final shouldShowLoader =
        showLoading || salesService.instantSalesTasks.isEmpty;
    if (shouldShowLoader) {
      isLoading(true);
    }
    try {
      final sales = await getInstantSalesUsecase.call(
        search: instantSalesSearchQuery.value.trim().isEmpty
            ? null
            : instantSalesSearchQuery.value.trim(),
        sortDirection: instantSalesSortDirection,
      );
      if (clearCache) {
        salesService.instantSalesTasks.clear();
      }
      _groupInstantSalesIntoMaps(sales);
    } catch (e) {
      // Background list load — must not crash handover or other flows.
      assert(() {
        debugPrint('[SalesController.fetchInstantSales] $e');
        return true;
      }());
    } finally {
      if (shouldShowLoader) {
        isLoading(false);
      }
    }
  }

  Future<void> fetchProfitSales({
    bool clearCache = true,
    bool showLoading = false,
  }) async {
    if (clearCache) {
      salesService.profitSalesTasks.clear();
      salesService.filterProfitSalesTasks.clear();
    }
    if (showLoading) {
      isLoading(true);
    }
    try {
      final list = await getProfitSalesUsecase.call();
      if (clearCache) {
        salesService.profitSalesTasks.clear();
      }
      for (final profitSale in list) {
        final dateKey =
            '${profitSale.createdAt.year}-${profitSale.createdAt.month}-${profitSale.createdAt.day}';
        salesService.profitSalesTasks
            .putIfAbsent(dateKey, () => [])
            .add(profitSale);
      }
      _syncFilteredProfitSales();
    } catch (e) {
      assert(() {
        debugPrint('[SalesController.fetchProfitSales] $e');
        return true;
      }());
    } finally {
      if (showLoading) {
        isLoading(false);
      }
    }
  }

  // get instant sales
  void getInstantSales({bool loding = false, bool clearCache = false}) {
    fetchInstantSales(clearCache: clearCache, showLoading: loding);
  }

  InvoiceModel? invoiceModel;

  Future<void> getInvoice({required String invoiceId}) async {
    isLoading(true);
    update();
    try {
      invoiceModel = await invoiceModelUsecase.call(invoiceId: invoiceId);
    } catch (_) {
      invoiceModel = null;
      rethrow;
    } finally {
      isLoading(false);
      update();
    }
  }

  Future<void> openInstantSaleBillDetails(String invoiceId) async {
    await getInvoice(invoiceId: invoiceId);
    await Get.toNamed(AppRoutes.INSTANTSALEBILLDETAILSSCREEN);
  }

  // بيانات العرض بعد الفلترة
  void filterLists(bool isFilter) {
    isLoading(true);
    final from = DateTime.tryParse(fromDateController.text);
    final to = DateTime.tryParse(toDateController.text);

    if (from == null && to == null) {
      _syncFilteredProfitSales();
      salesService.filterInstantSalesTasks
          .assignAll(salesService.instantSalesTasks);
      salesListRevision.value++;
      isFilter ? Get.back() : null;
      isLoading(false);
      return;
    }

    final Map<String, List<ProfitSale>> newMap = Map.fromEntries(
      salesService.profitSalesTasks.entries.map((entry) {
        final list = entry.value.where((task) {
          final start = task.createdAt;
          final end = task.updatedAt;
          // لو فيه from فقط
          if (from != null && to == null) {
            return start.isAtSameMomentAs(from) || start.isAfter(from);
          }
          // لو فيه to فقط
          if (to != null && from == null) {
            return end.isAtSameMomentAs(to) || end.isBefore(to);
          }
          // لو الاتنين موجودين
          if (from != null && to != null) {
            final startsOk =
                start.isAtSameMomentAs(from) || start.isAfter(from);
            final endsOk = end.isAtSameMomentAs(to) || end.isBefore(to);
            return startsOk && endsOk;
          }
          return true;
        }).toList();
        return MapEntry(entry.key, list);
      }).where((e) => e.value.isNotEmpty),
    );

    final Map<String, List<InstantSalesModel>> newMap2 = Map.fromEntries(
      salesService.instantSalesTasks.entries.map((entry) {
        final list = entry.value.where((task) {
          final start = task.date;
          final end = task.date;
          // لو فيه from فقط
          if (from != null && to == null) {
            return start.isAtSameMomentAs(from) || start.isAfter(from);
          }
          // لو فيه to فقط
          if (to != null && from == null) {
            return end.isAtSameMomentAs(to) || end.isBefore(to);
          }
          // لو الاتنين موجودين
          if (from != null && to != null) {
            final startsOk =
                start.isAtSameMomentAs(from) || start.isAfter(from);
            final endsOk = end.isAtSameMomentAs(to) || end.isBefore(to);
            return startsOk && endsOk;
          }
          return true;
        }).toList();
        return MapEntry(entry.key, list);
      }).where((e) => e.value.isNotEmpty),
    );
    isLoading(false);

    salesService.filterProfitSalesTasks.assignAll(newMap);
    salesService.filterInstantSalesTasks.assignAll(newMap2);
    notifySalesListChanged();
    isFilter ? Get.back() : null;
  }

  // get all products
  final List<ProductModel> products = [];
  Future<void> getAllProducts({bool showLoading = true}) async {
    final requestId = ++_productsFetchSerial;
    if (showLoading) {
      productsLoading(true);
    }
    try {
      final result = await getAllProductsUsecase.call(
        customerId: pickerPersonType == 'customer' ? pickerPersonId : null,
        sellerId: pickerPersonType == 'seller' ? pickerPersonId : null,
        search: instantSaleProductSearch.value,
        storeSectionId: pickerLocationSectionId.value,
      );
      if (requestId != _productsFetchSerial) return;
      products
        ..clear()
        ..addAll(result);
      if (hasPickerPartner && cartLines.isNotEmpty) {
        final availableIds = products.map((product) => product.id).toSet();
        for (var i = cartLines.length - 1; i >= 0; i--) {
          if (!availableIds.contains(cartLines[i].productId)) {
            removeCartLine(i);
          }
        }
        syncCartToItems();
      }
    } catch (e) {
      if (requestId != _productsFetchSerial) return;
      assert(() {
        debugPrint('[SalesController.getAllProducts] $e');
        return true;
      }());
    } finally {
      if (requestId == _productsFetchSerial) {
        productsLoading(false);
        instantSalePickerSearchLoading(false);
        _bumpProductsList();
      }
    }
  }

  /// Note sent with payment receive so box history matches cancel wording.
  String buildInstantSalePaymentBoxNote() {
    final lineLabels = <String>[];

    if (hasSelectedPackage) {
      final pkg = selectedOfferPackage;
      final pkgName = pkg?.name.trim();
      final qty = items.first.quantityController.text.trim();
      if (pkgName != null && pkgName.isNotEmpty) {
        lineLabels.add('$pkgName × ${qty.isEmpty ? '1' : qty}');
      }
    }

    for (final line in cartLines) {
      lineLabels.add('${line.productName} × ${line.quantityText}');
    }

    if (lineLabels.isEmpty) {
      for (final item in items) {
        final productId = item.selectedItem.value.trim();
        if (productId.isEmpty) {
          continue;
        }
        final qty = item.quantityController.text.trim();
        if (qty.isEmpty || qty == '0') {
          continue;
        }
        final product =
            products.firstWhereOrNull((p) => p.id.toString() == productId);
        final name = product != null && product.nameAr.trim().isNotEmpty
            ? product.nameAr
            : 'منتج';
        lineLabels.add('$name × $qty');
      }
    }

    return BoxLogNoteFormat.instantSaleReceive(
      lineLabels: lineLabels,
      amount: SalesAmountFormat.display(totalCost.value),
    );
  }

  /// After cancel/edit: refresh sales list, stock, success toast (auto-closes).
  Future<void> _completeInstantSaleListAction(BuildContext context) async {
    if (Get.currentRoute == AppRoutes.INSTANTSALEBILLDETAILSSCREEN) {
      Get.back();
    }
    await refreshAllSalesData(showLoading: true);
    getAllProducts();
    Helpers.showCustomDialogSuccess(
      context: Get.context ?? context,
      title: 'success'.tr,
      message: 'operationCompletedSuccessfully'.tr,
    );
  }

  void showInstantSaleActionsSheet(
    BuildContext context,
    InstantSalesModel sale,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => InstantSaleActionsSheet(
        sale: sale,
        onViewInvoice: () async {
          Navigator.of(ctx).pop();
          try {
            await openInstantSaleBillDetails(sale.id.toString());
          } catch (_) {
            Helpers.showCustomDialogError(
              context: context,
              title: 'error'.tr,
              message: 'failed'.tr,
            );
          }
        },
        onEdit: () {
          Navigator.of(ctx).pop();
          openEditInstantSaleFlow(context, sale);
        },
        onCancel: () {
          Navigator.of(ctx).pop();
          confirmCancelInstantSale(context, sale);
        },
      ),
    );
  }

  Future<void> confirmCancelInstantSale(
    BuildContext context,
    InstantSalesModel sale,
  ) async {
    if (sale.isCancelled) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'instantSaleAlreadyCancelled'.tr,
      );
      return;
    }

    final confirmed = await InstantSaleActionDialog.showCancelConfirm(context);

    if (confirmed != true) return;

    isLoading(true);
    try {
      final result = await Get.find<SalesImplement>().cancelInstantSale(
        instantSaleId: sale.id.toString(),
      );
      await result.fold(
        (failure) async {
          final msg = failure.errMessage;
          if (msg.contains('sales_daily_cancel_request_required') ||
              msg.contains('أرسل طلب إلغاء')) {
            await _promptCancellationRequest(
              context,
              saleType: 'instant',
              saleId: sale.id.toString(),
            );
            return;
          }
          Helpers.showCustomDialogError(
            context: context,
            title: 'error'.tr,
            message: failure.errMessage,
          );
        },
        (_) async {
          await _completeInstantSaleListAction(context);
        },
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> _promptCancellationRequest(
    BuildContext context, {
    required String saleType,
    required String saleId,
  }) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('salesDailyCancelRequestTitle'.tr),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'salesDailyCancelReasonHint'.tr,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('submit'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      reasonCtrl.dispose();
      return;
    }
    final reason = reasonCtrl.text;
    reasonCtrl.dispose();
    await requestSaleCancellation(
      saleType: saleType,
      saleId: saleId,
      reason: reason,
    );
  }

  Future<void> confirmCancelProfitSale(
    BuildContext context,
    ProfitSale sale,
  ) async {
    if (sale.isCancelled) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'instantSaleAlreadyCancelled'.tr,
      );
      return;
    }

    final confirmed = await InstantSaleActionDialog.showCancelConfirm(context);
    if (confirmed != true) return;

    isLoading(true);
    try {
      final result = await Get.find<SalesImplement>().cancelProfitSale(
        profitSaleId: sale.id.toString(),
      );
      await result.fold(
        (failure) async {
          final msg = failure.errMessage;
          if (msg.contains('sales_daily_cancel_request_required') ||
              msg.contains('أرسل طلب إلغاء')) {
            await _promptCancellationRequest(
              context,
              saleType: 'profit',
              saleId: sale.id.toString(),
            );
            return;
          }
          final serverError = failure.data?['error']?.toString();
          Helpers.showCustomDialogError(
            context: context,
            title: 'error'.tr,
            message: serverError != null && serverError.trim().isNotEmpty
                ? '${failure.errMessage}\n$serverError'
                : failure.errMessage,
          );
        },
        (_) async {
          await _completeInstantSaleListAction(context);
        },
      );
    } finally {
      isLoading(false);
    }
  }

  // get ongoing projects
  final ApiConsumer api = Get.find<DioConsumer>();
  final List<OngoingProject> ongoingProjects = [];

  void getOngoingProjects() async {
    try {
      final result = await api.get(EndPoints.ongoingProjects);
      final raw = result.data['ongoing projects'];
      if (raw is! List) return;
      ongoingProjects.clear();
      ongoingProjects.addAll(
        raw
            .whereType<Map>()
            .map((e) => OngoingProject.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } catch (e) {
      assert(() {
        debugPrint('[SalesController.getOngoingProjects] $e');
        return true;
      }());
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadDailySession();
    loadSuspendedInvoicesCount();
    getInstantSales();
    getProfitSales(loding: false);
    getOngoingProjects();
    getAllProducts();
    loadOfferPackagesForSale();
    animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    opacityAnimation = Tween<double>(begin: 0, end: 1).animate(animController);
    sizeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: animController, curve: Curves.fastOutSlowIn),
    );

    ever(isAddMenuOpen, (bool open) {
      if (open) {
        animController.forward();
      } else {
        animController.reverse();
      }
    });
    ever(items, (_) => calculateGrandTotal());
    discountController.addListener(_scheduleLocalInstantSaleDraftSave);
  }

  @override
  void onClose() {
    animController.dispose();
    discountController.dispose();
    totalController.dispose();
    noteController.dispose();
    totalCostController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    instantSalesSearchController.dispose();
    profitSalesSearchController.dispose();
    clearInstantSaleNotes(dispose: true);
    _instantSalesSearchDebounce?.cancel();
    _profitSalesSearchDebounce?.cancel();
    _instantSalePickerSearchDebounce?.cancel();
    _autoSuspendDebounce?.cancel();
    _localDraftDebounce?.cancel();
    super.onClose();
  }

  double get instantSaleNotesTotal => instantSaleNotes.fold<double>(
        0,
        (sum, line) => sum + SalesAmountFormat.parse(line.amount.text),
      );

  String get instantSaleNotesText => instantSaleNotes
      .map((line) => line.text.text.trim())
      .where((text) => text.isNotEmpty)
      .join('\n');

  void addInstantSaleNoteLine() {
    instantSaleNotes.add(InstantSaleNoteLine());
    _scheduleLocalInstantSaleDraftSave();
  }

  void saveInstantSaleNoteLine({
    int? index,
    required String text,
    required String amount,
  }) {
    if (index != null && index >= 0 && index < instantSaleNotes.length) {
      instantSaleNotes[index].text.text = text;
      instantSaleNotes[index].amount.text = amount;
      instantSaleNotes.refresh();
    } else {
      instantSaleNotes.add(InstantSaleNoteLine(text: text, amount: amount));
    }
    calculateGrandTotal();
    _scheduleLocalInstantSaleDraftSave();
  }

  void removeInstantSaleNoteLine(int index) {
    if (index < 0 || index >= instantSaleNotes.length) return;
    final line = instantSaleNotes.removeAt(index);
    line.dispose();
    calculateGrandTotal();
    _scheduleLocalInstantSaleDraftSave();
  }

  void clearInstantSaleNotes({bool dispose = true}) {
    for (final line in instantSaleNotes) {
      if (dispose) {
        line.dispose();
      } else {
        line.clear();
      }
    }
    instantSaleNotes.clear();
  }

  List<Map<String, dynamic>> instantSaleNotesPayload() {
    return instantSaleNotes
        .map((line) => {
              'text': line.text.text.trim(),
              'amount': SalesAmountFormat.parse(line.amount.text),
            })
        .where((line) =>
            (line['text'] as String).isNotEmpty ||
            ((line['amount'] as double) > 0))
        .toList();
  }
}

class InstantSaleNoteLine {
  InstantSaleNoteLine({String text = '', String amount = ''})
      : text = TextEditingController(text: text),
        amount = TextEditingController(text: amount);

  final TextEditingController text;
  final TextEditingController amount;

  void dispose() {
    text.dispose();
    amount.dispose();
  }

  void clear() {
    text.clear();
    amount.clear();
  }
}

class ItemModel {
  final RxString selectedItem = ''.obs;
  final RxBool selectedCustomersSellers = false.obs;
  final RxnString selectedValue = RxnString();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  final RxDouble total = 0.0.obs;

  ItemModel() {
    priceController.addListener(_updateTotal);
    quantityController.addListener(_updateTotal);
  }

  void _updateTotal() {
    final price = SalesAmountFormat.parse(priceController.text);
    final quantity = SalesAmountFormat.parse(quantityController.text);
    total.value = price * quantity;
  }

  void syncLineTotal(double value) {
    total.value = value;
  }

  void recalculateTotal() => _updateTotal();

  void onClose() {
    priceController.dispose();
    quantityController.dispose();
  }
}
