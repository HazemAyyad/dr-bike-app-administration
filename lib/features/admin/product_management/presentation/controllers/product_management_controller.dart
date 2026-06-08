import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/helpers/product_image_utils.dart';
import '../../../sales/data/models/product_model.dart';
import '../../../sales/domain/usecases/get_all_products_usecase.dart';
import '../../data/models/product_development_model.dart';
import '../../data/models/product_management_list_item.dart';
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

  int get totalSteps => timeLineSteps.length + timeLineSteps2.length;

  int get currentGlobalStep {
    if (selectedStep2.value == 0) {
      return selectedStep.value;
    }
    return timeLineSteps.length + selectedStep2.value;
  }

  bool get canGoPrevious => currentGlobalStep > 1;

  String get nextButtonLabel {
    if (!isEdit.value) return 'next'.tr;
    if (currentStep >= totalSteps) return 'developmentFinal'.tr;
    return 'next'.tr;
  }

  void _setGlobalStep(int globalStep) {
    if (globalStep <= timeLineSteps.length) {
      selectedStep.value = globalStep;
      selectedStep2.value = 0;
    } else {
      selectedStep2.value = globalStep - timeLineSteps.length;
      selectedStep.value = timeLineSteps.length;
    }
  }

  Future<void> nextStep() async {
    if (!isEdit.value) {
      await _createDevelopment();
      return;
    }

    if (currentGlobalStep >= totalSteps) {
      await _saveAndUpdateStep(
        totalSteps,
        refreshList: true,
        closeOnSuccess: true,
      );
      return;
    }

    final targetStep = currentGlobalStep + 1;
    _setGlobalStep(targetStep);
    await _saveAndUpdateStep(
      targetStep,
      refreshList: true,
      closeOnSuccess: targetStep >= totalSteps,
    );
  }

  Future<void> prevStep() async {
    if (!canGoPrevious) return;

    final targetStep = currentGlobalStep - 1;
    _setGlobalStep(targetStep);

    if (isEdit.value) {
      await _saveAndUpdateStep(targetStep, refreshList: true);
    } else {
      update();
    }
  }

  final RxBool isLoading = false.obs;
  final RxBool isProductsLoading = false.obs;

  Future<void> getProductManagement() async {
    ProductManagementServes().productManagement.isEmpty
        ? isLoading(true)
        : null;
    final result = await getProductDevelopmentsUsecase.call();
    ProductManagementServes().productManagement.assignAll(result);
    _refreshDisplayedProducts();
    isLoading(false);
    update();
  }

  List<ProductManagementListItem> displayedProducts = [];

  final RxBool sortDescending = true.obs;
  final RxInt statusFilter = 0.obs;
  final RxInt stageFilter = 0.obs;
  final RxString searchQuery = ''.obs;
  final Rx<DateTime?> filterDateFrom = Rx<DateTime?>(null);
  final Rx<DateTime?> filterDateTo = Rx<DateTime?>(null);

  static const int statusAll = 0;
  static const int statusInDevelopment = 1;
  static const int statusFinal = 2;

  void _refreshDisplayedProducts() {
    applyFilters();
  }

  void applyFilters() {
    final devMap = <String, ProductDevelopmentModel>{
      for (final dev in ProductManagementServes().productManagement)
        dev.productId: dev,
    };

    var items = products
        .map(
          (product) => ProductManagementListItem(
            product: product,
            development: devMap[product.id],
          ),
        )
        .toList();

    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items
          .where(
            (item) => item.productName.toLowerCase().contains(query),
          )
          .toList();
    }

    switch (statusFilter.value) {
      case statusInDevelopment:
        items = items
            .where((item) => item.hasDevelopment && item.stepValue < 7)
            .toList();
        break;
      case statusFinal:
        items = items
            .where((item) => item.hasDevelopment && item.stepValue == 7)
            .toList();
        break;
    }

    if (stageFilter.value > 0) {
      final stepValue = stageFilter.value;
      items = items.where((item) => item.stepValue == stepValue).toList();
    }

    if (filterDateFrom.value != null || filterDateTo.value != null) {
      items = items.where((item) {
        if (!item.hasDevelopment) return false;
        final date = _parseDevelopmentDate(item.developmentDate);
        if (date == null) return false;
        if (filterDateFrom.value != null &&
            date.isBefore(_dateOnly(filterDateFrom.value!))) {
          return false;
        }
        if (filterDateTo.value != null &&
            date.isAfter(_dateOnly(filterDateTo.value!))) {
          return false;
        }
        return true;
      }).toList();
    }

    items.sort((a, b) {
      final byStep = sortDescending.value
          ? b.stepValue.compareTo(a.stepValue)
          : a.stepValue.compareTo(b.stepValue);
      if (byStep != 0) return byStep;
      return sortDescending.value
          ? b.productName.compareTo(a.productName)
          : a.productName.compareTo(b.productName);
    });

    displayedProducts = items;
    update();
  }

  DateTime? _parseDevelopmentDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  void onSearchChanged(String value) {
    searchQuery.value = value;
    applyFilters();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    applyFilters();
  }

  void toggleSortOrder() {
    sortDescending.value = !sortDescending.value;
    applyFilters();
  }

  void applyFilterSettings({
    required int status,
    required int stage,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    statusFilter.value = status;
    stageFilter.value = stage;
    filterDateFrom.value = dateFrom;
    filterDateTo.value = dateTo;
    applyFilters();
  }

  void clearFilters() {
    statusFilter.value = statusAll;
    stageFilter.value = 0;
    filterDateFrom.value = null;
    filterDateTo.value = null;
    applyFilters();
  }

  bool get hasActiveFilters =>
      statusFilter.value != statusAll ||
      stageFilter.value != 0 ||
      filterDateFrom.value != null ||
      filterDateTo.value != null;

  int get activeFilterCount {
    var count = 0;
    if (statusFilter.value != statusAll) count++;
    if (stageFilter.value != 0) count++;
    if (filterDateFrom.value != null) count++;
    if (filterDateTo.value != null) count++;
    return count;
  }

  ProductDevelopmentModel? developmentForProduct(String productId) {
    return ProductManagementServes().productManagement.firstWhereOrNull(
          (element) => element.productId == productId,
        );
  }

  String stepTitle(String currentStep) {
    final step = int.tryParse(currentStep) ?? 0;
    if (step == 0) return '';
    for (final item in [...timeLineSteps, ...timeLineSteps2]) {
      if (item.containsKey(step)) {
        return item[step]!.tr;
      }
    }
    return '';
  }

  final List<ProductModel> products = [];

  Future<void> getAllProducts() async {
    if (products.isEmpty) {
      isProductsLoading(true);
      update();
    }
    try {
      final result = await getAllProductsUsecase.call();
      products.assignAll(result);
      _refreshDisplayedProducts();
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
    _setProductImages(
      productId: product.id,
      devImage: development?.productImage,
      product: product,
    );
    description = development?.description ?? '';
    currentStep = int.tryParse(development?.currentStep ?? '') ?? 0;
    if (development == null) {
      _setGlobalStep(1);
    } else {
      _setGlobalStep(currentStep);
    }
    update();
  }

  void editDevelopment(ProductDevelopmentModel product) {
    editProduct(id: product.id.toString(), isEditing: true);
  }

  void openListItem(ProductManagementListItem item) {
    if (item.hasDevelopment) {
      editProduct(id: item.developmentId.toString(), isEditing: true);
    } else {
      selectProductForDevelopment(item.product);
    }
  }

  void _showSuccessMessage(String message) {
    final context = Get.context;
    if (context == null) return;
    Helpers.showCustomDialogSuccess(
      context: context,
      title: 'success'.tr,
      message: message,
    );
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
        _refreshDisplayedProducts();
        _showSuccessMessage('productDevelopmentDeletedSuccessfully'.tr);
        getProductManagement();
      },
    );
    isLoading(false);
    update();
  }

  Future<void> _createDevelopment() async {
    isLoading(true);
    update();

    final productId = selectedProduct?.id ?? productIdController.text;
    final result = await createProductDevelopmentUsecase.call(
      productId: productId,
      description: descriptionController.text,
      step: '',
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
            message: failure.data['message'] ?? failure.errMessage,
          );
        }
      },
      (success) async {
        final developmentId = success.developmentId;
        isEdit(true);
        currentStep = 1;
        _setGlobalStep(1);
        if (developmentId != null) {
          productIdController.text = developmentId;
        } else {
          await getProductManagement();
          final created = developmentForProduct(productId);
          if (created != null) {
            productIdController.text = created.id.toString();
          }
        }
        description = descriptionController.text;
        await getProductManagement();
        _showSuccessMessage('productDevelopmentCreatedSuccessfully'.tr);
      },
    );

    isLoading(false);
    update();
  }

  Future<void> _saveAndUpdateStep(
    int step, {
    bool refreshList = true,
    bool closeOnSuccess = false,
  }) async {
    if (!isEdit.value || step < 1) return;

    isLoading(true);
    update();

    final result = await createProductDevelopmentUsecase.call(
      productId: productIdController.text,
      description: descriptionController.text,
      step: step.toString(),
    );

    await result.fold(
      (failure) async {
        Helpers.showCustomDialogError(
          context: Get.context!,
          title: 'error'.tr,
          message: failure.data?['message'] ?? failure.errMessage,
        );
      },
      (success) async {
        currentStep = step;
        description = descriptionController.text;
        if (refreshList) {
          await getProductManagement();
        }
        if (closeOnSuccess) {
          Future.delayed(
            const Duration(milliseconds: 650),
            Get.back,
          );
        }
        _showSuccessMessage('productDevelopmentUpdatedSuccessfully'.tr);
      },
    );

    isLoading(false);
    update();
  }

  final RxBool isEdit = false.obs;
  String productName = '';
  String productImage = '';
  List<String> productImageUrls = [];
  String description = '';
  int currentStep = 0;

  void _setProductImages({
    required String productId,
    String? devImage,
    ProductModel? product,
  }) {
    if (ProductImageUtils.isValidUrl(devImage)) {
      productImageUrls = [devImage!.trim()];
      productImage = devImage.trim();
      return;
    }

    final resolvedProduct = product ??
        products.firstWhereOrNull((p) => p.id == productId) ??
        selectedProduct;
    productImageUrls = resolvedProduct?.allImageUrlsInPriority ?? [];
    productImage = resolvedProduct?.preferredImageUrl ?? '';
  }

  void editProduct({required String id, required bool isEditing}) {
    if (isEditing) {
      isEdit(true);
      final product = ProductManagementServes()
          .productManagement
          .firstWhere((f) => f.id.toString() == id);
      productIdController.text = id;
      productName = product.productName;
      _setProductImages(
        productId: product.productId,
        devImage: product.productImage,
      );
      description = product.description;
      descriptionController.text = product.description;
      currentStep = int.tryParse(product.currentStep) ?? 1;
      _setGlobalStep(currentStep);
    } else {
      isEdit(false);
      selectedProduct = null;
      productIdController.clear();
      descriptionController.clear();
      _setGlobalStep(1);
      productName = '';
      productImage = '';
      productImageUrls = [];
      description = '';
      currentStep = 0;
    }
    update();
  }

  @override
  void onInit() {
    getProductManagement();
    getAllProducts();
    super.onInit();
  }
}
