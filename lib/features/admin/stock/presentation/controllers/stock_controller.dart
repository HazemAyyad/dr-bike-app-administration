import 'package:dio/dio.dart';
import 'package:doctorbike/core/helpers/sweet_success_dialog.dart';
import 'package:doctorbike/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../core/helpers/server_validation_messages.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../sales/data/models/product_model.dart';
import '../../data/models/all_stock_products_model.dart';
import '../../data/models/product_details_model.dart';
import '../../domain/usecases/add_combination_usecase.dart';
import '../../domain/usecases/get_all_stock_usecase.dart';
import '../../domain/usecases/get_archived_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_main_categories_usecase.dart';
import '../../domain/usecases/get_product_details_usecase.dart';
import '../../domain/usecases/get_product_size_options_usecase.dart';
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
  final GetMainCategoriesUsecase getMainCategoriesUsecase;
  final SearchProductsUsecase searchProductsUsecase;
  final AddCombinationUsecase addCombinationUsecase;
  final SaveProductFullUsecase saveProductFullUsecase;
  final GetProductSizeOptionsUsecase getProductSizeOptionsUsecase;

  StockController({
    required this.getAllStockUsecase,
    required this.getProductDetailsUsecase,
    required this.moveToArchiveUsecase,
    required this.getArchivedUsecase,
    required this.getCategoriesUsecase,
    required this.getMainCategoriesUsecase,
    required this.searchProductsUsecase,
    required this.addCombinationUsecase,
    required this.saveProductFullUsecase,
    required this.getProductSizeOptionsUsecase,
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
  final TextEditingController nameEngController = TextEditingController();
  final TextEditingController nameAbreeController = TextEditingController();
  final TextEditingController descriptionEngController = TextEditingController();
  final TextEditingController descriptionAbreeController =
      TextEditingController();
  final TextEditingController manufactureYearController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController minSalePriceController = TextEditingController();
  final TextEditingController listPriceController = TextEditingController();
  final TextEditingController rotationDateController = TextEditingController();

  final RxBool isForcedSale = false.obs;
  final RxBool isShowProduct = true.obs;
  final RxBool isNewItemProduct = true.obs;
  final RxBool isMoreSalesProduct = false.obs;

  final RxList<String> selectedSubCategoryIds = <String>[].obs;

  /// Main category for dependent subcategory picker (UI); API still uses `sub_categories[]` only.
  final Rxn<String> selectedMainCategoryId = Rxn<String>();

  final List<XFile> pendingNormalImages = [];
  final List<XFile> pendingViewImages = [];
  final List<XFile> pendingThreeDImages = [];
  XFile? pendingVideo;

  final RxList<ProductMediaItem> existingNormalMedia = <ProductMediaItem>[].obs;
  final RxList<ProductMediaItem> existingViewMedia = <ProductMediaItem>[].obs;
  final RxList<ProductMediaItem> existingThreeDMedia = <ProductMediaItem>[].obs;
  final RxList<String> pendingDeleteNormalIds = <String>[].obs;
  final RxList<String> pendingDeleteViewIds = <String>[].obs;
  final RxList<String> pendingDeleteThreeDIds = <String>[].obs;
  final RxBool pendingDeleteExistingVideo = false.obs;
  String? existingVideoUrlForEdit;

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

  void _resetEditMediaState() {
    existingNormalMedia.clear();
    existingViewMedia.clear();
    existingThreeDMedia.clear();
    pendingDeleteNormalIds.clear();
    pendingDeleteViewIds.clear();
    pendingDeleteThreeDIds.clear();
    pendingDeleteExistingVideo.value = false;
    existingVideoUrlForEdit = null;
  }

  List<ProductMediaItem> _mediaItemsForEdit(
    List<ProductMediaItem>? items,
    List<String>? urls,
  ) {
    if (items != null && items.isNotEmpty) {
      return items
          .where(
            (e) =>
                e.id.isNotEmpty &&
                (e.url ?? '').isNotEmpty &&
                e.url != 'no image',
          )
          .toList();
    }
    return [];
  }

  void toggleSubCategory(String id) {
    if (selectedSubCategoryIds.contains(id)) {
      if (selectedSubCategoryIds.length > 1) {
        selectedSubCategoryIds.remove(id);
      }
    } else {
      selectedSubCategoryIds.add(id);
    }
    update();
  }

  Future<void> pickNormalImages() async {
    final files = await ImagePicker().pickMultiImage();
    if (files.isNotEmpty) {
      pendingNormalImages.addAll(files);
      update();
    }
  }

  Future<void> pickViewImages() async {
    final files = await ImagePicker().pickMultiImage();
    if (files.isNotEmpty) {
      pendingViewImages.addAll(files);
      update();
    }
  }

  Future<void> pickThreeDImages() async {
    final files = await ImagePicker().pickMultiImage();
    if (files.isNotEmpty) {
      pendingThreeDImages.addAll(files);
      update();
    }
  }

  static const _allowedVideoSuffixes = ['.mp4', '.mov', '.avi', '.webm'];

  Future<void> pickProductVideo() async {
    final f = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (f == null) return;
    final name = f.name.toLowerCase();
    final ok = _allowedVideoSuffixes.any((e) => name.endsWith(e));
    if (!ok) {
      Get.snackbar(
        'error'.tr,
        'videoFormatInvalid'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return;
    }
    pendingVideo = f;
    if (existingVideoUrlForEdit != null && existingVideoUrlForEdit!.isNotEmpty) {
      pendingDeleteExistingVideo.value = true;
    }
    update();
  }

  void clearPendingMedia() {
    pendingNormalImages.clear();
    pendingViewImages.clear();
    pendingThreeDImages.clear();
    pendingVideo = null;
    update();
  }

  void removePendingNormalAt(int index) {
    if (index >= 0 && index < pendingNormalImages.length) {
      pendingNormalImages.removeAt(index);
    }
    update();
  }

  void removePendingViewAt(int index) {
    if (index >= 0 && index < pendingViewImages.length) {
      pendingViewImages.removeAt(index);
    }
    update();
  }

  void removePendingThreeDAt(int index) {
    if (index >= 0 && index < pendingThreeDImages.length) {
      pendingThreeDImages.removeAt(index);
    }
    update();
  }

  Future<void> confirmRemoveExistingNormal(ProductMediaItem item) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('deleteMediaConfirmTitle'.tr),
        content: Text('deleteMediaConfirmMessage'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    if (ok == true) {
      existingNormalMedia.removeWhere((e) => e.id == item.id);
      if (item.id.isNotEmpty) {
        pendingDeleteNormalIds.add(item.id);
      }
      update();
    }
  }

  Future<void> confirmRemoveExistingView(ProductMediaItem item) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('deleteMediaConfirmTitle'.tr),
        content: Text('deleteMediaConfirmMessage'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    if (ok == true) {
      existingViewMedia.removeWhere((e) => e.id == item.id);
      if (item.id.isNotEmpty) {
        pendingDeleteViewIds.add(item.id);
      }
      update();
    }
  }

  Future<void> confirmRemoveExistingThreeD(ProductMediaItem item) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('deleteMediaConfirmTitle'.tr),
        content: Text('deleteMediaConfirmMessage'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    if (ok == true) {
      existingThreeDMedia.removeWhere((e) => e.id == item.id);
      if (item.id.isNotEmpty) {
        pendingDeleteThreeDIds.add(item.id);
      }
      update();
    }
  }

  Future<void> confirmRemoveExistingVideo() async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('deleteMediaConfirmTitle'.tr),
        content: Text('deleteVideoConfirmMessage'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    if (ok == true) {
      pendingDeleteExistingVideo.value = true;
      existingVideoUrlForEdit = null;
      pendingVideo = null;
      update();
    }
  }

  late AnimationController animController;
  late Animation<double> opacityAnimation;
  late Animation<double> sizeAnimation;

  void toggleAddMenu() {
    isAddMenuOpen.value = !isAddMenuOpen.value;
  }

  final items = <SizedModel>[].obs;

  final RxList<String> productSizeOptions = <String>[].obs;

  Future<void> loadProductSizeOptions({String? productId}) async {
    try {
      final list =
          await getProductSizeOptionsUsecase.call(productId: productId);
      productSizeOptions.assignAll(list);
    } catch (_) {
      productSizeOptions.clear();
    }
    update();
  }

  void addSized() {
    items.add(SizedModel());
    update();
  }

  void removeItem(int index) {
    if (index < 0 || index >= items.length) {
      return;
    }
    items.removeAt(index);
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

  /// حفظ المنتج (إضافة/تعديل) — منفصل عن [isLoading] لقائمة المنتجات حتى لا يبقى زر الحفظ يدور بلا نهاية.
  final RxBool isSubmittingProduct = false.obs;

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
  Future<void> getAllProducts({bool isRefresh = false}) async {
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
  /// Main categories (`get/all/categories`).
  List<ProductModel> mainCategories = [];

  /// All subcategories with optional [ProductModel.mainCategoryId] for filtering.
  List<ProductModel> allSubCategories = [];

  List<ProductModel> projects = [];

  /// Subcategories belonging to [selectedMainCategoryId], for the subcategory dropdown.
  List<ProductModel> getFilteredSubCategories() {
    final mid = selectedMainCategoryId.value;
    if (mid == null || mid.isEmpty) {
      return <ProductModel>[];
    }
    return allSubCategories
        .where((s) => s.mainCategoryId != null && s.mainCategoryId == mid)
        .toList();
  }

  void setMainCategory(String? id) {
    selectedMainCategoryId.value = id;
    syncSelectedSubCategoriesWithMainCategory();
    update();
  }

  /// Drops selected subcategories that are not under the current main category.
  /// If main is unknown, keeps existing sub selections (legacy / incomplete API data).
  void syncSelectedSubCategoriesWithMainCategory() {
    final mid = selectedMainCategoryId.value;
    if (mid == null || mid.isEmpty) {
      update();
      return;
    }
    final allowed = allSubCategories
        .where((s) => s.mainCategoryId == mid)
        .map((s) => s.id)
        .toSet();
    selectedSubCategoryIds.removeWhere((id) => !allowed.contains(id));
    update();
  }

  void getCategories() async {
    mainCategories.assignAll(await getMainCategoriesUsecase.call());
    allSubCategories.assignAll(await getCategoriesUsecase.call(isProject: false));
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
    saveScopeFull.value = false;
    productNameController.clear();
    productDetailsController.clear();
    nameEngController.clear();
    nameAbreeController.clear();
    descriptionEngController.clear();
    descriptionAbreeController.clear();
    subCategoryController.clear();
    selectedMainCategoryId.value = null;
    selectedSubCategoryIds.clear();
    stockController.text = '0';
    minimumStockController.clear();
    wholesalePricesController.clear();
    retailPricesController.clear();
    discountPercentageController.clear();
    selectPurchaseController.clear();
    purchasePriceController.clear();
    manufactureYearController.text = '0';
    modelController.clear();
    rateController.text = '4';
    minSalePriceController.clear();
    listPriceController.clear();
    rotationDateController.clear();
    isShowProduct.value = true;
    isNewItemProduct.value = true;
    isMoreSalesProduct.value = false;
    clearPendingMedia();
    _resetEditMediaState();
    for (final el in items) {
      el.onClose();
    }
    items.clear();
    isForcedSale.value = false;
    loadProductSizeOptions(productId: null);
    update();
  }

  void initProductDetails() {
    final p = productDetails.value!;
    editingProductId.value = p.id;
    saveScopeFull.value = false;
    productNameController.text = p.nameAr;
    productDetailsController.text = p.descriptionAr ?? '';
    nameEngController.text = p.nameEng;
    nameAbreeController.text = p.nameAbree ?? '';
    descriptionEngController.text = p.descriptionEng ?? '';
    descriptionAbreeController.text = p.descriptionAbree ?? '';
    subCategoryController.text =
        p.productSubCategories != null && p.productSubCategories!.isNotEmpty
            ? p.productSubCategories!.first.subCategoryId.toString()
            : '';
    selectedSubCategoryIds.clear();
    selectedMainCategoryId.value = null;
    if (p.productSubCategories != null) {
      for (final s in p.productSubCategories!) {
        final sid = s.subCategoryId;
        if (sid != null && sid.isNotEmpty) {
          selectedSubCategoryIds.add(sid);
        }
      }
      final firstMain = p.productSubCategories!.first.mainCategoryId;
      if (firstMain != null && firstMain.isNotEmpty) {
        selectedMainCategoryId.value = firstMain;
      } else if (selectedSubCategoryIds.isNotEmpty) {
        try {
          final sub = allSubCategories.firstWhere(
            (x) => selectedSubCategoryIds.contains(x.id),
          );
          selectedMainCategoryId.value = sub.mainCategoryId;
        } catch (_) {}
      }
    }
    stockController.text = p.stock?.toString() ?? '0';
    minimumStockController.text = p.minStock?.toString() ?? '';
    retailPricesController.text = p.normailPrice?.toString() ?? '';
    wholesalePricesController.text = p.wholesalePrice?.toString() ?? '';
    purchasePriceController.clear();
    discountPercentageController.text = p.discount?.toString() ?? '0';
    manufactureYearController.text = p.manufactureYear?.toString() ?? '0';
    modelController.text = p.model ?? '';
    rateController.text = p.rate?.toString() ?? '4';
    minSalePriceController.text = p.minSalePrice?.toString() ?? '';
    listPriceController.text = p.price?.toString() ?? '';
    rotationDateController.text = _formatRotationForInput(p.rotationDate);
    isShowProduct.value = _truthyDynamic(p.isShow);
    isNewItemProduct.value = _truthyDynamic(p.isNewItem);
    isMoreSalesProduct.value = _truthyDynamic(p.isMoreSales);
    if (p.projectId != null) {
      selectPurchaseController.text = p.projectId.toString();
    }
    clearPendingMedia();
    _resetEditMediaState();
    existingNormalMedia.assignAll(_mediaItemsForEdit(p.normalImageItems, p.normalImages));
    existingViewMedia.assignAll(_mediaItemsForEdit(p.viewImageItems, p.viewImages));
    existingThreeDMedia.assignAll(_mediaItemsForEdit(p.image3dItems, p.image3d));
    final vu = p.videoUrl?.toString();
    existingVideoUrlForEdit =
        (vu == null || vu.isEmpty || vu == 'null') ? null : vu;

    for (final el in items) {
      el.onClose();
    }
    items.clear();
    final sizesList = p.sizes;
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
          colorModel.colorEnController.text = colorJson.colorEn ?? '';
          colorModel.colorAbbrController.text = colorJson.colorAbbr ?? '';
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
    isForcedSale.value =
        p.isSoldWithPaper == '1' || p.isSoldWithPaper == 1;
    loadProductSizeOptions(productId: p.id);
    update();
  }

  bool _truthyDynamic(dynamic v) {
    if (v == null) {
      return false;
    }
    if (v is bool) {
      return v;
    }
    if (v is int) {
      return v == 1;
    }
    final s = v.toString().trim().toLowerCase();
    return s == '1' || s == 'true';
  }

  String _formatRotationForInput(dynamic rotationDate) {
    if (rotationDate == null) {
      return '';
    }
    if (rotationDate is String) {
      final s = rotationDate.trim();
      if (s.length >= 10) {
        return s.substring(0, 10);
      }
      return s;
    }
    try {
      final dt = rotationDate as DateTime;
      return '${dt.year.toString().padLeft(4, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Future<FormData> _buildProductFormData() async {
    final form = FormData();

    void addField(String key, String value) {
      form.fields.add(MapEntry(key, value));
    }

    addField('nameAr', productNameController.text.trim());
    addField('descriptionAr', productDetailsController.text.trim());
    addField('nameEng', nameEngController.text.trim());
    addField('nameAbree', nameAbreeController.text.trim());
    addField('descriptionEng', descriptionEngController.text.trim());
    addField('descriptionAbree', descriptionAbreeController.text.trim());
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
      'wholesalePrice',
      wholesalePricesController.text.trim().isEmpty
          ? '0'
          : wholesalePricesController.text.trim(),
    );
    addField(
      'min_stock',
      minimumStockController.text.trim().isEmpty
          ? '0'
          : minimumStockController.text.trim(),
    );
    addField('is_sold_with_paper', isForcedSale.value ? '1' : '0');
    addField('save_scope', saveScopeFull.value ? 'full' : 'local_only');
    addField('isShow', isShowProduct.value ? '1' : '0');
    addField('isNewItem', isNewItemProduct.value ? '1' : '0');
    addField('isMoreSales', isMoreSalesProduct.value ? '1' : '0');
    addField(
      'rate',
      rateController.text.trim().isEmpty ? '4' : rateController.text.trim(),
    );
    addField(
      'manufactureYear',
      manufactureYearController.text.trim().isEmpty
          ? '0'
          : manufactureYearController.text.trim(),
    );
    addField('model', modelController.text.trim());
    if (stockController.text.trim().isNotEmpty) {
      addField('stock', stockController.text.trim());
    }
    if (selectPurchaseController.text.trim().isNotEmpty) {
      addField('project_id', selectPurchaseController.text.trim());
    }
    if (minSalePriceController.text.trim().isNotEmpty) {
      addField('min_sale_price', minSalePriceController.text.trim());
    }
    if (listPriceController.text.trim().isNotEmpty) {
      addField('price', listPriceController.text.trim());
    }
    if (rotationDateController.text.trim().isNotEmpty) {
      addField('rotation_date', rotationDateController.text.trim());
    }
    if (editingProductId.value != null) {
      addField('product_id', editingProductId.value!);
      for (final id in pendingDeleteNormalIds) {
        addField('delete_normal_image_ids[]', id);
      }
      for (final id in pendingDeleteViewIds) {
        addField('delete_view_image_ids[]', id);
      }
      for (final id in pendingDeleteThreeDIds) {
        addField('delete_three_d_image_ids[]', id);
      }
      if (pendingDeleteExistingVideo.value) {
        addField('delete_video', '1');
      }
    }

    for (final subId in selectedSubCategoryIds) {
      if (subId.trim().isNotEmpty) {
        form.fields.add(MapEntry('sub_categories[]', subId.trim()));
      }
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
          'sizes[$sizeIndex][color_sizes][$j][colorEn]',
          c.colorEnController.text.trim(),
        );
        addField(
          'sizes[$sizeIndex][color_sizes][$j][colorAbbr]',
          c.colorAbbrController.text.trim(),
        );
        addField(
          'sizes[$sizeIndex][color_sizes][$j][normailPrice]',
          c.priceController.text.trim().isEmpty
              ? '0'
              : c.priceController.text.trim(),
        );
        addField(
          'sizes[$sizeIndex][color_sizes][$j][stock]',
          c.quantityController.text.trim().isEmpty
              ? '0'
              : c.quantityController.text.trim(),
        );
        final cid = c.dbColorId;
        if (cid != null && cid.isNotEmpty && cid != '0') {
          addField('sizes[$sizeIndex][color_sizes][$j][id]', cid);
        }
      }
      sizeIndex++;
    }

    Future<void> appendFiles(
      String fieldName,
      List<XFile> files,
    ) async {
      for (final x in files) {
        final bytes = await x.readAsBytes();
        form.files.add(
          MapEntry(
            fieldName,
            MultipartFile.fromBytes(bytes, filename: x.name),
          ),
        );
      }
    }

    await appendFiles('normal_images[]', pendingNormalImages);
    await appendFiles('view_images[]', pendingViewImages);
    await appendFiles('three_d_images[]', pendingThreeDImages);
    if (pendingVideo != null) {
      final v = pendingVideo!;
      final bytes = await v.readAsBytes();
      form.files.add(
        MapEntry(
          'video',
          MultipartFile.fromBytes(bytes, filename: v.name),
        ),
      );
    }

    return form;
  }

  Future<void> submitProduct() async {
    if (productNameController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'productNameRequired'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (productDetailsController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'productDetailsRequired'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (selectedSubCategoryIds.isNotEmpty) {
      var mid = selectedMainCategoryId.value;
      if (mid == null || mid.isEmpty) {
        try {
          final sub = allSubCategories.firstWhere(
            (x) => selectedSubCategoryIds.contains(x.id),
          );
          if (sub.mainCategoryId != null && sub.mainCategoryId!.isNotEmpty) {
            selectedMainCategoryId.value = sub.mainCategoryId;
            mid = sub.mainCategoryId;
          }
        } catch (_) {}
      }
      if (mid == null || mid.isEmpty) {
        Get.snackbar('error'.tr, 'selectMainCategoryFirst'.tr,
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final allowed = getFilteredSubCategories().map((e) => e.id).toSet();
      for (final id in selectedSubCategoryIds) {
        if (!allowed.contains(id)) {
          Get.snackbar('error'.tr, 'invalidCategoryCombination'.tr,
              snackPosition: SnackPosition.BOTTOM);
          return;
        }
      }
    }

    isSubmittingProduct(true);
    update();
    try {
      final wasEdit = editingProductId.value != null;
      final editedId = editingProductId.value;
      final form = await _buildProductFormData();
      final result = await saveProductFullUsecase.call(
        formData: form,
        isCreate: editingProductId.value == null,
      );
      final msg = result['message']?.toString() ?? 'success'.tr;
      final mediaExtra = result['media_warning'] ?? result['image_warning'];
      final buf = StringBuffer(msg);
      if (mediaExtra != null) {
        buf.writeln();
        buf.writeln(mediaExtra.toString());
      }

      allProducts.clear();
      allClearances.clear();
      allCombinations.clear();
      page = 1;
      await getAllProducts();

      clearPendingMedia();
      _resetEditMediaState();
      editingProductId.value = null;

      currentTab.value = 0;
      update();

      Get.back();
      if (wasEdit && editedId != null) {
        await getProductDetails(productId: editedId);
      }

      final createMessage = buf.toString().trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showSweetSuccessDialog(
          title: 'success'.tr,
          message: wasEdit ? 'productUpdatedSuccess'.tr : createMessage,
          subtitle: null,
        );
      });
    } on ServerFailure catch (e) {
      final details = formatLaravelValidationErrors(
        e.data is Map<String, dynamic>
            ? Map<String, dynamic>.from(e.data as Map)
            : null,
      );
      final text = details.isEmpty ? e.errMessage : '${e.errMessage}\n$details';
      Get.snackbar(
        'validationErrorsTitle'.tr,
        text,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 8),
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmittingProduct(false);
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
    nameEngController.dispose();
    nameAbreeController.dispose();
    descriptionEngController.dispose();
    descriptionAbreeController.dispose();
    manufactureYearController.dispose();
    modelController.dispose();
    rateController.dispose();
    minSalePriceController.dispose();
    listPriceController.dispose();
    rotationDateController.dispose();
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
    for (final c in colors) {
      c.onClose();
    }
  }
}

class ColorModel {
  final TextEditingController colorController = TextEditingController();
  final TextEditingController colorEnController = TextEditingController();
  final TextEditingController colorAbbrController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String? dbColorId;

  void onClose() {
    colorController.dispose();
    colorEnController.dispose();
    colorAbbrController.dispose();
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
