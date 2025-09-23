import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../checks/data/models/check_model.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../data/models/maintenances_model.dart';
import '../../domain/usecases/creat_maintenance_usecase.dart';
import '../../domain/usecases/get_maintenances_details_usecase.dart';
import '../../domain/usecases/maintenance_usecase.dart';
import 'maintenance_serves.dart';

class MaintenanceController extends GetxController {
  final MaintenanceUsecase maintenanceUsecase;
  final CreatMaintenanceUsecase creatMaintenanceUsecase;
  final AllCustomersSellersUsecase allCustomersSellersUsecase;
  final GetMaintenancesDetailsUsecase getMaintenancesDetailsUsecase;

  MaintenanceController({
    required this.maintenanceUsecase,
    required this.creatMaintenanceUsecase,
    required this.allCustomersSellersUsecase,
    required this.getMaintenancesDetailsUsecase,
  });

  final formKey = GlobalKey<FormState>();
  TextEditingController employeeNameController = TextEditingController();
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();

  TextEditingController partnerIdController = TextEditingController();

  TextEditingController descriptionController = TextEditingController();

  RxInt currentTab = 0.obs;

  void changeTab(int index) {
    currentTab.value = index;
    update();
  }

  RxBool selectedSellers = false.obs;

  List<String> tabs = ['newRequest', 'inProgress', 'readyToDeliver', 'archive'];

  @override
  void onClose() {
    employeeNameController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    partnerIdController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  // متغير لاظهار الخطوات
  final RxInt selectedStep = 1.obs;

  final List<Map<int, String>> timeLineSteps = [
    {1: 'newMaintenance'},
    {2: 'inProgress'},
    {3: 'readyToDeliver'},
  ];

  void changeSelected(int index) => selectedStep.value = index;

  final RxBool isEditLoading = false.obs;
  final RxBool isEdit = false.obs;
  String? maintenanceId;
  void nextStep() {
    if (selectedStep.value < timeLineSteps.length) {
      if (!formKey.currentState!.validate()) {
        return;
      }
      if (!isEdit.value) createMaintenance(step: selectedStep.value);
      selectedStep.value += 1;
      if (isEdit.value) {
        createMaintenance(
            step: selectedStep.value, maintenanceId: maintenanceId);
      }
    } else {
      Get.back();
      selectedStep.value += 1;
      createMaintenance(step: selectedStep.value, maintenanceId: maintenanceId);
      selectedStep.value = 1;
    }
  }

  void prevStep() {
    createMaintenance(step: selectedStep.value, maintenanceId: maintenanceId);
    selectedStep.value -= 1;
  }

  // متغير لاظهار التكرار
  RxBool isRecurrenceVisible = false.obs;

  void toggleRecurrence() {
    isRecurrenceVisible.value = !isRecurrenceVisible.value;
  }

  RxList<String> selectedDaysList = <String>[].obs;

  final Rx<DateTime> deliveryDate = DateTime.now().obs;

  final Rx<TimeOfDay> deliveryTime = TimeOfDay.now().obs;

  // final Rx<File?> selectedImage = Rx<File?>(null);
  List<File> selectedMedia = [];
  final RxBool isLoading = false.obs;

  void getMaintenancesData() async {
    if (MaintenanceServes().maintenancesList.isEmpty) isLoading(true);
    update();

    // دالة مساعدة للتجميع
    Map<String, List<MaintenanceDataModel>> groupByDate(
        List<MaintenanceDataModel> list) {
      final Map<String, List<MaintenanceDataModel>> grouped = {};

      for (var task in list) {
        final receiptDateObj = DateTime.parse(task.receiptDate);
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
          final aDate = DateTime.parse(a.value.first.receiptDate);
          final bDate = DateTime.parse(b.value.first.receiptDate);
          return aDate.compareTo(bDate); // الأحدث الأول
        });

      return Map.fromEntries(sortedEntries);
    }

    // maintenances
    final maintenancesData = await maintenanceUsecase.call(tab: 0);
    final maintenances = (maintenancesData['maintenance_details'] as List)
        .map((e) => MaintenanceDataModel.fromJson(e))
        .toList();

    MaintenanceServes().maintenancesList.assignAll(maintenances);
    MaintenanceServes().maintenancesTasks.value = groupByDate(maintenances);
    maintenancesSearch.assignAll(MaintenanceServes().maintenancesTasks);

    isLoading(false);
    update();

    // ongoingMaintenances
    final ongoingData = await maintenanceUsecase.call(tab: 1);
    final ongoing = (ongoingData['maintenance_details'] as List)
        .map((e) => MaintenanceDataModel.fromJson(e))
        .toList();

    MaintenanceServes().ongoingMaintenancesList.assignAll(ongoing);
    MaintenanceServes().ongoingMaintenancesTasks.value = groupByDate(ongoing);
    ongoingMaintenancesSearch
        .assignAll(MaintenanceServes().ongoingMaintenancesTasks);

    // readyMaintenances
    final readyData = await maintenanceUsecase.call(tab: 2);
    final ready = (readyData['maintenance_details'] as List)
        .map((e) => MaintenanceDataModel.fromJson(e))
        .toList();

    MaintenanceServes().readyMaintenancesList.assignAll(ready);
    MaintenanceServes().readyMaintenancesTasks.value = groupByDate(ready);
    readyMaintenancesSearch
        .assignAll(MaintenanceServes().readyMaintenancesTasks);

    // archiveMaintenances
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

  // get maintenances details
  void getMaintenancesDetails({required String maintenanceId}) async {
    isEdit(true);
    isEditLoading(true);
    update();
    // maintenances
    final maintenancesData =
        await getMaintenancesDetailsUsecase.call(maintenanceId: maintenanceId);
    final maintenances = maintenancesData['maintenance'];

    this.maintenanceId = maintenances['id'].toString();
    deliveryDate.value = DateTime.parse(
        maintenances['receipt_date'] ?? DateTime.now().toString());
    final receiptDateTime = DateTime.parse(
        '${maintenances['receipt_date']} ${maintenances['receipt_time']}');

    deliveryTime.value = TimeOfDay.fromDateTime(receiptDateTime);
    descriptionController.text = maintenances['description'] ?? '';
    partnerIdController.text = (maintenances['customer'] != null &&
            maintenances['customer'].isNotEmpty)
        ? maintenances['customer']['id'].toString()
        : (maintenances['seller'] != null && maintenances['seller'].isNotEmpty)
            ? maintenances['seller']['id'].toString()
            : '';
    selectedSellers.value =
        (maintenances['seller'] != null && maintenances['seller'].isNotEmpty)
            ? true
            : false;
    selectedStep.value = maintenances['status'] == 'new'
        ? 1
        : maintenances['status'] == 'ongoing'
            ? 2
            : maintenances['status'] == 'ready'
                ? 3
                : 1;
    if (maintenances['files'] != null) {
      selectedMedia = List<File>.from(
        (maintenances['files'] as List).map(
          (file) => File(
            ShowNetImage.getPhoto(file),
          ),
        ),
      );
    }
    isEditLoading(false);
    update();
  }

  void clearControllers() {
    isEdit(false);
    partnerIdController.clear();
    descriptionController.clear();
    deliveryDate.value = DateTime.now();
    deliveryTime.value = TimeOfDay.now();
    selectedMedia = [];
    selectedSellers(false);
    selectedStep(1);
    update();
  }

  // get all customers and sellers
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

  // create maintenance
  Future<void> createMaintenance(
      {required int step, String? maintenanceId}) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    isLoading(true);
    update();
    final result = await creatMaintenanceUsecase.call(
      maintenanceId: isEdit.value ? maintenanceId : null,
      customerId: !selectedSellers.value ? partnerIdController.text : '',
      sellerId: selectedSellers.value ? partnerIdController.text : '',
      description: descriptionController.text,
      receipDate: deliveryDate.value.toIso8601String().split('T').first,
      receiptTime:
          '${deliveryTime.value.hour.toString().padLeft(2, '0')}:${deliveryTime.value.minute.toString().padLeft(2, '0')}',
      files: selectedMedia,
      status: step == 1
          ? ''
          : step == 2
              ? 'ongoing'
              : step == 3
                  ? 'ready'
                  : 'delivered',
    );

    result.fold(
      (failure) {
        final errors = failure.data['errors'];
        String errorMessage = '';

        if (errors is Map) {
          errorMessage = errors.entries
              .map((e) => "${e.key}: ${(e.value as List).join(', ')}")
              .join("\n");
        } else {
          errorMessage = errors.toString();
        }
        Get.snackbar(
          failure.data['message'] ?? 'error'.tr,
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (success) {
        getMaintenancesData();
        // Get.back();
        // Future.delayed(
        //   const Duration(milliseconds: 1500),
        //   () {
        //     Get.back();
        //   },
        // );
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
    isLoading(false);
    update();
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
        final name = (item.customerName.isNotEmpty && item.sellerName != null
                ? item.customerName
                : item.sellerName ?? "")
            .toLowerCase();

        // ✅ فلترة بالاسم
        final matchesName =
            (nameQuery.isEmpty) ? true : name.contains(nameQuery.toLowerCase());

        // ✅ فلترة بالتاريخ
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

    // ✅ تطبيق الفلتر على كل القوائم
    Map<String, List<MaintenanceDataModel>> groupByDate(
        List<MaintenanceDataModel> list) {
      final Map<String, List<MaintenanceDataModel>> grouped = {};
      for (var task in list) {
        final receiptDateObj = DateTime.parse(task.receiptDate);
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
  // لو التاب الحالي هو 3 يبقى أخضر على طول
  if (currentTab == 3) return AppColors.customGreen1;

  // دمج التاريخ مع الوقت وتحويله لـ DateTime
  final DateTime receiptDateTime = DateTime.parse("$receiptDate $receiptTime");

  // الفرق بين وقت الاستلام والوقت الحالي
  final Duration diff = receiptDateTime.difference(DateTime.now());

  if (diff.inHours > 1) {
    return AppColors.customGreen1; // باقي أكتر من ساعة
  } else if (diff.inMinutes > 0) {
    return AppColors.customOrange3; // باقي أقل من ساعة (لكن لسه ما جاش)
  } else {
    return AppColors.redColor; // الوقت فات
  }
}

String getStatusText({
  required String receiptDate,
  required String receiptTime,
}) {
  final DateTime receiptDateTime = DateTime.parse("$receiptDate $receiptTime");
  final Duration diff = receiptDateTime.difference(DateTime.now());

  // عدد الساعات (ممكن يكون بالسالب لو متأخر)
  final int hours = diff.inHours;
  if (hours < 0 && hours <= -100) {
    return 'late'.tr;
  }
  // لو باقي وقت
  if (hours > 0) {
    return "$hours ${hours > 1 ? 'hour'.tr : 'hours'.tr}";
  }
  // لو متأخر
  else if (hours < 0) {
    return "$hours ${hours > 10 ? 'hour'.tr : 'hours'.tr}";
  }
  // لو بالظبط دلوقتي
  return hours == 0 ? 'now'.tr : '';
}
