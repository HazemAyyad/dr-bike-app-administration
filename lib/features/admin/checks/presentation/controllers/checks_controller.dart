import 'package:doctorbike/features/admin/boxes/domain/usecases/get_shown_box_usecase.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../data/models/archive_data_modell.dart';
import '../../data/models/cashed_to_person_outgoing_model.dart';
import '../../data/models/check_model.dart';
import '../../data/models/general_incoming_model.dart';
import '../../data/models/general_outgoing_data_model.dart';
import '../../domain/usecases/add_checks_usecase.dart';
import '../../domain/usecases/all_customers_sellers_usecase.dart';
import '../../domain/usecases/cashed_to_person_cancel_usecase.dart';
import '../../domain/usecases/general_checks_data_usecase.dart';
import '../../domain/usecases/general_outgoing_data_usecase.dart';
import '../../domain/usecases/get_checks_usecase.dart';
import '../../domain/usecases/return_check_usercase.dart';
import '../../domain/usecases/chash_to_box_usecase.dart';
import 'checks_serves.dart';

class ChecksController extends GetxController
    with GetSingleTickerProviderStateMixin {
  AddChecksUsecase addChecksUsecase;
  GetChecksUsecase getChecksUsecase;
  GeneralChecksDataUsecase generalChecksDataUsecase;
  CashedToPersonCancelUsecase cashedToPersonCancelUsecase;
  AllCustomersSellersUsecase allCustomersSellersUsecase;
  GeneralOutgoingDataUsecase generalOutgoingDataUsecase;
  ReturnCheckUsercase returnCheckUsercase;
  GetShownBoxUsecase getShownBoxUsecase;
  ChashToBoxUsecase chashToBoxUsecase;

  ChecksController({
    required this.addChecksUsecase,
    required this.getChecksUsecase,
    required this.generalChecksDataUsecase,
    required this.cashedToPersonCancelUsecase,
    required this.allCustomersSellersUsecase,
    required this.generalOutgoingDataUsecase,
    required this.returnCheckUsercase,
    required this.getShownBoxUsecase,
    required this.chashToBoxUsecase,
  });

  final GlobalKey formKey = GlobalKey<FormState>();

  final TextEditingController checkValueController = TextEditingController();

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
    // currentTab.value == 0
    //     ? getNotCashedOutgoing()
    //     : currentTab.value == 0
    //         ? getCashedToPerson()
    //         : getArchiveData();
  }

  RxBool selectedCustomersSellers = false.obs;

  bool isInComing = false;

  // الشيكات الصادرة
  RxList<String> outgoingChecksDidNotActOnIt =
      <String>['endorseTheCheck', 'voidTheCheck'].obs;

  RxList<String> outgoingChecksActedOnIt =
      <String>['cashTheCheck', 'returnedCheck', 'voidTheCheck'].obs;

  List<String> beneficiary = [
    'ماجد أحمد',
    'علي محمد',
    'سارة خالد',
    'أحمد علي',
  ].obs;

  String selectedBeneficiary = '';

  final RxBool amountFilter = false.obs;

  final RxBool dateFilter = false.obs;

  // الشيكات الواردة
  RxList<String> incomingChecksDidNotActOnIt =
      <String>['cashTheCheck', 'returnedCheck', 'endorseTheCheck'].obs;

  RxList<String> incomingChecksActedOnIt =
      <String>['cashTheCheck', 'returnedCheck'].obs;

  RxList<String> archive = ['voidTheCheck', 'returnedCheck'].obs;

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
        img: checkFrontImage.value!,
        frontImage: checkFrontImage.value,
        backImage: checkBackImage.value,
      );
      result.fold(
        (failure) {
          isLoading(false);

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
          generalData();
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
    isLoading(false);
  }

  // cash to person or cancel
  void cashedToPersonOrCancel({
    required bool toPerson,
    required String checkId,
    String? customerId,
    String? sellerId,
  }) async {
    isLoading(true);
    final result = await cashedToPersonCancelUsecase.call(
      isInComing: isInComing,
      toPerson: toPerson,
      checkId: checkId,
      customerId: customerId,
      sellerId: sellerId,
    );
    result.fold(
      (failure) {
        isLoading(false);

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
          generalData(),
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
      (failure) {
        isLoading(false);

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
          generalData(),
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
          generalData(),
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
  }

  // get all not cashed outgoing checks
  final Rxn<NotCashedModel> inComingChecksList = Rxn<NotCashedModel>(null);
  final Map<String, List<CheckModel>> inComingTasks = {};

  Future<void> getNotCashed() async {
    isLoading(true);
    final result = await getChecksUsecase.call(
      endPoint: isInComing
          ? EndPoints.inComingChecks
          : EndPoints.notCashedOutgoingChecks,
    );
    inComingChecksList.value = NotCashedModel.fromJson(result);
    inComingTasks.clear();
    for (var task in inComingChecksList.value!.inComingChecksList) {
      String dateKey = "${task.dueDate.year}-${task.dueDate.month}";
      if (inComingTasks.containsKey(dateKey)) {
        if (!inComingTasks[dateKey]!.any((a) => a.id == task.id)) {
          inComingTasks[dateKey]!.add(task);
        }
      } else {
        inComingTasks[dateKey] = [task];
      }
    }
    isLoading(false);
  }

  // get cashed to person checks
  final Rxn<CashedToPersonOutgoingModel> cashedToPerson =
      Rxn<CashedToPersonOutgoingModel>(null);
  Map<String, List<CheckModel>> cashedToPersonTasks = {};

  Future<void> getCashedToPerson() async {
    isLoading(true);
    final result = await getChecksUsecase.call(
      endPoint: isInComing
          ? EndPoints.cashedIncomingChecks
          : EndPoints.cashedOutgoingChecks,
    );

    cashedToPerson.value = CashedToPersonOutgoingModel.fromJson(result);
    cashedToPersonTasks.clear();
    for (var task in cashedToPerson.value!.cashedToPerson) {
      String dateKey = "${task.dueDate.year}-${task.dueDate.month}";
      if (cashedToPersonTasks.containsKey(dateKey)) {
        if (!cashedToPersonTasks[dateKey]!.any((a) => a.id == task.id)) {
          cashedToPersonTasks[dateKey]!.add(task);
        }
      } else {
        cashedToPersonTasks[dateKey] = [task];
      }
    }
    isLoading(false);
  }

  // get cashed to person checks
  final Rxn<ArchiveDataModel> archiveData = Rxn<ArchiveDataModel>(null);
  final Map<String, List<CheckModel>> archiveTasks = {};

  Future<void> getArchive() async {
    isLoading(true);
    final result = await getChecksUsecase.call(
      endPoint: isInComing
          ? EndPoints.archivedIncomingChecks
          : EndPoints.archivedOutgoingChecks,
    );
    archiveData.value = ArchiveDataModel.fromJson(result);
    archiveTasks.clear();
    for (var task in archiveData.value!.archiveData) {
      String dateKey = "${task.dueDate.year}-${task.dueDate.month}";
      if (archiveTasks.containsKey(dateKey)) {
        if (!archiveTasks[dateKey]!.any((a) => a.id == task.id)) {
          archiveTasks[dateKey]!.add(task);
        }
      } else {
        archiveTasks[dateKey] = [task];
      }
    }
    isLoading(false);
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

  Future<void> generalData() async {
    isLoading(true);
    final result =
        await generalOutgoingDataUsecase.call(isInComing: isInComing);
    isInComing
        ? generalIncoming.value = GeneralIncomingModel.fromJson(result)
        : generalOutgoing.value = GeneralOutgoingDataModel.fromJson(result);
    isLoading(false);
    update();
  }

  // get shown boxes
  final RxList<GetShownBoxesModel> shownBoxesList = <GetShownBoxesModel>[].obs;

  void getShowBoxes() async {
    final boxes = await getShownBoxUsecase.call(screen: currentTab.value);
    shownBoxesList.value = boxes;
  }

// filter assets by date
  // final assetsFilter = <String, List<Asset>>{}.obs;
  // void filterAssetsByDate() {
  //   final from = DateTime.tryParse(fromController.text);
  //   final to = DateTime.tryParse(toController.text);

  //   // رجع الداتا الأصلية قبل أي فلترة
  //   assetsFilter.assignAll(FinacialService().assetsTasks);

  //   final Map<String, List<Asset>> filtered = {};
  //   assetsFilter.forEach(
  //     (dateKey, tasks) {
  //       for (var task in tasks) {
  //         bool matches = true;
  //         // لو فيه "من"
  //         if (from != null) {
  //           matches = task.createdAt.isAtSameMomentAs(from) ||
  //               task.createdAt.isAfter(from);
  //         }
  //         // لو فيه "إلى"
  //         if (to != null) {
  //           matches = matches &&
  //               (task.createdAt.isAtSameMomentAs(to) ||
  //                   task.createdAt.isBefore(to));
  //         }
  //         if (matches) {
  //           filtered.putIfAbsent(dateKey, () => []);
  //           filtered[dateKey]!.add(task);
  //         }
  //       }
  //     },
  //   );
  //   assetsFilter.assignAll(filtered);
  //   update();
  //   Get.back();
  // }

  @override
  void onInit() {
    super.onInit();
    getGeneralChecksData();

    getAllCustomersAndSellers();
    getShowBoxes();

    // outgoing checks
    generalData();
    getCashedToPerson();
    getNotCashed();
    getArchive();

    // incoming checks
    generalData();
    getCashedToPerson();
    getNotCashed();
    getArchive();
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
