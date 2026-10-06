import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/show_net_image.dart';
import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';
import '../controllers/online_store_listings_controller.dart';
import '../utils/online_store_admin_ui.dart';

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
          Expanded(child: _content()),
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
      return const Center(child: Text('لا توجد منتجات مطابقة.'));
    }
    return ListView.separated(
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
        onTap: alreadyListed
            ? null
            : () async {
                final listing = await Get.find<OnlineStoreListingsController>()
                    .create(product.id);
                if (listing != null && mounted) Get.back(result: listing);
              },
      ),
    );
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}
