import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../routes/app_routes.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../data/models/check_model.dart';
import '../../data/models/general_incoming_model.dart';
import '../../data/models/general_outgoing_data_model.dart';
import '../../domain/usecases/add_checks_usecase.dart';
import '../../domain/usecases/all_customers_sellers_usecase.dart';
import '../../domain/usecases/cashed_to_person_cancel_usecase.dart';
import '../../domain/usecases/delete_check_usecase.dart';
import '../../domain/usecases/edit_checks_usecase.dart';
import '../../domain/usecases/general_checks_data_usecase.dart';
import '../../domain/usecases/get_checks_usecase.dart';
import '../../domain/usecases/return_check_usercase.dart';
import '../../domain/usecases/chash_to_box_usecase.dart';
import 'checks_serves.dart';

class ChecksController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final AddChecksUsecase addChecksUsecase;
  final GetChecksUsecase getChecksUsecase;
  final GeneralChecksDataUsecase generalChecksDataUsecase;
  final CashedToPersonOrCashedUsecase cashedToPersonCancelUsecase;
  final AllCustomersSellersUsecase allCustomersSellersUsecase;
  // final GeneralOutgoingDataUsecase generalOutgoingDataUsecase;
  final ReturnCheckUsercase returnCheckUsercase;
  final GetShownBoxUsecase getShownBoxUsecase;
  final ChashToBoxUsecase chashToBoxUsecase;
  final EditChecksUsecase editChecksUsecase;
  final DeleteCheckUsecase deleteCheckUsecase;

  ChecksController({
    required this.addChecksUsecase,
    required this.getChecksUsecase,
    required this.generalChecksDataUsecase,
    required this.cashedToPersonCancelUsecase,
    required this.allCustomersSellersUsecase,
    // required this.generalOutgoingDataUsecase,
    required this.returnCheckUsercase,
    required this.getShownBoxUsecase,
    required this.chashToBoxUsecase,
    required this.editChecksUsecase,
    required this.deleteCheckUsecase,
  });

  final GlobalKey formKey = GlobalKey<FormState>();

  final TextEditingController checkValueController = TextEditingController();

  final TextEditingController employeeNameController = TextEditingController();

  final RxBool amountFilter = false.obs;

  final RxBool dateFilter = false.obs;

  // متغيرات للتقويم
  final selectedDay = DateTime.now().obs;
  final isCalendarVisible = false.obs;
  // دالة لإظهار/إخفاء التقويم
  void toggleCalendar() {
    isCalendarVisible.value = !isCalendarVisible.value;
  }

  // العملات
  final TextEditingController currencyController = TextEditingController();
  List<String> currency = [
    'currency',
    'currency1',
    'currency2',
  ].obs;

  final TextEditingController checkNumberController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  // صورة الشيك من الامام
  final Rx<XFile?> checkFrontImage = Rx<XFile?>(null);
  // List<File> checkFrontImage = [];
  // صورة الشيك من الخلف
  final Rx<XFile?> checkBackImage = Rx<XFile?>(null);
  // List<File> checkBackImage = [];

  final currentTab = 0.obs;
  final tabs = ['didNotActOnIt', 'actedOnIt', 'archive'].obs;

  final isLoading = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
    // generalData();
    update();
  }

  RxBool selectedCustomersSellers = false.obs;

  bool isInComing = false;

  // الشيكات الصادرة
  RxList<String> outgoingChecksDidNotActOnIt = <String>[
    'endorseTheCheck',
    'returnedCheck',
    'voidTheCheck',
    'deleteCheck'
  ].obs;

  RxList<String> outgoingChecksActedOnIt = <String>[
    // 'cashTheCheck',
    'returnedCheck', 'voidTheCheck'
  ].obs;

  // الشيكات الواردة
  RxList<String> incomingChecksDidNotActOnIt = <String>[
    'endorseTheCheck',
    'cashTheCheck',
    'returnedCheck',
    'deleteCheck',
    'voidTheCheck'
  ].obs;

  RxList<String> incomingChecksActedOnIt = <String>[
    // 'cashTheCheck',
    'returnedCheck'
  ].obs;

  RxList<String> archive = ['deleteCheck'].obs;

  // add checks
  void addChecks({
    required BuildContext context,
    required bool isInComing,
    String? customerId,
    String? sellerId,
  }) async {
    if ((formKey.currentState as FormState).validate()) {
      isLoading(true);
      final result = await addChecksUsecase.call(
        isInComing: isInComing,
        customerId: customerId,
        sellerId: sellerId,
        total: checkValueController.text,
        dueDate: selectedDay.value,
        currency: currencyController.text.tr,
        checkId: checkNumberController.text,
        bankName: bankNameController.text,
        frontImage: checkFrontImage.value,
        backImage: checkBackImage.value,
      );
      result.fold(
        (failure) {
          isLoading(false);
          update();

          final errors = failure.data['errors'];
          String errorMessage = '';
          if (errors is Map) {
            errorMessage = errors.entries
                .map((e) => "${e.key}: ${(e.value as List).join(', ')}")
                .join("\n");
          } else {
            errorMessage = errors.toString();
          }
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: errorMessage,
          );
        },
        (success) {
          getGeneralChecksData();
          // generalData();
          getCashedToPerson();
          getNotCashed();
          getArchive();

          checkValueController.clear();
          currencyController.clear();
          checkNumberController.clear();
          bankNameController.clear();
          checkFrontImage.value = null;
          checkBackImage.value = null;
          selectedDay.value = DateTime.now();
          isCalendarVisible.value = false;
          checkFrontImage.value = null;
          checkBackImage.value = null;
          Get.back();
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
    isLoading(false);
    update();
  }

  final RxnString selectedValue = RxnString();
  RxBool isEdit = false.obs;
  final Rx<XFile?> editCheckFrontImage = Rx<XFile?>(null);
  final Rx<XFile?> editCheckBackImage = Rx<XFile?>(null);

  String? checkId;
  void getCeckData({CheckModel? check, required bool isOutgoing}) {
    if (isEdit.value) {
      Get.toNamed(
        AppRoutes.NEWCHECKSCREEN,
        arguments: {'isNewCheck': isOutgoing},
      );
      checkId = check!.id.toString();
      checkValueController.text = check.total.toString();
      currencyController.text =
          currency.where((element) => element.tr == check.currency).first;
      checkNumberController.text = check.checkId;
      bankNameController.text = check.bankName;
      editCheckFrontImage.value =
          check.frontImage != null ? XFile(check.frontImage!) : null;
      editCheckBackImage.value =
          check.backImage != null ? XFile(check.backImage!) : null;
      selectedDay.value = check.dueDate;
      isCalendarVisible.value = false;
      selectedValue.value = check.fromCustomer != null
          ? check.fromCustomer!.id.toString()
          : check.fromSeller?.id.toString();
      selectedCustomersSellers.value = check.fromCustomer == null;
    } else {
      Get.toNamed(
        AppRoutes.NEWCHECKSCREEN,
        arguments: {'isNewCheck': isOutgoing},
      );
      selectedValue.value = null;
      selectedCustomersSellers.value = false;
      checkId = null;
      checkValueController.clear();
      currencyController.clear();
      checkNumberController.clear();
      bankNameController.clear();
      editCheckFrontImage.value = null;
      editCheckBackImage.value = null;
      selectedDay.value = DateTime.now();
      isCalendarVisible.value = false;
    }
    update();
  }

  // edit checks
  void editChecks({
    required BuildContext context,
    required bool isInComing,
    required String checkId,
  }) async {
    if ((formKey.currentState as FormState).validate()) {
      isLoading(true);
      final result = await editChecksUsecase.call(
        isInComing: isInComing,
        outgoingCheckId: checkId,
        dueDate: selectedDay.value,
        checkId: checkNumberController.text,
        bankName: bankNameController.text,
        frontImage: checkFrontImage.value != null
            ? XFile(checkFrontImage.value!.path)
            : editCheckFrontImage.value != null
                ? XFile(editCheckFrontImage.value!.path)
                : null,
        backImage: checkBackImage.value != null
            ? XFile(checkBackImage.value!.path)
            : editCheckBackImage.value != null
                ? XFile(editCheckBackImage.value!.path)
                : null,
      );
      result.fold(
        (failure) {
          isLoading(false);
          update();

          final errors = failure.data['errors'];
          String errorMessage = '';
          if (errors is Map) {
            errorMessage = errors.entries
                .map((e) => "${e.key}: ${(e.value as List).join(', ')}")
                .join("\n");
          } else {
            errorMessage = errors.toString();
          }
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: errorMessage,
          );
        },
        (success) {
          getGeneralChecksData();
          // generalData();
          getCashedToPerson();
          getNotCashed();
          getArchive();

          checkValueController.clear();
          currencyController.clear();
          checkNumberController.clear();
          bankNameController.clear();
          checkFrontImage.value = null;
          checkBackImage.value = null;
          selectedDay.value = DateTime.now();
          isCalendarVisible.value = false;
          Get.back();
          Get.back();
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
    isLoading(false);
    update();
  }

  // cash to person or cancel
  void cashedToPersonOrCashed({
    required String checkId,
    String? customerId,
    String? sellerId,
  }) async {
    isLoading(true);
    final result = await cashedToPersonCancelUsecase.call(
      isInComing: isInComing,
      checkId: checkId,
      customerId: customerId,
      sellerId: sellerId,
    );
    result.fold(
      (failure) {
        isLoading(false);
        update();
        Get.snackbar(
          'error'.tr,
          failure.errMessage,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
      (success) async {
        Get.back();
        await Future.wait([
          getGeneralChecksData(),
          // generalData(),
          getCashedToPerson(),
          getNotCashed(),
          getArchive(),
        ]);
        Future.delayed(
          const Duration(milliseconds: 1500),
          () {
            Get.back();
          },
        );
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
    );
    isLoading(false);
    update();
  }

  // return check
  void returnCheck({required String checkId, required bool isCancel}) async {
    isLoading(true);
    final result = await returnCheckUsercase.call(
      checkId: checkId,
      isInComing: isInComing,
      isCancel: isCancel,
    );
    result.fold(
      (failure) async {
        isLoading(false);
        update();

        await Future.wait([
          getGeneralChecksData(),
          // generalData(),
          getCashedToPerson(),
          getNotCashed(),
          getArchive(),
        ]);
        Future.delayed(
          const Duration(milliseconds: 1500),
          () {
            Get.back();
          },
        );
      },
      (success) async {
        Get.back();
        await Future.wait([
          getGeneralChecksData(),
          // generalData(),
          getCashedToPerson(),
          getNotCashed(),
          getArchive(),
        ]);
        Future.delayed(
          const Duration(milliseconds: 1500),
          () {
            Get.back();
          },
        );
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
    );
    isLoading(false);
    update();
  }

  // cash to box
  void chashToBox({required String checkId, required String boxId}) async {
    isLoading(true);
    final result = await chashToBoxUsecase.chashToBox(
      checkId: checkId,
      boxId: boxId,
    );
    result.fold(
      (failure) {
        isLoading(false);
        update();

        Get.snackbar(
          'error'.tr,
          failure.errMessage,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
      (success) async {
        Get.back();
        await Future.wait([
          getGeneralChecksData(),
          // generalData(),
          getCashedToPerson(),
          getNotCashed(),
          getArchive(),
        ]);
        Future.delayed(
          const Duration(milliseconds: 1500),
          () {
            Get.back();
          },
        );
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
    );

    isLoading(false);
    update();
  }

  // delete check
  void deleteCheck({required String checkId}) async {
    isLoading(true);
    final result = await deleteCheckUsecase.deleteCheck(checkId: checkId);
    result.fold(
      (failure) {
        isLoading(false);
        update();
        Get.snackbar(
          'error'.tr,
          failure.errMessage,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1000),
        );
      },
      (success) async {
        Get.back();
        await Future.wait([
          getGeneralChecksData(),
          // generalData(),
          getCashedToPerson(),
          getNotCashed(),
          getArchive(),
        ]);
        Future.delayed(
          const Duration(milliseconds: 1000),
          () {
            Get.back();
          },
        );
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1000),
        );
      },
    );
    isLoading(false);
    update();
  }

  // get all not cashed outgoing checks
  final Rxn<NotCashedModel> inComingChecksList = Rxn<NotCashedModel>(null);
  final Map<String, List<CheckModel>> inComingTasks = {};
  final Map<String, double> totalInComing = {};

  Future<void> getNotCashed() async {
    isLoading(true);

    filteredInComingTasks.clear();
    inComingTasks.clear();
    totalInComing.clear();

    final result = await getChecksUsecase.call(
      endPoint: isInComing
          ? EndPoints.inComingChecks
          : EndPoints.notCashedOutgoingChecks,
    );
    inComingChecksList.value =
        NotCashedModel.fromJson(result, checksPath: 'not_cashed_checks');

    for (var task in inComingChecksList.value!.inComingChecksList) {
      String dateKey =
          "${task.dueDate.year}/${task.dueDate.month.toString().padLeft(2, '0')}";

      // group by month
      if (inComingTasks.containsKey(dateKey)) {
        if (!inComingTasks[dateKey]!.any((a) => a.id == task.id)) {
          inComingTasks[dateKey]!.add(task);
        }
      } else {
        inComingTasks[dateKey] = [task];
      }
      final total = double.tryParse(task.total.toString()) ?? 0.0;
      totalInComing[dateKey] = (totalInComing[dateKey] ?? 0.0) + total;
    }

    inComingTasks.forEach((key, tasks) {
      tasks.sort((a, b) => a.dueDate.day.compareTo(b.dueDate.day));
    });

    filteredInComingTasks.assignAll(inComingTasks);
    update();
    isLoading(false);
    update();
  }

  // get cashed to person checks
  final Rxn<NotCashedModel> cashedToPerson = Rxn<NotCashedModel>(null);
  final Map<String, List<CheckModel>> cashedToPersonTasks = {};
  final Map<String, double> totalCashedToPerson = {};

  Future<void> getCashedToPerson() async {
    isLoading(true);

    filteredCashedToPersonTasks.clear();
    cashedToPersonTasks.clear();
    totalCashedToPerson.clear();
    final result = await getChecksUsecase.call(
      endPoint: isInComing
          ? EndPoints.cashedIncomingChecks
          : EndPoints.cashedOutgoingChecks,
    );
    cashedToPerson.value =
        NotCashedModel.fromJson(result, checksPath: 'cashed_to_person_checks');

    for (var task in cashedToPerson.value!.inComingChecksList) {
      String dateKey =
          "${task.dueDate.year}/${task.dueDate.month.toString().padLeft(2, '0')}";
      if (cashedToPersonTasks.containsKey(dateKey)) {
        if (!cashedToPersonTasks[dateKey]!.any((a) => a.id == task.id)) {
          cashedToPersonTasks[dateKey]!.add(task);
        }
      } else {
        cashedToPersonTasks[dateKey] = [task];
      }
      final total = double.tryParse(task.total.toString()) ?? 0.0;
      // accumulate totals by month
      totalCashedToPerson[dateKey] =
          (totalCashedToPerson[dateKey] ?? 0.0) + total;
    }
    cashedToPersonTasks.forEach((key, tasks) {
      tasks.sort((a, b) => a.dueDate.day.compareTo(b.dueDate.day));
    });
    filteredCashedToPersonTasks.assignAll(cashedToPersonTasks);
    update();
    isLoading(false);
    update();
  }

  // get cashed to person checks
  final Rxn<NotCashedModel> archiveData = Rxn<NotCashedModel>(null);
  final Map<String, List<CheckModel>> archiveTasks = {};
  final Map<String, double> totalArchive = {};

  Future<void> getArchive() async {
    isLoading(true);

    filteredArchiveTasks.clear();
    archiveTasks.clear();
    totalArchive.clear();
    final result = await getChecksUsecase.call(
      endPoint: isInComing
          ? EndPoints.archivedIncomingChecks
          : EndPoints.archivedOutgoingChecks,
    );
    archiveData.value =
        NotCashedModel.fromJson(result, checksPath: 'archived_checks');

    for (var task in archiveData.value!.inComingChecksList) {
      String dateKey =
          "${task.dueDate.year}/${task.dueDate.month.toString().padLeft(2, '0')}";
      if (archiveTasks.containsKey(dateKey)) {
        if (!archiveTasks[dateKey]!.any((a) => a.id == task.id)) {
          archiveTasks[dateKey]!.add(task);
        }
      } else {
        archiveTasks[dateKey] = [task];
      }
      final total = double.tryParse(task.total.toString()) ?? 0.0;
      totalArchive[dateKey] = (totalArchive[dateKey] ?? 0.0) + total;
    }
    filteredArchiveTasks.assignAll(archiveTasks);
    update();
    isLoading(false);
    update();
  }

  // get general checks data
  // final Rxn<GeneralChecksDataModel> generalChecksData =
  //     Rxn<GeneralChecksDataModel>(null);

  Future<void> getGeneralChecksData() async {
    final result = await generalChecksDataUsecase.call();
    ChecksServes().generalChecksData.value = result;
    update();
  }

  // get all customers and sellers
  final RxList<SellerModel> allCustomersList = <SellerModel>[].obs;
  final RxList<SellerModel> allSellersList = <SellerModel>[].obs;

  void getAllCustomersAndSellers() async {
    final resultCustomers = await allCustomersSellersUsecase.call(
        endPoint: EndPoints.all_customers);
    final resultSellers =
        await allCustomersSellersUsecase.call(endPoint: EndPoints.all_sellers);
    allSellersList.assignAll(resultSellers);
    allCustomersList.assignAll(resultCustomers);
  }

  // get general incoming
  final Rxn<GeneralIncomingModel> generalIncoming =
      Rxn<GeneralIncomingModel>(null);

  // get general outgoing
  final Rxn<GeneralOutgoingDataModel> generalOutgoing =
      Rxn<GeneralOutgoingDataModel>(null);

  // Future<void> generalData() async {
  //   isLoading(true);
  //   final result =
  //       await generalOutgoingDataUsecase.call(isInComing: isInComing);
  //   isInComing
  //       ? generalIncoming.value = GeneralIncomingModel.fromJson(result)
  //       : generalOutgoing.value = GeneralOutgoingDataModel.fromJson(result);
  //   isLoading(false);
  //   update();
  // }

  // get shown boxes
  final RxList<shownBoxesModel> shownBoxesList = <shownBoxesModel>[].obs;

  void getShowBoxes() async {
    final boxes = await getShownBoxUsecase.call(screen: currentTab.value);
    shownBoxesList.value = boxes;
  }

  // filter assets by date
  // فلترة وتجميع الشيكات حسب التاريخ + الترتيب
  Map<String, List<CheckModel>> filterChecks(
    Map<String, List<CheckModel>> source,
    String nameQuery,
    bool filterByAmount,
  ) {
    // لو الفلاتر كلها فاضية → رجع النسخة الأصلية زي ما هي
    if (nameQuery.isEmpty && !filterByAmount) {
      return Map.from(source);
    }

    final allChecks = source.values.expand((tasks) => tasks).toList();

    final filtered = allChecks.where((check) {
      bool matchesName = true;
      bool matchesAmount = true;

      // فلترة بالاسم
      if (nameQuery.isNotEmpty) {
        if (check.customer != null) {
          matchesName = check.customer!.name
              .toLowerCase()
              .contains(nameQuery.toLowerCase());
        }
        if (check.seller != null) {
          matchesName = check.seller!.name
              .toLowerCase()
              .contains(nameQuery.toLowerCase());
        }
        if (check.fromCustomer != null) {
          matchesName = check.fromCustomer!.name
              .toLowerCase()
              .contains(nameQuery.toLowerCase());
        }
        if (check.fromSeller != null) {
          matchesName = check.fromSeller!.name
              .toLowerCase()
              .contains(nameQuery.toLowerCase());
        }
      }

      // فلترة بالمبلغ (أكبر من 0)
      if (filterByAmount) {
        matchesAmount = (double.tryParse(check.total.toString()) ?? 0) > 0;
      }

      return matchesName && matchesAmount;
    }).toList();

    // إعادة التجميع حسب التاريخ (شهر/سنة)
    final Map<String, List<CheckModel>> grouped = {};
    for (var check in filtered) {
      final dateKey =
          "${check.dueDate.year}/${check.dueDate.month.toString().padLeft(2, '0')}";
      grouped.putIfAbsent(dateKey, () => []).add(check);
    }

    // الترتيب داخل كل شهر
    grouped.forEach((key, checks) {
      checks.sort((a, b) {
        if (filterByAmount) {
          // لو فلترة بالمبلغ → رتب تنازلي حسب المبلغ
          final totalA = double.tryParse(a.total.toString()) ?? 0.0;
          final totalB = double.tryParse(b.total.toString()) ?? 0.0;
          return totalB.compareTo(totalA);
        } else {
          // لو مفيش فلترة مبلغ → رتب حسب اليوم
          return a.dueDate.day.compareTo(b.dueDate.day);
        }
      });
    });

    // ترتيب الشهور زمنيًا (قديم → جديد)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final aParts = a.split('/');
        final bParts = b.split('/');
        final aDate = DateTime(int.parse(aParts[0]), int.parse(aParts[1]));
        final bDate = DateTime(int.parse(bParts[0]), int.parse(bParts[1]));
        return aDate.compareTo(bDate);
      });

    final Map<String, List<CheckModel>> sortedGrouped = {
      for (var key in sortedKeys) key: grouped[key]!
    };

    return sortedGrouped;
  }

  Map<String, List<CheckModel>> filteredInComingTasks = {};
  Map<String, List<CheckModel>> filteredCashedToPersonTasks = {};
  Map<String, List<CheckModel>> filteredArchiveTasks = {};

  void applyFilters() {
    final query = employeeNameController.text.trim();

    filteredCashedToPersonTasks.assignAll(
      filterChecks(cashedToPersonTasks, query, amountFilter.value),
    );

    filteredArchiveTasks.assignAll(
      filterChecks(archiveTasks, query, amountFilter.value),
    );

    filteredInComingTasks.assignAll(
      filterChecks(inComingTasks, query, amountFilter.value),
    );
    Get.back();
    update();
  }

  void searchBar(String value) {
    bool matches(CheckModel check, String query) {
      final q = query.toLowerCase();
      return (check.checkId.toLowerCase().contains(q)) ||
          (check.bankName.toLowerCase().contains(q)) ||
          (check.currency.toLowerCase().contains(q)) ||
          (check.total.toLowerCase().contains(q)) ||
          (check.dueDate.toString().contains(q)) ||
          (check.customer?.name.toLowerCase().contains(q) ?? false) ||
          (check.seller?.name.toLowerCase().contains(q) ?? false) ||
          (check.fromCustomer?.name.toLowerCase().contains(q) ?? false) ||
          (check.fromSeller?.name.toLowerCase().contains(q) ?? false);
    }

    if (value.isNotEmpty) {
      filteredInComingTasks = Map.fromEntries(
        inComingTasks.entries.map((entry) {
          final filtered =
              entry.value.where((check) => matches(check, value)).toList();
          return MapEntry(entry.key, filtered);
        }).where((entry) => entry.value.isNotEmpty),
      );

      filteredCashedToPersonTasks = Map.fromEntries(
        cashedToPersonTasks.entries.map((entry) {
          final filtered =
              entry.value.where((check) => matches(check, value)).toList();
          return MapEntry(entry.key, filtered);
        }).where((entry) => entry.value.isNotEmpty),
      );

      filteredArchiveTasks = Map.fromEntries(
        archiveTasks.entries.map((entry) {
          final filtered =
              entry.value.where((check) => matches(check, value)).toList();
          return MapEntry(entry.key, filtered);
        }).where((entry) => entry.value.isNotEmpty),
      );
    } else {
      filteredInComingTasks.assignAll(inComingTasks);
      filteredCashedToPersonTasks.assignAll(cashedToPersonTasks);
      filteredArchiveTasks.assignAll(archiveTasks);
    }

    update();
  }

  @override
  void onInit() {
    super.onInit();
    getGeneralChecksData();

    getAllCustomersAndSellers();
    getShowBoxes();
  }

  @override
  void onClose() {
    checkValueController.dispose();
    currencyController.dispose();
    checkNumberController.dispose();
    bankNameController.dispose();
    super.onClose();
  }
}
