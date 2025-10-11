import 'package:doctorbike/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  StockController({
    required this.getAllStockUsecase,
    required this.getProductDetailsUsecase,
    required this.moveToArchiveUsecase,
    required this.getArchivedUsecase,
    required this.getCategoriesUsecase,
    required this.searchProductsUsecase,
    required this.addCombinationUsecase,
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
  void initProductDetails() {
    isLoading(true);
    productNameController.text = productDetails.value!.nameAr;
    productDetailsController.text = productDetails.value!.descriptionAr!;
    subCategoryController.text =
        productDetails.value!.productSubCategories!.isNotEmpty &&
                productDetails.value!.productSubCategories != null
            ? productDetails.value!.productSubCategories!.first.subCategoryId
                .toString()
            : '';
    stockController.text = productDetails.value!.stock.toString();
    minimumStockController.text = productDetails.value!.minSalePrice.toString();
    purchasePriceController.text =
        productDetails.value!.normailPrice!.isNotEmpty &&
                productDetails.value!.purchasePrices != null
            ? productDetails.value!.normailPrice.toString()
            : '';
    discountPercentageController.text =
        productDetails.value!.discount.toString();
    retailPricesController.text = productDetails.value!.normailPrice.toString();

    for (var sizeJson in productDetails.value!.sizes!) {
      items.clear();
      final sizeModel = SizedModel();
      sizeModel.sizeController.text = sizeJson.size!;

      final colorsJson = sizeJson.colorSizes!;
      for (var colorJson in colorsJson) {
        final colorModel = ColorModel();
        colorModel.colorController.text = colorJson.colorAr!;
        colorModel.priceController.text = colorJson.normailPrice!;
        colorModel.quantityController.text = colorJson.stock!;
        sizeModel.colors.add(colorModel);
      }
      items.add(sizeModel);
    }
    isForcedSale.value = productDetails.value!.isSoldWithPaper == '1';
    isLoading(false);
    update();
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
