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
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../../sales/data/models/product_model.dart';
import '../../../sales/domain/usecases/get_all_products_usecase.dart';
import '../../data/models/bills_models/bills_details_model.dart';
import '../../data/models/bills_models/bills_model.dart';
import '../../domain/usecases/bills_usecases/add_bill_usecase.dart';
import '../../domain/usecases/get_bills_usecase.dart';
import '../../domain/usecases/get_billt_details_usecase.dart';
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

  BillsController({
    required this.getBillsUsecase,
    required this.getAllProductsUsecase,
    required this.allCustomersSellersUsecase,
    required this.addBillUsecase,
    required this.getBilltDetailsUsecase,
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
        'unfinished rawType=${bills.runtimeType} keys=${bills is Map ? (bills as Map).keys.toList() : []}',
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
        'archive rawType=${billsArchive.runtimeType} keys=${billsArchive is Map ? (billsArchive as Map).keys.toList() : []}',
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
    }

    isAddLoading(false);
    update();
  }

  final RxBool isAddLoading = false.obs;
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
