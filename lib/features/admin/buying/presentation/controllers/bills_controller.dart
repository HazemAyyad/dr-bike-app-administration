import 'dart:io';

import 'package:doctorbike/core/helpers/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
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
  final TextEditingController discountController = TextEditingController();

  final TextEditingController searchController = TextEditingController();

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

  final RxInt totalCost = 0.obs;

  void calculateGrandTotal() {
    int cost = 0;

    for (BillModel item in billModel) {
      cost += item.totalPrice.value.toInt();
    }
    if (discountController.text.isNotEmpty) {
      cost -= int.parse(discountController.text);
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

  void changeTab(int index) {
    currentTab.value = index;
    update();
  }

  // get all products
  final List<ProductModel> products = [];
  void getAllProducts() async {
    final result = await getAllProductsUsecase.call();
    products.assignAll(result);
  }

  // get all sellers
  final RxList<SellerModel> allSellersList = <SellerModel>[].obs;
  void getAllSellers() async {
    final resultSellers =
        await allCustomersSellersUsecase.call(endPoint: EndPoints.all_sellers);
    allSellersList.assignAll(resultSellers);
    isLoading(false);
  }

  RxBool isLoading = false.obs;

  void getBills() async {
    BuyingServes().allBillsTasks.isEmpty ? isLoading(true) : null;
    update();

    // دالة مساعدة للتجميع
    Map<String, List<BillDataModel>> groupByDate(List<BillDataModel> list) {
      final Map<String, List<BillDataModel>> grouped = {};

      for (var task in list) {
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
          return aDate.compareTo(bDate); // الأحدث الأول
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
    allBillsSearch.assignAll(BuyingServes().allBillsTasks);
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
    allBillsArchiveSearch.assignAll(BuyingServes().allBillsArchiveTasks);

    isLoading(false);
    update();
  }

  // get bill details
  BillDetailsModel? billDetails;
  void getBillDetails({
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
      loadPurchaseTimeline(billId);
    }

    isAddLoading(false);
    update();
  }

  final RxBool isAddLoading = false.obs;
  final RxBool isWorkflowLoading = false.obs;
  final RxBool isTimelineLoading = false.obs;
  final RxList<Map<String, dynamic>> purchaseTimeline =
      <Map<String, dynamic>>[].obs;
  final RxList<ShownBoxesModel> purchaseBoxes = <ShownBoxesModel>[].obs;
  final Rxn<ShownBoxesModel> selectedPurchaseBox = Rxn<ShownBoxesModel>();
  final TextEditingController purchasePaymentAmountController =
      TextEditingController();
  final TextEditingController purchasePaymentNoteController =
      TextEditingController();
  String isaddNewBill = '1';
  // add bill
  void addBill(BuildContext context) async {
    isAddLoading(true);
    final result = await addBillUsecase.call(
      page: isaddNewBill,
      sellerId: sellerIdController.text,
      products: billModel,
      total: totalCost.value.toString(),
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
        discountController.clear();
        totalCost.value = 0;
        billModel.map((e) => e.productIdController.clear()).toList();
        billModel.map((e) => e.quantityController.clear()).toList();
        billModel.map((e) => e.priceController.clear()).toList();
        Get.back();
        Get.back();
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

  Future<void> receiveAllShownItems(BuildContext context) async {
    final details = billDetails;
    if (details == null) return;
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
      return;
    }
    await _runWorkflowAction(
      context,
      purchaseWorkflowUsecase.receive(
        billId: details.billId.toString(),
        items: items,
      ),
    );
  }

  Future<void> finalizeShownPurchase(
    BuildContext context, {
    String initialPayment = '0',
    String? boxId,
  }) async {
    final details = billDetails;
    if (details == null) return;
    await _runWorkflowAction(
      context,
      purchaseWorkflowUsecase.finalize(
        billId: details.billId.toString(),
        initialPayment: initialPayment,
        boxId: boxId,
      ),
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
  }

  Future<void> payShownPurchase(
    BuildContext context, {
    required String amount,
    required String boxId,
    String? note,
  }) async {
    final details = billDetails;
    if (details == null) return;
    await _runWorkflowAction(
      context,
      purchaseWorkflowUsecase.pay(
        billId: details.billId.toString(),
        amount: amount,
        boxId: boxId,
        note: note,
      ),
    );
  }

  Future<void> paySupplierAccountForShownSeller(BuildContext context) async {
    final details = billDetails;
    final box = selectedPurchaseBox.value;
    if (details == null) return;
    if (details.sellerId.isEmpty) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'لا يوجد مورد مرتبط بالفاتورة',
      );
      return;
    }
    if (box == null) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب اختيار صندوق',
      );
      return;
    }
    final amount = purchasePaymentAmountController.text.trim();
    if (amount.isEmpty || (num.tryParse(amount) ?? 0) <= 0) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب إدخال مبلغ صحيح',
      );
      return;
    }
    await _runWorkflowAction(
      context,
      purchaseWorkflowUsecase.paySupplierAccount(
        sellerId: details.sellerId,
        amount: amount,
        boxId: box.boxId.toString(),
        note: purchasePaymentNoteController.text.trim(),
      ),
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

  Future<void> _runWorkflowAction(
    BuildContext context,
    Future<dynamic> future,
  ) async {
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
      Helpers.showCustomDialogSuccess(
        context: context,
        title: 'success'.tr,
        message: success,
      );
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
  }

  Future<void> submitShownPurchasePayment(BuildContext context) async {
    final box = selectedPurchaseBox.value;
    if (box == null) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب اختيار صندوق',
      );
      return;
    }
    final amount = purchasePaymentAmountController.text.trim();
    if (amount.isEmpty || (num.tryParse(amount) ?? 0) <= 0) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'يجب إدخال مبلغ صحيح',
      );
      return;
    }
    await payShownPurchase(
      context,
      amount: amount,
      boxId: box.boxId.toString(),
      note: purchasePaymentNoteController.text.trim(),
    );
  }

  Future<void> finalizeShownPurchaseWithInitialPayment(
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
      return;
    }
    await finalizeShownPurchase(
      context,
      initialPayment: parsed > 0 ? amount : '0',
      boxId: box?.boxId.toString(),
    );
  }

  final allBillsSearch = <String, List<BillDataModel>>{}.obs;
  final allBillsArchiveSearch = <String, List<BillDataModel>>{}.obs;

  void searchBar(String value) {
    if (value.isNotEmpty) {
      allBillsSearch.value = Map.fromEntries(
        BuyingServes().allBillsTasks.entries.map((entry) {
          final filteredBills = entry.value
              .where((bill) =>
                  bill.seller.toLowerCase().contains(value.toLowerCase()))
              .toList();
          return MapEntry(entry.key, filteredBills);
        }).where((entry) => entry.value.isNotEmpty),
      );

      allBillsArchiveSearch.value = Map.fromEntries(
        BuyingServes().allBillsArchiveTasks.entries.map((entry) {
          final filteredBills = entry.value
              .where((bill) =>
                  bill.seller.toLowerCase().contains(value.toLowerCase()))
              .toList();
          return MapEntry(entry.key, filteredBills);
        }).where((entry) => entry.value.isNotEmpty),
      );
    } else {
      allBillsSearch.assignAll(BuyingServes().allBillsTasks);
      allBillsArchiveSearch.assignAll(BuyingServes().allBillsArchiveTasks);
    }
    update();
  }

  @override
  void onInit() {
    getBills();
    getAllProducts();
    getAllSellers();
    loadPurchaseBoxes();
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

  @override
  void onClose() {
    animController.dispose();
    opacityAnimation.isDismissed;
    sizeAnimation.isDismissed;
    sellerIdController.dispose();
    discountController.dispose();
    searchController.dispose();
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
