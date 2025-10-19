import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../checks/data/models/check_model.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../../sales/data/models/product_model.dart';
import '../../../sales/domain/usecases/get_all_products_usecase.dart';
import '../../data/models/project_details_model.dart';
import '../../data/models/project_expenses_model.dart';
import '../../data/models/project_model.dart';
import '../../data/models/project_sale_model.dart';
import '../../domain/usecases/add_product_to_project_usecase.dart';
import '../../domain/usecases/create_project_usecase.dart';
import '../../domain/usecases/get_project_details_usecase.dart';
import '../../domain/usecases/get_project_expenses_sales_usecase.dart';
import '../../domain/usecases/get_usecase.dart';
import 'project_service.dart';

class ProjectController extends GetxController {
  final GetProjectsUsecase getProjectsUsecase;
  final GetAllProductsUsecase getAllProductsUsecase;
  final AllCustomersSellersUsecase allCustomersSellersUsecase;
  final CreateProjectUsecase createProjectUsecase;
  final GetProjectDetailsUsecase getProjectDetailsUsecase;
  final AddProductToProjectUsecase addProductToProjectUsecase;
  final GetProjectExpensesSalesUsecase getProjectExpensesSalesUsecase;

  ProjectController({
    required this.getProjectsUsecase,
    required this.getAllProductsUsecase,
    required this.allCustomersSellersUsecase,
    required this.createProjectUsecase,
    required this.getProjectDetailsUsecase,
    required this.addProductToProjectUsecase,
    required this.getProjectExpensesSalesUsecase,
  });

  final formKey = GlobalKey<FormState>();

  final TextEditingController employeeNameController = TextEditingController();

  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController projectCostController = TextEditingController();
  final TextEditingController partnerShareController = TextEditingController();
  final TextEditingController partnerPercentageController =
      TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController paymentMethodController = TextEditingController();
  final TextEditingController paymentNoteController = TextEditingController();
  final TextEditingController itemIdController = TextEditingController();
  final TextEditingController expensesController = TextEditingController();

  final List<ProjectProductModel> productsIds = [];

  List<File> projectImages = [];

  List<File> paperImages = [];

  final RxBool selectedCustomersSellers = false.obs;

  final RxString partnerId = ''.obs;

  final currentTab = 0.obs;

  final tabs = ['projectList', 'completedProjects'].obs;

  void changeTab(int index) {
    currentTab.value = index;
  }

  List<String> paymentMethodList = ['cash'.tr, 'visa'.tr];

  List<String> projectPartnersList = [
    'noPartners'.tr,
    'محمد احمد',
    'احمد محمد'
  ];
  final List<String> noPartnerValues = ['بدون', 'No Partners'];

  // متغير لاظهار الخطوات
  final RxInt selectedStep = 1.obs;

  final List<Map<int, String>> timeLineSteps = [
    {1: 'partnerData'},
    {2: 'paymentMethod'},
  ];

  void changeSelected(int index) => selectedStep.value = index;

  void nextStep() {
    if (selectedStep.value < timeLineSteps.length) {
      if (formKey.currentState!.validate()) selectedStep.value += 1;
    } else if (isEdit.value) {
      addNewProject(
        Get.context!,
        projectId: ProjectService().projectDetails.value!.id.toString(),
      );
    } else {
      addNewProject(Get.context!);
    }
  }

  void prevStep() => selectedStep.value -= 1;

  final RxBool isLoading = false.obs;

  // get all products
  final List<ProductModel> products = [];
  void getAllProducts() async {
    final result = await getAllProductsUsecase.call();
    products.assignAll(result);
  }

  // get projects
  void getProjects({bool loding = false}) async {
    ProjectService().ongoingProjects.isEmpty
        ? isLoading(true)
        : isLoading(false);
    loding ? isLoading(true) : null;
    final ongoingProjectsResponse =
        await getProjectsUsecase.call(isCompleted: false);
    final ongoingProjectsJson =
        ongoingProjectsResponse['ongoing projects'] as List;
    final ongoingProjectsList = ongoingProjectsJson
        .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
    ProjectService().ongoingProjects.assignAll(ongoingProjectsList);
    ongoingProjectsSearch.assignAll(ProjectService().ongoingProjects);

    final completedProjectsResponse =
        await getProjectsUsecase.call(isCompleted: true);
    final completedProjectsJson =
        completedProjectsResponse['completed projects'] as List;
    final completedProjectsList = completedProjectsJson
        .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
    ProjectService().completedProjects.assignAll(completedProjectsList);
    completedProjectsSearch.assignAll(ProjectService().completedProjects);
    isLoading(false);
  }

  // get all customers and sellers
  final RxList<SellerModel> allCustomersList = <SellerModel>[].obs;
  final RxList<SellerModel> allSellersList = <SellerModel>[].obs;
  void getAllCustomersAndSellers() async {
    final resultCustomers = await allCustomersSellersUsecase.call(
        endPoint: EndPoints.all_customers);
    allCustomersList.assignAll(resultCustomers);
    final resultSellers =
        await allCustomersSellersUsecase.call(endPoint: EndPoints.all_sellers);
    allSellersList.assignAll(resultSellers);
  }

  final RxBool isLoadingProjectDetails = false.obs;
  // get project details
  void getProjectDetails(int projectId) async {
    if (ProjectService().projectDetails.value != null) {
      ProjectService().projectDetails.value!.id == projectId
          ? isLoadingProjectDetails(false)
          : isLoadingProjectDetails(true);
    } else {
      isLoadingProjectDetails(true);
    }
    final result = await getProjectDetailsUsecase.call(projectId: projectId);
    ProjectService().projectDetails.value = result;
    isLoadingProjectDetails(false);
    update();
  }

  // get project expenses
  Future<void> getProjectExpenses({
    bool isSales = false,
    String expenses = '',
    String notes = '',
  }) async {
    isLoading(true);

    final result = await getProjectExpensesSalesUsecase.call(
      isSales: isSales,
      projectId: ProjectService().projectDetails.value!.id.toString(),
      expenses: expenses,
      notes: notes,
    );
    if ((expenses.isEmpty || notes.isEmpty) && !isSales) {
      ProjectService().projectExpenses.value =
          ProjectExpensesModel.fromJson(result);
    } else if (isSales) {
      ProjectService().projectSales.value = ProjectSaleModel.fromJson(result);
    } else {
      Get.snackbar(
        'success'.tr,
        result['message'],
        backgroundColor: AppColors.secondaryColor,
        colorText: AppColors.whiteColor,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    expensesController.clear();
    notesController.clear();
    isLoading(false);
    update();
  }

  // add new project
  void addNewProject(BuildContext context, {String projectId = ''}) async {
    isLoading(true);
    final result = await createProjectUsecase.call(
      projectId: projectId,
      name: projectNameController.text,
      projectCost: projectCostController.text,
      productId: productsIds,
      customerId: selectedCustomersSellers.value ? null : partnerId.value,
      sellerId: selectedCustomersSellers.value ? partnerId.value : null,
      projectImages: projectImages,
      partnerShare: partnerShareController.text,
      partnerPercentage: partnerPercentageController.text,
      paperImages: paperImages,
      notes: notesController.text,
      paymentMethod: paymentMethodController.text,
      paymentNote: paymentNoteController.text,
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
        getProjects(loding: true);
        if (projectId.isNotEmpty) {
          getProjectDetails(ProjectService().projectDetails.value!.id);
        }
        projectNameController.clear();
        projectCostController.clear();
        itemIdController.clear();
        productsIds.clear();
        projectImages.clear();
        partnerId.value = '';
        partnerShareController.clear();
        partnerPercentageController.clear();
        paperImages.clear();
        notesController.clear();
        paymentMethodController.clear();
        paymentNoteController.clear();
        selectedStep.value = 1;
        Helpers.showCustomDialogSuccess(
          context: context,
          title: 'success'.tr,
          message: success,
        );
        Future.delayed(
          const Duration(milliseconds: 1500),
          () {
            Get.back();
            Get.back();
            getProjects(loding: true);
          },
        );
      },
    );
    isLoading(false);
  }

  // add product to project Or complete
  Future<void> addProductToProjectOrComplete({
    required BuildContext context,
    required int projectId,
  }) async {
    isLoading(true);
    final result = await addProductToProjectUsecase.call(
      projectId: projectId,
      productId: itemIdController.text.isNotEmpty ? itemIdController.text : '',
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
        itemIdController.clear();
        getProjects(loding: true);
        getProjectDetails(projectId);
        Get.back();
        Future.delayed(
          const Duration(milliseconds: 500),
          () {
            // Get.back();
            Get.snackbar(
              'success'.tr,
              success,
              colorText: Colors.white,
              backgroundColor: Colors.green,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          },
        );
      },
    );
    isLoading(false);
  }

  final List<ProjectModel> completedProjectsSearch = [];
  final List<ProjectModel> ongoingProjectsSearch = [];

  void searchProjects() {
    isLoading(true);

    if (employeeNameController.text.isEmpty) {
      completedProjectsSearch.assignAll(ProjectService().completedProjects);
      ongoingProjectsSearch.assignAll(ProjectService().ongoingProjects);
      isLoading(false);
      Get.back();
      update();

      return;
    }
    ongoingProjectsSearch
        .assignAll(ProjectService().ongoingProjects.where((element) {
      return element.name.toLowerCase().contains(employeeNameController.text);
    }));
    completedProjectsSearch
        .assignAll(ProjectService().completedProjects.where((element) {
      return element.name.toLowerCase().contains(employeeNameController.text);
    }));
    isLoading(false);

    Get.back();
    update();
  }

  final RxBool isEdit = false.obs;
  String partnershipName = '';

  void editProject() {
    isLoading(true);
    isEdit.value = true;
    Get.toNamed(AppRoutes.CREATEPROJECTSCREEN);
    projectNameController.text = ProjectService().projectDetails.value!.name;
    projectCostController.text =
        ProjectService().projectDetails.value!.projectCost;
    productsIds.assignAll(ProjectService().projectDetails.value!.products);
    if (ProjectService().projectDetails.value!.partnership != null) {
      partnershipName = ProjectService()
              .projectDetails
              .value!
              .partnership!
              .sellerName!
              .isNotEmpty
          ? ProjectService().projectDetails.value!.partnership!.sellerName!
          : ProjectService().projectDetails.value!.partnership!.customerName ??
              '';
      partnerId.value = ProjectService()
              .projectDetails
              .value!
              .partnership!
              .sellerName!
              .isNotEmpty
          ? ProjectService().projectDetails.value!.partnership!.sellerId!
          : ProjectService().projectDetails.value!.partnership!.customerId ??
              '';
      selectedCustomersSellers.value = ProjectService()
          .projectDetails
          .value!
          .partnership!
          .sellerName!
          .isNotEmpty;
      partnerShareController.text =
          ProjectService().projectDetails.value!.partnership!.share;
      partnerPercentageController.text = ProjectService()
          .projectDetails
          .value!
          .partnership!
          .partnershipPercentage;
    }
    notesController.text = ProjectService().projectDetails.value!.notes;
    paymentMethodController.text =
        ProjectService().projectDetails.value!.paymentMethod;
    paymentNoteController.text =
        ProjectService().projectDetails.value!.paymentNotes;
    projectImages.assignAll(
      ProjectService()
          .projectDetails
          .value!
          .images
          .map((e) => File(e))
          .toList(),
    );
    paperImages.assignAll(
      ProjectService()
          .projectDetails
          .value!
          .partnershipPapers
          .map((e) => File(e))
          .toList(),
    );
    isLoading(false);
  }

  void clear() {
    isEdit.value = false;
    projectNameController.clear();
    projectCostController.clear();
    productsIds.clear();
    partnershipName = '';
    selectedCustomersSellers.value = false;
    partnerShareController.clear();
    partnerPercentageController.clear();
    notesController.clear();
    paymentMethodController.clear();
    paymentNoteController.clear();
    projectImages.clear();
    paperImages.clear();
    partnerId.value = '';
    selectedStep.value = 1;
    Get.toNamed(AppRoutes.CREATEPROJECTSCREEN);
  }

  @override
  void onInit() {
    super.onInit();
    getProjects();
    getAllProducts();
    getAllCustomersAndSellers();
    completedProjectsSearch.assignAll(ProjectService().completedProjects);
    ongoingProjectsSearch.assignAll(ProjectService().ongoingProjects);
  }

  @override
  void onClose() {
    projectNameController.dispose();
    projectCostController.dispose();
    partnerShareController.dispose();
    partnerPercentageController.dispose();
    notesController.dispose();
    paymentMethodController.dispose();
    paymentNoteController.dispose();
    itemIdController.dispose();
    employeeNameController.dispose();
    super.onClose();
  }
}
