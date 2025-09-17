import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../domain/usecases/get_report_information_usecase.dart';
import '../../domain/usecases/get_report_by_type_usecase.dart';
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
    Get.snackbar(
      "info".tr,
      "جار تحميل الملف. سيتم اعلامك عند الانتهاء".tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(milliseconds: 1500),
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
      // اطلب صلاحية التخزين
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        Get.snackbar("error".tr, "Storage permission denied");
        return;
      }
      // استخدم FileSaver لحفظ الملف في Downloads
      final path = await FileSaver.instance.saveAs(
        name: "report",
        bytes: success,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      Get.snackbar(
        "fileDownloadedSuccessfully".tr,
        path!,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 1500),
      );
      // افتح الملف
      await OpenFilex.open(path);
    });
  }

  @override
  void onInit() {
    getReportInformation();
    super.onInit();
  }
}
