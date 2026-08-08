import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/meta_catalog_api_service.dart';
import '../../data/meta_catalog_models.dart';

class MetaCatalogController extends GetxController {
  MetaCatalogController(this.api);
  final MetaCatalogApiService api;

  final tabIndex = 0.obs;
  final loading = false.obs;
  final actionLoading = false.obs;
  final error = RxnString();
  final accounts = <MetaCatalogAccount>[].obs;
  final selectedAccountId = RxnInt();
  final status = Rxn<MetaCatalogStatus>();
  final settings = Rxn<MetaCatalogSettings>();
  final products = <MetaCatalogProduct>[].obs;
  final productSets = <MetaCatalogProductSet>[].obs;
  final logs = <MetaCatalogSyncLog>[].obs;
  final productStatus = 'all'.obs;
  final productSetStatus = 'all'.obs;
  final productSetType = 'all'.obs;
  final logStatus = 'all'.obs;
  final logAction = 'all'.obs;
  final bulkSourceType = 'all'.obs;
  final search = TextEditingController();
  final bulkSourceId = TextEditingController();
  final productsScrollController = ScrollController();
  final loadingMoreProducts = false.obs;
  int _productsPage = 1;
  int _productsLastPage = 1;

  @override
  void onInit() {
    super.onInit();
    productsScrollController.addListener(_onProductsScroll);
    loadAccounts().then((_) => refreshCurrent());
  }

  Future<void> setTab(int value) async {
    tabIndex.value = value;
    await refreshCurrent();
  }

  Future<void> refreshCurrent() async {
    if (tabIndex.value == 1) return loadProducts();
    if (tabIndex.value == 2) return loadProductSets();
    if (tabIndex.value == 3) return loadLogs();
    if (tabIndex.value == 4) return loadSettings();
    return loadStatus();
  }

  int? get selectedAccountIdValue => selectedAccountId.value;

  MetaCatalogAccount? get selectedAccount {
    final id = selectedAccountId.value;
    if (id == null) return null;
    return _firstAccountWhere((account) => account.id == id);
  }

  Future<void> _load(Future<void> Function() callback) async {
    loading.value = true;
    error.value = null;
    try {
      await callback();
    } catch (e) {
      error.value = _message(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadAccounts() async {
    try {
      final result = await api.getAccounts();
      final data =
          result['accounts'] is List ? result['accounts'] as List : const [];
      accounts.assignAll(data.whereType<Map>().map(
          (e) => MetaCatalogAccount.fromJson(Map<String, dynamic>.from(e))));
      selectedAccountId.value ??=
          _firstAccountWhere((account) => account.isActive)?.id ??
              (accounts.isNotEmpty ? accounts.first.id : null);
    } catch (e) {
      error.value = _message(e);
    }
  }

  Future<void> selectAccount(int? id) async {
    selectedAccountId.value = id;
    products.clear();
    productSets.clear();
    logs.clear();
    await refreshCurrent();
  }

  Future<void> loadStatus() => _load(() async {
        final result = await api.getStatus(accountId: selectedAccountIdValue);
        status.value = MetaCatalogStatus.fromJson(
            Map<String, dynamic>.from(result['catalog'] as Map? ?? {}));
      });

  Future<void> loadProducts() => _load(() async {
        _productsPage = 1;
        final result = await api.getProducts(
            page: _productsPage,
            search: search.text,
            status: productStatus.value,
            accountId: selectedAccountIdValue);
        final block = result['products'];
        final data =
            block is Map && block['data'] is List ? block['data'] as List : [];
        _productsLastPage =
            block is Map ? _asInt(block['last_page'], fallback: 1) : 1;
        products.assignAll(data.whereType<Map>().map(
            (e) => MetaCatalogProduct.fromJson(Map<String, dynamic>.from(e))));
      });

  Future<void> loadMoreProducts() async {
    if (loadingMoreProducts.value || _productsPage >= _productsLastPage) {
      return;
    }
    loadingMoreProducts.value = true;
    try {
      final nextPage = _productsPage + 1;
      final result = await api.getProducts(
          page: nextPage,
          search: search.text,
          status: productStatus.value,
          accountId: selectedAccountIdValue);
      final block = result['products'];
      final data =
          block is Map && block['data'] is List ? block['data'] as List : [];
      final incoming = data
          .whereType<Map>()
          .map((e) => MetaCatalogProduct.fromJson(Map<String, dynamic>.from(e)))
          .where((item) => !products.any((current) => current.id == item.id));
      products.addAll(incoming);
      _productsPage = block is Map
          ? _asInt(block['current_page'], fallback: nextPage)
          : nextPage;
      _productsLastPage = block is Map
          ? _asInt(block['last_page'], fallback: _productsPage)
          : _productsPage;
    } catch (e) {
      Get.snackbar('خطأ', _message(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      loadingMoreProducts.value = false;
    }
  }

  void _onProductsScroll() {
    if (!productsScrollController.hasClients) return;
    if (productsScrollController.position.extentAfter < 350) {
      loadMoreProducts();
    }
  }

  Future<void> loadLogs() => _load(() async {
        final result = await api.getLogs(
            status: logStatus.value,
            action: logAction.value,
            accountId: selectedAccountIdValue);
        final block = result['logs'];
        final data =
            block is Map && block['data'] is List ? block['data'] as List : [];
        logs.assignAll(data.whereType<Map>().map(
            (e) => MetaCatalogSyncLog.fromJson(Map<String, dynamic>.from(e))));
      });

  Future<void> loadProductSets() => _load(() async {
        final result = await api.getProductSets(
            status: productSetStatus.value,
            type: productSetType.value,
            accountId: selectedAccountIdValue);
        final block = result['product_sets'];
        final data =
            block is Map && block['data'] is List ? block['data'] as List : [];
        productSets.assignAll(data.whereType<Map>().map((e) =>
            MetaCatalogProductSet.fromJson(Map<String, dynamic>.from(e))));
      });

  Future<void> loadSettings() => _load(() async {
        final result = await api.getSettings();
        settings.value = MetaCatalogSettings.fromJson(
            Map<String, dynamic>.from(result['settings'] as Map? ?? {}));
      });

  Future<void> productAction(MetaCatalogProduct product, String action) async {
    await _action(() {
      if (action == 'disable') {
        return api.disableProduct(product.id,
            accountId: selectedAccountIdValue);
      }
      if (action == 'resync') {
        return api.resyncProduct(product.id, accountId: selectedAccountIdValue);
      }
      return api.syncProduct(product.id, accountId: selectedAccountIdValue);
    }, 'تم تنفيذ العملية');
    await loadProducts();
  }

  Future<void> bulkSync() async {
    final confirmed = await Get.dialog<bool>(AlertDialog(
      title: Text(_bulkDialogTitle()),
      content: Text(
          'ستتم إضافة المنتجات إلى قائمة الانتظار لحساب ${selectedAccount?.name ?? 'الكتالوج الحالي'} وقد تستغرق العملية بعض الوقت.'),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء')),
        FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('بدء المزامنة')),
      ],
    ));
    if (confirmed != true) return;
    final sourceId = int.tryParse(bulkSourceId.text.trim());
    if (bulkSourceType.value != 'all' && sourceId == null) {
      Get.snackbar('تنبيه', 'أدخل رقم التصنيف المطلوب للمزامنة',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    await _action(
        () => api.bulkSync(
              accountId: selectedAccountIdValue,
              sourceType: bulkSourceType.value,
              sourceId: bulkSourceType.value == 'all' ? null : sourceId,
            ),
        'بدأت مزامنة المنتجات');
    await loadStatus();
  }

  Future<void> syncHierarchy() async {
    await _action(() => api.syncHierarchy(accountId: selectedAccountIdValue),
        'تمت مزامنة التصنيفات ومجموعات المنتجات');
    await Future.wait([loadStatus(), loadProductSets()]);
  }

  Future<void> saveSettings() async {
    final value = settings.value;
    if (value == null) return;
    await _action(() => api.saveSettings(value.toJson()), 'تم حفظ الإعدادات');
    await loadSettings();
  }

  Future<void> _action(
      Future<Map<String, dynamic>> Function() callback, String success) async {
    actionLoading.value = true;
    try {
      final result = await callback();
      if (result['status'] != 'success') {
        throw Exception(result['message'] ?? 'تعذر تنفيذ العملية');
      }
      Get.snackbar('تم', result['message']?.toString() ?? success,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('خطأ', _message(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      actionLoading.value = false;
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  int _asInt(dynamic value, {required int fallback}) =>
      int.tryParse(value?.toString() ?? '') ?? fallback;

  String _bulkDialogTitle() {
    if (bulkSourceType.value == 'category') return 'مزامنة تصنيف رئيسي';
    if (bulkSourceType.value == 'sub_category') return 'مزامنة تصنيف فرعي';
    return 'مزامنة كل المنتجات';
  }

  MetaCatalogAccount? _firstAccountWhere(
      bool Function(MetaCatalogAccount account) test) {
    for (final account in accounts) {
      if (test(account)) return account;
    }
    return null;
  }

  @override
  void onClose() {
    search.dispose();
    bulkSourceId.dispose();
    productsScrollController
      ..removeListener(_onProductsScroll)
      ..dispose();
    super.onClose();
  }
}
