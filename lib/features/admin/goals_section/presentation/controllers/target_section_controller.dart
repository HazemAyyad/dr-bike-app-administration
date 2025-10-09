import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../routes/app_routes.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../../checks/data/models/check_model.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../../employee_section/domain/entities/employee_entity.dart';
import '../../../employee_section/domain/usecases/get_all_employee.dart';
import '../../../projects/data/models/project_details_model.dart';
import '../../../sales/data/models/product_model.dart';
import '../../../sales/domain/usecases/get_all_products_usecase.dart';
import '../../data/models/goals_details_model.dart' hide SellerModel;
import '../../data/models/goals_model.dart';
import '../../domain/usecases/add_goal_usecase.dart';
import '../../domain/usecases/get_goal_details_usecase.dart';
import '../../domain/usecases/get_goals_usecase.dart';
import 'goals_services.dart';

class TargetSectionController extends GetxController {
  final GetGoalsUsecase getGoalsUsecase;
  final GetAllEmployeeUsecase getAllEmployeeUsecase;
  final AllCustomersSellersUsecase allCustomersSellersUsecase;
  final GetShownBoxUsecase getShownBoxUsecase;
  final AddGoalUsecase addGoalUsecase;
  final GetGoalDetailsUsecase getGoalDetailsUsecase;
  final GetAllProductsUsecase getAllProductsUsecase;

  TargetSectionController({
    required this.getGoalsUsecase,
    required this.getAllEmployeeUsecase,
    required this.allCustomersSellersUsecase,
    required this.getShownBoxUsecase,
    required this.addGoalUsecase,
    required this.getGoalDetailsUsecase,
    required this.getAllProductsUsecase,
  });

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController toDateController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();

  final TextEditingController targetNameController = TextEditingController();
  final TextEditingController targetScopeController = TextEditingController();
  final TextEditingController formController = TextEditingController();

  final TextEditingController targetTypeController = TextEditingController();
  final TextEditingController customerAndSellerIdController =
      TextEditingController();
  final TextEditingController mainValueController = TextEditingController();
  final TextEditingController targetValueController = TextEditingController();
  final TextEditingController currentValueController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController employeeIdController = TextEditingController();
  final TextEditingController boxIdController = TextEditingController();
  final TextEditingController productIdController = TextEditingController();
  final TextEditingController mainCategoriesIdController =
      TextEditingController();
  final TextEditingController subCategoriesIdController =
      TextEditingController();

  final currentTab = 0.obs;
  final tabs = ['generalTarget', 'specialTarget', 'archive'].obs;

  final isLoading = false.obs;

  final isAddLoading = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
    update();
  }

  final RxBool isDelete = true.obs;

  List<String> targetTypes = ['private', 'public'];

  List<String> targetTypeList = [
    'total_sell_values',
    'net_profit',
    'sell_pieces',
    'purchase_pieces',
    'total_purchase_values',
    'finish_tasks',
    'pay_person',
    'deposit_to_box'
  ];
  List<String> options1 = [
    'main_categories',
    'sub_categories',
    'products',
  ];

  List<String> options3 = [
    'main_categories',
    'sub_categories',
    'products',
    'people',
  ];

  final List<ProjectProductModel> productsIds = [];

  final RxBool targetTimeController = false.obs;

  final Rx<DateTime> selectedTime = DateTime.now().obs;

  void getAllGoal() async {
    GoalsServices().globalGoalsList.isEmpty
        ? isLoading(true)
        : isLoading(false);
    update();
    final response = await getGoalsUsecase.call();
    GoalsServices().globalGoalsList.assignAll(
          response.where(
            (goal) =>
                goal.scope == 'public' &&
                double.parse(goal.achievementPercentage) < 100 &&
                !goal.isCanceled,
          ),
        );
    globalGoalsFilterList.assignAll(GoalsServices().globalGoalsList);
    isLoading(false);
    update();
    GoalsServices().privateGoalsList.assignAll(
          response.where(
            (goal) =>
                !goal.isCanceled &&
                double.parse(goal.achievementPercentage) < 100 &&
                goal.scope == 'private',
          ),
        );
    privateGoalsFilterList.assignAll(GoalsServices().privateGoalsList);

    GoalsServices().archiveGoalsList.assignAll(response.where((goal) =>
        goal.isCanceled || double.parse(goal.achievementPercentage) >= 100));
    archiveGoalsFilterList.assignAll(GoalsServices().archiveGoalsList);

    isLoading(false);
    update();
  }

  final RxList<EmployeeEntity> employeeList = <EmployeeEntity>[].obs;
  void getEmployee() async {
    final result = await getAllEmployeeUsecase.call();
    employeeList.assignAll(result);
    isLoading(false);
  }

  final RxBool isCustomer = true.obs;
  final RxList<SellerModel> allCustomersList = <SellerModel>[].obs;
  final RxList<SellerModel> allSellersList = <SellerModel>[].obs;

  void getAllCustomersAndSellers() async {
    final resultCustomers = await allCustomersSellersUsecase.call(
        endPoint: EndPoints.all_customers);
    allCustomersList.assignAll(resultCustomers);
    final resultSellers =
        await allCustomersSellersUsecase.call(endPoint: EndPoints.all_sellers);
    allSellersList.assignAll(resultSellers);
    isLoading(false);
  }

  // get shown boxes
  final RxList<shownBoxesModel> shownBoxes = <shownBoxesModel>[].obs;
  void getShowBoxes() async {
    final boxes = await getShownBoxUsecase.call(screen: currentTab.value);
    shownBoxes.value = boxes;
    isLoading(false);
  }

  // get goals details
  GoalDetailsModel? goalDetailsList;
  void getGoalDetails({
    required String goalId,
    bool? isCancel,
    bool? isTransfer,
    bool? isDelete,
  }) async {
    isCancel == true || isTransfer == true || isDelete == true
        ? isLoading(true)
        : isAddLoading(true);
    update();
    final goalDetails = await getGoalDetailsUsecase.call(
      goalId: goalId,
      isCancel: isCancel,
      isTransfer: isTransfer,
      isDelete: isDelete,
    );
    if (isCancel == null && isTransfer == null && isDelete == null) {
      goalDetailsList = GoalDetailsModel.fromJson(goalDetails['goal']);
    } else {
      Get.back();
      getAllGoal();
      Get.snackbar(
        'success'.tr,
        goalDetails['message'],
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
    isLoading(false);
    isAddLoading(false);
    update();
  }

  final RxBool isEdit = false.obs;
  // Edit Goal
  void editGoal() {
    isEdit(true);
    update();
    Get.toNamed(AppRoutes.ADDNEWTARGETSCREEN);
    isAddLoading(true);
    update();
    targetNameController.text = goalDetailsList!.name;
    targetScopeController.text = goalDetailsList!.type;
    targetTypeController.text = goalDetailsList!.form;
    targetValueController.text = goalDetailsList!.targetedValue;
    currentValueController.text = goalDetailsList!.currentValue;
    notesController.text = goalDetailsList!.notes;
    formController.text = goalDetailsList!.scope;
    if (goalDetailsList!.employee != null) {
      employeeIdController.text = goalDetailsList!.employee!.id.toString();
    }
    if (goalDetailsList!.customer != null) {
      isCustomer.value = false;
      customerAndSellerIdController.text =
          goalDetailsList!.customer!.id.toString();
    }
    if (goalDetailsList!.seller != null) {
      isCustomer.value = true;
      customerAndSellerIdController.text =
          goalDetailsList!.seller!.id.toString();
    }

    if (goalDetailsList!.box != null) {
      boxIdController.text = goalDetailsList!.box!.id.toString();
    }
    isAddLoading(false);
    update();
  }

  // reset Data
  void reset() {
    isEdit(false);
    update();
    Get.toNamed(AppRoutes.ADDNEWTARGETSCREEN);
    targetNameController.clear();
    targetScopeController.clear();
    targetTypeController.clear();
    targetValueController.clear();
    currentValueController.clear();
    notesController.clear();
    formController.clear();
    employeeIdController.clear();
    customerAndSellerIdController.clear();
    boxIdController.clear();
  }

  // add Goal
  void addGoal(BuildContext context) async {
    isAddLoading(true);
    final result = await addGoalUsecase.call(
      goalId: isEdit.value ? goalDetailsList!.id.toString() : '',
      name: targetNameController.text,
      type: targetTypeController.text,
      form: formController.text,
      targetedValue: targetValueController.text,
      notes: notesController.text,
      scope: targetScopeController.text,
      currentValue: currentValueController.text,
      employeeId: employeeIdController.text,
      sellerId: isCustomer.value ? customerAndSellerIdController.text : '',
      customerId: !isCustomer.value ? customerAndSellerIdController.text : '',
      boxId: boxIdController.text,
      mainCategoriesId: mainCategoriesIdController.text,
      subCategoriesId: subCategoriesIdController.text,
      dueDate: selectedTime.value,
      productsIds: productsIds,
    );

    result.fold(
      (failure) {
        String errorMessages = '';
        bool data = false;
        final errors = failure.data?['errors'] as Map<String, dynamic>?;
        if (errors != null) {
          errors.forEach((key, value) {
            if (key.startsWith('permissions')) {
              if (!data) {
                errorMessages += "Permissions: ${value.first}\n";
                data = true;
              }
            } else {
              for (var msg in value) {
                errorMessages += "- $key: $msg\n";
              }
            }
          });
        } else {
          errorMessages = failure.data?['message'] ?? failure.errMessage;
        }
        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: errorMessages,
        );
        isAddLoading(false);
      },
      (success) {
        targetNameController.clear();
        targetTypeController.clear();
        formController.clear();
        targetValueController.clear();
        notesController.clear();
        targetScopeController.clear();
        currentValueController.clear();
        employeeIdController.clear();
        customerAndSellerIdController.clear();
        boxIdController.clear();
        mainCategoriesIdController.clear();
        subCategoriesIdController.clear();
        selectedTime.value = DateTime.now();
        productsIds.clear();

        getAllGoal();
        if (goalDetailsList != null) {
          getGoalDetails(goalId: goalDetailsList!.id.toString());
        }
        Future.delayed(
          const Duration(milliseconds: 800),
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
    isAddLoading(false);
  }

  // get all products
  final List<ProductModel> products = [];
  void getAllProducts() async {
    final result = await getAllProductsUsecase.call();
    products.assignAll(result);
  }

  // get all products
  final List<ProductModel> categories = [];
  void getAllCategories() async {
    final result =
        await getAllProductsUsecase.call(endPoint: EndPoints.categories);
    categories.assignAll(result);
  } // get all products

  final List<ProductModel> subCategories = [];
  void getAllSubCategories() async {
    final result =
        await getAllProductsUsecase.call(endPoint: EndPoints.sub_categories);
    subCategories.assignAll(result);
  }

  final List<GoalsModel> globalGoalsFilterList = <GoalsModel>[].obs;
  final List<GoalsModel> privateGoalsFilterList = <GoalsModel>[].obs;
  final List<GoalsModel> archiveGoalsFilterList = <GoalsModel>[].obs;

  void filterGoals() {
    final fromDate = fromDateController.text.trim();
    final toDate = toDateController.text.trim();

    List<GoalsModel> applyFilter(List<GoalsModel> sourceList) {
      return sourceList.where((item) {
        // ✅ فلترة بالتاريخ
        final itemDate = item.createdAt;
        final from = (fromDate.isNotEmpty) ? DateTime.tryParse(fromDate) : null;
        final to = (toDate.isNotEmpty) ? DateTime.tryParse(toDate) : null;
        bool matchesDate = true;
        if (from != null && itemDate.isBefore(from)) matchesDate = false;
        if (to != null && itemDate.isAfter(to)) matchesDate = false;
        return matchesDate;
      }).toList();
    }

    globalGoalsFilterList
      ..clear()
      ..addAll(applyFilter(GoalsServices().globalGoalsList));
    privateGoalsFilterList
      ..clear()
      ..addAll(applyFilter(GoalsServices().privateGoalsList));
    archiveGoalsFilterList
      ..clear()
      ..addAll(applyFilter(GoalsServices().archiveGoalsList));
    Get.back();
    update();
  }

  @override
  void onInit() {
    super.onInit();
    getAllGoal();
    getEmployee();
    getShowBoxes();
    getAllProducts();
    getAllCategories();
    getAllSubCategories();
    getAllCustomersAndSellers();
    globalGoalsFilterList.assignAll(GoalsServices().globalGoalsList);
    privateGoalsFilterList.assignAll(GoalsServices().privateGoalsList);
    archiveGoalsFilterList.assignAll(GoalsServices().archiveGoalsList);
  }

  @override
  void onClose() {
    super.onClose();
    fromDateController.dispose();
    toDateController.dispose();
    targetNameController.dispose();
    targetValueController.dispose();
    targetTypeController.dispose();
    customerAndSellerIdController.dispose();
    currentValueController.dispose();
    mainValueController.dispose();
    notesController.dispose();
    targetScopeController.dispose();
    employeeIdController.dispose();
    boxIdController.dispose();
    formController.dispose();
  }
}
