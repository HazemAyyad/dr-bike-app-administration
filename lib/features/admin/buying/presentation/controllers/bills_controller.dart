import 'dart:io';

import 'package:doctorbike/core/helpers/helpers.dart';
import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../routes/app_routes.dart';
import '../../../checks/data/models/check_model.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../../sales/data/models/product_model.dart';
import '../../../sales/domain/usecases/get_all_products_usecase.dart';
import '../../data/models/bills_models/bills_details_model.dart';
import '../../data/models/bills_models/bills_model.dart';
import '../../domain/usecases/bills_usecases/add_bill_usecase.dart';
import '../../domain/usecases/get_bills_usecase.dart';
import '../../domain/usecases/get_billt_details_usecase.dart';
import '../../domain/usecases/purchase_workflow_usecase.dart';
import 'buying_serves.dart';
import 'return_purchases_controller.dart';

/// Resolves `bill_details` whether it is top-level or under `data`.
Map<String, dynamic> _billDetailsMap(dynamic result) {
  final m = asMap(result);
  dynamic raw = m['bill_details'];
  raw ??= asMap(m['data'])['bill_details'];
  if (kDebugMode) {
    debugParseLog(
      'BillsController.getBillDetails',
      'bill_detailsKeys=${asMap(raw).keys.toList()}',
    );
    final prods = asMap(raw)['products'];
    if (prods is List && prods.isNotEmpty && prods.first is Map) {
      final pm = Map<String, dynamic>.from(prods.first as Map);
      debugParseLog(
        'BillsController.getBillDetails',
        'sampleProductFieldTypes=${pm.map((k, v) => MapEntry(k, v.runtimeType))}',
      );
    }
  }
  return asMap(raw);
}

enum PurchaseLoadStatus { idle, loading, success, empty, error }

class BillsController extends GetxController with GetTickerProviderStateMixin {
  final GetBillsUsecase getBillsUsecase;
  final GetAllProductsUsecase getAllProductsUsecase;
  final AllCustomersSellersUsecase allCustomersSellersUsecase;
  final AddBillUsecase addBillUsecase;
  final GetBilltDetailsUsecase getBilltDetailsUsecase;
  final PurchaseWorkflowUsecase purchaseWorkflowUsecase;
  final GetShownBoxUsecase getShownBoxUsecase;

  BillsController({
    required this.getBillsUsecase,
    required this.getAllProductsUsecase,
    required this.allCustomersSellersUsecase,
    required this.addBillUsecase,
    required this.getBilltDetailsUsecase,
    required this.purchaseWorkflowUsecase,
    required this.getShownBoxUsecase,
  });

  final formKey = GlobalKey<FormState>();

  final TextEditingController sellerIdController = TextEditingController();
  final TextEditingController customerIdController = TextEditingController();
  final TextEditingController discountController = TextEditingController();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController purchaseNotesController = TextEditingController();
  final TextEditingController purchaseProductSearchController =
      TextEditingController();

  final billModel = <BillModel>[BillModel()].obs;

  void addBillModel() {
    billModel.add(BillModel());
    update();
  }

  void removeItem(int index) {
    if (billModel.length > 1) {
      billModel.removeAt(index);
    }
    update();
  }

  final RxDouble totalCost = 0.0.obs;

  void calculateGrandTotal() {
    double cost = 0;

    for (BillModel item in billModel) {
      cost += item.totalPrice.value;
    }
    if (discountController.text.isNotEmpty) {
      cost -= double.tryParse(discountController.text) ?? 0;
    }

    totalCost.value = cost;
    update();
  }

  // متغير للتحكم في قائمة الإضافة
  final RxBool isAddMenuOpen = false.obs;

  late AnimationController animController;
  late Animation<double> opacityAnimation;
  late Animation<double> sizeAnimation;

  void toggleAddMenu() {
    isAddMenuOpen.value = !isAddMenuOpen.value;
  }

  List<String> tabs = ['bills', 'archive'];

  RxInt currentTab = 0.obs;
  final RxBool isPurchaseSearchVisible = false.obs;
  final RxString purchaseBillStateFilter = 'all'.obs;

  void changeTab(int index) {
    currentTab.value = index;
    _applyPurchaseBillFilters();
    update();
  }

  void togglePurchaseSearch() {
    isPurchaseSearchVisible.value = !isPurchaseSearchVisible.value;
    update();
  }

  void closePurchaseSearch() {
    searchController.clear();
    isPurchaseSearchVisible.value = false;
    _applyPurchaseBillFilters();
    update();
  }

  void changePurchaseBillStateFilter(String value) {
    purchaseBillStateFilter.value = value;
    _applyPurchaseBillFilters();
    update();
  }

  // get all products
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final Rx<PurchaseLoadStatus> purchaseProductsStatus =
      PurchaseLoadStatus.idle.obs;
  final Rx<PurchaseLoadStatus> purchaseSourcesStatus =
      PurchaseLoadStatus.idle.obs;
  String purchaseProductsError = '';
  String purchaseSourcesError = '';

  Future<void> getAllProducts() async {
    if (purchaseProductsStatus.value == PurchaseLoadStatus.loading) return;

    purchaseProductsStatus.value = PurchaseLoadStatus.loading;
    purchaseProductsError = '';
    update();

    try {
      final result = await getAllProductsUsecase.call();
      products.assignAll(result);
      purchaseProductsStatus.value = products.isEmpty
          ? PurchaseLoadStatus.empty
          : PurchaseLoadStatus.success;
    } catch (error, stackTrace) {
      purchaseProductsError = error.toString();
      purchaseProductsStatus.value = PurchaseLoadStatus.error;
      products.clear();
      if (kDebugMode) {
        debugPrint('BillsController.getAllProducts failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    update();
  }

  // get all sellers
  final RxList<SellerModel> allSellersList = <SellerModel>[].obs;
  final RxList<SellerModel> allCustomersList = <SellerModel>[].obs;
  final Rxn<PurchaseSourceModel> selectedPurchaseSource =
      Rxn<PurchaseSourceModel>();
  final RxList<PurchaseCartItemModel> purchaseCart =
      <PurchaseCartItemModel>[].obs;
  final RxString purchaseProductSearch = ''.obs;
  final RxMap<String, Map<String, dynamic>> purchasePriceIntelligence =
      <String, Map<String, dynamic>>{}.obs;
  final RxSet<String> purchasePriceLoading = <String>{}.obs;
  final RxBool isAmanatDashboardLoading = false.obs;
  final RxBool isDiscrepanciesDashboardLoading = false.obs;
  final RxList<Map<String, dynamic>> amanatDashboard =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> discrepanciesDashboard =
      <Map<String, dynamic>>[].obs;

  List<PurchaseSourceModel> get purchaseSources {
    final byName = <String, PurchaseSourceModel>{};
    for (final seller in allSellersList) {
      final key = seller.name.trim().toLowerCase();
      byName[key] = PurchaseSourceModel(
        id: seller.id,
        name: seller.name,
        phone: seller.phone,
        hasSeller: true,
        hasCustomer: false,
      );
    }
    for (final customer in allCustomersList) {
      final key = customer.name.trim().toLowerCase();
      final current = byName[key];
      byName[key] = PurchaseSourceModel(
        id: current?.id ?? customer.id,
        name: current?.name ?? customer.name,
        phone:
            current?.phone.isNotEmpty == true ? current!.phone : customer.phone,
        hasSeller: current?.hasSeller == true,
        hasCustomer: true,
        customerId: customer.id,
        sellerId: current?.sellerId ?? current?.id,
      );
    }
    return byName.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  List<ProductModel> get filteredPurchaseProducts {
    final query = purchaseProductSearch.value.trim().toLowerCase();
    if (query.isEmpty) return products;
    return products.where((product) {
      return product.nameAr.toLowerCase().contains(query) ||
          product.displayProductCode.toLowerCase().contains(query);
    }).toList();
  }

  void getAllSellers() async {
    final resultSellers =
        await allCustomersSellersUsecase.call(endPoint: EndPoints.all_sellers);
    allSellersList.assignAll(resultSellers);
    isLoading(false);
  }

  Future<void> getAllPurchaseSources() async {
    if (purchaseSourcesStatus.value == PurchaseLoadStatus.loading) return;

    purchaseSourcesStatus.value = PurchaseLoadStatus.loading;
    purchaseSourcesError = '';
    update();

    try {
      final resultCustomers = await allCustomersSellersUsecase.call(
        endPoint: EndPoints.all_customers,
      );
      final resultSellers = await allCustomersSellersUsecase.call(
        endPoint: EndPoints.all_sellers,
      );
      allCustomersList.assignAll(resultCustomers);
      allSellersList.assignAll(resultSellers);
      purchaseSourcesStatus.value = purchaseSources.isEmpty
          ? PurchaseLoadStatus.empty
          : PurchaseLoadStatus.success;
    } catch (error, stackTrace) {
      purchaseSourcesError = error.toString();
      purchaseSourcesStatus.value = PurchaseLoadStatus.error;
      if (kDebugMode) {
        debugPrint('BillsController.getAllPurchaseSources failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    update();
  }

  void retryPurchaseProducts() {
    getAllProducts();
  }

  void retryPurchaseSources() {
    getAllPurchaseSources();
  }

  void selectPurchaseSource(PurchaseSourceModel? source) {
    selectedPurchaseSource.value = source;
    sellerIdController.clear();
    customerIdController.clear();
    if (source == null) {
      update();
      return;
    }
    if (source.hasSeller) {
      sellerIdController.text = (source.sellerId ?? source.id).toString();
    } else if (source.hasCustomer) {
      customerIdController.text = (source.customerId ?? source.id).toString();
    }
    update();
  }

  void onPurchaseProductSearchChanged(String value) {
    purchaseProductSearch.value = value;
    update();
  }

  void addProductToPurchaseCart(ProductModel product) {
    final index =
        purchaseCart.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      purchaseCart[index].quantityController.text =
          ((num.tryParse(purchaseCart[index].quantityController.text) ?? 0) + 1)
              .toString();
      purchaseCart.refresh();
    } else {
      purchaseCart.add(_createPurchaseCartItem(product));
    }
    loadPurchasePriceIntelligence(product.id);
    calculatePurchaseCartTotal();
    update();
  }

  int purchaseCartQtyForProduct(String productId) {
    for (final item in purchaseCart) {
      if (item.product.id == productId) {
        return item.quantity.toInt();
      }
    }
    return 0;
  }

  int get purchaseCartDistinctCount => purchaseCart.length;

  int get purchaseCartTotalPieces => purchaseCart.fold<int>(
        0,
        (sum, item) => sum + item.quantity.toInt(),
      );

  void incrementPurchaseProduct(ProductModel product) {
    addProductToPurchaseCart(product);
  }

  void togglePurchaseProductSelection(ProductModel product) {
    final index =
        purchaseCart.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      removePurchaseCartItem(purchaseCart[index]);
      return;
    }
    purchaseCart.add(_createPurchaseCartItem(product));
    loadPurchasePriceIntelligence(product.id);
    calculatePurchaseCartTotal();
    update();
  }

  void decrementPurchaseProduct(String productId) {
    final index =
        purchaseCart.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;
    final item = purchaseCart[index];
    final nextQty = item.quantity - 1;
    if (nextQty <= 0) {
      removePurchaseCartItem(item);
      return;
    }
    item.quantityController.text = nextQty.toInt().toString();
    purchaseCart.refresh();
    calculatePurchaseCartTotal();
    update();
  }

  Future<void> loadPurchasePriceIntelligence(String productId) async {
    if (purchasePriceLoading.contains(productId)) return;
    purchasePriceLoading.add(productId);
    update();
    try {
      final source = selectedPurchaseSource.value;
      final result = await purchaseWorkflowUsecase.priceIntelligence(
        productId: productId,
        sellerId: source?.hasSeller == true
            ? (source?.sellerId ?? source?.id).toString()
            : null,
        customerId: source?.hasSeller == true
            ? null
            : (source?.customerId ?? source?.id).toString(),
      );
      final data = asMap(result);
      final intelligence = asMap(data['price_intelligence']);
      purchasePriceIntelligence[productId] = intelligence;
      final suggested = asString(intelligence['suggested_price']);
      PurchaseCartItemModel? item;
      for (final row in purchaseCart) {
        if (row.product.id == productId) {
          item = row;
          break;
        }
      }
      if (item != null &&
          item.priceController.text.trim().isEmpty &&
          suggested.isNotEmpty) {
        item.priceController.text = suggested;
      }
    } catch (_) {
      purchasePriceIntelligence.remove(productId);
    }
    purchasePriceLoading.remove(productId);
    calculatePurchaseCartTotal();
    update();
  }

  Future<void> loadAmanatDashboard({String? status, String? search}) async {
    isAmanatDashboardLoading(true);
    update();
    try {
      final result = await purchaseWorkflowUsecase.amanatIndex(
        status: status,
        search: search,
      );
      amanatDashboard.assignAll(
        mapListFromResponseKey(
          result,
          'amanat',
          (Map<String, dynamic> m) => m,
          debugScope: 'BillsController.amanatDashboard',
        ),
      );
    } catch (_) {
      amanatDashboard.clear();
    }
    isAmanatDashboardLoading(false);
    update();
  }

  Future<void> loadDiscrepanciesDashboard({
    String? type,
    String? search,
  }) async {
    isDiscrepanciesDashboardLoading(true);
    update();
    try {
      final result = await purchaseWorkflowUsecase.discrepancies(
        type: type,
        search: search,
      );
      discrepanciesDashboard.assignAll(
        mapListFromResponseKey(
          result,
          'discrepancies',
          (Map<String, dynamic> m) => m,
          debugScope: 'BillsController.discrepanciesDashboard',
        ),
      );
    } catch (_) {
      discrepanciesDashboard.clear();
    }
    isDiscrepanciesDashboardLoading(false);
    update();
  }

  void applyHistoricalPurchasePrice({
    required PurchaseCartItemModel item,
    required String price,
  }) {
    item.priceController.text = price;
    calculatePurchaseCartTotal();
    update();
  }

  void removePurchaseCartItem(PurchaseCartItemModel item) {
    item.dispose();
    purchaseCart.remove(item);
    calculatePurchaseCartTotal();
    update();
  }

  void calculatePurchaseCartTotal() {
    totalCost.value = purchaseCart.fold<double>(
      0,
      (sum, item) => sum + item.total.toDouble(),
    );
    update(['purchaseCheckoutSummary']);
    update();
  }

  PurchaseCartItemModel _createPurchaseCartItem(ProductModel product) {
    return PurchaseCartItemModel(
      product: product,
      onChanged: calculatePurchaseCartTotal,
    );
  }

  void preparePurchaseReturnForm() {
    purchaseReturnResolution.value = 'supplier_credit';
    purchaseReturnNoteController.clear();
    purchaseProductSearch.value = '';
    selectedPurchaseSource.value = null;
    sellerIdController.clear();
    customerIdController.clear();
    for (final item in purchaseCart) {
      item.dispose();
    }
    purchaseCart.clear();
    totalCost.value = 0;
    update();
  }

  void changePurchaseReturnResolution(String value) {
    purchaseReturnResolution.value = value;
    update();
  }

  Future<void> createPurchaseReturnFromCart(BuildContext context) async {
    final source = selectedPurchaseSource.value;
    if (source == null) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب اختيار مصدر المرتجع',
      );
      return;
    }
    if (purchaseCart.isEmpty) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب إضافة منتجات للمرتجع',
      );
      return;
    }
    for (final item in purchaseCart) {
      if (item.quantity <= 0 || item.unitPrice <= 0) {
        Helpers.showCustomDialogError(
          context: context,
          title: 'error'.tr,
          message: 'تأكد من الكميات والأسعار',
        );
        return;
      }
    }
    if (purchaseReturnResolution.value == 'cash_refund' &&
        selectedPurchaseBox.value == null) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب اختيار صندوق للاسترداد النقدي',
      );
      return;
    }

    billModel.assignAll(purchaseCart.map((item) {
      final row = BillModel();
      row.productIdController.text = item.product.id;
      row.quantityController.text = item.quantityController.text.trim();
      row.priceController.text = item.priceController.text.trim();
      return row;
    }).toList());
    totalCost.value = purchaseCart.fold<double>(
      0,
      (sum, item) => sum + item.total.toDouble(),
    );

    isWorkflowLoading(true);
    update();
    final result = await purchaseWorkflowUsecase.createPurchaseReturn(
      sellerId:
          source.hasSeller ? (source.sellerId ?? source.id).toString() : '',
      customerId:
          source.hasSeller ? '' : (source.customerId ?? source.id).toString(),
      products: billModel,
      total: totalCost.value.toString(),
      resolution: purchaseReturnResolution.value,
      refundBoxId: purchaseReturnResolution.value == 'cash_refund'
          ? selectedPurchaseBox.value?.boxId.toString()
          : null,
      note: purchaseReturnNoteController.text.trim(),
    );

    result.fold(
      (failure) {
        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: failure.data['message']?.toString() ?? failure.errMessage,
        );
      },
      (success) {
        Get.find<ReturnPurchasesController>().getReturnBills();
        preparePurchaseReturnForm();
        Get.back();
        Helpers.showCustomDialogSuccess(
          context: context,
          title: 'success'.tr,
          message: success,
        );
      },
    );
    isWorkflowLoading(false);
    update();
  }

  Future<void> createPurchaseFromCart(BuildContext context) async {
    final source = selectedPurchaseSource.value;
    if (source == null) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب اختيار مصدر الشراء',
      );
      return;
    }
    if (purchaseCart.isEmpty) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب إضافة منتجات للفاتورة',
      );
      return;
    }
    for (final item in purchaseCart) {
      if (item.quantity <= 0 || item.unitPrice < 0) {
        Helpers.showCustomDialogError(
          context: context,
          title: 'error'.tr,
          message: 'تأكد من الكميات والأسعار',
        );
        return;
      }
    }
    final paid = num.tryParse(purchasePaymentAmountController.text.trim()) ?? 0;
    if (paid < 0 || paid > totalCost.value) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'تأكد من المبلغ المدفوع',
      );
      return;
    }
    if (paid > 0 && selectedPurchaseBox.value == null) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب اختيار صندوق للمبلغ المدفوع',
      );
      return;
    }

    billModel.assignAll(purchaseCart.map((item) {
      final row = BillModel();
      row.productIdController.text = item.product.id;
      row.quantityController.text = item.quantityController.text.trim();
      row.priceController.text = item.priceController.text.trim();
      return row;
    }).toList());
    totalCost.value = purchaseCart.fold<double>(
      0,
      (sum, item) => sum + item.total.toDouble(),
    );
    addBill(context);
  }

  RxBool isLoading = false.obs;

  Future<void> getBills() async {
    BuyingServes().allBillsTasks.isEmpty ? isLoading(true) : null;
    update();

    // دالة مساعدة للتجميع
    Map<String, List<BillDataModel>> groupByDate(List<BillDataModel> list) {
      final Map<String, List<BillDataModel>> grouped = {};
      final sortedList = list.toList()
        ..sort((a, b) {
          final dateCompare = DateTime.parse(b.createdAt).compareTo(
            DateTime.parse(a.createdAt),
          );
          return dateCompare != 0 ? dateCompare : b.id.compareTo(a.id);
        });

      for (var task in sortedList) {
        final receiptDateObj = DateTime.parse(task.createdAt);
        final dayName =
            DateFormat.EEEE(Get.locale!.languageCode).format(receiptDateObj);
        final dateKey =
            "$dayName ${receiptDateObj.year}-${receiptDateObj.month}-${receiptDateObj.day}";

        if (grouped.containsKey(dateKey)) {
          if (!grouped[dateKey]!.any((a) => a.id == task.id)) {
            grouped[dateKey]!.add(task);
          }
        } else {
          grouped[dateKey] = [task];
        }
      }

      // ✅ الترتيب من الأقرب للأبعد
      final sortedEntries = grouped.entries.toList()
        ..sort((a, b) {
          final aDate = DateTime.parse(a.value.first.createdAt);
          final bDate = DateTime.parse(b.value.first.createdAt);
          return bDate.compareTo(aDate);
        });

      return Map.fromEntries(sortedEntries);
    }

    final bills = await getBillsUsecase.call(page: '0');
    if (kDebugMode) {
      debugParseLog(
        'BillsController.getBills',
        'unfinished rawType=${bills.runtimeType} keys=${bills is Map ? bills.keys.toList() : []}',
      );
    }
    final allBillsTasks = mapListFromResponseKey(
      bills,
      'bills',
      (Map<String, dynamic> m) => BillDataModel.fromJson(m),
      debugScope: 'BillsController.getBills.unfinished',
    );
    BuyingServes().allBillsTasks.value = groupByDate(allBillsTasks);
    _applyPurchaseBillFilters();
    isLoading(false);
    update();

    final billsArchive = await getBillsUsecase.call(page: '1');
    if (kDebugMode) {
      debugParseLog(
        'BillsController.getBills',
        'archive rawType=${billsArchive.runtimeType} keys=${billsArchive is Map ? billsArchive.keys.toList() : []}',
      );
    }
    final billsArchiveTasks = mapListFromResponseKey(
      billsArchive,
      'bills',
      (Map<String, dynamic> m) => BillDataModel.fromJson(m),
      debugScope: 'BillsController.getBills.archive',
    );
    BuyingServes().allBillsArchiveTasks.value = groupByDate(billsArchiveTasks);
    _applyPurchaseBillFilters();

    isLoading(false);
    update();
  }

  // get bill details
  BillDetailsModel? billDetails;
  Future<void> getBillDetails({
    required BuildContext context,
    required String billId,
    bool isDownload = false,
  }) async {
    if (billDetails != null) {
      billDetails!.billId.toString() == billId ? null : isAddLoading(true);
    } else {
      isAddLoading(true);
    }
    if (isDownload) {
      try {
        // نطلب من المستخدم يختار فولدر
        Get.snackbar(
          "info".tr,
          "جار تحميل الملف. سيتم اعلامك عند الانتهاء".tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 2500),
        );
        // نجيب الداتا من API
        final response = await getBilltDetailsUsecase.call(
          billId: billId,
          isDownload: isDownload,
        );
        late Directory directory;
        if (Platform.isAndroid) {
          directory = Directory("/storage/emulated/0/Download/Doctor Bike/PDF");
        } else if (Platform.isIOS) {
          // على iOS نحفظ في Documents الخاص بالتطبيق
          final appDocDir = await getApplicationDocumentsDirectory();
          directory = Directory("${appDocDir.path}/Doctor Bike/PDF");
        } else {
          directory = Directory(
              "${(await getApplicationDocumentsDirectory()).path}/Doctor Bike/PDF");
        }
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final filePath =
            "${directory.path}/فاتورة_${billDetails!.sellerName}${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}.pdf";
        final file = File(filePath);
        await file.writeAsBytes(response);
        Get.snackbar(
          "fileDownloadedSuccessfully".tr,
          filePath,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 2000),
        );

        await OpenFilex.open(filePath);
      } catch (e) {
        Get.snackbar("error".tr, e.toString());
      }
    } else {
      final result = await getBilltDetailsUsecase.call(
        billId: billId,
        isDownload: isDownload,
      );
      billDetails = BillDetailsModel.fromJson(_billDetailsMap(result));
      purchaseTimeline.assignAll(
        billDetails!.timeline.map((event) => event.toJson()).toList(),
      );
      loadPurchaseTimeline(billId);
    }

    isAddLoading(false);
    update();
  }

  final RxBool isAddLoading = false.obs;
  final RxBool isWorkflowLoading = false.obs;
  final RxBool isTimelineLoading = false.obs;
  final RxBool isOpenPurchaseBillsLoading = false.obs;
  final RxList<Map<String, dynamic>> purchaseTimeline =
      <Map<String, dynamic>>[].obs;
  final RxList<ShownBoxesModel> purchaseBoxes = <ShownBoxesModel>[].obs;
  final Rxn<ShownBoxesModel> selectedPurchaseBox = Rxn<ShownBoxesModel>();
  final RxList<PlatformFile> purchasePaymentEvidenceFiles =
      <PlatformFile>[].obs;
  final TextEditingController purchasePaymentAmountController =
      TextEditingController();
  final TextEditingController purchasePaymentNoteController =
      TextEditingController();
  final TextEditingController purchaseReturnNoteController =
      TextEditingController();
  final TextEditingController amanatQuantityController =
      TextEditingController();
  final TextEditingController amanatUnitPriceController =
      TextEditingController();
  final TextEditingController amanatNoteController = TextEditingController();
  final TextEditingController issueQuantityController = TextEditingController();
  final TextEditingController issueUnitPriceController =
      TextEditingController();
  final TextEditingController issueAdjustmentController =
      TextEditingController();
  final TextEditingController issueReasonController = TextEditingController();
  final TextEditingController issueNotesController = TextEditingController();
  final RxList<PurchaseReceivingRowModel> receivingRows =
      <PurchaseReceivingRowModel>[].obs;
  final RxList<PurchaseOpenBillAllocationModel> openPurchaseBills =
      <PurchaseOpenBillAllocationModel>[].obs;
  final RxString purchaseReturnResolution = 'supplier_credit'.obs;
  String isaddNewBill = '1';
  // add bill
  void addBill(BuildContext context) async {
    isAddLoading(true);
    final result = await addBillUsecase.call(
      page: isaddNewBill,
      sellerId: sellerIdController.text,
      customerId: customerIdController.text,
      products: billModel,
      total: totalCost.value.toString(),
      initialPayment: purchasePaymentAmountController.text.trim().isEmpty
          ? '0'
          : purchasePaymentAmountController.text.trim(),
      boxId: selectedPurchaseBox.value?.boxId.toString(),
    );

    result.fold((failure) {
      Helpers.showCustomDialogError(
        context: context,
        title: failure.errMessage,
        message: failure.data['message'],
      );
    }, (success) {
      Future.delayed(const Duration(seconds: 1), () {
        sellerIdController.clear();
        customerIdController.clear();
        discountController.clear();
        purchaseNotesController.clear();
        purchasePaymentAmountController.clear();
        purchasePaymentNoteController.clear();
        selectedPurchaseSource.value = null;
        for (final item in purchaseCart) {
          item.dispose();
        }
        purchaseCart.clear();
        totalCost.value = 0;
        billModel.map((e) => e.productIdController.clear()).toList();
        billModel.map((e) => e.quantityController.clear()).toList();
        billModel.map((e) => e.priceController.clear()).toList();
        Get.offNamed(AppRoutes.BILLSSCREEN);
      });
      getBills();
      Get.find<ReturnPurchasesController>().getReturnBills();
      Helpers.showCustomDialogSuccess(
        context: context,
        title: 'success'.tr,
        message: success,
      );
    });

    isAddLoading(false);
    update();
  }

  Future<bool> receiveAllShownItems(BuildContext context) async {
    final details = billDetails;
    if (details == null) return false;
    final items = details.products
        .map((product) => {
              'bill_item_id': product.billItemId,
              'accepted_quantity': product.remainingQuantity,
              'unit_price': product.price,
            })
        .where((item) => (item['accepted_quantity'] as num) > 0)
        .toList();
    if (items.isEmpty) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'لا توجد كميات متبقية للاستلام',
      );
      return false;
    }
    return _runWorkflowAction(
      context,
      purchaseWorkflowUsecase.receive(
        billId: details.billId.toString(),
        items: items,
      ),
      showSuccess: false,
    );
  }

  void prepareReceivingRows() {
    for (final row in receivingRows) {
      row.dispose();
    }
    final details = billDetails;
    receivingRows.clear();
    if (details == null) return;
    receivingRows.assignAll(
      details.products
          .where((product) => product.remainingQuantity > 0)
          .map((product) => PurchaseReceivingRowModel(product: product)),
    );
    update();
  }

  Future<bool> submitReviewedReceiving(BuildContext context) async {
    final details = billDetails;
    if (details == null) return false;
    final items = <Map<String, dynamic>>[];
    for (final row in receivingRows) {
      if (row.isEmpty) continue;
      if (!row.isValid) {
        Helpers.showCustomDialogError(
          context: context,
          title: 'error'.tr,
          message: 'راجع كميات ${row.product.productName}',
        );
        return false;
      }
      items.add(row.toApiMap());
    }
    if (items.isEmpty) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب إدخال استلام لصنف واحد على الأقل',
      );
      return false;
    }
    return _runWorkflowAction(
      context,
      purchaseWorkflowUsecase.receive(
        billId: details.billId.toString(),
        items: items,
      ),
      showSuccess: false,
    );
  }

  Future<bool> finalizeShownPurchase(
    BuildContext context, {
    String initialPayment = '0',
    String? boxId,
  }) async {
    final details = billDetails;
    if (details == null) return false;
    return _runWorkflowAction(
      context,
      purchaseWorkflowUsecase.finalize(
        billId: details.billId.toString(),
        initialPayment: initialPayment,
        boxId: boxId,
      ),
      showSuccess: false,
    );
  }

  Future<void> loadPurchaseBoxes() async {
    if (purchaseBoxes.isNotEmpty) return;
    final boxes = await getShownBoxUsecase.call(screen: 0);
    purchaseBoxes.assignAll(boxes);
    if (boxes.isNotEmpty) {
      selectedPurchaseBox.value = boxes.first;
    }
    update();
  }

  void selectPurchaseBox(ShownBoxesModel? box) {
    selectedPurchaseBox.value = box;
    update();
  }

  void preparePaymentAmount({String? amount}) {
    purchasePaymentAmountController.text = amount ?? '';
    purchasePaymentNoteController.clear();
    purchasePaymentEvidenceFiles.clear();
    clearOpenPurchaseBills();
    update();
  }

  void clearOpenPurchaseBills() {
    for (final bill in openPurchaseBills) {
      bill.dispose();
    }
    openPurchaseBills.clear();
  }

  void prepareAmanatAction({
    required String quantity,
    String? unitPrice,
  }) {
    amanatQuantityController.text = quantity;
    amanatUnitPriceController.text = unitPrice ?? '';
    amanatNoteController.clear();
  }

  void prepareIssueResolution({
    required String quantity,
    String? unitPrice,
  }) {
    issueQuantityController.text = quantity;
    issueUnitPriceController.text = unitPrice ?? '';
    issueAdjustmentController.clear();
    issueReasonController.clear();
    issueNotesController.clear();
  }

  Future<bool> payShownPurchase(
    BuildContext context, {
    required String amount,
    required String boxId,
    String? note,
    List<dio.MultipartFile> evidenceFiles = const [],
    bool showSuccess = true,
  }) async {
    final details = billDetails;
    if (details == null) return false;
    return _runWorkflowAction(
      context,
      purchaseWorkflowUsecase.pay(
        billId: details.billId.toString(),
        amount: amount,
        boxId: boxId,
        note: note,
        evidenceFiles: evidenceFiles,
      ),
      showSuccess: showSuccess,
    );
  }

  Future<bool> payPurchaseBillFromList(
    BuildContext context, {
    required BillDataModel bill,
  }) async {
    final box = selectedPurchaseBox.value;
    if (box == null) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب اختيار صندوق',
      );
      return false;
    }
    final amount = purchasePaymentAmountController.text.trim();
    if (amount.isEmpty || (num.tryParse(amount) ?? 0) <= 0) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب إدخال مبلغ صحيح',
      );
      return false;
    }

    isWorkflowLoading(true);
    update();
    final result = await purchaseWorkflowUsecase.pay(
      billId: bill.id.toString(),
      amount: amount,
      boxId: box.boxId.toString(),
      note: purchasePaymentNoteController.text.trim(),
      evidenceFiles: await _buildPaymentEvidenceMultipart(context),
    );
    var ok = false;
    result.fold(
      (failure) {
        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: failure.data['message'],
        );
      },
      (success) {
        ok = true;
        Helpers.showCustomDialogSuccess(
          context: context,
          title: 'success'.tr,
          message: success,
        );
        getBills();
      },
    );
    isWorkflowLoading(false);
    update();
    return ok;
  }

  Future<void> loadOpenPurchaseAccountBills() async {
    final details = billDetails;
    if (details == null) return;
    final sellerId = details.sellerId;
    final customerId = details.customerId;
    if (sellerId.isEmpty && customerId.isEmpty) return;
    isOpenPurchaseBillsLoading(true);
    update();
    try {
      final result = await purchaseWorkflowUsecase.openAccountBills(
        sellerId: sellerId,
        customerId: customerId,
        currency: selectedPurchaseBox.value?.currency,
      );
      clearOpenPurchaseBills();
      openPurchaseBills.assignAll(
        mapListFromResponseKey(
          result,
          'bills',
          (Map<String, dynamic> m) =>
              PurchaseOpenBillAllocationModel.fromJson(m),
          debugScope: 'BillsController.openPurchaseAccountBills',
        ),
      );
    } catch (_) {
      clearOpenPurchaseBills();
    }
    isOpenPurchaseBillsLoading(false);
    update();
  }

  Future<bool> paySupplierAccountForShownSeller(BuildContext context) async {
    final details = billDetails;
    final box = selectedPurchaseBox.value;
    if (details == null) return false;
    final sellerId = details.sellerId;
    final customerId = details.customerId;
    if (sellerId.isEmpty && customerId.isEmpty) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'لا يوجد مصدر مرتبط بالفاتورة',
      );
      return false;
    }
    if (box == null) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب اختيار صندوق',
      );
      return false;
    }
    final amount = purchasePaymentAmountController.text.trim();
    if (amount.isEmpty || (num.tryParse(amount) ?? 0) <= 0) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب إدخال مبلغ صحيح',
      );
      return false;
    }
    final allocations = openPurchaseBills
        .map((bill) => bill.toAllocation())
        .whereType<Map<String, dynamic>>()
        .toList();
    final evidenceFiles = await _buildPaymentEvidenceMultipart(context);
    if (!context.mounted) return false;
    return _runWorkflowAction(
      context,
      purchaseWorkflowUsecase.paySupplierAccount(
        sellerId: sellerId,
        customerId: customerId,
        amount: amount,
        boxId: box.boxId.toString(),
        note: purchasePaymentNoteController.text.trim(),
        allocateOldestFirst: allocations.isEmpty,
        allocations: allocations,
        evidenceFiles: evidenceFiles,
      ),
      showSuccess: false,
    );
  }

  Future<void> loadPurchaseTimeline(String billId) async {
    isTimelineLoading(true);
    update();
    try {
      final result = await purchaseWorkflowUsecase.timeline(billId: billId);
      purchaseTimeline.assignAll(
        mapListFromResponseKey(
          result,
          'timeline',
          (Map<String, dynamic> m) => m,
          debugScope: 'BillsController.purchaseTimeline',
        ),
      );
    } catch (_) {
      purchaseTimeline.clear();
    }
    isTimelineLoading(false);
    update();
  }

  Future<bool> purchaseShownAmanat(
    BuildContext context, {
    required String amanatId,
  }) async {
    final quantity = amanatQuantityController.text.trim();
    final unitPrice = amanatUnitPriceController.text.trim();
    if (quantity.isEmpty || (num.tryParse(quantity) ?? 0) <= 0) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب إدخال كمية صحيحة',
      );
      return false;
    }
    if (unitPrice.isEmpty || (num.tryParse(unitPrice) ?? 0) < 0) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب إدخال سعر صحيح',
      );
      return false;
    }
    return _runWorkflowAction(
      context,
      purchaseWorkflowUsecase.purchaseAmanat(
        amanatId: amanatId,
        quantity: quantity,
        unitPrice: unitPrice,
      ),
      showSuccess: false,
    );
  }

  Future<bool> returnShownAmanat(
    BuildContext context, {
    required String amanatId,
  }) async {
    final quantity = amanatQuantityController.text.trim();
    if (quantity.isEmpty || (num.tryParse(quantity) ?? 0) <= 0) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب إدخال كمية صحيحة',
      );
      return false;
    }
    return _runWorkflowAction(
      context,
      purchaseWorkflowUsecase.returnAmanat(
        amanatId: amanatId,
        quantity: quantity,
        note: amanatNoteController.text.trim(),
      ),
      showSuccess: false,
    );
  }

  Future<bool> resolveShownIssue(
    BuildContext context, {
    required BillProductModel product,
    required String issueType,
    required String resolution,
  }) async {
    final details = billDetails;
    if (details == null) return false;
    final quantity = issueQuantityController.text.trim();
    if (quantity.isEmpty || (num.tryParse(quantity) ?? 0) <= 0) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب إدخال كمية صحيحة',
      );
      return false;
    }
    if ((resolution == 'accept_with_discount' ||
            resolution == 'accept_negotiated_price') &&
        ((num.tryParse(issueUnitPriceController.text.trim()) ?? -1) < 0)) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب إدخال سعر تفاوضي صحيح',
      );
      return false;
    }
    return _runWorkflowAction(
      context,
      purchaseWorkflowUsecase.resolveIssue(
        billId: details.billId.toString(),
        billItemId: product.billItemId.toString(),
        issueType: issueType,
        resolution: resolution,
        quantity: quantity,
        negotiatedUnitPrice: issueUnitPriceController.text.trim(),
        financialAdjustment: issueAdjustmentController.text.trim(),
        reason: issueReasonController.text.trim(),
        notes: issueNotesController.text.trim(),
      ),
      showSuccess: false,
    );
  }

  Future<void> pickAndUploadPurchaseAttachments(
    BuildContext context, {
    String category = 'evidence',
    String? attachableType,
    String? attachableId,
  }) async {
    final details = billDetails;
    if (details == null) return;
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: false,
    );
    if (!context.mounted) return;
    if (picked == null || picked.files.isEmpty) return;
    final multipart = <dio.MultipartFile>[];
    for (final file in picked.files) {
      if (file.path == null) continue;
      multipart.add(
        await dio.MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        ),
      );
    }
    if (!context.mounted) return;
    if (multipart.isEmpty) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'تعذر قراءة الملفات المختارة',
      );
      return;
    }
    await _runWorkflowAction(
      context,
      purchaseWorkflowUsecase.uploadAttachments(
        billId: details.billId.toString(),
        files: multipart,
        category: category,
        attachableType: attachableType,
        attachableId: attachableId,
      ),
    );
  }

  Future<void> pickPurchasePaymentEvidence(BuildContext context) async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: false,
    );
    if (!context.mounted) return;
    if (picked == null || picked.files.isEmpty) return;
    final readable = picked.files.where((file) => file.path != null).toList();
    if (readable.isEmpty) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'تعذر قراءة الملفات المختارة',
      );
      return;
    }
    purchasePaymentEvidenceFiles.assignAll(readable);
    update();
  }

  void removePurchasePaymentEvidence(PlatformFile file) {
    purchasePaymentEvidenceFiles.remove(file);
    update();
  }

  Future<List<dio.MultipartFile>> _buildPaymentEvidenceMultipart(
    BuildContext context,
  ) async {
    final multipart = <dio.MultipartFile>[];
    for (final file in purchasePaymentEvidenceFiles) {
      if (file.path == null) continue;
      multipart.add(
        await dio.MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        ),
      );
    }
    if (purchasePaymentEvidenceFiles.isNotEmpty &&
        multipart.isEmpty &&
        context.mounted) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'تعذر قراءة ملفات الإثبات المختارة',
      );
    }
    return multipart;
  }

  Future<bool> _runWorkflowAction(
    BuildContext context,
    Future<dynamic> future, {
    bool showSuccess = true,
  }) async {
    isWorkflowLoading(true);
    update();
    final result = await future;
    result.fold((failure) {
      Helpers.showCustomDialogError(
        context: context,
        title: failure.errMessage,
        message: failure.data['message'],
      );
    }, (success) {
      if (showSuccess) {
        Helpers.showCustomDialogSuccess(
          context: context,
          title: 'success'.tr,
          message: success,
        );
      }
      if (billDetails != null) {
        getBillDetails(
          context: context,
          billId: billDetails!.billId.toString(),
        );
      }
      getBills();
    });
    isWorkflowLoading(false);
    update();
    return result.isRight();
  }

  Future<bool> submitShownPurchasePayment(BuildContext context) async {
    final box = selectedPurchaseBox.value;
    if (box == null) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب اختيار صندوق',
      );
      return false;
    }
    final amount = purchasePaymentAmountController.text.trim();
    if (amount.isEmpty || (num.tryParse(amount) ?? 0) <= 0) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب إدخال مبلغ صحيح',
      );
      return false;
    }
    final evidenceFiles = await _buildPaymentEvidenceMultipart(context);
    if (!context.mounted) return false;
    return payShownPurchase(
      context,
      amount: amount,
      boxId: box.boxId.toString(),
      note: purchasePaymentNoteController.text.trim(),
      evidenceFiles: evidenceFiles,
      showSuccess: false,
    );
  }

  Future<bool> finalizeShownPurchaseWithInitialPayment(
    BuildContext context,
  ) async {
    final box = selectedPurchaseBox.value;
    final amount = purchasePaymentAmountController.text.trim();
    final parsed = num.tryParse(amount) ?? 0;
    if (parsed > 0 && box == null) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب اختيار صندوق للدفعة الأولية',
      );
      return false;
    }
    return finalizeShownPurchase(
      context,
      initialPayment: parsed > 0 ? amount : '0',
      boxId: box?.boxId.toString(),
    );
  }

  final allBillsSearch = <String, List<BillDataModel>>{}.obs;
  final allBillsArchiveSearch = <String, List<BillDataModel>>{}.obs;

  bool _billMatchesState(BillDataModel bill, String filter) {
    if (filter == 'all') return true;
    final haystack = [
      bill.status,
      bill.workflowStatus,
      bill.paymentStatus,
    ].join(' ').toLowerCase();
    switch (filter) {
      case 'awaiting_receiving':
        return haystack.contains('awaiting_receiving') ||
            haystack.contains('draft');
      case 'partially_received':
        return haystack.contains('partially_received');
      case 'receiving_issues':
        return haystack.contains('issue') ||
            haystack.contains('discrep') ||
            haystack.contains('damaged') ||
            haystack.contains('mismatch');
      case 'awaiting_finalization':
        return haystack.contains('awaiting_finalization') ||
            haystack.contains('received');
      case 'unpaid':
        return haystack.contains('unpaid');
      case 'partially_paid':
        return haystack.contains('partial');
      case 'paid':
        return haystack.contains('paid') && !haystack.contains('unpaid');
      default:
        return haystack.contains(filter.toLowerCase());
    }
  }

  Map<String, List<BillDataModel>> _filterBillGroups(
    Map<String, List<BillDataModel>> source,
  ) {
    final query = searchController.text.trim().toLowerCase();
    final state = purchaseBillStateFilter.value;
    return Map.fromEntries(
      source.entries.map((entry) {
        final filteredBills = entry.value.where((bill) {
          final textMatches = query.isEmpty ||
              bill.seller.toLowerCase().contains(query) ||
              bill.id.toString().contains(query);
          return textMatches && _billMatchesState(bill, state);
        }).toList();
        return MapEntry(entry.key, filteredBills);
      }).where((entry) => entry.value.isNotEmpty),
    );
  }

  void _applyPurchaseBillFilters() {
    allBillsSearch.assignAll(_filterBillGroups(BuyingServes().allBillsTasks));
    allBillsArchiveSearch
        .assignAll(_filterBillGroups(BuyingServes().allBillsArchiveTasks));
  }

  void searchBar(String value) {
    searchController.text = value;
    _applyPurchaseBillFilters();
    update();
  }

  @override
  void onInit() {
    purchasePaymentAmountController.addListener(_refreshPurchasePaymentSummary);
    getBills();
    getAllProducts();
    getAllPurchaseSources();
    loadPurchaseBoxes();
    loadAmanatDashboard();
    loadDiscrepanciesDashboard();
    allBillsSearch.assignAll(BuyingServes().allBillsTasks);
    allBillsArchiveSearch.assignAll(BuyingServes().allBillsArchiveTasks);
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
    super.onInit();
  }

  void _refreshPurchasePaymentSummary() {
    update(['purchaseCheckoutSummary']);
  }

  @override
  void onClose() {
    animController.dispose();
    opacityAnimation.isDismissed;
    sizeAnimation.isDismissed;
    sellerIdController.dispose();
    customerIdController.dispose();
    discountController.dispose();
    searchController.dispose();
    purchaseNotesController.dispose();
    purchaseProductSearchController.dispose();
    for (final item in purchaseCart) {
      item.dispose();
    }
    purchasePaymentAmountController
        .removeListener(_refreshPurchasePaymentSummary);
    purchasePaymentAmountController.dispose();
    purchasePaymentNoteController.dispose();
    purchaseReturnNoteController.dispose();
    amanatQuantityController.dispose();
    amanatUnitPriceController.dispose();
    amanatNoteController.dispose();
    issueQuantityController.dispose();
    issueUnitPriceController.dispose();
    issueAdjustmentController.dispose();
    issueReasonController.dispose();
    issueNotesController.dispose();
    for (final row in receivingRows) {
      row.dispose();
    }
    clearOpenPurchaseBills();
    super.onClose();
  }
}

class BillModel {
  final TextEditingController productIdController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  final RxDouble totalPrice = 0.0.obs;

  final RxInt totalQuantity = 0.obs;

  void _updateTotal() {
    final price = double.tryParse(priceController.text.trim()) ?? 0;
    final quantity = double.tryParse(quantityController.text.trim()) ?? 0;
    totalPrice.value = price * quantity;
    totalQuantity.value = quantity.toInt();
  }

  BillModel() {
    priceController.addListener(_updateTotal);
    quantityController.addListener(_updateTotal);
  }

  void onClose() {
    productIdController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}

class PurchaseSourceModel {
  final int id;
  final String name;
  final String phone;
  final bool hasSeller;
  final bool hasCustomer;
  final int? sellerId;
  final int? customerId;

  const PurchaseSourceModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.hasSeller,
    required this.hasCustomer,
    this.sellerId,
    this.customerId,
  });

  String get typeLabel {
    if (hasSeller && hasCustomer) return 'مورد + زبون';
    if (hasSeller) return 'مورد';
    return 'زبون';
  }
}

class PurchaseCartItemModel {
  final ProductModel product;
  final TextEditingController quantityController;
  final TextEditingController priceController;
  final VoidCallback? onChanged;

  PurchaseCartItemModel({required this.product, this.onChanged})
      : quantityController = TextEditingController(text: '1'),
        priceController = TextEditingController(
          text: product.purchaseCost > 0
              ? product.purchaseCost.toStringAsFixed(2)
              : '',
        ) {
    if (onChanged != null) {
      quantityController.addListener(onChanged!);
      priceController.addListener(onChanged!);
    }
  }

  num get quantity => num.tryParse(quantityController.text.trim()) ?? 0;
  num get unitPrice => num.tryParse(priceController.text.trim()) ?? 0;
  num get total => quantity * unitPrice;

  void dispose() {
    if (onChanged != null) {
      quantityController.removeListener(onChanged!);
      priceController.removeListener(onChanged!);
    }
    quantityController.dispose();
    priceController.dispose();
  }
}

class PurchaseReceivingRowModel {
  final BillProductModel product;
  final TextEditingController deliveredNowController;
  final TextEditingController acceptedController;
  final TextEditingController missingController;
  final TextEditingController extraController;
  final TextEditingController damagedController;
  final TextEditingController mismatchedController;
  final TextEditingController unitPriceController;
  final TextEditingController reasonController;
  final TextEditingController notesController;
  bool hasExtra = false;
  bool hasDamaged = false;
  bool hasMismatched = false;
  bool editUnitPrice = false;

  PurchaseReceivingRowModel({required this.product})
      : deliveredNowController = TextEditingController(),
        acceptedController = TextEditingController(),
        missingController = TextEditingController(),
        extraController = TextEditingController(),
        damagedController = TextEditingController(),
        mismatchedController = TextEditingController(),
        unitPriceController = TextEditingController(text: product.price),
        reasonController = TextEditingController(),
        notesController = TextEditingController();

  num get deliveredNow => _num(deliveredNowController);
  num get accepted => _num(acceptedController);
  num get missing => _num(missingController);
  num get extra => _num(extraController);
  num get damaged => _num(damagedController);
  num get mismatched => _num(mismatchedController);
  bool get hasDeliveredEntry => deliveredNowController.text.trim().isNotEmpty;
  num get effectiveExtra {
    if (!hasDeliveredEntry) return hasExtra ? extra : 0;
    if (hasExtra) return extra;
    final surplus =
        deliveredNow - product.remainingQuantity - damaged - mismatched;
    return surplus > 0 ? surplus : 0;
  }

  num get autoAccepted {
    if (!hasDeliveredEntry || deliveredNow <= 0) return 0;
    final issueTotal = effectiveExtra + damaged + mismatched;
    final owned = deliveredNow - issueTotal;
    if (owned <= 0 || issueTotal >= deliveredNow) return 0;
    return owned > product.remainingQuantity
        ? product.remainingQuantity
        : owned;
  }

  num get autoMissing {
    final missing = product.remainingQuantity - autoAccepted;
    return missing > 0 ? missing : 0;
  }

  bool get isEmpty =>
      !hasDeliveredEntry &&
      accepted <= 0 &&
      missing <= 0 &&
      effectiveExtra <= 0 &&
      damaged <= 0 &&
      mismatched <= 0;

  bool get isValid {
    if (accepted < 0 ||
        missing < 0 ||
        effectiveExtra < 0 ||
        damaged < 0 ||
        mismatched < 0) {
      return false;
    }
    final effectiveAccepted = hasDeliveredEntry ? autoAccepted : accepted;
    final effectiveMissing = hasDeliveredEntry ? autoMissing : missing;
    if (effectiveAccepted > product.remainingQuantity) return false;
    if (effectiveAccepted + effectiveMissing > product.remainingQuantity) {
      return false;
    }
    if (hasDeliveredEntry &&
        effectiveAccepted + effectiveExtra + damaged + mismatched >
            deliveredNow) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> toApiMap() {
    final effectiveAccepted = hasDeliveredEntry ? autoAccepted : accepted;
    final effectiveMissing = hasDeliveredEntry ? autoMissing : missing;
    return {
      'bill_item_id': product.billItemId,
      'accepted_quantity': effectiveAccepted,
      'missing_quantity': effectiveMissing,
      'extra_quantity': effectiveExtra,
      'damaged_quantity': hasDamaged ? damaged : 0,
      'mismatched_quantity': hasMismatched ? mismatched : 0,
      'unit_price': unitPriceController.text.trim(),
      if (reasonController.text.trim().isNotEmpty)
        'reason': reasonController.text.trim(),
      if (notesController.text.trim().isNotEmpty)
        'notes': notesController.text.trim(),
    };
  }

  num _num(TextEditingController controller) {
    return num.tryParse(controller.text.trim()) ?? 0;
  }

  void setIssueEnabled(String type, bool enabled) {
    switch (type) {
      case 'extra':
        hasExtra = enabled;
        if (!enabled) extraController.clear();
        break;
      case 'damaged':
        hasDamaged = enabled;
        if (!enabled) damagedController.clear();
        break;
      case 'mismatched':
        hasMismatched = enabled;
        if (!enabled) mismatchedController.clear();
        break;
      case 'price':
        editUnitPrice = enabled;
        if (!enabled) unitPriceController.text = product.price;
        break;
    }
  }

  void dispose() {
    deliveredNowController.dispose();
    acceptedController.dispose();
    missingController.dispose();
    extraController.dispose();
    damagedController.dispose();
    mismatchedController.dispose();
    unitPriceController.dispose();
    reasonController.dispose();
    notesController.dispose();
  }
}

class PurchaseOpenBillAllocationModel {
  final int billId;
  final String sourceName;
  final String currency;
  final num finalTotal;
  final num paidAmount;
  final num remainingAmount;
  final String finalizedAt;
  final TextEditingController amountController = TextEditingController();

  PurchaseOpenBillAllocationModel({
    required this.billId,
    required this.sourceName,
    required this.currency,
    required this.finalTotal,
    required this.paidAmount,
    required this.remainingAmount,
    required this.finalizedAt,
  });

  factory PurchaseOpenBillAllocationModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOpenBillAllocationModel(
      billId: asInt(json['id']),
      sourceName: asString(json['source_name']),
      currency: asString(json['currency']),
      finalTotal: asDouble(json['final_total']),
      paidAmount: asDouble(json['paid_amount']),
      remainingAmount: asDouble(json['remaining_amount']),
      finalizedAt: asString(json['finalized_at']),
    );
  }

  Map<String, dynamic>? toAllocation() {
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    if (amount <= 0) return null;
    return {
      'bill_id': billId,
      'amount': amount,
    };
  }

  void fillRemaining() {
    amountController.text = remainingAmount.toStringAsFixed(2);
  }

  void dispose() {
    amountController.dispose();
  }
}
