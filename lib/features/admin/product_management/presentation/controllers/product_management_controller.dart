import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../sales/data/models/product_model.dart';
import '../../../sales/domain/usecases/get_all_products_usecase.dart';
import '../../data/models/product_development_model.dart';
import '../../domain/usecases/create_product_development_usecase.dart';
import '../../domain/usecases/delete_product_development_usecase.dart';
import '../../domain/usecases/get_product_developments_usecase.dart';
import 'product_management_serves.dart';

class ProductManagementController extends GetxController {
  final GetProductDevelopmentsUsecase getProductDevelopmentsUsecase;
  final GetAllProductsUsecase getAllProductsUsecase;
  final CreateProductDevelopmentUsecase createProductDevelopmentUsecase;
  final DeleteProductDevelopmentUsecase deleteProductDevelopmentUsecase;

  ProductManagementController({
    required this.getProductDevelopmentsUsecase,
    required this.getAllProductsUsecase,
    required this.createProductDevelopmentUsecase,
    required this.deleteProductDevelopmentUsecase,
  });

  final formKey = GlobalKey<FormState>();

  final TextEditingController searchController = TextEditingController();

  final TextEditingController productIdController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  RxInt currentTab = 0.obs;

  final tabs = [
    'products',
    'productInDevelopment',
    'archive',
  ].obs;

  void changeTab(int index) {
    currentTab.value = index;
    update();
  }

  /// ✅ القيم المراقبة
  final RxInt selectedStep = 1.obs;
  final RxInt selectedStep2 = 0.obs;

  /// ✅ خطوات المرحلة الأولى
  final List<Map<int, String>> timeLineSteps = [
    {1: 'purchase_anywhere'},
    {2: 'purchase_second_hand'},
    {3: 'purchase_first_hand'},
  ];

  /// ✅ خطوات المرحلة الثانية
  final List<Map<int, String>> timeLineSteps2 = [
    {4: 'local_supplier'},
    {5: 'import'},
    {6: 'wholesale_purchase'},
    {7: 'our_factory'},
  ];

  /// ✅ إجمالي الخطوات
  int get totalSteps => timeLineSteps.length + timeLineSteps2.length;

  /// ✅ الخطوة الحالية عالميًا
  int get currentGlobalStep {
    if (selectedStep2.value == 0) {
      return selectedStep.value; // لسه في المرحلة الأولى
    } else {
      return timeLineSteps.length + selectedStep2.value; // دخل المرحلة الثانية
    }
  }

  /// ✅ الخطوة التالية
  void nextStep() {
    if (selectedStep2.value == 0) {
      // لسه في المرحلة الأولى
      if (selectedStep.value < timeLineSteps.length) {
        createProduct();
        selectedStep.value++;
      } else {
        // خلص المرحلة الأولى → يدخل على التانية
        createProduct();
        selectedStep2.value = 1;
        selectedStep.value = timeLineSteps.length;
      }
    } else {
      // المرحلة التانية
      if (selectedStep2.value < timeLineSteps2.length) {
        createProduct();
        selectedStep2.value++;
      } else {
        // خلص الكل → رجّعه للبداية
        createProduct();
        selectedStep.value = 1;
        selectedStep2.value = 0;
      }
    }
    update();
  }

  /// ✅ الخطوة السابقة
  void prevStep() {
    if (selectedStep2.value > 0) {
      if (selectedStep2.value == 1) {
        selectedStep2.value = 0;
        selectedStep.value = timeLineSteps.length;
      } else {
        selectedStep2.value--;
      }
    } else {
      if (selectedStep.value > 1) {
        selectedStep.value--;
      }
    }
    update();
  }

  /// ✅ تغيير الخطوة يدويًا
  void changeSelected(int step, {bool isSecond = false}) {
    if (isSecond) {
      if (selectedStep.value == timeLineSteps.length) {
        selectedStep2.value = step;
      }
    } else {
      selectedStep.value = step;
      if (step < timeLineSteps.length) {
        selectedStep2.value = 0;
      }
    }
    update();
  }

  final RxBool isLoading = false.obs;
  final RxBool isProductsLoading = false.obs;

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

  ProductDevelopmentModel? developmentForProduct(String productId) {
    return ProductManagementServes().productManagement.firstWhereOrNull(
          (element) =>
              element.productId == productId && element.currentStep != '7',
        );
  }

  String stepTitle(String currentStep) {
    final step = int.tryParse(currentStep) ?? 0;
    for (final item in [...timeLineSteps, ...timeLineSteps2]) {
      if (item.containsKey(step)) {
        return item[step]!.tr;
      }
    }
    return '';
  }

  void searchBar(String value) {
    if (value.isNotEmpty) {
      searchProducts.assignAll(
        products
            .where(
              (element) =>
                  element.nameAr.toLowerCase().contains(value.toLowerCase()),
            )
            .toList(),
      );
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
      searchProducts.assignAll(products);
    }
    update();
  }

  final List<ProductModel> products = [];
  final List<ProductModel> searchProducts = [];
  void getAllProducts() async {
    if (products.isEmpty) {
      isProductsLoading(true);
      update();
    }
    try {
      final result = await getAllProductsUsecase.call();
      products.assignAll(result);
      searchProducts.assignAll(result);
    } finally {
      isProductsLoading(false);
      update();
    }
  }

  ProductModel? selectedProduct;
  void selectProductForDevelopment(ProductModel product) {
    final development = developmentForProduct(product.id);
    isEdit(development != null);
    selectedProduct = product;
    productIdController.text = development?.id.toString() ?? product.id;
    descriptionController.text = development?.description ?? '';
    productName = product.nameAr;
    productImage = development?.productImage.isNotEmpty == true
        ? development!.productImage
        : product.imageUrl;
    description = development?.description ?? '';
    currentStep = int.tryParse(development?.currentStep ?? '') ?? 0;
    if (development == null) {
      selectedStep.value = 1;
      selectedStep2.value = 0;
    } else if (currentStep < timeLineSteps.length) {
      selectedStep.value = currentStep + 1;
      selectedStep2.value = 0;
    } else {
      selectedStep2.value = currentStep - timeLineSteps.length + 1;
      selectedStep.value = timeLineSteps.length + 1;
    }
    update();
  }

  void editDevelopment(ProductDevelopmentModel product) {
    editProduct(id: product.id.toString(), isEditing: true);
  }

  void deleteDevelopment(String productDevelopmentId) async {
    isLoading(true);
    update();
    final result = await deleteProductDevelopmentUsecase.call(
      productDevelopmentId: productDevelopmentId,
    );
    result.fold(
      (failure) {
        Helpers.showCustomDialogError(
          context: Get.context!,
          title: 'error'.tr,
          message: failure.errMessage,
        );
      },
      (success) {
        ProductManagementServes().productManagement.removeWhere(
              (element) => element.id.toString() == productDevelopmentId,
            );
        searchProductManagement.removeWhere(
          (element) => element.id.toString() == productDevelopmentId,
        );
        searcharchiveProductManagement.removeWhere(
          (element) => element.id.toString() == productDevelopmentId,
        );
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
        getProductManagement();
      },
    );
    isLoading(false);
    update();
  }

  // create product
  void createProduct() async {
    isLoading(true);
    final result = await createProductDevelopmentUsecase.call(
      productId: productIdController.text,
      description: descriptionController.text,
      step: isEdit.value ? (currentStep + 1).toString() : '',
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
        productIdController.clear();
        descriptionController.clear();
        getProductManagement();
        Get.back();
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
  String description = '';
  int currentStep = 0;
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
      final product = ProductManagementServes()
          .productManagement
          .firstWhere((f) => f.id.toString() == id);
      description = product.description;
      final currentStep = int.tryParse(product.currentStep) ?? 1;
      this.currentStep = currentStep;
      if (currentStep < timeLineSteps.length) {
        selectedStep.value = currentStep + 1;
        selectedStep2.value = 0;
      } else {
        selectedStep2.value = currentStep - timeLineSteps.length + 1;
        selectedStep.value =
            timeLineSteps.length + 1; // يوقف الأولى عند آخر خطوة
      }
    } else {
      isEdit(false);
      selectedProduct = null;
      productIdController.clear();
      descriptionController.clear();
      selectedStep.value = 1;
      selectedStep2.value = 0;
      productName = '';
      productImage = '';
      currentStep = 0;
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
