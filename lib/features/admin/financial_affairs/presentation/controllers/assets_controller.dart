import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../data/models/assets_models/assets_data_model.dart';
import '../../data/models/assets_models/assets_detials_model.dart';
import '../../domain/usecases/assets_usecases/add_new_assers_usecase.dart';
import '../../domain/usecases/assets_usecases/assets_detials_usecase.dart';
import '../../domain/usecases/assets_usecases/depreciate_assets_usecase.dart';
import '../../domain/usecases/assets_usecases/depreciate_one_assets_usecase.dart';
import '../../domain/usecases/assets_usecases/get_asset_report_usecase.dart';
import '../../domain/usecases/get_all_dinancial_usecase.dart';
import '../../domain/usecases/assets_usecases/get_assets_logs_usecase.dart';
import 'finacial_service.dart';

class AssetsController extends GetxController {
  final GetAllFinancialUsecase getAllFinancialUsecase;
  final GetAssetsLogsUsecase getAssetsLogsUsecase;
  final AddNewAssetsUsecase addNewAssetsUsecase;
  final DepreciateAssetsUsecase depreciateAssetsUsecase;
  final AssetsDetialsUsecase assetsDetialsUsecase;
  final GetAssetReportUsecase getAssetReportUsecase;
  final DepreciateOneAssetsUsecase depreciateOneAssetsUsecase;

  AssetsController({
    required this.getAllFinancialUsecase,
    required this.getAssetsLogsUsecase,
    required this.addNewAssetsUsecase,
    required this.depreciateAssetsUsecase,
    required this.assetsDetialsUsecase,
    required this.getAssetReportUsecase,
    required this.depreciateOneAssetsUsecase,
  });

  final formKey = GlobalKey<FormState>();

  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  final TextEditingController assetNameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController depreciationRateController =
      TextEditingController();
  final TextEditingController monthsNumberController = TextEditingController();

  RxList<String> list = <String>['delete', 'destruction'].obs;

  void onMonthsChanged(String value) {
    if (value.isEmpty) return;
    final months = double.tryParse(value);
    if (months != null && months > 0) {
      final percent = 100 / months;
      depreciationRateController.text = percent.toStringAsFixed(2);
    }
  }

  void onDepreciationChanged(String value) {
    if (value.isEmpty) return;
    final percent = double.tryParse(value);
    if (percent != null && percent > 0) {
      final months = 100 / percent;
      monthsNumberController.text = months.toStringAsFixed(0);
    }
  }

  List<File?> selectedFile = [];
  final RxBool isLoading = false.obs;

  // filter assets by date
  final assetsFilter = <String, List<Asset>>{}.obs;
  void filterAssetsByDate() {
    final from = DateTime.tryParse(fromController.text);
    final to = DateTime.tryParse(toController.text);

    // رجع الداتا الأصلية قبل أي فلترة
    assetsFilter.assignAll(FinacialService().assetsTasks);

    final Map<String, List<Asset>> filtered = {};
    assetsFilter.forEach(
      (dateKey, tasks) {
        for (var task in tasks) {
          bool matches = true;
          // لو فيه "من"
          if (from != null) {
            matches = task.createdAt.isAtSameMomentAs(from) ||
                task.createdAt.isAfter(from);
          }
          // لو فيه "إلى"
          if (to != null) {
            matches = matches &&
                (task.createdAt.isAtSameMomentAs(to) ||
                    task.createdAt.isBefore(to));
          }
          if (matches) {
            filtered.putIfAbsent(dateKey, () => []);
            filtered[dateKey]!.add(task);
          }
        }
      },
    );
    assetsFilter.assignAll(filtered);
    update();
    Get.back();
  }

  // get all assets
  void getAllAssets() async {
    FinacialService().assetsTasks.isEmpty ? isLoading(true) : isLoading(false);
    update();

    final assets = await getAllFinancialUsecase.call(page: '1');

    // 🧹 امسح الداتا القديمة قبل ما تضيف الجديدة
    FinacialService().assetsTasks.clear();

    // حدّث الموديل الرئيسي
    FinacialService().assets.value = AssetsModel.fromJson(assets);

    // حدّث الفلتر
    assetsFilter.value = FinacialService().assetsTasks;

    for (var task in FinacialService().assets.value!.assets) {
      String dayName =
          DateFormat.EEEE(Get.locale!.languageCode).format(task.createdAt);
      String dateKey =
          "$dayName ${task.createdAt.year}-${task.createdAt.month}-${task.createdAt.day}";

      // أضف المهام الجديدة بشكل منظم
      if (FinacialService().assetsTasks.containsKey(dateKey)) {
        FinacialService().assetsTasks[dateKey]!.add(task);
      } else {
        FinacialService().assetsTasks[dateKey] = [task];
      }
    }

    isLoading(false);
    update();
  }

  // get assets logs
  void getAssetsLogs() async {
    FinacialService().assetsLogs.isEmpty
        ? isLoadingDepreciate(true)
        : isLoadingDepreciate(false);
    update();
    final assetsLogs = await getAssetsLogsUsecase.call();
    FinacialService().assetsLogs.assignAll(assetsLogs);
    isLoadingDepreciate(false);
    update();
  }

  final RxBool isEditing = false.obs;
  // get assets details
  final Rxn<AssetDetailsModel> assetDetails = Rxn();
  void getAssetsDetials({required String assetId}) async {
    isLoadingDepreciate(true);
    update();
    selectedFile.clear();
    update();
    final assetsLogs = await assetsDetialsUsecase.call(assetId: assetId);
    assetDetails.value = assetsLogs;
    isEditing.value ? editAsset() : null;

    isLoadingDepreciate(false);
    update();
  }

  void editAsset() {
    if (isEditing.value) {
      isLoadingDepreciate(true);
      assetNameController.text = assetDetails.value?.name ?? '';
      priceController.text = assetDetails.value?.price ?? '';
      noteController.text = assetDetails.value?.notes ?? '';
      depreciationRateController.text =
          assetDetails.value?.depreciationRate ?? '';
      monthsNumberController.text =
          assetDetails.value?.monthsNumber.split('.').first ?? '';
      selectedFile =
          assetDetails.value?.media.map((e) => File(e)).toList() ?? [];
    } else {
      assetNameController.clear();
      priceController.clear();
      noteController.clear();
      depreciationRateController.clear();
      monthsNumberController.clear();
      selectedFile.clear();
    }
    isLoadingDepreciate(false);
    update();
  }

  // add new assets
  void addNewAssets(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      isLoading(true);
      final result = await addNewAssetsUsecase.call(
        assetId: isEditing.value ? assetDetails.value?.id.toString() : null,
        assetName: assetNameController.text,
        price: double.parse(priceController.text),
        note: noteController.text,
        depreciationRate: double.parse(depreciationRateController.text),
        numberOfMonths: int.parse(monthsNumberController.text),
        selectedFile: selectedFile,
      );
      result.fold(
        (failure) {
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: failure.data['message'],
          );
        },
        (success) {
          assetNameController.clear();
          priceController.clear();
          noteController.clear();
          depreciationRateController.clear();
          monthsNumberController.clear();
          selectedFile.clear();
          getAllAssets();
          Future.delayed(
            const Duration(milliseconds: 1000),
            () {
              Get.back();
              Get.back();
            },
          );
          Helpers.showCustomDialogSuccess(
            context: context,
            title: 'success'.tr,
            message: success,
          );
        },
      );
      isLoading(false);
    }
  }

  // destruction one assets
  void destructionOneAssets(String assetId) async {
    isLoading(true);
    final result = await depreciateOneAssetsUsecase.call(assetId: assetId);
    result.fold(
      (failure) {
        Get.back();
        Get.snackbar(
          "error".tr,
          failure.errMessage,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
      (success) {
        Get.back();
        getAllAssets();

        Get.snackbar(
          "success".tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
    );
    isLoading(false);
  }

  final RxBool isLoadingDepreciate = false.obs;
  // add new assets
  void depreciateAssets() async {
    isLoadingDepreciate(true);
    final result = await depreciateAssetsUsecase.call();

    result.fold(
      (failure) {
        Get.snackbar(
          'error'.tr,
          failure.errMessage,
          colorText: Colors.white,
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (success) {
        getAllAssets();
        Get.back();
        Get.snackbar(
          'success'.tr,
          success,
          colorText: Colors.white,
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
    );
    isLoadingDepreciate(false);
  }

  // download report
  Future<void> downloadReport() async {
    try {
      Get.snackbar(
        "info".tr,
        "جار تحميل الملف. سيتم اعلامك عند الانتهاء".tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 2500),
      );
      final response = await getAssetReportUsecase.call();
      final directory =
          Directory("/storage/emulated/0/Download/Doctor Bike/PDF");
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final filePath =
          "${directory.path}/سجل_الأهلاك${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}.pdf";
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
      Get.snackbar(
        "error".tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 2500),
      );
    }
  }

  @override
  void onInit() {
    getAllAssets();
    assetsFilter.value = FinacialService().assetsTasks;
    super.onInit();
  }

  @override
  void onClose() {
    fromController.dispose();
    toController.dispose();
    assetNameController.dispose();
    priceController.dispose();
    noteController.dispose();
    depreciationRateController.dispose();
    monthsNumberController.dispose();
    super.onClose();
  }
}
