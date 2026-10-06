import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/show_net_image.dart';
import '../../../../../../core/databases/api/end_points.dart';
import '../../../../../../routes/app_routes.dart';
import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';
import '../controllers/online_store_listings_controller.dart';
import '../utils/online_store_admin_ui.dart';
import '../utils/online_store_permissions.dart';

bool canCreateOnlineStoreListing(int productId, Set<int> listedProductIds) =>
    !listedProductIds.contains(productId);

class OnlineStoreProductPickerScreen extends StatefulWidget {
  const OnlineStoreProductPickerScreen({Key? key}) : super(key: key);

  @override
  State<OnlineStoreProductPickerScreen> createState() =>
      _OnlineStoreProductPickerScreenState();
}

class _OnlineStoreProductPickerScreenState
    extends State<OnlineStoreProductPickerScreen> {
  final search = TextEditingController();
  List<OnlineStoreProductCandidate> rows = const [];
  Set<int> listedProductIds = const {};
  bool loading = false;
  String? error;

  Future<void> _load() async {
    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final repository = Get.find<OnlineStoreRepository>();
      final results = await Future.wait([
        repository.productCandidates(search: search.text),
        repository.allListings(),
      ]);
      if (!mounted) return;
      setState(() {
        rows = results[0] as List<OnlineStoreProductCandidate>;
        listedProductIds = (results[1] as List<OnlineStoreListing>)
            .map((listing) => listing.productId)
            .toSet();
      });
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _clear() {
    search.clear();
    _load();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OnlineStoreAdminUi.pageBackground,
        appBar: AppBar(title: const Text('اختيار منتج من المخزون')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'الاسم العربي أو الإنجليزي أو كود المنتج',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (search.text.isNotEmpty)
                    IconButton(
                      tooltip: 'مسح البحث',
                      onPressed: _clear,
                      icon: const Icon(Icons.clear),
                    ),
                  IconButton(
                    tooltip: 'بحث',
                    onPressed: loading ? null : _load,
                    icon: const Icon(Icons.search),
                  ),
                ]),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
              child: RefreshIndicator(onRefresh: _load, child: _content())),
        ]),
      );

  Widget _content() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline,
                color: OnlineStoreAdminUi.danger, size: 42),
            const SizedBox(height: 12),
            const Text('تعذر تحميل منتجات المخزون'),
            const SizedBox(height: 6),
            Text(error!,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: OnlineStoreAdminUi.textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OnlineStoreAdminUi.actionButtonStyle,
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ]),
        ),
      );
    }
    if (rows.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(child: Text('لا توجد منتجات مطابقة.')),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _productRow(rows[index]),
    );
  }

  Widget _productRow(OnlineStoreProductCandidate product) {
    final alreadyListed =
        !canCreateOnlineStoreListing(product.id, listedProductIds);
    return Card(
      color: OnlineStoreAdminUi.surface,
      child: ListTile(
        enabled: !alreadyListed,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.square(
            dimension: 52,
            child: product.imageUrl.isEmpty
                ? const ColoredBox(
                    color: OnlineStoreAdminUi.surfaceMuted,
                    child: Icon(Icons.inventory_2_outlined),
                  )
                : Image.network(
                    ShowNetImage.getPhoto(product.imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: OnlineStoreAdminUi.surfaceMuted,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
        ),
        title: Text(product.displayName.isEmpty
            ? 'منتج #${product.id}'
            : product.displayName),
        subtitle: Text([
          if (product.nameEn.isNotEmpty &&
              product.nameEn != product.displayName)
            product.nameEn,
          if (product.code.isNotEmpty) 'الكود: ${product.code}',
          'المخزون: ${product.stock}  •  سعر التجزئة: ${product.retailPrice}',
          if (alreadyListed) 'مضاف مسبقًا إلى المتجر',
        ].join('\n')),
        trailing: Icon(
          alreadyListed ? Icons.check_circle_outline : Icons.add_circle_outline,
          color: alreadyListed
              ? OnlineStoreAdminUi.success
              : OnlineStoreAdminUi.accent,
        ),
        onTap: alreadyListed ? null : () => _prepareProduct(product),
      ),
    );
  }

  Future<void> _prepareProduct(OnlineStoreProductCandidate product) async {
    final repository = Get.find<OnlineStoreRepository>();
    final categories = OnlineStorePermissions.canManageCategories
        ? (await repository.allEntities(EndPoints.onlineStoreCategories))
            .where((category) =>
                category.values['is_active'] == true ||
                category.values['is_active'] == 1)
            .toList(growable: false)
        : <OnlineStoreEntity>[];
    if (!mounted) return;
    final selected = <int>{};
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OnlineStoreAdminUi.pageBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .86,
          maxChildSize: .96,
          minChildSize: .55,
          builder: (_, scrollController) => Column(children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: OnlineStoreAdminUi.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Expanded(
                child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Text(product.displayName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900)),
                if (product.nameEn.isNotEmpty)
                  Text(product.nameEn,
                      style: const TextStyle(
                          color: OnlineStoreAdminUi.textSecondary)),
                const SizedBox(height: 14),
                if (product.imageUrls.isNotEmpty)
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: product.imageUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          ShowNetImage.getPhoto(product.imageUrls[index]),
                          width: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 180,
                            child: ColoredBox(
                              color: OnlineStoreAdminUi.surfaceMuted,
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _DetailChip(Icons.qr_code,
                      product.code.isEmpty ? 'بدون كود' : product.code),
                  _DetailChip(
                      Icons.inventory_2_outlined, 'المخزون ${product.stock}'),
                  _DetailChip(
                      Icons.sell_outlined, 'تجزئة ${product.retailPrice}'),
                  _DetailChip(
                      Icons.store_outlined, 'جملة ${product.wholesalePrice}'),
                  if (product.storeSectionName.isNotEmpty)
                    _DetailChip(
                        Icons.warehouse_outlined, product.storeSectionName),
                  if (product.hasVariants)
                    _DetailChip(Icons.style_outlined,
                        '${product.variants.length} مقاسات/خيارات'),
                ]),
                const SizedBox(height: 20),
                const Text('تصنيف المنتج في المتجر',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  categories.isEmpty
                      ? 'يمكنك تحديد التصنيف لاحقاً من شاشة تعديل المنتج.'
                      : 'اختر تصنيفاً واحداً أو أكثر. هذه التصنيفات مستقلة عن قسم المخزون.',
                  style:
                      const TextStyle(color: OnlineStoreAdminUi.textSecondary),
                ),
                const SizedBox(height: 8),
                ...categories.map((category) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: selected.contains(category.id),
                      title: Text(category.label),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) => setSheetState(() => value == true
                          ? selected.add(category.id)
                          : selected.remove(category.id)),
                    )),
              ],
            )),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(children: [
                  Expanded(
                      child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: const Text('إلغاء'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('إضافة ومتابعة التجهيز'),
                      )),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
    if (accepted != true || !mounted) return;
    final controller = Get.find<OnlineStoreListingsController>();
    var listing = await controller.create(product.id);
    if (listing == null || !mounted) return;
    if (selected.isNotEmpty) {
      await controller.saveListingCategories(listing.id, selected);
      listing = await controller.repository.listing(listing.id);
    }
    if (!mounted) return;
    await Get.offNamed(AppRoutes.ONLINESTORELISTINGEDITOR, arguments: listing);
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: OnlineStoreAdminUi.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: OnlineStoreAdminUi.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: OnlineStoreAdminUi.accent),
          const SizedBox(width: 6),
          Text(label),
        ]),
      );
}
