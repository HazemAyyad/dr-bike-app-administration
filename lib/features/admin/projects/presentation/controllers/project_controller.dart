import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../checks/data/models/check_model.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../../sales/data/models/product_model.dart';
import '../../../sales/domain/usecases/get_all_products_usecase.dart';
import '../../data/models/project_model.dart';
import '../../domain/usecases/create_project_usecase.dart';
import '../../domain/usecases/get_project_details_usecase.dart';
import '../../domain/usecases/get_usecase.dart';
import 'project_service.dart';

class ProjectController extends GetxController {
  final GetProjectsUsecase getProjectsUsecase;
  final GetAllProductsUsecase getAllProductsUsecase;
  final AllCustomersSellersUsecase allCustomersSellersUsecase;
  final CreateProjectUsecase createProjectUsecase;
  final GetProjectDetailsUsecase getProjectDetailsUsecase;

  ProjectController({
    required this.getProjectsUsecase,
    required this.getAllProductsUsecase,
    required this.allCustomersSellersUsecase,
    required this.createProjectUsecase,
    required this.getProjectDetailsUsecase,
  });

  final formKey = GlobalKey<FormState>();

  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController projectCostController = TextEditingController();
  final TextEditingController itemIdController = TextEditingController();
  final TextEditingController partnerShareController = TextEditingController();
  final TextEditingController partnerPercentageController =
      TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController paymentMethodController = TextEditingController();
  final TextEditingController paymentNoteController = TextEditingController();

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
    } else {
      addNewProject(Get.context!);
      // selectedStep.value = 1;
    }
  }

  void prevStep() => selectedStep.value -= 1;

  // final Rx<File?> selectedFile = Rx<File?>(null);

  final RxBool isLoading = false.obs;

  // get all products
  final List<ProductModel> products = [];
  void getAllProducts() async {
    final result = await getAllProductsUsecase.call();
    products.assignAll(result);
  }

  // get projects
  void getProjects() async {
    ProjectService().ongoingProjects.isEmpty ? isLoading(true) : null;
    final ongoingProjectsResponse =
        await getProjectsUsecase.call(isCompleted: false);
    final ongoingProjectsJson =
        ongoingProjectsResponse['ongoing projects'] as List;
    final ongoingProjectsList = ongoingProjectsJson
        .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
    ProjectService().ongoingProjects.assignAll(ongoingProjectsList);

    final completedProjectsResponse =
        await getProjectsUsecase.call(isCompleted: true);
    final completedProjectsJson =
        completedProjectsResponse['completed projects'] as List;
    final completedProjectsList = completedProjectsJson
        .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
    ProjectService().completedProjects.assignAll(completedProjectsList);
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

  // add new project
  void addNewProject(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      isLoading(true);
      final result = await createProjectUsecase.call(
        name: projectNameController.text,
        projectCost: projectCostController.text,
        productId: itemIdController.text,
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
          getProjects();
          projectNameController.clear();
          projectCostController.clear();
          itemIdController.clear();
          projectImages.clear();
          partnerId.value = '';
          partnerShareController.clear();
          partnerPercentageController.clear();
          paperImages.clear();
          notesController.clear();
          paymentMethodController.clear();
          paymentNoteController.clear();
          selectedStep.value = 1;
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
      isLoading(false);
    }
  }

  @override
  void onInit() {
    super.onInit();
    getProjects();
    getAllProducts();
    getAllCustomersAndSellers();
  }

  @override
  void onClose() {
    fromDateController.dispose();
    toDateController.dispose();
    projectNameController.dispose();
    super.onClose();
  }
}
