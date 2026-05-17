import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/features/admin/sales/data/models/product_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/profit_sale_model.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/add_instant_sales_usecase.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/get_instant_sales_usecase.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../../stock/data/models/offer_package_model.dart';
import '../../../stock/presentation/controllers/offer_packages_controller.dart';
import '../../data/datasources/sales_datasources.dart';
import '../../data/models/instant_sales_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/ongoing_project_model.dart';
import '../../data/repositories/sales_implement.dart';
import '../../domain/usecases/add_profit_sale.dart';
import '../../domain/usecases/get_all_products_usecase.dart';
import '../../domain/usecases/get_profit_sales_usecase.dart';
import '../../domain/usecases/invoice_model_usecase.dart';
import '../widgets/instant_sale_action_dialog.dart';
import '../widgets/instant_sale_actions_sheet.dart';
import 'sales_service.dart';

class SalesController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final AddProfitSaleUsecase addProfitSaleUsecase;
  final GetProfitSalesUsecase getProfitSalesUsecase;
  final GetInstantSalesUsecase getInstantSalesUsecase;
  final GetAllProductsUsecase getAllProductsUsecase;
  final AddInstantSalesUsecase addInstantSalesUsecase;
  final InvoiceModelUsecase invoiceModelUsecase;
  final SalesService salesService;

  SalesController({
    required this.salesService,
    required this.addProfitSaleUsecase,
    required this.getProfitSalesUsecase,
    required this.getInstantSalesUsecase,
    required this.getAllProductsUsecase,
    required this.addInstantSalesUsecase,
    required this.invoiceModelUsecase,
  });

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  final TextEditingController discountController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController totalCostController = TextEditingController();

  // filters
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  final TextEditingController instantSalesSearchController =
      TextEditingController();
  final instantSalesSearchQuery = ''.obs;
  final instantSalesSortDescending = true.obs;
  Timer? _instantSalesSearchDebounce;

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

  /// Date groups for instant sales tab, newest dates first when sort is desc.
  List<MapEntry<String, List<InstantSalesModel>>> get orderedInstantSalesGroups {
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

  DateTime? _parseDateGroupKey(String key) {
    try {
      final parts = key.split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  void _groupInstantSalesIntoMaps(List<InstantSalesModel> sales) {
    salesService.instantSalesTasks.clear();
    for (final instantSale in sales) {
      final dateKey =
          '${instantSale.date.year}-${instantSale.date.month}-${instantSale.date.day}';
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
    if (from == null && to == null) {
      salesService.filterProfitSalesTasks
          .assignAll(salesService.profitSalesTasks);
      return;
    }
    final filtered = Map<String, List<ProfitSale>>.fromEntries(
      salesService.profitSalesTasks.entries.map((entry) {
        final list = entry.value.where((task) {
          final start = task.createdAt;
          final end = task.updatedAt;
          if (from != null && to == null) {
            return start.isAtSameMomentAs(from) || start.isAfter(from);
          }
          if (to != null && from == null) {
            return end.isAtSameMomentAs(to) || end.isBefore(to);
          }
          if (from != null && to != null) {
            final okStart =
                start.isAtSameMomentAs(from) || start.isAfter(from);
            final okEnd = end.isAtSameMomentAs(to) || end.isBefore(to);
            return okStart && okEnd;
          }
          return true;
        }).toList();
        return MapEntry(entry.key, list);
      }).where((e) => e.value.isNotEmpty),
    );
    salesService.filterProfitSalesTasks.assignAll(filtered);
  }

  void notifySalesListChanged() {
    _syncFilteredInstantSales();
    _syncFilteredProfitSales();
    salesListRevision.value++;
  }

  final currentTab = 0.obs;

  /// Bumped when sales lists change so [Obx] on [SalesScreen] rebuilds.
  final salesListRevision = 0.obs;

  List<String> tabs = ['spotSale', 'cashProfit'];

  final instantSalesSubTabs = ['instantSaleTabProducts', 'instantSaleTabPackages'];
  final instantSalesSubTab = 0.obs;

  final targets = <Map<String, dynamic>>[].obs;

  final isLoading = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
  }

  void changeInstantSalesSubTab(int index) {
    instantSalesSubTab.value = index;
    notifySalesListChanged();
  }

  /// Instant sales grouped by date, filtered by products vs packages sub-tab.
  List<MapEntry<String, List<InstantSalesModel>>>
      get orderedInstantSalesGroupsFiltered {
    final wantPackages = instantSalesSubTab.value == 1;
    final filtered = orderedInstantSalesGroups
        .map(
          (entry) => MapEntry(
            entry.key,
            entry.value
                .where((sale) => sale.isPackageSale == wantPackages)
                .toList(),
          ),
        )
        .where((entry) => entry.value.isNotEmpty)
        .toList();
    return filtered;
  }

  final items = <ItemModel>[ItemModel()].obs;

  final RxBool isPackageSale = false.obs;
  final RxnInt selectedPackageId = RxnInt();
  final RxList<OfferPackageModel> offerPackagesForSale =
      <OfferPackageModel>[].obs;

  /// Filled from payment screen (طريقة القبض) after successful receipt.
  String _paymentBuyerType = 'unknown';
  String? _paymentBuyerId;
  String? _paymentBuyerName;
  String? _paymentBoxId;
  String? _paymentBoxName;
  String? _paymentBoxValue;

  void applyBuyerFromPayment(Map<String, dynamic> result) {
    _paymentBuyerType = result['buyer_type']?.toString() ?? 'unknown';
    final id = result['buyer_id']?.toString();
    _paymentBuyerId = (id != null && id.isNotEmpty) ? id : null;
    final name = result['buyer_name']?.toString();
    _paymentBuyerName = (name != null && name.isNotEmpty) ? name : null;
    final boxId = result['payment_box_id']?.toString();
    _paymentBoxId = (boxId != null && boxId.isNotEmpty) ? boxId : null;
    final boxName = result['payment_box_name']?.toString();
    _paymentBoxName = (boxName != null && boxName.isNotEmpty) ? boxName : null;
    final boxValue = result['payment_box_value']?.toString();
    _paymentBoxValue = (boxValue != null && boxValue.isNotEmpty) ? boxValue : null;
  }

  void _clearPaymentBuyer() {
    _paymentBuyerType = 'unknown';
    _paymentBuyerId = null;
    _paymentBuyerName = null;
    _paymentBoxId = null;
    _paymentBoxName = null;
    _paymentBoxValue = null;
  }

  void resetInstantSaleForm() {
    noteController.clear();
    totalCostController.clear();
    discountController.clear();
    totalController.clear();
    isPackageSale.value = false;
    selectedPackageId.value = null;
    for (final e in items) {
      e.quantityController.clear();
      e.priceController.clear();
      e.selectedItem.value = '';
    }
    while (items.length > 1) {
      items.removeLast();
    }
    totalCost.value = 0;
    _clearPaymentBuyer();
    update();
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

  OfferPackageModel? get selectedOfferPackage =>
      offerPackagesForSale
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
      formKey.currentState?.validate();
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

  final RxInt totalCost = 0.obs;
  final RxInt packageLineTotal = 0.obs;

  void calculateGrandTotal() {
    int total = 0;
    if (isPackageSale.value && selectedPackageId.value != null) {
      final pkg = selectedOfferPackage;
      final unitPrice = pkg?.price ??
          double.tryParse(items.first.priceController.text.trim()) ??
          0;
      final qty =
          int.tryParse(items.first.quantityController.text.trim()) ?? 0;
      final lineTotal = (unitPrice * qty).round();
      packageLineTotal.value = lineTotal;
      items.first.syncLineTotal(lineTotal);
      total = lineTotal;
    } else {
      packageLineTotal.value = 0;
      for (final item in items) {
        total += item.total.value;
      }
    }
    final discount = int.tryParse(discountController.text.trim()) ?? 0;

    totalCost.value = total - discount;
    totalController.text = totalCost.value.toString();
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
      'route': AppRoutes.NEWINSTANTSALESCREEN
    },
    {
      'title': 'newCashProfit',
      'icon': AssetsManager.moneyIcon,
      'route': AppRoutes.NEWCASHPROFITSCREEN,
    },
  ];

  // add profit sale
  Future<bool> addProfitSale(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      isLoading(true);
      final result = await addProfitSaleUsecase.call(
        notes: noteController.text,
        totalCost: totalCostController.text,
      );
      result.fold(
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
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: errorMessages,
          );
          return false;
        },
        (success) async {
          noteController.clear();
          totalCostController.clear();
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
    }
    isLoading(false);
    return false;
  }

  // add instant sale
  Future<void> addInstantSale(BuildContext context) async {
    isLoading(true);
    try {
      final result = await addInstantSalesUsecase.call(
        productId: isPackageSale.value
            ? ''
            : items.first.selectedItem.value.toString(),
        quantity: items.first.quantityController.text,
        cost: items.first.priceController.text,
        discount:
            discountController.text.isEmpty ? '0' : discountController.text,
        totalCost: totalCost.value.toString(),
        note: noteController.text,
        type: items.first.selectedCustomersSellers.value ? 'project' : 'normal',
        projectId: items.first.selectedCustomersSellers.value
            ? items.first.selectedValue.value!
            : '',
        otherProducts: isPackageSale.value ? RxList<ItemModel>() : items,
        buyerType: _paymentBuyerType,
        buyerId: _paymentBuyerId,
        buyerName: _paymentBuyerName,
        paymentBoxId: _paymentBoxId,
        paymentBoxName: _paymentBoxName,
        paymentBoxValue: _paymentBoxValue,
        offerPackageId: isPackageSale.value
            ? selectedPackageId.value?.toString()
            : null,
      );
      await result.fold(
        (failure) async {
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
          resetInstantSaleForm();
          await loadOfferPackagesForSale();
          if (Get.currentRoute == AppRoutes.NEWINSTANTSALESCREEN) {
            Get.back();
          }
          await refreshAllSalesData(showLoading: true);
          getAllProducts();
          final dialogContext = Get.context ?? context;
          Helpers.showCustomDialogSuccess(
            context: dialogContext,
            title: 'success'.tr,
            message: 'operationCompletedSuccessfully'.tr,
          );
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
      salesService.filterProfitSalesTasks.assignAll(
        salesService.profitSalesTasks,
      );
      salesService.filterInstantSalesTasks
          .assignAll(salesService.instantSalesTasks);
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
  void getAllProducts() async {
    final result = await getAllProductsUsecase.call();
    products.assignAll(result);
  }

  /// Note sent with payment receive so box history matches cancel wording.
  String buildInstantSalePaymentBoxNote() {
    final parts = <String>[];
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
      parts.add('$name × $qty');
    }
    if (parts.isEmpty) {
      return 'قبض — بيع فوري | مبلغ: ${totalCost.value}';
    }
    return 'قبض — بيع فوري | ${parts.join(' | ')} | مبلغ: ${totalCost.value}';
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
          showEditInstantSaleDialog(context, sale);
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

  Future<void> showEditInstantSaleDialog(
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

    final costCtrl = TextEditingController(text: sale.cost);
    final qtyCtrl = TextEditingController(text: sale.quantity);
    final totalCtrl = TextEditingController(text: sale.totalCost);
    final notesCtrl = TextEditingController(text: sale.notes);

    final confirmed = await InstantSaleActionDialog.showEdit(
      context: context,
      costCtrl: costCtrl,
      qtyCtrl: qtyCtrl,
      totalCtrl: totalCtrl,
      notesCtrl: notesCtrl,
    );

    if (confirmed != true) {
      costCtrl.dispose();
      qtyCtrl.dispose();
      totalCtrl.dispose();
      notesCtrl.dispose();
      return;
    }

    final cost = costCtrl.text.trim();
    final quantity = qtyCtrl.text.trim();
    final totalCost = totalCtrl.text.trim();
    final notes = notesCtrl.text.trim();
    costCtrl.dispose();
    qtyCtrl.dispose();
    totalCtrl.dispose();
    notesCtrl.dispose();

    isLoading(true);
    try {
      final result = await Get.find<SalesImplement>().editInstantSale(
        instantSaleId: sale.id.toString(),
        cost: cost,
        quantity: quantity,
        totalCost: totalCost,
        notes: notes,
      );
      await result.fold(
        (failure) async {
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

  // get ongoing projects
  final ApiConsumer api = Get.find<DioConsumer>();
  final List<OngoingProject> ongoingProjects = [];

  void getOngoingProjects() async {
    final result = await api.get(EndPoints.ongoingProjects);
    ongoingProjects.clear();
    ongoingProjects.addAll(
      (result.data['ongoing projects'] as List)
          .map((e) => OngoingProject.fromJson(e))
          .toList(),
    );
  }

  @override
  void onInit() {
    super.onInit();
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
    _instantSalesSearchDebounce?.cancel();
    super.onClose();
  }
}

class ItemModel {
  final RxString selectedItem = ''.obs;
  final RxBool selectedCustomersSellers = false.obs;
  final RxnString selectedValue = RxnString();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  final RxInt total = 0.obs;

  ItemModel() {
    priceController.addListener(_updateTotal);
    quantityController.addListener(_updateTotal);
  }

  void _updateTotal() {
    final price = double.tryParse(priceController.text.trim()) ?? 0;
    final quantity = double.tryParse(quantityController.text.trim()) ?? 0;
    total.value = (price * quantity).round();
  }

  void syncLineTotal(int value) {
    total.value = value;
  }

  void onClose() {
    priceController.dispose();
    quantityController.dispose();
  }
}
