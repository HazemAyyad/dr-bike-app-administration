import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/app_navigation.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../routes/app_routes.dart';
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
import '../widgets/box_report_pdf_builder.dart';

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
  final TextEditingController reportSearchController = TextEditingController();
  final TextEditingController reportMinAmountController =
      TextEditingController();
  final TextEditingController reportMaxAmountController =
      TextEditingController();
  final RxString reportDirection = ''.obs;
  final RxList<String> reportMovementTypes = <String>[].obs;

  final tabs = ['boxes', 'movements', 'archive'].obs;

  final RxInt currentTab = 0.obs;
  final RxBool isSearchVisible = false.obs;
  final RxString listCurrencyFilter = ''.obs;
  final RxnInt movementBoxFilter = RxnInt();

  final RxBool isLoading = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
    boxNameController.clear();
    if (index == 1) applyMovementFilters();
    update();
  }

  void toggleSearch() {
    isSearchVisible.value = !isSearchVisible.value;
    if (!isSearchVisible.value) {
      boxNameController.clear();
      searchBar('');
    }
    update(['boxesSearch']);
  }

  void closeSearch() {
    isSearchVisible.value = false;
    boxNameController.clear();
    searchBar('');
    update(['boxesSearch']);
  }

  BoxLogModel? lastMovementFor(int boxId) {
    final id = boxId.toString();
    BoxLogModel? result;
    for (final log in BoxesServes().allBoxesLogs) {
      if (log.boxId != id && log.fromBoxId != id && log.toBoxId != id) {
        continue;
      }
      if (result == null || log.createdAt.isAfter(result.createdAt)) {
        result = log;
      }
    }
    return result;
  }

  List<String> get availableBoxCurrencies => BoxesServes()
      .shownBoxes
      .map((box) => box.currency.trim())
      .where((currency) => currency.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  void applyListFilters() {
    final query = boxNameController.text.trim().toLowerCase();
    final currency = listCurrencyFilter.value;
    filteredShownBoxes.assignAll(
      BoxesServes().shownBoxes.where((box) {
        final matchesQuery = query.isEmpty ||
            box.boxName.toLowerCase().contains(query) ||
            box.currency.toLowerCase().contains(query) ||
            box.totalBalance.toString().contains(query) ||
            (lastMovementFor(box.boxId)
                    ?.description
                    .toLowerCase()
                    .contains(query) ??
                false);
        return matchesQuery &&
            (currency.isEmpty || box.currency.trim() == currency);
      }),
    );
    update();
  }

  void clearListFilters() {
    listCurrencyFilter.value = '';
    movementBoxFilter.value = null;
    if (currentTab.value == 1) {
      applyMovementFilters();
      return;
    }
    applyListFilters();
  }

  List<ShownBoxesModel> get movementFilterBoxes {
    final unique = <int, ShownBoxesModel>{};
    for (final box in [
      ...BoxesServes().shownBoxes,
      ...BoxesServes().shownBoxesArchive
    ]) {
      unique[box.boxId] = box;
    }
    return unique.values.toList()
      ..sort((a, b) => a.boxName.compareTo(b.boxName));
  }

  void applyMovementFilters() {
    final query = boxNameController.text.trim().toLowerCase();
    final selectedId = movementBoxFilter.value?.toString();
    filteredAllBoxesLogs.assignAll(BoxesServes().allBoxesLogs.where((log) {
      final matchesBox = selectedId == null ||
          log.boxId == selectedId ||
          log.fromBoxId == selectedId ||
          log.toBoxId == selectedId;
      final fields = [
        log.description,
        log.note ?? '',
        log.value.toString(),
        log.type ?? '',
        log.box?.name ?? '',
        log.fromBox?.name ?? '',
        log.toBox?.name ?? ''
      ];
      return matchesBox &&
          (query.isEmpty ||
              fields.any((field) => field.toLowerCase().contains(query)));
    }));
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
  final RxString boxDetailsDebugMessage = ''.obs;

  final List<String> appears = ['visible', 'notVisible'];

  // اضافة رصيد
  final TextEditingController addBalanceValueController =
      TextEditingController();
  final TextEditingController addBalanceNoteController =
      TextEditingController();

  // نقل رصيد
  final TextEditingController transferToBoxIdController =
      TextEditingController();
  final TextEditingController transferTotalController = TextEditingController();

  // get shown boxes

  Future<void> pullToRefresh() => getAllBoxes(showLoading: true);

  Future<void> getAllBoxes({bool showLoading = false}) async {
    if (kDebugMode) {
      debugPrint(
        '[BoxesController] getAllBoxes start '
        'userType=$userType permissionIds=$employeePermissions '
        'permissionNames=$employeePermissionNames '
        'cachedShown=${BoxesServes().shownBoxes.length}',
      );
    }
    if (showLoading || BoxesServes().shownBoxes.isEmpty) {
      isLoading(true);
    } else {
      isLoading(false);
    }
    final shownBoxesList = await getShownBoxUsecase.call(screen: 0);
    if (kDebugMode) {
      debugPrint(
        '[BoxesController] fetched shown boxes count=${shownBoxesList.length} '
        'boxes=${shownBoxesList.map((b) => '${b.boxId}:${b.boxName}:${b.type}').join('|')}',
      );
    }
    BoxesServes().shownBoxes.assignAll(shownBoxesList);
    filteredShownBoxes.assignAll(BoxesServes().shownBoxes);

    final boxesLogsList = await allBoxesLogsUsecase.call();
    if (kDebugMode) {
      debugPrint(
        '[BoxesController] fetched box logs count=${boxesLogsList.length}',
      );
    }
    BoxesServes().allBoxesLogs.assignAll(boxesLogsList);
    filteredAllBoxesLogs.assignAll(BoxesServes().allBoxesLogs);

    final boxesArchiveList = await getShownBoxUsecase.call(screen: 2);
    if (kDebugMode) {
      debugPrint(
        '[BoxesController] fetched archive boxes count=${boxesArchiveList.length} '
        'boxes=${boxesArchiveList.map((b) => '${b.boxId}:${b.boxName}:${b.type}').join('|')}',
      );
    }
    BoxesServes().shownBoxesArchive.assignAll(boxesArchiveList);
    filteredShownBoxesArchive.assignAll(BoxesServes().shownBoxesArchive);
    isLoading(false);
    update();
  }

  String boxDetailsId = '0';
  // get box details
  Future<void> getboxDetails(String boxId) async {
    isLoading(true);
    update();
    boxDetailsId = boxId;
    boxDetailsDebugMessage.value = '';
    try {
      if (kDebugMode) {
        debugPrint('[BoxesController.getboxDetails] start boxId=$boxId');
      }
      if (boxId.isEmpty) {
        throw Exception('Missing box id from navigation arguments');
      }
      final boxDetails = await boxDetailsUesecase.call(boxId: boxId);

      editBoxNameController.text = boxDetails.boxName;
      editStartBalanceController.text = boxDetails.totalBalance.toString();
      editAppearController.text =
          boxDetails.isShown == 1.toString() ? 'visible' : 'notVisible';
      editCurrencyController.text = boxDetails.currency;
      boxDetailsLogs.assignAll(boxDetails.boxLogs);
      if (kDebugMode) {
        debugPrint(
          '[BoxesController.getboxDetails] success '
          'name=${boxDetails.boxName} total=${boxDetails.totalBalance} '
          'shown=${boxDetails.isShown} currency=${boxDetails.currency} '
          'logs=${boxDetails.boxLogs.length}',
        );
      }
    } catch (e, stackTrace) {
      boxDetailsDebugMessage.value = e.toString();
      if (kDebugMode) {
        debugPrint('[BoxesController.getboxDetails] error: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading(false);
      update();
    }
  }

  final RxBool isAddBoxLoading = false.obs;

  void _popToBoxesScreen() {
    Future.delayed(
      const Duration(milliseconds: 650),
      () => AppNavigation.popToRoute(AppRoutes.BOXESSCREEN),
    );
  }

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
          transferToBoxIdController.clear();
          createStartBalanceController.clear();
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
          createBoxNameController.clear();
          createStartBalanceController.clear();
          currencyController.clear();
          _popToBoxesScreen();
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
  void addBoxBalance(BuildContext context, String boxId) async {
    if ((formKey.currentState as FormState).validate()) {
      isAddBoxLoading(true);

      final result = await addBoxBalanceUsecase.call(
        boxId: boxId,
        total: addBalanceValueController.text,
        note: addBalanceNoteController.text.trim(),
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
          addBalanceNoteController.clear();
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
        getAllBoxes();
        _popToBoxesScreen();
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

  RxList<ShownBoxesModel> filteredShownBoxes = <ShownBoxesModel>[].obs;
  RxList<BoxLogModel> filteredAllBoxesLogs = <BoxLogModel>[].obs;
  RxList<ShownBoxesModel> filteredShownBoxesArchive = <ShownBoxesModel>[].obs;

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
    bool matches(ShownBoxesModel box, String query) {
      final q = query.toLowerCase();
      return (box.boxName.toLowerCase().contains(q)) ||
          (box.currency.toLowerCase().contains(q)) ||
          (box.totalBalance.toString().toLowerCase().contains(q));
    }

    if (currentTab.value == 0) {
      applyListFilters();
      return;
    }
    if (currentTab.value == 1) {
      applyMovementFilters();
      return;
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
    String action = 'save',
  }) async {
    try {
      Get.back();
      Get.snackbar(
        "info".tr,
        "جار تحميل الملف. سيتم اعلامك عند الانتهاء".tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 2500),
      );
      final response = await Get.find<DioConsumer>().post(
        EndPoints.boxLogsData,
        data: {
          'box_id': boxId,
          'from_date': fromDateController.text,
          'to_date': toDateController.text,
          'all': true,
          if (reportDirection.value.isNotEmpty)
            'direction': reportDirection.value,
          if (reportMovementTypes.isNotEmpty)
            'types': reportMovementTypes.toList(),
          if (reportSearchController.text.trim().isNotEmpty)
            'search': reportSearchController.text.trim(),
          if (double.tryParse(reportMinAmountController.text) != null)
            'min_amount': double.parse(reportMinAmountController.text),
          if (double.tryParse(reportMaxAmountController.text) != null)
            'max_amount': double.parse(reportMaxAmountController.text),
        },
      );
      final root = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      if (root['status'] != 'success' || root['data'] is! Map) {
        throw Exception(root['message'] ?? 'تعذر تجهيز بيانات التقرير');
      }
      final success = await BoxReportPdfBuilder.build(
          Map<String, dynamic>.from(root['data'] as Map));
      final safeName = boxName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final reportFileName =
          'تقرير_صندوق_${safeName}_${fromDateController.text}_${toDateController.text}.pdf';
      if (action == 'share') {
        await Printing.sharePdf(bytes: success, filename: reportFileName);
        _clearReportFilters();
        return;
      }
      if (action == 'print') {
        await Printing.layoutPdf(
          name: reportFileName,
          onLayout: (_) async => success,
        );
        _clearReportFilters();
        return;
      }
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
      final filePath = "${directory.path}/$reportFileName";
      final file = File(filePath);
      await file.writeAsBytes(success);
      Get.snackbar(
        "fileDownloadedSuccessfully".tr,
        filePath,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 2000),
      );

      await OpenFilex.open(filePath);
      _clearReportFilters();
    } catch (e) {
      Get.snackbar(
        "error".tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 2500),
      );
    }
  }

  void _clearReportFilters() {
    fromDateController.clear();
    toDateController.clear();
    reportSearchController.clear();
    reportMinAmountController.clear();
    reportMaxAmountController.clear();
    reportDirection.value = '';
    reportMovementTypes.clear();
  }

  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) {
      debugPrint(
        '[BoxesController] onInit userType=$userType '
        'permissionIds=$employeePermissions permissionNames=$employeePermissionNames '
        'cachedShown=${BoxesServes().shownBoxes.length}',
      );
    }
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
    addBalanceNoteController.dispose();
    transferToBoxIdController.dispose();
    transferTotalController.dispose();
    currencyController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    reportSearchController.dispose();
    reportMinAmountController.dispose();
    reportMaxAmountController.dispose();

    super.onClose();
  }
}
