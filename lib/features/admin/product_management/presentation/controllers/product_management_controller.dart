import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../sales/data/models/product_model.dart';
import '../../../sales/domain/usecases/get_all_products_usecase.dart';
import '../../data/models/product_development_model.dart';
import '../../domain/usecases/create_product_development_usecase.dart';
import '../../domain/usecases/get_product_developments_usecase.dart';
import 'product_management_serves.dart';

class ProductManagementController extends GetxController {
  final GetProductDevelopmentsUsecase getProductDevelopmentsUsecase;
  final GetAllProductsUsecase getAllProductsUsecase;
  final CreateProductDevelopmentUsecase createProductDevelopmentUsecase;

  ProductManagementController({
    required this.getProductDevelopmentsUsecase,
    required this.getAllProductsUsecase,
    required this.createProductDevelopmentUsecase,
  });

  final formKey = GlobalKey<FormState>();

  final TextEditingController searchController = TextEditingController();

  final TextEditingController productIdController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  RxInt currentTab = 0.obs;

  final tabs = [
    'products',
    'archive',
  ].obs;

  void changeTab(int index) {
    currentTab.value = index;
    update();
  }

  final RxInt selectedStep = 1.obs;
  final RxInt selectedStep2 = 0.obs;

  final List<Map<int, String>> timeLineSteps = [
    {1: 'purchase_anywhere'},
    {2: 'purchase_second_hand'},
    {3: 'purchase_first_hand'},
  ];

  final List<Map<int, String>> timeLineSteps2 = [
    {4: 'local_supplier'},
    {5: 'import'},
    {6: 'wholesale_purchase'},
    {7: 'our_factory'},
  ];

  /// ✅ المجموع الكلي للخطوات
  int get totalSteps => timeLineSteps.length + timeLineSteps2.length;

  /// ✅ الخطوة الحالية عالميًا (تجمع الأولى والتانية)
  int get currentGlobalStep {
    if (selectedStep2.value == 0) {
      return selectedStep.value; // لسه في الأولى
    } else {
      return timeLineSteps.length + selectedStep2.value; // دخل التانية
    }
  }

  /// ✅ التالي
  void nextStep() {
    if (selectedStep2.value == 0) {
      if (selectedStep.value < timeLineSteps.length) {
        if (selectedStep.value == 1) {
          return createProduct();
        }
        createProduct();
        selectedStep.value += 1;
      } else {
        createProduct();
        selectedStep.value = 4;
        selectedStep2.value = 1;
      }
    } else {
      if (selectedStep2.value < timeLineSteps2.length) {
        createProduct();

        selectedStep2.value += 1;
      } else {
        createProduct();
        selectedStep.value = 1;
        selectedStep2.value = 0;
      }
    }
    update();
  }

  /// ✅ السابق
  void prevStep() {
    if (selectedStep2.value > 0) {
      if (selectedStep2.value == 1) {
        selectedStep2.value = 0;
        selectedStep.value = timeLineSteps.length; // آخر خطوة في الأولى
      } else {
        selectedStep2.value -= 1;
      }
    } else {
      if (selectedStep.value > 1) {
        selectedStep.value -= 1;
      }
    }
    update();
  }

  void changeSelected(int step, {bool isSecond = false}) {
    if (isSecond) {
      // ما يقدرش يروح للتانية إلا بعد ما يخلص الأولى
      if (selectedStep.value == timeLineSteps.length) {
        selectedStep2.value = step;
      }
    } else {
      selectedStep.value = step;
      // لو المستخدم ضغط آخر خطوة في الأولى، خلي التانية تبدأ من 0 لحد ما يضغط Next
      if (step < timeLineSteps.length) {
        selectedStep2.value = 0;
      }
    }
    update();
  }

  final RxBool isLoading = false.obs;

  // Product Management
  void getProductManagement() async {
    ProductManagementServes().productManagement.isEmpty
        ? isLoading(true)
        : null;
    final result = await getProductDevelopmentsUsecase.call();
    ProductManagementServes().productManagement.assignAll(result);
    searchProductManagement.assignAll(ProductManagementServes()
        .productManagement
        .where((element) => element.currentStep != '7'));
    searcharchiveProductManagement.assignAll(ProductManagementServes()
        .productManagement
        .where((element) => element.currentStep == '7'));
    isLoading(false);
    update();
  }

  List<ProductDevelopmentModel> searchProductManagement = [];
  List<ProductDevelopmentModel> searcharchiveProductManagement = [];

  void searchBar(String value) {
    if (value.isNotEmpty) {
      searchProductManagement.assignAll(ProductManagementServes()
          .productManagement
          .where((element) => element.currentStep != '7')
          .where(
            (element) =>
                element.productName.toLowerCase().contains(value.toLowerCase()),
          )
          .toList());
      searcharchiveProductManagement.assignAll(ProductManagementServes()
          .productManagement
          .where((element) => element.currentStep == '7')
          .where(
            (element) =>
                element.productName.toLowerCase().contains(value.toLowerCase()),
          )
          .toList());
    } else {
      searchProductManagement.assignAll(ProductManagementServes()
          .productManagement
          .where((element) => element.currentStep != '7')
          .toList());
      searcharchiveProductManagement.assignAll(ProductManagementServes()
          .productManagement
          .where((element) => element.currentStep == '7')
          .toList());
    }
    update();
  }

  final List<ProductModel> products = [];
  void getAllProducts() async {
    final result = await getAllProductsUsecase.call();
    products.assignAll(result);
  }

  // create product
  void createProduct() async {
    isLoading(true);
    final result = await createProductDevelopmentUsecase.call(
      productId: productIdController.text,
      description: descriptionController.text,
      step: isEdit.value ? (int.parse(currentStep) + 1).toString() : '',
    );

    result.fold(
      (failure) {
        final errors = failure.data != null ? failure.data['errors'] : null;

        if (errors is Map<String, dynamic>) {
          final messages = errors.values
              .expand((list) => list)
              .cast<String>()
              .join('')
              .replaceAll('.', '- \n');

          Helpers.showCustomDialogError(
            context: Get.context!,
            title: failure.errMessage,
            message: messages,
          );
        } else {
          Helpers.showCustomDialogError(
            context: Get.context!,
            title: 'error'.tr,
            message: failure.data['message'],
          );
        }
      },
      (success) {
        // productIdController.clear();
        // descriptionController.clear();
        // currentStep = '';
        getProductManagement();
        // isEdit.value
        // ?
        editProduct(isEditing: true, id: productIdController.text);
        Get.back();
        Future.delayed(
          const Duration(milliseconds: 2000),
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

  final RxBool isEdit = false.obs;
  String productName = '';
  String productImage = '';
  String currentStep = '';
  void editProduct({required String id, required bool isEditing}) {
    if (isEditing) {
      isEdit(true);
      productIdController.text = id;
      productName = ProductManagementServes()
          .productManagement
          .where((f) => f.id.toString() == id)
          .first
          .productName
          .toString();
      productImage = ProductManagementServes()
          .productManagement
          .where((f) => f.id.toString() == id)
          .first
          .productImage
          .toString();
      if (int.parse(
            ProductManagementServes()
                .productManagement
                .where((f) => f.id.toString() == id)
                .first
                .currentStep,
          ) <
          3) {
        selectedStep.value = int.parse(
              ProductManagementServes()
                  .productManagement
                  .where((f) => f.id.toString() == id)
                  .first
                  .currentStep,
            ) +
            1;
      } else {
        (selectedStep2.value = int.parse(
              ProductManagementServes()
                  .productManagement
                  .where((f) => f.id.toString() == id)
                  .first
                  .currentStep,
            ) -
            2);
      }
      selectedStep.value = int.parse(
            ProductManagementServes()
                .productManagement
                .where((f) => f.id.toString() == id)
                .first
                .currentStep,
          ) +
          1;
      currentStep = ProductManagementServes()
          .productManagement
          .where((f) => f.id.toString() == id)
          .first
          .currentStep
          .toString();
    } else {
      isEdit(false);
      productIdController.clear();
      selectedStep.value = 1;
      selectedStep2.value = 0;
      productName = '';
      productImage = '';
      currentStep = '';
    }
    update();
  }

  @override
  void onInit() {
    getProductManagement();
    getAllProducts();
    searchProductManagement.assignAll(ProductManagementServes()
        .productManagement
        .where((element) => element.currentStep != '7'));
    searcharchiveProductManagement.assignAll(ProductManagementServes()
        .productManagement
        .where((element) => element.currentStep == '7'));
    super.onInit();
  }
}
