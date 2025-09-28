import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

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
        final directory = Directory("/storage/emulated/0/Pictures/Doctor Bike");
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final filePath =
            "${directory.path}/${p.basename(type)} Report ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}.pdf";
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
