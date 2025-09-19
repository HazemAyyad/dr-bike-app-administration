import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../data/models/all_boxes_logs_model.dart';
import '../../data/models/get_shown_boxes_model.dart';
import '../../domain/usecases/add_box_balance_usecase.dart';
import '../../domain/usecases/add_boxes_usecase.dart';
import '../../domain/usecases/all_boxes_logs_usercase.dart';
import '../../domain/usecases/box_details_uesecase.dart';
import '../../domain/usecases/edit_box_usecase.dart';
import '../../domain/usecases/get_shown_box_usecase.dart';
import '../../domain/usecases/transfer_box_balance_usecase.dart';

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

  TextEditingController boxNameController = TextEditingController();
  // TextEditingController fromDateController = TextEditingController();
  // TextEditingController toDateController = TextEditingController();

  final tabs = ['boxes', 'movements', 'archive'].obs;

  RxInt currentTab = 0.obs;

  RxBool isLoading = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
    currentTab.value == 1 ? getAllBoxesLogs() : getShowBoxes();
  }

  // انشاء الصناديق

  TextEditingController createBoxNameController = TextEditingController();
  TextEditingController createStartBalanceController = TextEditingController();

  // تعديل الصناديق
  TextEditingController editBoxNameController = TextEditingController();
  TextEditingController editStartBalanceController = TextEditingController();
  TextEditingController appearController = TextEditingController();

  List<String> appears = ['visible', 'notVisible'];

  // اضافة رصيد
  TextEditingController addBalanceValueController = TextEditingController();

  // نقل رصيد
  TextEditingController transferToBoxIdController = TextEditingController();
  TextEditingController transferTotalController = TextEditingController();

  // get shown boxes
  final RxList<GetShownBoxesModel> shownBoxes = <GetShownBoxesModel>[].obs;
  void getShowBoxes() async {
    shownBoxes.isEmpty ? isLoading(true) : isLoading(false);
    final boxes = await getShownBoxUsecase.call(screen: currentTab.value);
    shownBoxes.value = boxes;
    isLoading(false);
  }

  // get all boxes
  final RxList<BoxLogModel> allBoxesLogs = <BoxLogModel>[].obs;
  void getAllBoxesLogs() async {
    allBoxesLogs.isEmpty ? isLoading(true) : isLoading(false);
    final boxes = await allBoxesLogsUsecase.call();
    allBoxesLogs.value = boxes;
    isLoading(false);
  }

  // get box details
  void getboxDetails(String boxId) async {
    isLoading(true);
    final boxes = await boxDetailsUesecase.call(boxId: boxId);
    editBoxNameController.text = boxes.boxName;
    editStartBalanceController.text = boxes.totalBalance.toString();
    appearController.text =
        boxes.isShown == 1.toString() ? 'visible' : 'notVisible';
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
          getShowBoxes();
          // transferFromBoxIdController.clear();
          transferToBoxIdController.clear();
          createStartBalanceController.clear();
          Future.delayed(
            const Duration(milliseconds: 1500),
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
          Future.delayed(
            const Duration(milliseconds: 1500),
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
          getShowBoxes();
          addBalanceValueController.clear();
          Future.delayed(
            const Duration(milliseconds: 1500),
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
        isShown: appearController.text == 'visible' ? '1' : '0',
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
          getShowBoxes();
          addBalanceValueController.clear();
          Future.delayed(
            const Duration(milliseconds: 1500),
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

  final RxList<BoxLogModel> filteredallBoxesLogs = <BoxLogModel>[].obs;
  final RxList<GetShownBoxesModel> filteredshownBoxes =
      <GetShownBoxesModel>[].obs;

  void filterLists() {
    if (boxNameController.text.isEmpty) {
      // رجع القوائم الأصلية
      filteredallBoxesLogs.value = allBoxesLogs;
      filteredshownBoxes.value = shownBoxes;
    } else {
      final lowerQuery = boxNameController.text.toLowerCase();
      // filter على الصناديق
      final filteredBoxes = shownBoxes.where(
        (e) => e.boxName.toLowerCase().contains(lowerQuery),
      );
      // filter على اللوجات
      final filteredLogs = allBoxesLogs.where((log) {
        final fromMatch =
            log.fromBox?.name.toLowerCase().contains(lowerQuery) ?? false;
        final toMatch =
            log.toBox?.name.toLowerCase().contains(lowerQuery) ?? false;
        final boxMatch =
            log.box?.name.toLowerCase().contains(lowerQuery) ?? false;
        return fromMatch || toMatch || boxMatch;
      }).toList();
      // هنا بترجع الليستات
      filteredshownBoxes.assignAll(filteredBoxes.toList());
      filteredallBoxesLogs.assignAll(filteredLogs.toList());
    }
    Get.back();
  }

  @override
  void onInit() {
    super.onInit();
    getShowBoxes();
    filteredallBoxesLogs.value = allBoxesLogs;
    filteredshownBoxes.value = shownBoxes;
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
    super.onClose();
  }
}
