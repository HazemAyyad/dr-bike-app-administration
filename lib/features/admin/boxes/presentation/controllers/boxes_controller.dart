import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
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

  BoxesController({
    required this.boxesUsecase,
    required this.getShownBoxUsecase,
    required this.allBoxesLogsUsecase,
    required this.transferBoxBalanceUsecase,
    required this.boxDetailsUesecase,
    required this.addBoxBalanceUsecase,
    required this.editBoxUsecase,
  });

  final GlobalKey formKey = GlobalKey();

  final TextEditingController boxNameController = TextEditingController();

  final tabs = ['boxes', 'movements', 'archive'].obs;

  final RxInt currentTab = 0.obs;

  final RxBool isLoading = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
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
    }
    isAddBoxLoading(false);
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
  }

  // add box
  void editBox(BuildContext context, String boxId) async {
    if ((formKey.currentState as FormState).validate()) {
      isAddBoxLoading(true);

      final result = await editBoxUsecase.call(
        boxId: boxId,
        name: editBoxNameController.text,
        total: editStartBalanceController.text,
        isShown: editAppearController.text == 'visible' ? '1' : '0',
        currency: editCurrencyController.text.tr,
      );

      result.fold(
        (failure) {
          isAddBoxLoading(false);

          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: failure.data['message'],
          );
        },
        (success) {
          Get.back();
          getAllBoxes();
          boxDetailsId = '0';
          addBalanceValueController.clear();
          editCurrencyController.clear();
          editBoxNameController.clear();
          editStartBalanceController.clear();
          editAppearController.clear();
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
  }

  final RxList<GetShownBoxesModel> filteredShownBoxes =
      <GetShownBoxesModel>[].obs;
  final RxList<BoxLogModel> filteredAllBoxesLogs = <BoxLogModel>[].obs;
  final RxList<GetShownBoxesModel> filteredShownBoxesArchive =
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

  @override
  void onInit() {
    super.onInit();
    getAllBoxes();
    filteredAllBoxesLogs.assignAll(BoxesServes().allBoxesLogs);
    filteredShownBoxes.assignAll(BoxesServes().shownBoxes);
    filteredShownBoxesArchive.assignAll(BoxesServes().shownBoxesArchive);
  }

  @override
  void onClose() {
    boxNameController.dispose();
    // fromDateController.dispose();
    // toDateController.dispose();
    createBoxNameController.dispose();
    createStartBalanceController.dispose();
    editBoxNameController.dispose();
    editStartBalanceController.dispose();
    appearController.dispose();
    // addBalanceBoxNameController.dispose();
    addBalanceValueController.dispose();
    // transferFromBoxIdController.dispose();
    transferToBoxIdController.dispose();
    transferTotalController.dispose();
    currencyController.dispose();

    super.onClose();
  }
}
