import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../counters/domain/usecases/get_report_by_type_usecase.dart';
import '../../data/models/all_boxes_logs_model.dart';
import '../../data/models/get_shown_boxes_model.dart';
import '../../domain/entity/all_boxes_logs_entity.dart';
import '../../domain/usecases/add_box_balance_usecase.dart';
import '../../domain/usecases/add_boxes_usecase.dart';
import '../../domain/usecases/all_boxes_logs_usercase.dart';
import '../../domain/usecases/box_details_uesecase.dart';
import '../../domain/usecases/edit_box_usecase.dart';
import '../../domain/usecases/get_shown_box_usecase.dart';
import '../../domain/usecases/transfer_box_balance_usecase.dart';
import 'boxes_serves.dart';

class BoxesController extends GetxController {
  AddBoxesUsecase boxesUsecase;
  GetShownBoxUsecase getShownBoxUsecase;
  AllBoxesLogsUsercase allBoxesLogsUsecase;
  TransferBoxBalanceUsecase transferBoxBalanceUsecase;
  BoxDetailsUesecase boxDetailsUesecase;
  AddBoxBalanceUsecase addBoxBalanceUsecase;
  EditBoxUsecase editBoxUsecase;
  final GetReportByTypeUsecase getReportByType;

  BoxesController({
    required this.boxesUsecase,
    required this.getShownBoxUsecase,
    required this.allBoxesLogsUsecase,
    required this.transferBoxBalanceUsecase,
    required this.boxDetailsUesecase,
    required this.addBoxBalanceUsecase,
    required this.editBoxUsecase,
    required this.getReportByType,
  });

  final GlobalKey formKey = GlobalKey();

  final TextEditingController boxNameController = TextEditingController();

  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  final tabs = ['boxes', 'movements', 'archive'].obs;

  final RxInt currentTab = 0.obs;

  final RxBool isLoading = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
    update();
  }

  final List<String> currency = ['currency1', 'currency2', 'currency'];
  final TextEditingController currencyController = TextEditingController();

  // انشاء الصناديق
  final TextEditingController createBoxNameController = TextEditingController();
  final TextEditingController createStartBalanceController =
      TextEditingController();
  final TextEditingController appearController = TextEditingController();

  // تعديل الصناديق
  final TextEditingController editBoxNameController = TextEditingController();
  final TextEditingController editStartBalanceController =
      TextEditingController();
  final TextEditingController editAppearController = TextEditingController();
  final TextEditingController editCurrencyController = TextEditingController();
  final List<BoxLog> boxDetailsLogs = [];

  final List<String> appears = ['visible', 'notVisible'];

  // اضافة رصيد
  final TextEditingController addBalanceValueController =
      TextEditingController();

  // نقل رصيد
  final TextEditingController transferToBoxIdController =
      TextEditingController();
  final TextEditingController transferTotalController = TextEditingController();

  // get shown boxes

  void getAllBoxes() async {
    BoxesServes().shownBoxes.isEmpty ? isLoading(true) : isLoading(false);
    final shownBoxesList = await getShownBoxUsecase.call(screen: 0);
    BoxesServes().shownBoxes.assignAll(shownBoxesList);
    filteredShownBoxes.assignAll(BoxesServes().shownBoxes);

    final boxesLogsList = await allBoxesLogsUsecase.call();
    BoxesServes().allBoxesLogs.assignAll(boxesLogsList);
    filteredAllBoxesLogs.assignAll(BoxesServes().allBoxesLogs);

    final boxesArchiveList = await getShownBoxUsecase.call(screen: 2);
    BoxesServes().shownBoxesArchive.assignAll(boxesArchiveList);
    filteredShownBoxesArchive.assignAll(BoxesServes().shownBoxesArchive);
    isLoading(false);
    update();
  }

  String boxDetailsId = '0';
  // get box details
  void getboxDetails(String boxId) async {
    final sameBox = boxDetailsId == boxId;
    if (!sameBox) {
      isLoading(true);
    }
    boxDetailsId = boxId;
    final boxDetails = await boxDetailsUesecase.call(boxId: boxId);

    editBoxNameController.text = boxDetails.boxName;
    editStartBalanceController.text = boxDetails.totalBalance.toString();
    editAppearController.text =
        boxDetails.isShown == 1.toString() ? 'visible' : 'notVisible';
    editCurrencyController.text = boxDetails.currency;
    boxDetailsLogs.assignAll(boxDetails.boxLogs);
    isLoading(false);
    update();
  }

  final RxBool isAddBoxLoading = false.obs;

  // transfer box
  void transferBoxBalance(BuildContext context, String boxId) async {
    if ((formKey.currentState as FormState).validate()) {
      isAddBoxLoading(true);

      final result = await transferBoxBalanceUsecase.call(
        fromBoxId: boxId,
        toBoxId: transferToBoxIdController.text,
        total: transferTotalController.text,
      );
      result.fold(
        (failure) {
          isAddBoxLoading(false);
          update();
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: failure.data['message'],
          );
        },
        (success) {
          Get.back();
          getAllBoxes();
          // transferFromBoxIdController.clear();
          transferToBoxIdController.clear();
          createStartBalanceController.clear();
          Future.delayed(
            const Duration(milliseconds: 1000),
            () {
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
    }
    isAddBoxLoading(false);
    update();
  }

  // add box
  void addBox(BuildContext context) async {
    if ((formKey.currentState as FormState).validate()) {
      isAddBoxLoading(true);

      final result = await boxesUsecase.call(
        boxName: createBoxNameController.text,
        total: createStartBalanceController.text,
        currency: currencyController.text.tr,
      );

      result.fold(
        (failure) {
          isAddBoxLoading(false);
          update();

          final errors = failure.data != null ? failure.data['errors'] : null;

          if (errors is Map<String, dynamic>) {
            final messages = errors.values
                .expand((list) => list)
                .cast<String>()
                .join('')
                .replaceAll('.', '- \n');

            Helpers.showCustomDialogError(
              context: context,
              title: failure.errMessage,
              message: messages,
            );
          } else {
            Helpers.showCustomDialogError(
              context: context,
              title: failure.errMessage,
              message: "Unexpected error occurred",
            );
          }
        },
        (success) {
          getAllBoxes();
          Helpers.showCustomDialogSuccess(
            context: context,
            title: 'success'.tr,
            message: success,
          );
          Future.delayed(
            const Duration(milliseconds: 1000),
            () {
              Get.back();
              Get.back();
              createBoxNameController.clear();
              createStartBalanceController.clear();
              currencyController.clear();
            },
          );
        },
      );
    }
    isAddBoxLoading(false);
    update();
  }

  // add box
  void addBoxBalance(BuildContext context, String boxId) async {
    if ((formKey.currentState as FormState).validate()) {
      isAddBoxLoading(true);

      final result = await addBoxBalanceUsecase.call(
        boxId: boxId,
        total: addBalanceValueController.text,
      );

      result.fold(
        (failure) {
          isAddBoxLoading(false);
          update();
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: "Unexpected error occurred",
          );
        },
        (success) {
          Get.back();
          getAllBoxes();
          addBalanceValueController.clear();
          Future.delayed(
            const Duration(milliseconds: 1000),
            () {
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
    }
    isAddBoxLoading(false);
    update();
  }

  // add box
  void editBox({
    required BuildContext context,
    required String boxId,
    bool isDelete = false,
  }) async {
    isAddBoxLoading(true);

    final result = await editBoxUsecase.call(
      boxId: boxId,
      name: isDelete ? '' : editBoxNameController.text,
      total: editStartBalanceController.text,
      isShown: editAppearController.text == 'visible' ? '1' : '0',
      currency: editCurrencyController.text.tr,
    );

    result.fold(
      (failure) {
        isAddBoxLoading(false);
        update();
        isDelete
            ? Get.snackbar(
                failure.errMessage,
                failure.data['message'],
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              )
            : Helpers.showCustomDialogError(
                context: context,
                title: failure.errMessage,
                message: failure.data['message'],
              );
      },
      (success) {
        Get.back();
        getAllBoxes();
        Future.delayed(
          const Duration(milliseconds: 1500),
          () {
            Get.back();
            boxDetailsId = '0';
            addBalanceValueController.clear();
            editCurrencyController.clear();
            editBoxNameController.clear();
            editStartBalanceController.clear();
            editAppearController.clear();
          },
        );
        isDelete
            ? Get.snackbar(
                'success'.tr,
                success,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              )
            : Helpers.showCustomDialogSuccess(
                context: context,
                title: 'success'.tr,
                message: success,
              );
      },
    );

    isAddBoxLoading(false);
    update();
  }

  RxList<GetShownBoxesModel> filteredShownBoxes = <GetShownBoxesModel>[].obs;
  RxList<BoxLogModel> filteredAllBoxesLogs = <BoxLogModel>[].obs;
  RxList<GetShownBoxesModel> filteredShownBoxesArchive =
      <GetShownBoxesModel>[].obs;

  void filterLists() {
    final query = boxNameController.text.trim().toLowerCase();

    if (query.isEmpty) {
      // رجّع القوائم الأصلية
      filteredAllBoxesLogs.assignAll(BoxesServes().allBoxesLogs);
      filteredShownBoxes.assignAll(BoxesServes().shownBoxes);
      filteredShownBoxesArchive.assignAll(BoxesServes().shownBoxesArchive);
    } else {
      //  فلترة الصناديق النشطة
      final filteredBoxes = BoxesServes()
          .shownBoxes
          .where((e) => e.boxName.toLowerCase().contains(query))
          .toList();

      //  فلترة الصناديق الأرشيفية
      final filteredBoxesArchive = BoxesServes()
          .shownBoxesArchive
          .where((e) => e.boxName.toLowerCase().contains(query))
          .toList();

      //  فلترة اللوجات
      final filteredLogs = BoxesServes().allBoxesLogs.where((log) {
        final fromMatch =
            log.fromBox?.name.toLowerCase().contains(query) ?? false;
        final toMatch = log.toBox?.name.toLowerCase().contains(query) ?? false;
        final boxMatch = log.box?.name.toLowerCase().contains(query) ?? false;
        return fromMatch || toMatch || boxMatch;
      }).toList();

      filteredShownBoxes.assignAll(filteredBoxes);
      filteredShownBoxesArchive.assignAll(filteredBoxesArchive);
      filteredAllBoxesLogs.assignAll(filteredLogs);
    }

    Get.back();
  }

  void searchBar(String value) {
    bool matches(GetShownBoxesModel box, String query) {
      final q = query.toLowerCase();
      return (box.boxName.toLowerCase().contains(q)) ||
          (box.currency.toLowerCase().contains(q)) ||
          (box.totalBalance.toString().toLowerCase().contains(q));
    }

    if (value.isNotEmpty) {
      filteredShownBoxes = BoxesServes()
          .shownBoxes
          .where((box) {
            final boxName = matches(box, value);
            final currency = matches(box, value);
            final totalBalance = matches(box, value);
            return boxName || currency || totalBalance;
          })
          .toList()
          .obs;

      filteredShownBoxesArchive = BoxesServes()
          .shownBoxesArchive
          .where((box) {
            final boxName = matches(box, value);
            final currency = matches(box, value);
            final totalBalance = matches(box, value);
            return boxName || currency || totalBalance;
          })
          .toList()
          .obs;

      filteredAllBoxesLogs = BoxesServes()
          .allBoxesLogs
          .where((box) {
            final search = value.toLowerCase();
            final valueMatch =
                box.value.toString().toLowerCase().contains(search);
            final fromMatch = box.fromBox != null &&
                box.fromBox!.name.toLowerCase().contains(search);
            final toMatch = box.toBox != null &&
                box.toBox!.name.toLowerCase().contains(search);
            final boxMatch =
                box.box != null && box.box!.name.toLowerCase().contains(search);
            final Map<String, List<String>> keywordsMap = {
              "transfer": ["transfer", "نقل", "تحويل"],
              "add": [
                'اضافه',
                'add',
                "اضافة",
                "إضافة",
                "إضافه",
                'إيداع',
                'ايداع'
              ],
              "minus": ['minus', 'سحب'],
            };
            final transferMatch = box.type != null &&
                keywordsMap.entries.any((entry) {
                  final apiValue = entry.key.toLowerCase();
                  final arabicWords =
                      entry.value.map((e) => e.toLowerCase()).toList();
                  final userMatch =
                      arabicWords.any((word) => word.contains(search));
                  return userMatch && box.type!.toLowerCase() == apiValue;
                });
            return valueMatch ||
                fromMatch ||
                toMatch ||
                boxMatch ||
                transferMatch;
          })
          .toList()
          .obs;
    } else {
      filteredShownBoxes.assignAll(BoxesServes().shownBoxes);
      filteredAllBoxesLogs.assignAll(BoxesServes().allBoxesLogs);
      filteredShownBoxesArchive.assignAll(BoxesServes().shownBoxesArchive);
    }
    update();
  }

  // download report
  Future<void> downloadReport({
    required BuildContext context,
    required String boxId,
    required String boxName,
  }) async {
    try {
      Get.back();
      Get.snackbar(
        "info".tr,
        "جار تحميل الملف. سيتم اعلامك عند الانتهاء".tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 2500),
      );
      final response = await getReportByType.call(
        type: '',
        boxId: boxId,
        fromDate: DateTime.parse(fromDateController.text),
        toDate: DateTime.parse(toDateController.text),
      );

      response.fold((failure) {
        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: failure.data['message'] ?? 'Unknown error',
        );
      }, (success) async {
        final directory =
            Directory("/storage/emulated/0/Download/Doctor Bike/PDF");
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final filePath =
            "${directory.path}/تقرير صندوق_$boxName${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}.pdf";
        final file = File(filePath);
        await file.writeAsBytes(success);
        Get.snackbar(
          "fileDownloadedSuccessfully".tr,
          filePath,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 2000),
        );

        await OpenFilex.open(filePath);
        fromDateController.clear();
        toDateController.clear();
      });
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
    super.onInit();
    getAllBoxes();
    filteredShownBoxes.assignAll(BoxesServes().shownBoxes);
    filteredAllBoxesLogs.assignAll(BoxesServes().allBoxesLogs);
    filteredShownBoxesArchive.assignAll(BoxesServes().shownBoxesArchive);
  }

  @override
  void onClose() {
    boxNameController.dispose();
    createBoxNameController.dispose();
    createStartBalanceController.dispose();
    editBoxNameController.dispose();
    editStartBalanceController.dispose();
    appearController.dispose();
    addBalanceValueController.dispose();
    transferToBoxIdController.dispose();
    transferTotalController.dispose();
    currencyController.dispose();
    fromDateController.dispose();
    toDateController.dispose();

    super.onClose();
  }
}
