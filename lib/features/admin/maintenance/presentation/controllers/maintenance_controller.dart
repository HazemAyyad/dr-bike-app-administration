import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
import '../../data/models/maintenance_product_model.dart';
import '../../data/models/maintenances_model.dart';
import '../../domain/usecases/creat_maintenance_usecase.dart';
import '../../domain/usecases/deliver_maintenance_usecase.dart';
import '../../domain/usecases/get_maintenance_activity_log_usecase.dart';
import '../../domain/usecases/get_maintenance_invoice_usecase.dart';
import '../../domain/usecases/get_maintenances_details_usecase.dart';
import '../../domain/usecases/maintenance_usecase.dart';
import '../../domain/usecases/sync_maintenance_products_usecase.dart';
import 'maintenance_serves.dart';
import '../widgets/maintenance_activity_log_sheet.dart';
import '../widgets/maintenance_delivery_dialog.dart';
import '../widgets/maintenance_invoice_sheet.dart';

class MaintenanceController extends GetxController {
  final MaintenanceUsecase maintenanceUsecase;
  final CreatMaintenanceUsecase creatMaintenanceUsecase;
  final AllCustomersSellersUsecase allCustomersSellersUsecase;
  final GetMaintenancesDetailsUsecase getMaintenancesDetailsUsecase;
  final SyncMaintenanceProductsUsecase syncMaintenanceProductsUsecase;
  final DeliverMaintenanceUsecase deliverMaintenanceUsecase;
  final GetMaintenanceActivityLogUsecase getMaintenanceActivityLogUsecase;
  final GetMaintenanceInvoiceUsecase getMaintenanceInvoiceUsecase;
  final GetShownBoxUsecase getShownBoxUsecase;

  MaintenanceController({
    required this.maintenanceUsecase,
    required this.creatMaintenanceUsecase,
    required this.allCustomersSellersUsecase,
    required this.getMaintenancesDetailsUsecase,
    required this.syncMaintenanceProductsUsecase,
    required this.deliverMaintenanceUsecase,
    required this.getMaintenanceActivityLogUsecase,
    required this.getMaintenanceInvoiceUsecase,
    required this.getShownBoxUsecase,
  });

  final formKey = GlobalKey<FormState>();
  TextEditingController employeeNameController = TextEditingController();
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();
  TextEditingController partnerIdController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController laborCostController = TextEditingController();
  TextEditingController discountController = TextEditingController();

  RxInt currentTab = 0.obs;
  RxBool selectedSellers = false.obs;
  RxBool isCalendarVisible = false.obs;
  RxBool isTimeVisible = false.obs;
  RxInt selectedStep = 1.obs;
  RxBool isEditLoading = false.obs;
  RxBool isEdit = false.obs;
  RxBool isDelivered = false.obs;
  final RxBool isLoading = false.obs;
  final RxList<MaintenanceProductModel> maintenanceProducts =
      <MaintenanceProductModel>[].obs;
  final RxList<ShownBoxesModel> paymentBoxes = <ShownBoxesModel>[].obs;

  String? maintenanceId;

  final List<Map<int, String>> timeLineSteps = [
    {1: 'newMaintenance'},
    {2: 'inProgress'},
    {3: 'readyToDeliver'},
  ];

  List<String> tabs = ['newRequest', 'inProgress', 'readyToDeliver', 'archive'];

  double get laborCost => SalesAmountFormat.parse(laborCostController.text);
  double get discount => SalesAmountFormat.parse(discountController.text);
  double get partsTotal => maintenanceProducts.fold(
        0.0,
        (sum, item) => sum + item.lineTotal,
      );
  double get invoiceTotal =>
      (partsTotal + laborCost - discount).clamp(0, double.infinity);

  void changeTab(int index) {
    currentTab.value = index;
    update();
  }

  void changeSelected(int index) => selectedStep.value = index;

  void recalculateTotals() => maintenanceProducts.refresh();

  @override
  void onClose() {
    employeeNameController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    partnerIdController.dispose();
    descriptionController.dispose();
    laborCostController.dispose();
    discountController.dispose();
    super.onClose();
  }

  void nextStep() async {
    if (!formKey.currentState!.validate()) return;

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

  void prevStep() {
    if (selectedStep.value <= 1) return;
    selectedStep.value -= 1;
    createMaintenance(step: selectedStep.value, maintenanceId: maintenanceId);
  }

  final Rx<DateTime> deliveryDate = DateTime.now().obs;
  final Rx<TimeOfDay> deliveryTime = TimeOfDay.now().obs;
  List<File> selectedMedia = [];

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
    _hydrateSalesCart(sales);
    sales.setMaintenancePickerFlow(true);
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
          imageUrl: product?.preferredImageUrl?.toString() ?? '',
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
    update();
  }

  Future<void> syncProductsIfPossible() async {
    if (maintenanceId == null || maintenanceId!.isEmpty) return;
    if (isDelivered.value) return;

    await syncMaintenanceProductsUsecase.call(
      maintenanceId: maintenanceId!,
      products: maintenanceProducts.toList(),
      laborCost: laborCost,
      discount: discount,
    );
  }

  Future<bool> deliverMaintenance({
    required double paymentAmount,
    int? paymentBoxId,
  }) async {
    if (maintenanceId == null || maintenanceId!.isEmpty) return false;

    isLoading(true);
    update();

    final result = await deliverMaintenanceUsecase.call(
      maintenanceId: maintenanceId!,
      laborCost: laborCost,
      discount: discount,
      paymentAmount: paymentAmount,
      paymentBoxId: paymentBoxId,
    );

    var ok = false;
    result.fold(
      (failure) {
        Get.snackbar(
          failure.data['message']?.toString() ?? 'error'.tr,
          '',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (success) async {
        ok = true;
        isDelivered(true);
        selectedStep(4);
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

  void getMaintenancesData() async {
    if (MaintenanceServes().maintenancesList.isEmpty) isLoading(true);
    update();

    Map<String, List<MaintenanceDataModel>> groupByDate(
        List<MaintenanceDataModel> list) {
      final Map<String, List<MaintenanceDataModel>> grouped = {};
      for (var task in list) {
        final receiptDateObj = DateTime.parse(task.receiptDate);
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
          final aDate = DateTime.parse(a.value.first.receiptDate);
          final bDate = DateTime.parse(b.value.first.receiptDate);
          return aDate.compareTo(bDate);
        });
      return Map.fromEntries(sortedEntries);
    }

    final maintenancesData = await maintenanceUsecase.call(tab: 0);
    final maintenances = (maintenancesData['maintenance_details'] as List)
        .map((e) => MaintenanceDataModel.fromJson(e))
        .toList();
    MaintenanceServes().maintenancesList.assignAll(maintenances);
    MaintenanceServes().maintenancesTasks.value = groupByDate(maintenances);
    maintenancesSearch.assignAll(MaintenanceServes().maintenancesTasks);

    final ongoingData = await maintenanceUsecase.call(tab: 1);
    final ongoing = (ongoingData['maintenance_details'] as List)
        .map((e) => MaintenanceDataModel.fromJson(e))
        .toList();
    MaintenanceServes().ongoingMaintenancesList.assignAll(ongoing);
    MaintenanceServes().ongoingMaintenancesTasks.value = groupByDate(ongoing);
    ongoingMaintenancesSearch
        .assignAll(MaintenanceServes().ongoingMaintenancesTasks);

    final readyData = await maintenanceUsecase.call(tab: 2);
    final ready = (readyData['maintenance_details'] as List)
        .map((e) => MaintenanceDataModel.fromJson(e))
        .toList();
    MaintenanceServes().readyMaintenancesList.assignAll(ready);
    MaintenanceServes().readyMaintenancesTasks.value = groupByDate(ready);
    readyMaintenancesSearch
        .assignAll(MaintenanceServes().readyMaintenancesTasks);

    final archiveData = await maintenanceUsecase.call(tab: 3);
    final archive = (archiveData['maintenance_details'] as List)
        .map((e) => MaintenanceDataModel.fromJson(e))
        .toList();
    MaintenanceServes().archiveMaintenancesList.assignAll(archive);
    MaintenanceServes().archiveMaintenancesTasks.value = groupByDate(archive);
    archiveMaintenancesSearch
        .assignAll(MaintenanceServes().archiveMaintenancesTasks);

    isLoading(false);
    update();
  }

  void getMaintenancesDetails({required String maintenanceId}) async {
    isEdit(true);
    isEditLoading(true);
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
      deliveryDate.value =
          DateTime.tryParse(maintenances['receipt_date']?.toString() ?? '') ??
              DateTime.now();

      final receiptDateTime = DateTime.tryParse(
          '${maintenances['receipt_date']} ${maintenances['receipt_time']}');
      if (receiptDateTime != null) {
        deliveryTime.value = TimeOfDay.fromDateTime(receiptDateTime);
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
      laborCostController.text =
          billing.laborCost > 0 ? billing.laborCost.toString() : '';
      discountController.text =
          billing.discount > 0 ? billing.discount.toString() : '';

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
      isEditLoading(false);
      update();
    }
  }

  void clearControllers() {
    isEdit(false);
    isDelivered(false);
    maintenanceId = null;
    partnerIdController.clear();
    descriptionController.clear();
    laborCostController.clear();
    discountController.clear();
    maintenanceProducts.clear();
    deliveryDate.value = DateTime.now();
    deliveryTime.value = TimeOfDay.now();
    selectedMedia = [];
    selectedSellers(false);
    selectedStep(1);
    update();
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

  Future<void> createMaintenance({
    required int step,
    String? maintenanceId,
    bool isSave = false,
  }) async {
    if (!formKey.currentState!.validate()) return;

    isLoading(true);
    update();

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
        receipDate: deliveryDate.value.toIso8601String().split('T').first,
        receiptTime:
            '${deliveryTime.value.hour.toString().padLeft(2, '0')}:${deliveryTime.value.minute.toString().padLeft(2, '0')}',
        files: selectedMedia,
        status: status,
        laborCost: laborCost,
        discount: discount,
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
          Get.snackbar(
            failure.data['message'] ?? 'error'.tr,
            errorMessage,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        (success) async {
          final newId = success['maintenance_id'];
          if (newId != null && newId.isNotEmpty) {
            this.maintenanceId = newId;
            isEdit(true);
          }
          await syncProductsIfPossible();
          getMaintenancesData();
          if (isSave) Get.back();
          Get.snackbar(
            'success'.tr,
            success['message'] ?? '',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      );
    } finally {
      isLoading(false);
      update();
    }
  }

  final Map<String, List<MaintenanceDataModel>> maintenancesSearch = {};
  final Map<String, List<MaintenanceDataModel>> ongoingMaintenancesSearch = {};
  final Map<String, List<MaintenanceDataModel>> readyMaintenancesSearch = {};
  final Map<String, List<MaintenanceDataModel>> archiveMaintenancesSearch = {};

  void filterAllMaintenances() {
    final nameQuery = employeeNameController.text.trim();
    final fromDate = fromDateController.text.trim();
    final toDate = toDateController.text.trim();

    List<MaintenanceDataModel> applyFilter(
        List<MaintenanceDataModel> sourceList) {
      return sourceList.where((item) {
        final name = item.customerName.isNotEmpty
            ? item.customerName.toLowerCase()
            : (item.sellerName ?? "").toLowerCase();
        final matchesName =
            (nameQuery.isEmpty) ? true : name.contains(nameQuery.toLowerCase());
        final itemDate = DateTime.tryParse(item.receiptDate);
        final from = (fromDate.isNotEmpty) ? DateTime.tryParse(fromDate) : null;
        final to = (toDate.isNotEmpty) ? DateTime.tryParse(toDate) : null;
        bool matchesDate = true;
        if (itemDate != null) {
          if (from != null && itemDate.isBefore(from)) matchesDate = false;
          if (to != null && itemDate.isAfter(to)) matchesDate = false;
        }
        return matchesName && matchesDate;
      }).toList();
    }

    Map<String, List<MaintenanceDataModel>> groupByDate(
        List<MaintenanceDataModel> list) {
      final Map<String, List<MaintenanceDataModel>> grouped = {};
      for (var task in list) {
        final receiptDateObj = DateTime.parse(task.receiptDate);
        final dayName =
            DateFormat.EEEE(Get.locale!.languageCode).format(receiptDateObj);
        final dateKey =
            "$dayName ${receiptDateObj.year}-${receiptDateObj.month}-${receiptDateObj.day}";
        grouped.putIfAbsent(dateKey, () => []);
        if (!grouped[dateKey]!.any((a) => a.id == task.id)) {
          grouped[dateKey]!.add(task);
        }
      }
      return grouped;
    }

    maintenancesSearch
      ..clear()
      ..addAll(groupByDate(applyFilter(MaintenanceServes().maintenancesList)));
    ongoingMaintenancesSearch
      ..clear()
      ..addAll(groupByDate(
          applyFilter(MaintenanceServes().ongoingMaintenancesList)));
    readyMaintenancesSearch
      ..clear()
      ..addAll(
          groupByDate(applyFilter(MaintenanceServes().readyMaintenancesList)));
    archiveMaintenancesSearch
      ..clear()
      ..addAll(groupByDate(
          applyFilter(MaintenanceServes().archiveMaintenancesList)));
    Get.back();
    update();
  }

  @override
  void onInit() {
    super.onInit();
    getMaintenancesData();
    getAllCustomersAndSellers();
    maintenancesSearch.assignAll(MaintenanceServes().maintenancesTasks);
    ongoingMaintenancesSearch
        .assignAll(MaintenanceServes().ongoingMaintenancesTasks);
    readyMaintenancesSearch
        .assignAll(MaintenanceServes().readyMaintenancesTasks);
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
