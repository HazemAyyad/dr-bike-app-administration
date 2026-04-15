import 'package:dio/dio.dart';
import 'package:doctorbike/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData;

import '../../../../../core/errors/failure.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../sales/data/models/product_model.dart';
import '../../data/models/all_stock_products_model.dart';
import '../../data/models/product_details_model.dart';
import '../../domain/usecases/add_combination_usecase.dart';
import '../../domain/usecases/get_all_stock_usecase.dart';
import '../../domain/usecases/get_archived_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_product_details_usecase.dart';
import '../../domain/usecases/move_to_archive_usecase.dart';
import '../../domain/usecases/save_product_full_usecase.dart';
import '../../domain/usecases/search_products_usecase.dart';
import 'stock_services.dart';

class StockController extends GetxController with GetTickerProviderStateMixin {
  final GetAllStockUsecase getAllStockUsecase;
  final GetProductDetailsUsecase getProductDetailsUsecase;
  final MoveToArchiveUsecase moveToArchiveUsecase;
  final GetArchivedUsecase getArchivedUsecase;
  final GetCategoriesUsecase getCategoriesUsecase;
  final SearchProductsUsecase searchProductsUsecase;
  final AddCombinationUsecase addCombinationUsecase;
  final SaveProductFullUsecase saveProductFullUsecase;

  StockController({
    required this.getAllStockUsecase,
    required this.getProductDetailsUsecase,
    required this.moveToArchiveUsecase,
    required this.getArchivedUsecase,
    required this.getCategoriesUsecase,
    required this.searchProductsUsecase,
    required this.addCombinationUsecase,
    required this.saveProductFullUsecase,
  });

  final TextEditingController productNameController = TextEditingController();
  final TextEditingController productDetailsController =
      TextEditingController();
  final TextEditingController subCategoryController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController minimumStockController = TextEditingController();
  final TextEditingController wholesalePricesController =
      TextEditingController();
  final TextEditingController retailPricesController = TextEditingController();
  final TextEditingController discountPercentageController =
      TextEditingController();
  final TextEditingController selectPurchaseController =
      TextEditingController();
  final TextEditingController purchasePriceController = TextEditingController();
  final RxBool isForcedSale = false.obs;

  final TextEditingController closeoutsMinimumSaleController =
      TextEditingController();
  final TextEditingController closeoutsProductNameController =
      TextEditingController();
  final scrollController = ScrollController();
  final showScrollToTopButton = false.obs;

  final tabs = ['products', 'clearance', 'productComposition'].obs;

  final currentTab = 0.obs;

  void changeTab(int index) {
    currentTab.value = index;
  }

  late AnimationController animController;
  late Animation<double> opacityAnimation;
  late Animation<double> sizeAnimation;

  void toggleAddMenu() {
    isAddMenuOpen.value = !isAddMenuOpen.value;
  }

  final items = <SizedModel>[SizedModel()].obs;

  void addSized() {
    items.add(SizedModel());
    update();
  }

  void removeItem(int index) {
    if (items.length > 1) {
      items.removeAt(index);
    }
    update();
  }

  void addColorToSize(int sizeIndex) {
    items[sizeIndex].colors.add(ColorModel());
    update();
  }

  void removeColorFromSize(int sizeIndex, int colorIndex) {
    if (items[sizeIndex].colors.length > 1) {
      items[sizeIndex].colors.removeAt(colorIndex);
    }
    update();
  }

  final newComposition = <NewCompositionModel>[NewCompositionModel()].obs;

  void addComposition() {
    newComposition.add(NewCompositionModel());
    update();
  }

  void removeComposition(int index) {
    if (newComposition.length > 1) {
      newComposition.removeAt(index);
    }
    update();
  }

  final RxInt totalCost = 0.obs;
  final RxInt totalQuantity = 0.obs;

  void calculateGrandTotal() {
    int cost = 0;
    int quantity = 0;

    for (NewCompositionModel item in newComposition) {
      cost += item.totalPrice.value.toInt();
    }
    for (NewCompositionModel item in newComposition) {
      quantity += item.totalQuantity.value;
    }

    totalCost.value = cost;
    totalQuantity.value = quantity;
  }

  List<Map<String, String>> addList = [
    {
      'title': 'newClearance',
      'icon': AssetsManager.invoiceIcon,
      'route': AppRoutes.CLOSEOUTSSCREEN,
    },
    {
      'title': 'newProductComposition',
      'icon': AssetsManager.invoiceIcon,
      'route': AppRoutes.ADDCOMBINATIONSCREEN,
    },
  ];

  final RxBool isLoading = false.obs;

  final RxBool isProductLoading = false.obs;

  final RxBool isLoadingMore = false.obs;

  final RxBool isAddMenuOpen = false.obs;

  /// `null` = إنشاء منتج جديد؛ وإلا تعديل المنتج ذو الـ id.
  final Rxn<String> editingProductId = Rxn<String>();

  /// يطابق `save_scope` في الـ API: `full` أو `local_only`.
  final RxBool saveScopeFull = true.obs;

  void scrollToTop() {
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 1) {
      StockServices().page++;
      getAllProducts(isRefresh: true);
    }
  }

  final RxList<AllStockProductsModel> allProducts =
      <AllStockProductsModel>[].obs;

  final RxList<AllStockProductsModel> allClearances =
      <AllStockProductsModel>[].obs;

  final RxList<AllStockProductsModel> allCombinations =
      <AllStockProductsModel>[].obs;
  int page = 1;

  // Get all products
  void getAllProducts({bool isRefresh = false}) async {
    isRefresh
        ? isLoadingMore(true)
        : allProducts.isEmpty
            ? isLoading(true)
            : isLoading(false);

    // 1- المنتجات العادية
    final result = await getAllStockUsecase.call(
      page: page,
      ifCombinations: false,
      ifCloseouts: false,
    );
    for (var product in result) {
      if (!allProducts.any((p) => p.productId == product.productId)) {
        allProducts.add(product);
        // filteredProducts.add(product);
      }
      // else {
      // filteredProducts.value = StockServices().allProducts;
      // }
    }
    final getClearances = await getAllStockUsecase.call(
      page: page,
      ifCombinations: false,
      ifCloseouts: true,
    );
    for (var product in getClearances) {
      if (!allClearances.any((p) => p.productId == product.productId)) {
        allClearances.add(product);
        // filteredClearances.add(product);
      }
      // else {
      // filteredClearances.value = StockServices().allClearances;
      // }
    }

    // 3- الكومبينيشن
    final getCombinations = await getAllStockUsecase.call(
      page: page,
      ifCombinations: true,
      ifCloseouts: false,
    );
    for (var product in getCombinations) {
      if (!allCombinations.any((p) => p.productId == product.productId)) {
        allCombinations.add(product);
        // filteredCombinations.add(product);
      }
      // else {
      // filteredCombinations.value = StockServices().allCombinations;
      // }
    }
    page++;
    isLoadingMore(false);
    isLoading(false);
  }

  Rxn<ProductDetailsModel> productDetails = Rxn<ProductDetailsModel>();
  // get product details
  Future<void> getProductDetails({required String productId}) async {
    isProductLoading(true);
    productDetails.value =
        await getProductDetailsUsecase.call(productId: productId);
    isProductLoading(false);
    update();
  }

  // get product
  List<AllStockProductsModel> archived = [];
  void getArchived() async {
    archived.isNotEmpty ? isProductLoading(false) : isProductLoading(true);
    archived.assignAll(await getArchivedUsecase.call());
    isProductLoading(false);
    update();
  }

  // search products
  List<AllStockProductsModel> searchProducts = [];
  void getSearchProducts({required String name}) async {
    searchProducts.clear();

    isProductLoading(true);
    searchProducts.clear();

    final result = await searchProductsUsecase.call(name: name);
    searchProducts.assignAll(result);
    isProductLoading(false);
    update();
  }

  // get categories & projects
  List<ProductModel> categories = [];
  List<ProductModel> projects = [];

  void getCategories() async {
    categories.assignAll(await getCategoriesUsecase.call(isProject: false));

    projects.assignAll(await getCategoriesUsecase.call(isProject: true));
    isProductLoading(false);
    update();
  }

  // move product to archive
  void moveProductToArchive({
    required BuildContext context,
    required String productId,
    required bool isMove,
  }) async {
    isLoading(true);
    final result = await moveToArchiveUsecase.call(
      productId: productId,
      isMove: isMove,
    );

    result.fold(
      (failure) {
        isLoading(false);

        Get.back();
        Get.snackbar(
          failure.errMessage,
          failure.data['message'],
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1000),
        );
      },
      (success) async {
        getAllProducts();
        Get.back();
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1000),
        );
        Future.delayed(
          const Duration(milliseconds: 1000),
          () {
            Get.back();
          },
        );
      },
    );
    isLoading(false);
  }

  // Add combination
  void addCombination() async {
    isLoading(true);
    final result = await addCombinationUsecase.call(
      productId: closeoutsProductsId,
      combination: newComposition,
    );

    result.fold(
      (failure) {
        isLoading(false);

        Get.back();
        Get.snackbar(
          failure.errMessage,
          failure.data['message'],
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1000),
        );
      },
      (success) async {
        getAllProducts();
        Get.back();
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1000),
        );
        Future.delayed(
          const Duration(milliseconds: 1000),
          () {
            Get.back();
          },
        );
      },
    );
    isLoading(false);
  }

  String closeoutsProductsId = '';

  /// نموذج فارغ لإضافة منتج من شاشة المخزون.
  void prepareCreateProduct() {
    editingProductId.value = null;
    saveScopeFull.value = true;
    productNameController.clear();
    productDetailsController.clear();
    subCategoryController.text =
        categories.isNotEmpty ? categories.first.id.toString() : '';
    stockController.text = '0';
    minimumStockController.clear();
    wholesalePricesController.clear();
    retailPricesController.clear();
    discountPercentageController.clear();
    selectPurchaseController.clear();
    purchasePriceController.clear();
    for (final el in items) {
      el.onClose();
    }
    items.clear();
    items.add(SizedModel());
    isForcedSale.value = false;
    update();
  }

  void initProductDetails() {
    editingProductId.value = productDetails.value?.id;
    productNameController.text = productDetails.value!.nameAr;
    productDetailsController.text = productDetails.value!.descriptionAr ?? '';
    subCategoryController.text =
        productDetails.value!.productSubCategories != null &&
                productDetails.value!.productSubCategories!.isNotEmpty
            ? productDetails.value!.productSubCategories!.first.subCategoryId
                .toString()
            : '';
    stockController.text = productDetails.value!.stock?.toString() ?? '0';
    minimumStockController.text =
        productDetails.value!.minStock?.toString() ?? '';
    purchasePriceController.text =
        productDetails.value!.normailPrice != null &&
                productDetails.value!.normailPrice!.isNotEmpty
            ? productDetails.value!.normailPrice.toString()
            : '';
    discountPercentageController.text =
        productDetails.value!.discount?.toString() ?? '0';
    retailPricesController.text =
        productDetails.value!.normailPrice?.toString() ?? '';

    for (final el in items) {
      el.onClose();
    }
    items.clear();
    final sizesList = productDetails.value!.sizes;
    if (sizesList != null) {
      for (final sizeJson in sizesList) {
        final sizeModel = SizedModel();
        sizeModel.dbSizeId = sizeJson.id;
        sizeModel.sizeController.text = sizeJson.size ?? '';

        sizeModel.colors.clear();
        final colorsJson = sizeJson.colorSizes ?? [];
        for (final colorJson in colorsJson) {
          final colorModel = ColorModel();
          colorModel.dbColorId = colorJson.id;
          colorModel.colorController.text = colorJson.colorAr ?? '';
          colorModel.priceController.text = colorJson.normailPrice ?? '';
          colorModel.quantityController.text = colorJson.stock ?? '';
          sizeModel.colors.add(colorModel);
        }
        if (sizeModel.colors.isEmpty) {
          sizeModel.colors.add(ColorModel());
        }
        items.add(sizeModel);
      }
    }
    if (items.isEmpty) {
      items.add(SizedModel());
    }
    isForcedSale.value = productDetails.value!.isSoldWithPaper == '1' ||
        productDetails.value!.isSoldWithPaper == 1;
    update();
  }

  FormData _buildProductFormData() {
    final form = FormData();

    void addField(String key, String value) {
      form.fields.add(MapEntry(key, value));
    }

    addField('nameAr', productNameController.text.trim());
    addField('descriptionAr', productDetailsController.text.trim());
    addField('nameEng', productNameController.text.trim());
    addField('nameAbree', productNameController.text.trim());
    addField('descriptionEng', productDetailsController.text.trim());
    addField('descriptionAbree', productDetailsController.text.trim());
    addField(
      'discount',
      discountPercentageController.text.trim().isEmpty
          ? '0'
          : discountPercentageController.text.trim(),
    );
    addField(
      'normailPrice',
      retailPricesController.text.trim().isEmpty
          ? '0'
          : retailPricesController.text.trim(),
    );
    addField(
      'min_stock',
      minimumStockController.text.trim().isEmpty
          ? '0'
          : minimumStockController.text.trim(),
    );
    addField('is_sold_with_paper', isForcedSale.value ? '1' : '0');
    addField('save_scope', saveScopeFull.value ? 'full' : 'local_only');
    addField('isShow', '1');
    addField('isNewItem', '1');
    addField('isMoreSales', '0');
    addField('rate', '4');
    addField('manufactureYear', '0');
    addField('model', '');
    addField('wholesalePrice', '0');
    if (stockController.text.trim().isNotEmpty) {
      addField('stock', stockController.text.trim());
    }
    if (selectPurchaseController.text.trim().isNotEmpty) {
      addField('project_id', selectPurchaseController.text.trim());
    }
    if (editingProductId.value != null) {
      addField('product_id', editingProductId.value!);
    }

    final subId = subCategoryController.text.trim();
    if (subId.isNotEmpty) {
      form.fields.add(MapEntry('sub_categories[]', subId));
    }

    var sizeIndex = 0;
    for (final sz in items) {
      final sizeText = sz.sizeController.text.trim();
      final hasId = sz.dbSizeId != null && sz.dbSizeId!.isNotEmpty;
      if (sizeText.isEmpty && !hasId) {
        continue;
      }
      addField('sizes[$sizeIndex][size]', sizeText);
      if (hasId) {
        addField('sizes[$sizeIndex][id]', sz.dbSizeId!);
      }
      for (var j = 0; j < sz.colors.length; j++) {
        final c = sz.colors[j];
        addField(
          'sizes[$sizeIndex][color_sizes][$j][colorAr]',
          c.colorController.text.trim(),
        );
        addField(
          'sizes[$sizeIndex][color_sizes][$j][normailPrice]',
          c.priceController.text.trim().isEmpty ? '0' : c.priceController.text.trim(),
        );
        addField(
          'sizes[$sizeIndex][color_sizes][$j][stock]',
          c.quantityController.text.trim().isEmpty ? '0' : c.quantityController.text.trim(),
        );
        final cid = c.dbColorId;
        if (cid != null && cid.isNotEmpty && cid != '0') {
          addField('sizes[$sizeIndex][color_sizes][$j][id]', cid);
        }
      }
      sizeIndex++;
    }

    return form;
  }

  Future<void> submitProduct() async {
    isLoading(true);
    update();
    try {
      final form = _buildProductFormData();
      final result = await saveProductFullUsecase.call(
        formData: form,
        isCreate: editingProductId.value == null,
      );
      final msg = result['message']?.toString() ?? 'success'.tr;
      if (result['media_warning'] != null ||
          result['image_warning'] != null) {
        Get.snackbar(
          'success'.tr,
          '$msg\n${result['media_warning'] ?? result['image_warning']}',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar(
          'success'.tr,
          msg,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      allProducts.clear();
      allClearances.clear();
      allCombinations.clear();
      page = 1;
      getAllProducts();
      if (editingProductId.value != null) {
        await getProductDetails(productId: editingProductId.value!);
      }
      Get.back();
    } on ServerFailure catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
      update();
    }
  }

  @override
  void onInit() {
    super.onInit();
    getAllProducts();
    getCategories();
    scrollController.addListener(_onScroll);
    scrollController.addListener(() {
      if (scrollController.offset > 100) {
        showScrollToTopButton.value = true;
      } else {
        showScrollToTopButton.value = false;
      }
    });
    animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    opacityAnimation = Tween<double>(begin: 0, end: 1).animate(animController);
    sizeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: animController, curve: Curves.fastOutSlowIn),
    );

    ever(isAddMenuOpen, (bool open) {
      if (open) {
        animController.forward();
      } else {
        animController.reverse();
      }
    });
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.removeListener(() {
      if (scrollController.offset > 100) {
        showScrollToTopButton.value = true;
      } else {
        showScrollToTopButton.value = false;
      }
    });
    scrollController.dispose();
    for (var element in items) {
      element.onClose();
    }
    animController.dispose();
    productNameController.dispose();
    productDetailsController.dispose();
    subCategoryController.dispose();
    stockController.dispose();
    minimumStockController.dispose();
    wholesalePricesController.dispose();
    retailPricesController.dispose();
    discountPercentageController.dispose();
    selectPurchaseController.dispose();
    purchasePriceController.dispose();
    closeoutsMinimumSaleController.dispose();
    super.onClose();
  }
}

class SizedModel {
  final TextEditingController sizeController = TextEditingController();
  final RxList<ColorModel> colors = <ColorModel>[].obs;
  String? dbSizeId;

  SizedModel() {
    colors.add(ColorModel());
  }
  void onClose() {
    sizeController.dispose();
  }
}

class ColorModel {
  final TextEditingController colorController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String? dbColorId;

  void onClose() {
    colorController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}

class NewCompositionModel {
  final TextEditingController productIdController = TextEditingController();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  final RxDouble totalPrice = 0.0.obs;

  final RxInt totalQuantity = 0.obs;

  NewCompositionModel() {
    priceController.addListener(_updateTotal);
    quantityController.addListener(_updateTotal);
  }

  void _updateTotal() {
    final price = double.tryParse(priceController.text.trim()) ?? 0;
    final quantity = double.tryParse(quantityController.text.trim()) ?? 0;
    totalPrice.value = price * quantity;
    totalQuantity.value = quantity.toInt();
  }

  void onClose() {
    productIdController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}


  // final RxList<AllStockProductsModel> filteredProducts =
  //     <AllStockProductsModel>[].obs;
  // final RxList<AllStockProductsModel> filteredClearances =
  //     <AllStockProductsModel>[].obs;
  // final RxList<AllStockProductsModel> filteredCombinations =
  //     <AllStockProductsModel>[].obs;

  // Search products
  // void searchedProducts(String searchQuery) {
  //   if (searchQuery.isEmpty) filteredProducts;
  //   if (searchQuery.isEmpty) filteredClearances;
  //   if (searchQuery.isEmpty) filteredCombinations;
  //   filteredProducts.value = StockServices()
  //       .allProducts
  //       .where((product) =>
  //           product.name.toLowerCase().contains(searchQuery.toLowerCase()))
  //       .toList();

  //   filteredClearances.value = StockServices()
  //       .allClearances
  //       .where((product) =>
  //           product.name.toLowerCase().contains(searchQuery.toLowerCase()))
  //       .toList();

  //   filteredCombinations.value = StockServices()
  //       .allCombinations
  //       .where((product) =>
  //           product.name.toLowerCase().contains(searchQuery.toLowerCase()))
  //       .toList();
  // }
  // move product to archive
  // void moveProductToArchive({
  //   required BuildContext context,
  //   required String productId,
  //   required bool isMove,
  // }) async {
  //   isLoading(true);
  //   final result = await moveToArchiveUsecase.call(
  //     productId: productId,
  //     isMove: isMove,
  //   );

  //   result.fold(
  //     (failure) {
  //       isLoading(false);

  //       Get.back();
  //       Get.snackbar(
  //         failure.errMessage,
  //         failure.data['message'],
  //         snackPosition: SnackPosition.BOTTOM,
  //         duration: const Duration(milliseconds: 1500),
  //       );
  //     },
  //     (success) async {
  //       getAllProducts();
  //       Get.back();
  //       Get.snackbar(
  //         'success'.tr,
  //         success,
  //         snackPosition: SnackPosition.BOTTOM,moveToArchive
  //         duration: const Duration(milliseconds: 1500),
  //       );
  //       Future.delayed(
  //         const Duration(milliseconds: 1500),
  //         () {
  //           Get.back();
  //         },
  //       );
  //     },
  //   );
  //   isLoading(false);
  // }
