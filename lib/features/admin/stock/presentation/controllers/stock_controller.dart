import 'dart:io';

import 'package:dio/dio.dart';
import '../../../../../core/helpers/app_navigation.dart';
import '../../../../../core/helpers/sweet_success_dialog.dart';
import 'package:doctorbike/routes/app_routes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../core/helpers/server_validation_messages.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../sales/data/models/product_model.dart';
import '../../data/datasources/stock_datasource.dart';
import '../../data/models/all_stock_products_model.dart';
import '../../data/models/product_details_model.dart';
import '../../data/models/stock_products_page_result.dart';
import '../../data/models/product_stock_movement_model.dart';
import '../../data/models/store_section_model.dart';
import '../../domain/product_location_utils.dart';
import '../../domain/stock_location_interactor.dart';
import '../utils/stock_search_history_storage.dart';
import '../../domain/stock_product_filters.dart';
import '../widgets/product_location_action_sheet.dart';
import '../widgets/product_location_confirm_screen.dart';
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
import 'offer_packages_controller.dart';

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
  final StockLocationInteractor stockLocationInteractor;
  final StockDatasource stockDatasource;

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
    required this.stockLocationInteractor,
    required this.stockDatasource,
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
  final TextEditingController descriptionEngController =
      TextEditingController();
  final TextEditingController descriptionAbreeController =
      TextEditingController();
  final TextEditingController manufactureYearController =
      TextEditingController();
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

  /// Main category from API `category_id` (required on save); subcategories are optional.
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
  final RxBool isProductsCsvBusy = false.obs;

  final tabs = [
    'products',
    'clearance',
    'productComposition',
    'storeLocationTab',
    'offerPackages',
  ].obs;

  final currentTab = 0.obs;

  void changeTab(int index) {
    if (index != currentTab.value) {
      exitLocationSelection();
    }
    currentTab.value = index;
    if (index == 3) {
      Future<void>(() async => ensureStoreSectionsLoaded());
      if (selectedLocationSectionId.value != null) {
        Future<void>(() async => selectLocationFilter(
              selectedLocationSectionId.value,
            ));
      }
    } else if (index == 4) {
      if (Get.isRegistered<OfferPackagesController>()) {
        final packagesCtrl = Get.find<OfferPackagesController>();
        if (packagesCtrl.packages.isEmpty) {
          Future<void>(() async => packagesCtrl.loadPackages());
        }
      }
    } else {
      final needsLoad = (index == 0 && allProducts.isEmpty) ||
          (index == 1 && allClearances.isEmpty) ||
          (index == 2 && allCombinations.isEmpty);
      if (needsLoad) {
        _resetPaginationForCurrentTab();
        Future<void>(() async => getAllProducts());
      }
    }
    update();
  }

  final RxList<StoreSectionModel> storeSections = <StoreSectionModel>[].obs;
  final RxnString selectedProductStoreSectionId = RxnString();
  final RxList<AllStockProductsModel> locationFilterProducts =
      <AllStockProductsModel>[].obs;
  final RxnString selectedLocationSectionId = RxnString();
  final RxInt locationFilterTotalCount = 0.obs;
  final RxInt productListTotalCount = 0.obs;
  final RxBool locationProductsLoadingMore = false.obs;
  int locationProductsPage = 1;
  int locationProductsLastPage = 1;

  final RxBool locationSelectionActive = false.obs;
  final RxList<String> selectedProductIds = <String>[].obs;
  final RxList<String> swapGroupAIds = <String>[].obs;
  final RxList<String> swapGroupBIds = <String>[].obs;
  final RxBool pickingSwapGroupB = false.obs;
  final RxBool isLocationActionBusy = false.obs;

  bool get canPickProductLocation =>
      currentTab.value == 0 || currentTab.value == 3;

  bool get canExecuteSwap =>
      swapGroupAIds.isNotEmpty && swapGroupBIds.isNotEmpty;

  bool isProductSelected(String productId) =>
      swapGroupAIds.contains(productId) ||
      swapGroupBIds.contains(productId);

  bool isProductInSwapGroupA(String productId) =>
      swapGroupAIds.contains(productId);

  bool isProductInSwapGroupB(String productId) =>
      swapGroupBIds.contains(productId);

  void _syncSelectedProductIds() {
    selectedProductIds.assignAll([...swapGroupAIds, ...swapGroupBIds]);
  }

  void toggleProductSelection(String productId) {
    if (swapGroupAIds.contains(productId)) {
      swapGroupAIds.remove(productId);
      _syncSelectedProductIds();
      if (selectedProductIds.isEmpty) {
        exitLocationSelection();
      }
      return;
    }
    if (swapGroupBIds.contains(productId)) {
      swapGroupBIds.remove(productId);
      _syncSelectedProductIds();
      if (selectedProductIds.isEmpty) {
        exitLocationSelection();
      }
      return;
    }
    locationSelectionActive.value = true;
    if (pickingSwapGroupB.value) {
      swapGroupBIds.add(productId);
    } else {
      swapGroupAIds.add(productId);
    }
    _syncSelectedProductIds();
  }

  void startLocationSelection(String productId) {
    if (!canPickProductLocation) return;
    locationSelectionActive.value = true;
    if (!isProductSelected(productId)) {
      swapGroupAIds.add(productId);
      _syncSelectedProductIds();
    }
  }

  void startSwapGroupBPicking() {
    pickingSwapGroupB.value = true;
  }

  void exitLocationSelection() {
    locationSelectionActive.value = false;
    selectedProductIds.clear();
    swapGroupAIds.clear();
    swapGroupBIds.clear();
    pickingSwapGroupB.value = false;
  }

  Future<void> showLocationActionSheetForProduct(
    BuildContext context,
    AllStockProductsModel product,
  ) async {
    if (!canPickProductLocation) return;
    startLocationSelection(product.productId);
    final action = await showProductLocationActionSheet(context);
    if (!context.mounted) return;
    if (action == null) {
      Get.snackbar(
        'locationMultiSelectHintTitle'.tr,
        'locationMultiSelectHint'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.secondaryColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    if (action == ProductLocationAction.move) {
      await openMoveSelectedDialog(context);
    } else if (action == ProductLocationAction.swap) {
      if (swapGroupAIds.isEmpty) return;
      startSwapGroupBPicking();
      Get.snackbar(
        'swapProductLocation'.tr,
        'swapPickGroupB'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.secondaryColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  List<AllStockProductsModel> _productsByIds(List<String> ids) {
    final byId = <String, AllStockProductsModel>{};
    for (final p in allProducts) {
      byId[p.productId] = p;
    }
    for (final p in locationFilterProducts) {
      byId[p.productId] = p;
    }
    return ids.map((id) => byId[id]).whereType<AllStockProductsModel>().toList();
  }

  List<AllStockProductsModel> getSelectedProductsList() =>
      _productsByIds(selectedProductIds);

  String _sectionNameById(String sectionId) {
    for (final s in storeSections) {
      if (s.id == sectionId) return s.name;
    }
    return sectionId;
  }

  Future<void> openMoveSelectedDialog(BuildContext context) async {
    if (selectedProductIds.isEmpty) return;
    await ensureStoreSectionsLoaded();
    if (!context.mounted) return;
    final activeSections =
        storeSections.where((s) => s.isActive).toList(growable: false);
    if (activeSections.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'noData'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    final picked = await showProductLocationMoveDialog(
      context: context,
      sections: activeSections,
    );
    if (!context.mounted || picked == null) return;
    final products = getSelectedProductsList();
    final confirmed = await showProductLocationMoveConfirm(
      context,
      products: products,
      targetSectionName: _sectionNameById(picked.sectionId),
    );
    if (!context.mounted || !confirmed) return;
    await executeMoveSelectedProducts(sectionId: picked.sectionId);
  }

  Future<void> executeMoveSelectedProducts({
    required String sectionId,
  }) async {
    if (selectedProductIds.isEmpty) return;
    final ids = selectedProductIds
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toList();
    if (ids.isEmpty) return;
    try {
      isLocationActionBusy.value = true;
      await stockLocationInteractor.moveProducts(
        productIds: ids,
        sectionId: sectionId,
      );
      Get.snackbar(
        'success'.tr,
        'productsLocationMoved'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      exitLocationSelection();
      await refreshAfterStoreSectionsChanged();
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLocationActionBusy.value = false;
    }
  }

  Future<void> executeSwapSelectedProducts({BuildContext? context}) async {
    if (!canExecuteSwap) {
      Get.snackbar(
        'error'.tr,
        'swapNeedsTwoGroups'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    final idsA = swapGroupAIds
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toList();
    final idsB = swapGroupBIds
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toList();
    if (idsA.isEmpty || idsB.isEmpty) return;

    final ctx = context ?? Get.context;
    if (ctx == null) return;
    final groupA = _productsByIds(swapGroupAIds);
    final groupB = _productsByIds(swapGroupBIds);
    await ensureStoreSectionsLoaded();
    if (!ctx.mounted) return;
    final activeSections =
        storeSections.where((s) => s.isActive).toList(growable: false);
    if (activeSections.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'noData'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    final swapTargets = await showSwapGroupTargetsDialog(
      context: ctx,
      sections: activeSections,
    );
    if (!ctx.mounted ||
        swapTargets == null ||
        swapTargets.groupA == null ||
        swapTargets.groupB == null) {
      return;
    }

    final confirmed = await showProductLocationSwapConfirm(
      ctx,
      groupA: groupA,
      groupB: groupB,
      targets: swapTargets,
    );
    if (!ctx.mounted || !confirmed) return;

    try {
      isLocationActionBusy.value = true;
      await stockLocationInteractor.swapProductGroups(
        groupA: idsA,
        groupB: idsB,
        groupATarget: swapTargets.groupA!,
        groupBTarget: swapTargets.groupB!,
      );
      Get.snackbar(
        'success'.tr,
        'productsLocationSwapped'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      exitLocationSelection();
      await refreshAfterStoreSectionsChanged();
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLocationActionBusy.value = false;
    }
  }

  String? get selectedProductSectionName {
    final id = selectedProductStoreSectionId.value;
    if (id == null || id.isEmpty) return null;
    for (final s in storeSections) {
      if (s.id == id) return s.name;
    }
    return null;
  }

  Future<void> refreshStoreSections() async {
    try {
      final list =
          await stockLocationInteractor.loadSections(includeInactive: true);
      storeSections.assignAll(list);
      update();
    } catch (_) {}
  }

  /// Reload sections, product list, and location tab after section CRUD.
  Future<void> refreshAfterStoreSectionsChanged() async {
    final filterSectionId = productListFilters.value.storeSectionId;
    final locationSectionId = selectedLocationSectionId.value;
    final editSectionId = selectedProductStoreSectionId.value;

    await refreshStoreSections();

    final sectionIds = storeSections.map((s) => s.id).toSet();

    if (editSectionId != null && !sectionIds.contains(editSectionId)) {
      selectedProductStoreSectionId.value = null;
      final p = productDetails.value;
      if (p != null) {
        p.storeSectionId = null;
        p.storeSectionName = null;
        productDetails.refresh();
      }
    } else if (editSectionId != null) {
      final p = productDetails.value;
      if (p != null) {
        p.storeSectionName = selectedProductSectionName;
        productDetails.refresh();
      }
    }

    if (filterSectionId != null &&
        !isUnassignedStoreSectionFilter(filterSectionId) &&
        !sectionIds.contains(filterSectionId)) {
      productListFilters.value = productListFilters.value.copyWith(
        clearStoreSectionId: true,
      );
      selectedLocationSectionId.value = null;
    }

    await reloadProductsList();

    if (locationSectionId != null &&
        !isUnassignedStoreSectionFilter(locationSectionId) &&
        !sectionIds.contains(locationSectionId)) {
      selectedLocationSectionId.value = null;
      locationFilterProducts.clear();
    } else if (selectedLocationSectionId.value != null) {
      await selectLocationFilter(selectedLocationSectionId.value);
    }

    update();
  }

  Future<void> reloadProductsList() async {
    _productsPage = 1;
    _hasMoreProducts = true;
    allProducts.clear();
    final filters = productListFilters.value.hasActiveFilters
        ? productListFilters.value
        : null;
    final showLoader = currentTab.value == 0;
    try {
      if (showLoader) {
        isLoading(true);
        update();
      }
      final result = await getAllStockUsecase.call(
        page: 1,
        ifCombinations: false,
        ifCloseouts: false,
        filters: filters,
      );
      _mergeStockItems(allProducts, result.products);
      productListTotalCount.value =
          filters != null ? result.total : 0;
      _productsPage = 2;
      _hasMoreProducts = result.currentPage < result.lastPage;
    } on ServerFailure {
      // Snackbar already shown in StockImplement.
    } on NoConnectionFailure catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (showLoader) {
        isLoading(false);
      }
      update();
    }
  }

  Future<void> ensureStoreSectionsLoaded() async {
    if (storeSections.isEmpty) {
      await refreshStoreSections();
    }
  }

  Future<void> selectLocationFilter(String? sectionId) async {
    selectedLocationSectionId.value = sectionId;
    locationFilterProducts.clear();
    locationFilterTotalCount.value = 0;
    locationProductsPage = 1;
    locationProductsLastPage = 1;
    if (sectionId == null || sectionId.isEmpty) {
      update();
      return;
    }
    isLoading(true);
    update();
    try {
      final res = await stockLocationInteractor.loadProductsByLocation(
        sectionId: sectionId,
        page: 1,
      );
      locationFilterProducts.assignAll(res.products);
      locationProductsPage = res.currentPage;
      locationProductsLastPage = res.lastPage;
      locationFilterTotalCount.value = res.total;
    } catch (_) {
      locationFilterProducts.clear();
      locationFilterTotalCount.value = 0;
    } finally {
      isLoading(false);
      update();
    }
  }

  Future<void> loadMoreLocationFilterProducts() async {
    final sectionId = selectedLocationSectionId.value;
    if (sectionId == null ||
        sectionId.isEmpty ||
        locationProductsLoadingMore.value) {
      return;
    }
    if (locationProductsPage >= locationProductsLastPage) {
      return;
    }
    locationProductsLoadingMore.value = true;
    update();
    try {
      final next = locationProductsPage + 1;
      final res = await stockLocationInteractor.loadProductsByLocation(
        sectionId: sectionId,
        page: next,
      );
      for (final p in res.products) {
        if (!locationFilterProducts.any((x) => x.productId == p.productId)) {
          locationFilterProducts.add(p);
        }
      }
      locationProductsPage = res.currentPage;
      locationProductsLastPage = res.lastPage;
    } catch (_) {
    } finally {
      locationProductsLoadingMore.value = false;
      update();
    }
  }

  void setProductStoreSection(String? sectionId) {
    selectedProductStoreSectionId.value = sectionId;
    update();
  }

  Future<void> createStoreSection({required String name}) async {
    final section = await stockLocationInteractor.createSection(name: name);
    storeSections.add(section);
    selectedProductStoreSectionId.value = section.id;
    update();
  }

  Future<void> deactivateStoreSection(String id) async {
    await stockLocationInteractor.deactivateSection(id);
    await refreshAfterStoreSectionsChanged();
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
      selectedSubCategoryIds.remove(id);
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
    if (existingVideoUrlForEdit != null &&
        existingVideoUrlForEdit!.isNotEmpty) {
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
          TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('cancel'.tr)),
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
          TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('cancel'.tr)),
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
          TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('cancel'.tr)),
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
          TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('cancel'.tr)),
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

  void addEmptySizeColorRow() {
    final sz = SizedModel();
    sz.colors.add(ColorModel());
    items.add(sz);
    update();
  }

  Future<void> pickSizeColorImage(int sizeIdx, int colorIdx) async {
    if (sizeIdx < 0 || sizeIdx >= items.length) return;
    final colors = items[sizeIdx].colors;
    if (colorIdx < 0 || colorIdx >= colors.length) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    colors[colorIdx].pendingImage = picked;
    update();
  }

  void clearSizeColorImage(int sizeIdx, int colorIdx) {
    if (sizeIdx < 0 || sizeIdx >= items.length) return;
    final colors = items[sizeIdx].colors;
    if (colorIdx < 0 || colorIdx >= colors.length) return;
    colors[colorIdx].pendingImage = null;
    colors[colorIdx].existingImageUrl = null;
    colors[colorIdx].clearImage = true;
    update();
  }

  /// Add a new color entry under an existing or new size block.
  void addSizeColorEntry({
    required String size,
    required String colorAr,
    required String colorEn,
    required String colorAbbr,
    required String qty,
    required String price,
    String wholesalePrice = '',
    String discount = '',
  }) {
    SizedModel? existingSized;
    for (final s in items) {
      if (s.sizeController.text.trim() == size.trim()) {
        existingSized = s;
        break;
      }
    }
    final c = ColorModel();
    c.colorController.text = colorAr;
    c.colorEnController.text = colorEn;
    c.colorAbbrController.text = colorAbbr;
    c.quantityController.text = qty;
    c.priceController.text = price;
    c.wholesalePriceController.text = wholesalePrice;
    c.discountController.text = discount;

    if (existingSized != null) {
      existingSized.colors.add(c);
    } else {
      final newSized = SizedModel();
      newSized.sizeController.text = size;
      newSized.colors.clear();
      newSized.colors.add(c);
      items.add(newSized);
    }
    update();
  }

  /// Update an existing color entry (by size/color index).
  void updateSizeColorEntry({
    required int sizeIdx,
    required int colorIdx,
    required String size,
    required String colorAr,
    required String colorEn,
    required String colorAbbr,
    required String qty,
    required String price,
    String wholesalePrice = '',
    String discount = '',
  }) {
    if (sizeIdx < 0 || sizeIdx >= items.length) return;
    final sz = items[sizeIdx];
    sz.sizeController.text = size;
    if (colorIdx < 0 || colorIdx >= sz.colors.length) return;
    final c = sz.colors[colorIdx];
    c.colorController.text = colorAr;
    c.colorEnController.text = colorEn;
    c.colorAbbrController.text = colorAbbr;
    c.quantityController.text = qty;
    c.priceController.text = price;
    c.wholesalePriceController.text = wholesalePrice;
    c.discountController.text = discount;
    update();
  }

  /// Remove a color entry; removes its parent size block if it was the last color.
  void removeSizeColorEntry(int sizeIdx, int colorIdx) {
    if (sizeIdx < 0 || sizeIdx >= items.length) return;
    final sz = items[sizeIdx];
    if (colorIdx < 0 || colorIdx >= sz.colors.length) return;
    sz.colors[colorIdx].onClose();
    sz.colors.removeAt(colorIdx);
    if (sz.colors.isEmpty) {
      sz.onClose();
      items.removeAt(sizeIdx);
    }
    update();
  }

  int get productStockTotal {
    final v = int.tryParse(stockController.text.trim());
    return v == null || v < 0 ? 0 : v;
  }

  int totalSizeColorQuantity({
    int? excludeSizeIdx,
    int? excludeColorIdx,
  }) {
    var sum = 0;
    for (var i = 0; i < items.length; i++) {
      final sz = items[i];
      for (var j = 0; j < sz.colors.length; j++) {
        if (excludeSizeIdx == i && excludeColorIdx == j) {
          continue;
        }
        final q = int.tryParse(sz.colors[j].quantityController.text.trim());
        if (q != null && q > 0) {
          sum += q;
        }
      }
    }
    return sum;
  }

  /// Returns localized error message key suffix or null if valid.
  String? validateSizeColorQuantity(
    String qty, {
    int? excludeSizeIdx,
    int? excludeColorIdx,
  }) {
    final parsed = int.tryParse(qty.trim());
    if (parsed == null || parsed < 0) {
      return 'sizeColorQtyInvalid';
    }
    final stock = productStockTotal;
    if (parsed > stock) {
      return 'sizeColorQtyExceedsStock';
    }
    final others = totalSizeColorQuantity(
      excludeSizeIdx: excludeSizeIdx,
      excludeColorIdx: excludeColorIdx,
    );
    if (others + parsed > stock) {
      return 'sizeColorTotalExceedsStock';
    }
    return null;
  }

  String? validateAllSizeColorQuantities() {
    if (items.isEmpty) {
      return null;
    }
    final stock = productStockTotal;
    final total = totalSizeColorQuantity();
    if (total > stock) {
      return 'sizeColorTotalExceedsStock';
    }
    for (var i = 0; i < items.length; i++) {
      for (var j = 0; j < items[i].colors.length; j++) {
        final q = items[i].colors[j].quantityController.text.trim();
        final err = validateSizeColorQuantity(
          q,
          excludeSizeIdx: i,
          excludeColorIdx: j,
        );
        if (err != null) {
          return err;
        }
      }
    }
    return null;
  }

  /// Flat list of size+color entries for table display.
  List<SizeColorEntry> get flatSizeColorEntries {
    final result = <SizeColorEntry>[];
    for (var i = 0; i < items.length; i++) {
      final sz = items[i];
      for (var j = 0; j < sz.colors.length; j++) {
        result.add(SizeColorEntry(
          sizeIdx: i,
          colorIdx: j,
          size: sz.sizeController.text,
          color: sz.colors[j],
        ));
      }
    }
    return result;
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
  final RxBool isSearchLoading = false.obs;
  final TextEditingController stockSearchQueryController = TextEditingController();
  final RxString stockSearchActiveQuery = ''.obs;
  final RxList<String> stockSearchHistory = <String>[].obs;

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
    if (!scrollController.hasClients) {
      return;
    }
    if (currentTab.value == 3 || currentTab.value == 4) {
      if (currentTab.value == 3 &&
          scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 120) {
        Future<void>(() async => loadMoreLocationFilterProducts());
      }
      return;
    }
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 1) {
      if (!isLoading.value && !isLoadingMore.value && _hasMoreForCurrentTab) {
        Future<void>(() async => getAllProducts(isRefresh: true));
      }
    }
  }

  final Rx<StockProductFilters> productListFilters =
      StockProductFilters.empty.obs;

  final RxList<AllStockProductsModel> allProducts =
      <AllStockProductsModel>[].obs;

  final RxList<AllStockProductsModel> allClearances =
      <AllStockProductsModel>[].obs;

  final RxList<AllStockProductsModel> allCombinations =
      <AllStockProductsModel>[].obs;
  int _productsPage = 1;
  int _clearancesPage = 1;
  int _combinationsPage = 1;
  bool _hasMoreProducts = true;
  bool _hasMoreClearances = true;
  bool _hasMoreCombinations = true;

  int get page {
    switch (currentTab.value) {
      case 1:
        return _clearancesPage;
      case 2:
        return _combinationsPage;
      default:
        return _productsPage;
    }
  }

  set page(int value) {
    switch (currentTab.value) {
      case 1:
        _clearancesPage = value;
        break;
      case 2:
        _combinationsPage = value;
        break;
      default:
        _productsPage = value;
        break;
    }
  }

  bool get _hasMoreForCurrentTab {
    switch (currentTab.value) {
      case 1:
        return _hasMoreClearances;
      case 2:
        return _hasMoreCombinations;
      default:
        return _hasMoreProducts;
    }
  }

  set _hasMoreForCurrentTab(bool value) {
    switch (currentTab.value) {
      case 1:
        _hasMoreClearances = value;
        break;
      case 2:
        _hasMoreCombinations = value;
        break;
      default:
        _hasMoreProducts = value;
        break;
    }
  }

  void _resetPaginationForCurrentTab() {
    page = 1;
    _hasMoreForCurrentTab = true;
  }

  Future<void> applyProductFilters(StockProductFilters filters) async {
    productListFilters.value = filters;
    _resetPaginationForCurrentTab();
    allProducts.clear();
    await getAllProducts();
  }

  Future<void> clearProductFilters() async {
    productListFilters.value = StockProductFilters.empty;
    productListTotalCount.value = 0;
    _resetPaginationForCurrentTab();
    allProducts.clear();
    await getAllProducts();
  }

  Future<void> applyStoreLocationFilterFromFab({
    String? sectionId,
  }) async {
    if (currentTab.value != 0) {
      currentTab.value = 0;
    }
    final base = productListFilters.value;
    final filters = StockProductFilters(
      search: base.search,
      categoryId: base.categoryId,
      subCategoryId: base.subCategoryId,
      storeSectionId: sectionId,
      dateFrom: base.dateFrom,
      dateTo: base.dateTo,
      sortBy: base.sortBy,
      sortDirection: base.sortDirection,
    );
    selectedLocationSectionId.value = sectionId;
    await applyProductFilters(filters);
  }

  Future<void> clearStoreLocationFilterFromFab() async {
    final base = productListFilters.value;
    selectedLocationSectionId.value = null;
    await applyProductFilters(
      StockProductFilters(
        search: base.search,
        categoryId: base.categoryId,
        subCategoryId: base.subCategoryId,
        dateFrom: base.dateFrom,
        dateTo: base.dateTo,
        sortBy: base.sortBy,
        sortDirection: base.sortDirection,
      ),
    );
  }

  Future<void> pullToRefresh() async {
    _resetPaginationForCurrentTab();
    if (currentTab.value == 4) {
      if (Get.isRegistered<OfferPackagesController>()) {
        await Get.find<OfferPackagesController>().pullToRefresh();
      }
      return;
    }
    if (currentTab.value == 3) {
      await ensureStoreSectionsLoaded();
      if (selectedLocationSectionId.value != null) {
        await selectLocationFilter(selectedLocationSectionId.value);
      }
      return;
    }
    if (currentTab.value == 0) {
      allProducts.clear();
    } else if (currentTab.value == 1) {
      allClearances.clear();
    } else if (currentTab.value == 2) {
      allCombinations.clear();
    }
    await getAllProducts();
  }

  Future<void> exportProductsCsv() async {
    if (isProductsCsvBusy.value) {
      return;
    }

    try {
      isProductsCsvBusy(true);
      final bytes = await stockDatasource.exportProductsCsv();
      final dir = await _productsCsvExportDirectory();
      final file = File('${dir.path}/${_productsCsvFileName()}');
      await file.writeAsBytes(bytes, flush: true);
      Get.snackbar(
        'success'.tr,
        '${'productsExported'.tr}\n${file.path}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      await OpenFilex.open(file.path);
    } on ServerException catch (e) {
      _showProductsCsvError(e.errorModel.errorMessage);
    } catch (e) {
      _showProductsCsvError(e.toString());
    } finally {
      isProductsCsvBusy(false);
    }
  }

  Future<void> importProductsCsv() async {
    if (isProductsCsvBusy.value) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }

    try {
      isProductsCsvBusy(true);
      final preview = await stockDatasource.previewImportProductsCsv(path);
      final confirmed = await _confirmProductsCsvImport(preview);
      if (!confirmed) {
        return;
      }

      final response = await stockDatasource.importProductsCsv(path);
      final updated = response['updated']?.toString() ?? '0';
      final errors = response['errors'];
      final errorsCount = errors is List ? errors.length : 0;
      final message = errorsCount > 0
          ? '${'productsImported'.tr}: $updated - ${'productsImportErrors'.tr}: $errorsCount'
          : '${'productsImported'.tr}: $updated';

      _resetPaginationForCurrentTab();
      allProducts.clear();
      await getAllProducts();

      Get.snackbar(
        'success'.tr,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on ServerException catch (e) {
      _showProductsCsvError(e.errorModel.errorMessage);
    } catch (e) {
      _showProductsCsvError(e.toString());
    } finally {
      isProductsCsvBusy(false);
    }
  }

  Future<bool> _confirmProductsCsvImport(Map<String, dynamic> preview) async {
    final changesRaw = preview['changes'];
    final errorsRaw = preview['errors'];
    final changes = changesRaw is List ? changesRaw : const [];
    final errors = errorsRaw is List ? errorsRaw : const [];

    if (changes.isEmpty) {
      Get.snackbar(
        'success'.tr,
        'productsImportNoChanges'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return false;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('productsImportPreviewTitle'.tr),
        content: SizedBox(
          width: Get.width * 0.92,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: Get.height * 0.65),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'productsImportPreviewMessage'.trParams({
                    'count': changes.length.toString(),
                  }),
                ),
                const SizedBox(height: 12),
                ...changes.map((item) {
                  final map = item is Map ? item : const {};
                  final fieldsRaw = map['fields'];
                  final fields = fieldsRaw is List ? fieldsRaw : const [];
                  final isCreate = map['operation']?.toString() == 'create';
                  final title = isCreate
                      ? '${'newProduct'.tr}: ${map['product_name'] ?? ''}'
                      : '${map['product_name'] ?? ''} #${map['product_id'] ?? ''}';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...fields.map((field) {
                            final fieldMap = field is Map ? field : const {};
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '${fieldMap['label'] ?? ''}: ${fieldMap['old'] ?? ''} -> ${fieldMap['new'] ?? ''}',
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }),
                if (errors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${'productsImportErrors'.tr}: ${errors.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ...errors.take(5).map((e) => Text(e.toString())),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('confirm'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return confirmed == true;
  }

  String _productsCsvFileName() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');

    return 'products_${now.year}-${two(now.month)}-${two(now.day)}_${two(now.hour)}-${two(now.minute)}.csv';
  }

  Future<Directory> _productsCsvExportDirectory() async {
    if (Platform.isAndroid) {
      final downloadsDir =
          Directory('/storage/emulated/0/Download/Doctor Bike/Products');
      try {
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir;
      } catch (_) {
        // Some Android versions block direct writes to public Downloads.
      }
    }

    final appDir = await getApplicationDocumentsDirectory();
    final fallbackDir = Directory('${appDir.path}/Doctor Bike/Products');
    if (!await fallbackDir.exists()) {
      await fallbackDir.create(recursive: true);
    }
    return fallbackDir;
  }

  void _showProductsCsvError(String message) {
    Get.snackbar(
      'error'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void _mergeStockItems(
    RxList<AllStockProductsModel> target,
    List<AllStockProductsModel> incoming,
  ) {
    for (final product in incoming) {
      if (!target.any((p) => p.productId == product.productId)) {
        target.add(product);
      }
    }
  }

  Future<StockProductsPageResult> _fetchStockForCurrentTab() {
    final tab = currentTab.value;
    final filters = tab == 0 && productListFilters.value.hasActiveFilters
        ? productListFilters.value
        : null;
    if (tab == 1) {
      return getAllStockUsecase.call(
        page: page,
        ifCombinations: false,
        ifCloseouts: true,
      );
    }
    if (tab == 2) {
      return getAllStockUsecase.call(
        page: page,
        ifCombinations: true,
        ifCloseouts: false,
      );
    }
    return getAllStockUsecase.call(
      page: page,
      ifCombinations: false,
      ifCloseouts: false,
      filters: filters,
    );
  }

  // Get stock list for the active tab only (avoids 3× API calls and rate limits).
  Future<void> getAllProducts({bool isRefresh = false}) async {
    final tab = currentTab.value;
    if (tab == 3 || tab == 4) {
      isLoading(false);
      isLoadingMore(false);
      return;
    }
    if (isLoading.value || isLoadingMore.value) {
      return;
    }
    if (isRefresh && !_hasMoreForCurrentTab) {
      return;
    }

    final listEmpty = tab == 0
        ? allProducts.isEmpty
        : tab == 1
            ? allClearances.isEmpty
            : allCombinations.isEmpty;

    try {
      if (isRefresh) {
        isLoadingMore(true);
      } else if (listEmpty) {
        isLoading(true);
      }

      final result = await _fetchStockForCurrentTab();
      if (tab != currentTab.value) {
        return;
      }
      if (result.products.isEmpty) {
        _hasMoreForCurrentTab = false;
        if (tab == 0 && page == 1) {
          productListTotalCount.value =
              productListFilters.value.hasActiveFilters ? result.total : 0;
        }
        return;
      }
      if (tab == 0) {
        if (page == 1) {
          productListTotalCount.value =
              productListFilters.value.hasActiveFilters ? result.total : 0;
        }
        _mergeStockItems(allProducts, result.products);
        _hasMoreForCurrentTab = result.currentPage < result.lastPage;
      } else if (tab == 1) {
        _mergeStockItems(allClearances, result.products);
        _hasMoreForCurrentTab = result.currentPage < result.lastPage;
      } else {
        _mergeStockItems(allCombinations, result.products);
        _hasMoreForCurrentTab = result.currentPage < result.lastPage;
      }
      page++;
    } on ServerFailure {
      // Snackbar already shown in StockImplement.
    } on NoConnectionFailure catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingMore(false);
      isLoading(false);
      update();
    }
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

  Future<bool> adjustProductStock({
    required String productId,
    String? sizeColorId,
    required int quantity,
    String? note,
  }) async {
    try {
      await stockDatasource.adjustProductStock(
        productId: productId,
        sizeColorId: sizeColorId,
        quantity: quantity,
        note: note,
      );
      await getProductDetails(productId: productId);
      Get.snackbar(
        'success'.tr,
        'productUpdatedSuccess'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.secondaryColor,
        colorText: Colors.white,
      );
      return true;
    } on ServerException catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errorModel.errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.redColor,
        colorText: Colors.white,
      );
      return false;
    } catch (_) {
      Get.snackbar(
        'error'.tr,
        'somethingWrong'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.redColor,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<StockMovementsPageResult?> loadStockMovements({
    required String productId,
    int page = 1,
    int perPage = 50,
    String? dateFrom,
    String? dateTo,
    String? type,
  }) async {
    try {
      return await stockDatasource.getProductStockMovements(
        productId: productId,
        page: page,
        perPage: perPage,
        dateFrom: dateFrom,
        dateTo: dateTo,
        type: type,
      );
    } on ServerException catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errorModel.errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.redColor,
        colorText: Colors.white,
      );
      return null;
    } catch (_) {
      Get.snackbar(
        'error'.tr,
        'somethingWrong'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.redColor,
        colorText: Colors.white,
      );
      return null;
    }
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

  void loadStockSearchHistory() {
    stockSearchHistory.assignAll(StockSearchHistoryStorage.load());
  }

  Future<void> _persistStockSearchHistory() {
    return StockSearchHistoryStorage.save(stockSearchHistory.toList());
  }

  void addStockSearchHistory(String query) {
    final trimmed = query.trim();
    if (trimmed.length < StockSearchHistoryStorage.minQueryLength) return;

    stockSearchHistory.remove(trimmed);
    stockSearchHistory.insert(0, trimmed);
    while (stockSearchHistory.length > StockSearchHistoryStorage.maxItems) {
      stockSearchHistory.removeLast();
    }
    _persistStockSearchHistory();
  }

  void removeStockSearchHistoryItem(String query) {
    stockSearchHistory.remove(query.trim());
    _persistStockSearchHistory();
  }

  void clearStockSearchHistory() {
    stockSearchHistory.clear();
    _persistStockSearchHistory();
  }

  void applyStockSearchHistory(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    stockSearchQueryController.text = trimmed;
    stockSearchQueryController.selection = TextSelection.collapsed(
      offset: trimmed.length,
    );
    stockSearchActiveQuery.value = trimmed;
    getSearchProducts(name: trimmed);
  }

  void onStockSearchQueryChanged(String value) {
    stockSearchActiveQuery.value = value;
    if (value.trim().isEmpty) {
      searchProducts.clear();
      update();
    }
  }

  void getSearchProducts({required String name}) async {
    searchProducts.clear();

    isSearchLoading(true);
    searchProducts.clear();

    final result = await searchProductsUsecase.call(name: name);
    searchProducts.assignAll(result);
    addStockSearchHistory(name);
    isSearchLoading(false);
    update();
  }

  // get categories & projects
  /// Main categories (`get/all/categories`).
  List<ProductModel> mainCategories = [];

  /// All subcategories with optional [ProductModel.mainCategoryId] for filtering.
  List<ProductModel> allSubCategories = [];

  List<ProductModel> projects = [];

  /// Subcategories for the multi-select: filtered by main when set; otherwise
  /// only already-selected subs (e.g. edit with multiple mains) so chips stay visible.
  List<ProductModel> getFilteredSubCategories() {
    final mid = selectedMainCategoryId.value;
    if (mid == null || mid.isEmpty) {
      if (selectedSubCategoryIds.isNotEmpty) {
        final selectedSet = selectedSubCategoryIds.toSet();
        return allSubCategories
            .where((s) => selectedSet.contains(s.id))
            .toList();
      }
      return <ProductModel>[];
    }
    return allSubCategories
        .where((s) => s.mainCategoryId != null && s.mainCategoryId == mid)
        .toList();
  }

  void setMainCategory(String? id) {
    final nextTrim = id?.trim();
    final prev = selectedMainCategoryId.value?.trim();
    final prevNonEmpty = prev != null && prev.isNotEmpty;
    final nextIsEmpty = nextTrim == null || nextTrim.isEmpty;
    selectedMainCategoryId.value = nextIsEmpty ? null : nextTrim;
    if (nextIsEmpty) {
      selectedSubCategoryIds.clear();
    } else if (prevNonEmpty && prev != nextTrim) {
      // Switched main category: remove old sub selections (they belonged to the previous main).
      selectedSubCategoryIds.clear();
    } else {
      syncSelectedSubCategoriesWithMainCategory();
    }
    _syncSubCategoryControllerText();
    update();
  }

  void _syncSubCategoryControllerText() {
    if (selectedSubCategoryIds.isEmpty) {
      subCategoryController.clear();
    } else {
      subCategoryController.text = selectedSubCategoryIds.first;
    }
  }

  /// Drops subcategories that do not belong to the current main category.
  /// If main is cleared, clears all sub selections.
  void syncSelectedSubCategoriesWithMainCategory() {
    final mid = selectedMainCategoryId.value;
    if (mid == null || mid.isEmpty) {
      selectedSubCategoryIds.clear();
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

  Future<void> getCategories() async {
    mainCategories.assignAll(await getMainCategoriesUsecase.call());
    allSubCategories
        .assignAll(await getCategoriesUsecase.call(isProject: false));
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
    selectedProductStoreSectionId.value = null;
    for (final el in items) {
      el.onClose();
    }
    items.clear();
    isForcedSale.value = false;
    loadProductSizeOptions(productId: null);
    Future<void>(() async => ensureStoreSectionsLoaded());
    update();
  }

  Future<bool> initProductDetails() async {
    final p = productDetails.value;
    if (p == null) {
      return false;
    }
    if (mainCategories.isEmpty || allSubCategories.isEmpty) {
      await getCategories();
    }

    selectedProductStoreSectionId.value = p.storeSectionId;
    editingProductId.value = p.id;
    saveScopeFull.value = false;
    productNameController.text = p.nameAr;
    productDetailsController.text = p.descriptionAr ?? '';
    nameEngController.text = p.nameEng;
    nameAbreeController.text = p.nameAbree ?? '';
    descriptionEngController.text = p.descriptionEng ?? '';
    descriptionAbreeController.text = p.descriptionAbree ?? '';
    selectedSubCategoryIds.clear();
    final flatSubs = p.subCategoryIds;
    if (flatSubs != null && flatSubs.isNotEmpty) {
      for (final sid in flatSubs) {
        if (sid.isNotEmpty) {
          selectedSubCategoryIds.add(sid);
        }
      }
    } else if (p.productSubCategories != null) {
      for (final s in p.productSubCategories!) {
        final sid = s.subCategoryId;
        if (sid != null && sid.isNotEmpty) {
          selectedSubCategoryIds.add(sid);
        }
      }
    }

    selectedMainCategoryId.value = null;
    final cid = p.categoryId;
    if (cid != null && cid.isNotEmpty) {
      selectedMainCategoryId.value = cid;
    }
    if (selectedMainCategoryId.value != null &&
        selectedMainCategoryId.value!.isNotEmpty) {
      syncSelectedSubCategoriesWithMainCategory();
    }
    _syncSubCategoryControllerText();
    stockController.text = p.stock?.toString() ?? '0';
    minimumStockController.text = p.minStock?.toString() ?? '';
    retailPricesController.text = p.normailPrice?.toString() ?? '';
    wholesalePricesController.text = p.wholesalePrice?.toString() ?? '';
    purchasePriceController.clear();
    if (p.purchasePrices != null && p.purchasePrices!.isNotEmpty) {
      final cost = p.purchasePrices!.first.price?.trim();
      if (cost != null && cost.isNotEmpty && cost != '0' && cost != 'null') {
        purchasePriceController.text = cost;
      }
    }
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
    existingNormalMedia
        .assignAll(_mediaItemsForEdit(p.normalImageItems, p.normalImages));
    existingViewMedia
        .assignAll(_mediaItemsForEdit(p.viewImageItems, p.viewImages));
    existingThreeDMedia
        .assignAll(_mediaItemsForEdit(p.image3dItems, p.image3d));
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
          colorModel.wholesalePriceController.text =
              colorJson.wholesalePrice ?? '';
          colorModel.discountController.text = colorJson.discount ?? '';
          colorModel.quantityController.text = colorJson.stock ?? '';
          colorModel.existingImageUrl = colorJson.imageUrl;
          sizeModel.colors.add(colorModel);
        }
        if (sizeModel.colors.isEmpty) {
          sizeModel.colors.add(ColorModel());
        }
        items.add(sizeModel);
      }
    }
    isForcedSale.value = p.isSoldWithPaper == '1' || p.isSoldWithPaper == 1;
    loadProductSizeOptions(productId: p.id);
    Future<void>(() async => ensureStoreSectionsLoaded());
    update();
    return true;
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
    if (purchasePriceController.text.trim().isNotEmpty) {
      addField('purchase_price', purchasePriceController.text.trim());
    }
    if (rotationDateController.text.trim().isNotEmpty) {
      addField('rotation_date', rotationDateController.text.trim());
    }
    final mainCat = selectedMainCategoryId.value?.trim();
    if (mainCat != null && mainCat.isNotEmpty) {
      addField('category_id', mainCat);
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

    final sectionId = selectedProductStoreSectionId.value;
    if (sectionId != null && sectionId.trim().isNotEmpty) {
      addField('store_section_id', sectionId.trim());
    } else {
      addField('store_section_id', '');
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
        if (c.wholesalePriceController.text.trim().isNotEmpty) {
          addField(
            'sizes[$sizeIndex][color_sizes][$j][wholesalePrice]',
            c.wholesalePriceController.text.trim(),
          );
        }
        if (c.discountController.text.trim().isNotEmpty) {
          addField(
            'sizes[$sizeIndex][color_sizes][$j][discount]',
            c.discountController.text.trim(),
          );
        }
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
        final pendingImg = c.pendingImage;
        if (pendingImg != null) {
          final bytes = await pendingImg.readAsBytes();
          form.files.add(
            MapEntry(
              'sizes[$sizeIndex][color_sizes][$j][image]',
              MultipartFile.fromBytes(bytes, filename: pendingImg.name),
            ),
          );
        } else if (c.clearImage) {
          addField('sizes[$sizeIndex][color_sizes][$j][delete_image]', '1');
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
    final mid = selectedMainCategoryId.value?.trim();
    if (mid == null || mid.isEmpty) {
      Get.snackbar('error'.tr, 'mainCategoryRequired'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final sizeQtyErr = validateAllSizeColorQuantities();
    if (sizeQtyErr != null) {
      Get.snackbar('error'.tr, sizeQtyErr.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (selectedSubCategoryIds.isNotEmpty) {
      final knownIds = allSubCategories.map((s) => s.id).toSet();
      for (final id in selectedSubCategoryIds) {
        if (!knownIds.contains(id)) {
          Get.snackbar('error'.tr, 'invalidCategoryCombination'.tr,
              snackPosition: SnackPosition.BOTTOM);
          return;
        }
      }
      final allowed = allSubCategories
          .where((s) => s.mainCategoryId == mid)
          .map((s) => s.id)
          .toSet();
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
      currentTab.value = 0;
      await getAllProducts();

      clearPendingMedia();
      _resetEditMediaState();
      editingProductId.value = null;

      update();

      if (wasEdit) {
        Get.back();
        if (editedId != null) {
          await getProductDetails(productId: editedId);
          await getCategories();
        }
      } else {
        AppNavigation.popToRoute(AppRoutes.STOCKSCREEN);
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
    loadStockSearchHistory();
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
    closeoutsProductNameController.dispose();
    stockSearchQueryController.dispose();
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
  final TextEditingController wholesalePriceController =
      TextEditingController();
  final TextEditingController discountController = TextEditingController();
  String? dbColorId;
  String? existingImageUrl;
  XFile? pendingImage;
  bool clearImage = false;

  void onClose() {
    colorController.dispose();
    colorEnController.dispose();
    colorAbbrController.dispose();
    quantityController.dispose();
    priceController.dispose();
    wholesalePriceController.dispose();
    discountController.dispose();
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

/// Simple value class used by [StockController.flatSizeColorEntries].
class SizeColorEntry {
  final int sizeIdx;
  final int colorIdx;
  final String size;
  final ColorModel color;

  const SizeColorEntry({
    required this.sizeIdx,
    required this.colorIdx,
    required this.size,
    required this.color,
  });
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
