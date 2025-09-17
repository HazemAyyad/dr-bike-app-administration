import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../data/models/maintenances_model.dart';
import '../../domain/usecases/maintenance_usecase.dart';

class MaintenanceController extends GetxController {
  final MaintenanceUsecase maintenanceUsecase;

  MaintenanceController({
    required this.maintenanceUsecase,
  });

  TextEditingController employeeNameController = TextEditingController();
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();

  TextEditingController customerNameController = TextEditingController();

  TextEditingController detailsController = TextEditingController();

  RxInt currentTab = 0.obs;

  void changeTab(int index) {
    currentTab.value = index;
    // getMaintenancesData();
    update();
  }

  List<String> tabs = ['newRequest', 'inProgress', 'readyToDeliver', 'archive'];

  @override
  void onClose() {
    employeeNameController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    customerNameController.dispose();
    detailsController.dispose();
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

  void nextStep() {
    if (selectedStep.value < timeLineSteps.length) {
      selectedStep.value += 1;
    } else {
      Get.back();
      selectedStep.value = 1;
    }
  }

  void prevStep() => selectedStep.value -= 1;

  List<String> customersNameList = [
    'محمد على',
    'محمد على',
    'محمد على',
  ];
  // متغير لاظهار التكرار
  RxBool isRecurrenceVisible = false.obs;

  void toggleRecurrence() {
    isRecurrenceVisible.value = !isRecurrenceVisible.value;
  }

  RxList<String> selectedDaysList = <String>[].obs;

  // متغير لاظهار الساعة
  RxBool isTimeVisible = false.obs;

  final startTime = TimeOfDay.now().obs;

  void toggleTime() {
    isTimeVisible.value = !isTimeVisible.value;
  }

  // final Rx<File?> selectedImage = Rx<File?>(null);
  List<File> selectedMedia = [];
  final RxBool isLoading = false.obs;

  final List<MaintenanceDataModel> maintenancesList = [];
  final List<MaintenanceDataModel> ongoingMaintenancesList = [];
  final List<MaintenanceDataModel> readyMaintenancesList = [];
  final List<MaintenanceDataModel> archiveMaintenancesList = [];

  void getMaintenancesData() async {
    isLoading(true);
    update();

    final maintenancesData = await maintenanceUsecase.call(tab: 0);
    final maintenances = maintenancesData['maintenance_details'] as List;
    final maintenancesList =
        maintenances.map((e) => MaintenanceDataModel.fromJson(e)).toList();
    this.maintenancesList.assignAll(maintenancesList);

    final ongoingMaintenancesData = await maintenanceUsecase.call(tab: 1);
    final ongoingMaintenances =
        ongoingMaintenancesData['maintenance_details'] as List;
    final ongoingMaintenancesList = ongoingMaintenances
        .map((e) => MaintenanceDataModel.fromJson(e))
        .toList();
    this.ongoingMaintenancesList.assignAll(ongoingMaintenancesList);

    final readyMaintenancesData = await maintenanceUsecase.call(tab: 2);
    final readyMaintenances =
        readyMaintenancesData['maintenance_details'] as List;
    final readyMaintenancesList =
        readyMaintenances.map((e) => MaintenanceDataModel.fromJson(e)).toList();
    this.readyMaintenancesList.assignAll(readyMaintenancesList);

    final archiveMaintenancesData = await maintenanceUsecase.call(tab: 3);
    final archiveMaintenances =
        archiveMaintenancesData['maintenance_details'] as List;
    final archiveMaintenancesList = archiveMaintenances
        .map((e) => MaintenanceDataModel.fromJson(e))
        .toList();
    this.archiveMaintenancesList.assignAll(archiveMaintenancesList);
    isLoading(false);
    update();
  }

  @override
  void onInit() {
    super.onInit();
    getMaintenancesData();
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

  // لو باقي وقت
  if (hours > 0) {
    return "$hours ${hours == 1 ? 'hour'.tr : 'hours'.tr}";
  }
  // لو متأخر
  else if (hours < 0) {
    return "${hours.abs()} ${hours.abs() == 1 ? 'hour'.tr : 'hours'.tr}";
  }

  // لو بالظبط دلوقتي
  return 'late'.tr;
}
