import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../data/datasources/countrers_datasource.dart';
import '../../domain/usecases/get_report_by_type_usecase.dart';
import '../../domain/usecases/get_report_information_usecase.dart';
import 'counters_serves.dart';

class CountersController extends GetxController {
  final GetReportInformationUsecase getReportInformationUsecase;
  final GetReportByTypeUsecase getReportByType;
  CountersController({
    required this.getReportInformationUsecase,
    required this.getReportByType,
  });

  final formKey = GlobalKey<FormState>();

  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool analyticsLoading = false.obs;
  final RxnString analyticsError = RxnString();
  final RxMap<String, dynamic> analytics = <String, dynamic>{}.obs;
  final RxString selectedPeriod = 'quarter'.obs;
  DateTime? customFrom;
  DateTime? customTo;

  static const analyticsPeriods = [
    {'key': 'today', 'label': 'اليوم'},
    {'key': 'week', 'label': 'الأسبوع'},
    {'key': 'month', 'label': 'الشهر'},
    {'key': 'quarter', 'label': '3 شهور'},
    {'key': 'year', 'label': 'السنة'},
    {'key': 'custom', 'label': 'مخصص'},
  ];

  Future<void> loadAnalytics() async {
    analyticsLoading(true);
    analyticsError.value = null;
    try {
      final data = await Get.find<CountrersDatasource>().getAnalytics(
        period: selectedPeriod.value,
        fromDate: selectedPeriod.value == 'custom' ? customFrom : null,
        toDate: selectedPeriod.value == 'custom' ? customTo : null,
      );
      analytics.assignAll(data);
    } catch (error) {
      analyticsError.value = error.toString();
    } finally {
      analyticsLoading(false);
    }
  }

  Future<void> selectAnalyticsPeriod(String period) async {
    selectedPeriod(period);
    if (period != 'custom') await loadAnalytics();
  }

  Future<void> setCustomPeriod(DateTime from, DateTime to) async {
    customFrom = from;
    customTo = to;
    selectedPeriod('custom');
    await loadAnalytics();
  }

  Future<void> getReportInformation() async {
    CountersServes().reportInformationData.value == null
        ? isLoading(true)
        : null;
    final result = await getReportInformationUsecase.call();
    CountersServes().reportInformationData.value = result;
    isLoading(false);
    update();
  }

  String reportType = '';
  List<String> reportTypeList = [
    'debts',
    'instant_sales',
    'employee_tasks',
    'boxes',
    'checks',
    'bills',
    'people',
    'projects',
    'employees',
    'expenses',
    'returns',
  ];

  Future<void> downloadReport({
    required String type,
    required BuildContext context,
  }) async {
    try {
      Get.snackbar(
        "info".tr,
        "جار تحميل الملف. سيتم اعلامك عند الانتهاء".tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 2500),
      );
      final response = await getReportByType.call(
        type: type,
        fromDate: fromDateController.text.isEmpty
            ? null
            : DateTime.parse(fromDateController.text),
        toDate: toDateController.text.isEmpty
            ? null
            : DateTime.parse(toDateController.text),
      );

      response.fold((failure) {
        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: failure.data['message'] ?? 'Unknown error',
        );
      }, (success) async {
        late Directory directory;
        if (Platform.isAndroid) {
          directory = Directory("/storage/emulated/0/Download/Doctor Bike/PDF");
        } else if (Platform.isIOS) {
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
            "${directory.path}/_تقرير${p.basename(type.tr)}${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}.pdf";
        final file = File(filePath);
        await file.writeAsBytes(success);
        Get.snackbar(
          "fileDownloadedSuccessfully".tr,
          filePath,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 2000),
        );

        await OpenFilex.open(filePath);
      });
    } catch (e) {
      Get.snackbar("error".tr, e.toString());
    }
  }

  @override
  void onInit() {
    loadAnalytics();
    super.onInit();
  }
}
