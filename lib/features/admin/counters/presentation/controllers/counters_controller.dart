import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../../core/helpers/helpers.dart';
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

  // get report information
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
  // download report
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
    getReportInformation();
    super.onInit();
  }
}
