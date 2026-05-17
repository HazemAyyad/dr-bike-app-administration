import 'package:doctorbike/core/errors/expentions.dart';
import 'package:doctorbike/features/admin/stock/data/datasources/stock_datasource.dart';
import 'package:doctorbike/features/admin/stock/data/models/all_stock_products_model.dart';
import 'package:doctorbike/features/admin/stock/data/models/offer_package_model.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/usecases/search_products_usecase.dart';
import '../widgets/offer_package_add_product_dialog.dart';

class OfferPackageProductRow {
  final String productId;
  final String productName;
  final String stock;
  final double unitPrice;
  final int quantityPerPackage;

  OfferPackageProductRow({
    required this.productId,
    required this.productName,
    required this.stock,
    required this.unitPrice,
    required this.quantityPerPackage,
  });

  double get lineTotal => unitPrice * quantityPerPackage;
}

class OfferPackagesController extends GetxController {
  final StockDatasource stockDatasource;
  final SearchProductsUsecase searchProductsUsecase;

  OfferPackagesController({
    required this.stockDatasource,
    required this.searchProductsUsecase,
  });

  final tabs = ['activeOfferPackages', 'offerPackagesNeedAdjustment'].obs;
  final currentTab = 0.obs;
  final RxList<OfferPackageModel> packages = <OfferPackageModel>[].obs;
  final RxBool isLoading = false.obs;

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final packageQuantityController = TextEditingController(text: '1');
  final RxnString editingPackageId = RxnString();
  final Rxn<XFile> pendingImage = Rxn<XFile>();
  String? existingImageUrl;
  final RxList<OfferPackageProductRow> packageProducts = <OfferPackageProductRow>[].obs;
  final RxBool isSubmitting = false.obs;

  final RxList<AllStockProductsModel> searchResults = <AllStockProductsModel>[].obs;
  final RxBool isSearching = false.obs;

  int get packageQuantity =>
      int.tryParse(packageQuantityController.text.trim()) ?? 1;

  /// مجموع أسعار القطع الفعلية داخل الباكيج الواحد.
  double get partsRealTotal => packageProducts.fold(
        0.0,
        (sum, row) => sum + row.lineTotal,
      );

  @override
  void onInit() {
    super.onInit();
    packageQuantityController.addListener(_onPriceFieldsChanged);
    loadPackages();
  }

  void _onPriceFieldsChanged() {
    update(['parts_total']);
  }

  String get _tabKey => currentTab.value == 0 ? 'active' : 'needs_adjustment';

  void changeTab(int index) {
    currentTab.value = index;
    loadPackages();
  }

  Future<void> loadPackages() async {
    isLoading.value = true;
    try {
      final list = await stockDatasource.getOfferPackages(tab: _tabKey);
      packages.assignAll(list);
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pullToRefresh() => loadPackages();

  void prepareCreate() {
    editingPackageId.value = null;
    nameController.clear();
    priceController.clear();
    packageQuantityController.text = '1';
    pendingImage.value = null;
    existingImageUrl = null;
    packageProducts.clear();
    update(['parts_total']);
  }

  void prepareEdit(OfferPackageModel pkg) {
    editingPackageId.value = pkg.id.toString();
    nameController.text = pkg.name;
    priceController.text = pkg.price.toString();
    packageQuantityController.text = pkg.packageQuantity.toString();
    pendingImage.value = null;
    existingImageUrl = pkg.image != 'no image' ? pkg.image : null;
    packageProducts.assignAll(
      pkg.items.map(
        (item) => OfferPackageProductRow(
          productId: item.productId.toString(),
          productName: item.productName,
          stock: item.stock.toString(),
          unitPrice: item.unitPrice,
          quantityPerPackage: item.quantity,
        ),
      ),
    );
    update(['parts_total']);
  }

  void notifyPartsTotalChanged() => update(['parts_total']);

  Future<void> searchProducts(String query) async {
    if (query.trim().length < 2) {
      searchResults.clear();
      return;
    }
    isSearching.value = true;
    try {
      final result = await searchProductsUsecase.call(name: query);
      searchResults.assignAll(result);
    } catch (_) {
      searchResults.clear();
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> openAddProductDialog() => openProductDialog();

  Future<void> openProductDialog({int? editIndex}) async {
    searchResults.clear();
    final initial =
        editIndex != null ? packageProducts[editIndex] : null;
    final result = await Get.dialog<OfferPackageProductRow>(
      OfferPackageAddProductDialog(
        controller: this,
        initial: initial,
      ),
      barrierDismissible: false,
    );
    if (result == null) return;

    final duplicateIndex = packageProducts.indexWhere(
      (p) => p.productId == result.productId,
    );
    if (duplicateIndex >= 0 && duplicateIndex != editIndex) {
      Get.snackbar('error'.tr, 'productAlreadyInPackage'.tr);
      return;
    }

    if (editIndex != null) {
      packageProducts[editIndex] = result;
    } else {
      packageProducts.add(result);
    }
    packageProducts.refresh();
    notifyPartsTotalChanged();
  }

  void editProductAt(int index) => openProductDialog(editIndex: index);

  void removeProductFromTable(int index) {
    if (index < 0 || index >= packageProducts.length) return;
    packageProducts.removeAt(index);
    notifyPartsTotalChanged();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      pendingImage.value = file;
    }
  }

  Future<void> submitPackage(BuildContext context) async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim()) ?? -1;
    final pkgQty = packageQuantity;

    if (name.isEmpty || price < 0 || pkgQty < 1) {
      Get.snackbar('error'.tr, 'requiredField'.tr);
      return;
    }

    if (packageProducts.isEmpty) {
      Get.snackbar('error'.tr, 'addAtLeastOneProductToPackage'.tr);
      return;
    }

    final items = packageProducts
        .map(
          (row) => {
            'product_id': int.parse(row.productId),
            'quantity': row.quantityPerPackage,
          },
        )
        .toList();

    isSubmitting.value = true;
    try {
      await stockDatasource.saveOfferPackage(
        name: name,
        price: price,
        packageQuantity: pkgQty,
        items: items,
        offerPackageId: editingPackageId.value,
        imagePath: pendingImage.value?.path,
      );

      await loadPackages();
      if (Get.currentRoute.contains('AddEditOfferPackage')) {
        Get.back();
      }
      Get.snackbar('success'.tr, 'operationCompletedSuccessfully'.tr);
    } catch (e) {
      _showError(e);
    } finally {
      isSubmitting.value = false;
    }
  }

  void _showError(Object e) {
    var message = e.toString();
    if (e is ServerException) {
      message = e.errorModel.errorMessage;
      final errors = e.errorModel.data?['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final parts = <String>[];
        errors.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            parts.add('$key: ${value.first}');
          }
        });
        if (parts.isNotEmpty) {
          message = '$message\n${parts.join('\n')}';
        }
      }
    }
    Get.snackbar('error'.tr, message, duration: const Duration(seconds: 5));
  }

  Future<void> deletePackage(OfferPackageModel pkg) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Get.theme.dialogBackgroundColor,
        title: Text(
          'confirm'.tr,
          style: Get.textTheme.titleMedium,
        ),
        content: Text(
          'deleteOfferPackageConfirm'.tr,
          style: Get.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr, style: Get.textTheme.bodyMedium),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'delete'.tr,
              style: Get.textTheme.bodyMedium?.copyWith(color: AppColors.redColor),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await stockDatasource.deleteOfferPackage(id: pkg.id.toString());
      await loadPackages();
      Get.snackbar('success'.tr, 'operationCompletedSuccessfully'.tr);
    } catch (e) {
      _showError(e);
    }
  }

  @override
  void onClose() {
    packageQuantityController.removeListener(_onPriceFieldsChanged);
    nameController.dispose();
    priceController.dispose();
    packageQuantityController.dispose();
    super.onClose();
  }
}
