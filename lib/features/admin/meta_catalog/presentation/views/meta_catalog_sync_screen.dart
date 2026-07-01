import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../core/helpers/show_net_image.dart';
import '../../data/meta_catalog_models.dart';
import '../controllers/meta_catalog_controller.dart';

class MetaCatalogSyncScreen extends GetView<MetaCatalogController> {
  const MetaCatalogSyncScreen({Key? key}) : super(key: key);

  static const _green = Color(0xff128c7e);
  static const _dark = Color(0xff173b3f);

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('مزامنة كتالوج واتساب'),
            actions: [
              Obx(() => controller.actionLoading.value
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox.square(
                          dimension: 20, child: CircularProgressIndicator()))
                  : IconButton(
                      onPressed: controller.refreshCurrent,
                      icon: const Icon(Icons.refresh))),
            ],
          ),
          body: Column(children: [
            Obx(() => _tabs(controller.tabIndex.value)),
            Expanded(child: Obx(_content)),
          ]),
        ),
      );

  Widget _tabs(int selected) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
        child: Row(
          children: [
            _tab(0, Icons.dashboard_outlined, 'الرئيسية', selected),
            _tab(1, Icons.inventory_2_outlined, 'المنتجات', selected),
            _tab(2, Icons.account_tree_outlined, 'المجموعات', selected),
            _tab(3, Icons.receipt_long_outlined, 'السجل', selected),
            _tab(4, Icons.settings_outlined, 'الإعدادات', selected),
          ],
        ),
      );

  Widget _tab(int index, IconData icon, String label, int selected) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => controller.setTab(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected == index ? _dark : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon,
                  size: 20,
                  color: selected == index ? Colors.white : Colors.black54),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          selected == index ? Colors.white : Colors.black87)),
            ]),
          ),
        ),
      );

  Widget _content() {
    if (controller.loading.value) {
      return const Center(child: CircularProgressIndicator(color: _green));
    }
    if (controller.error.value != null) {
      return _empty(Icons.error_outline, controller.error.value!,
          action: controller.refreshCurrent);
    }
    switch (controller.tabIndex.value) {
      case 1:
        return _products();
      case 2:
        return _productSets();
      case 3:
        return _logs();
      case 4:
        return _settings();
      default:
        return _dashboard();
    }
  }

  Widget _dashboard() {
    final value = controller.status.value;
    if (value == null) return _empty(Icons.storefront, 'لا توجد بيانات');
    return RefreshIndicator(
      onRefresh: controller.loadStatus,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: _dark, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.storefront, color: _green)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Dr Bike Products',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text('Catalog ID: ${value.catalogId ?? '-'}',
                        style: const TextStyle(color: Colors.white70)),
                  ])),
              Icon(value.configured ? Icons.cloud_done : Icons.cloud_off,
                  color:
                      value.configured ? Colors.greenAccent : Colors.redAccent),
            ]),
          ),
          if (value.configurationError != null)
            _notice(value.configurationError!, Colors.red),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _stat('المنتجات', value.totalProducts, Icons.inventory_2, _dark),
              _stat('تمت', value.synced, Icons.check_circle, Colors.green),
              _stat('فشلت', value.failed, Icons.error, Colors.red),
              _stat('انتظار', value.pending, Icons.schedule, Colors.orange),
              _stat('معطلة', value.disabled, Icons.block, Colors.blueGrey),
              _stat('آخر مزامنة', value.lastSyncedAt == null ? 0 : 1,
                  Icons.sync, _green,
                  subtitle: _date(value.lastSyncedAt)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.account_tree_outlined, color: _green),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'مجموعات التصنيفات: ${value.syncedProductSets}/${value.totalProductSets}')),
              if (value.failedProductSets > 0)
                Text('فشل ${value.failedProductSets}',
                    style: const TextStyle(color: Colors.red)),
            ]),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: controller.syncHierarchy,
            icon: const Icon(Icons.account_tree_outlined),
            label: const Text('مزامنة التصنيفات والمجموعات'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _green),
            onPressed: controller.bulkSync,
            icon: const Icon(Icons.sync),
            label: const Text('مزامنة كل المنتجات'),
          ),
        ],
      ),
    );
  }

  Widget _products() => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            controller: controller.search,
            onSubmitted: (_) => controller.loadProducts(),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'ابحث عن منتج...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                  onPressed: controller.loadProducts,
                  icon: const Icon(Icons.arrow_back)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            scrollDirection: Axis.horizontal,
            children: [
              _filter('all', 'الكل'),
              _filter('synced', 'تمت'),
              _filter('failed', 'فشلت'),
              _filter('pending', 'انتظار'),
              _filter('disabled', 'معطلة'),
            ],
          ),
        ),
        Expanded(
          child: controller.products.isEmpty
              ? _empty(Icons.inventory_2_outlined, 'لا توجد منتجات')
              : RefreshIndicator(
                  onRefresh: controller.loadProducts,
                  child: ListView.builder(
                    controller: controller.productsScrollController,
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                    itemCount: controller.products.length + 1,
                    itemBuilder: (_, index) {
                      if (index == controller.products.length) {
                        return Obx(() => controller.loadingMoreProducts.value
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child:
                                    Center(child: CircularProgressIndicator()))
                            : const SizedBox(height: 8));
                      }
                      return _product(controller.products[index]);
                    },
                  ),
                ),
        ),
      ]);

  Widget _productSets() => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
          child: Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: controller.productSetType.value,
                isDense: true,
                decoration: const InputDecoration(
                    labelText: 'المستوى', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(value: 'category', child: Text('رئيسي')),
                  DropdownMenuItem(value: 'sub_category', child: Text('فرعي')),
                ],
                onChanged: (value) {
                  controller.productSetType.value = value ?? 'all';
                  controller.loadProductSets();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: controller.productSetStatus.value,
                isDense: true,
                decoration: const InputDecoration(
                    labelText: 'الحالة', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(value: 'synced', child: Text('تمت')),
                  DropdownMenuItem(value: 'failed', child: Text('فشلت')),
                  DropdownMenuItem(value: 'pending', child: Text('انتظار')),
                  DropdownMenuItem(value: 'disabled', child: Text('معطلة')),
                ],
                onChanged: (value) {
                  controller.productSetStatus.value = value ?? 'all';
                  controller.loadProductSets();
                },
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _green),
              onPressed: controller.syncHierarchy,
              icon: const Icon(Icons.sync),
              label: const Text('مزامنة كل التصنيفات'),
            ),
          ),
        ),
        Expanded(
          child: controller.productSets.isEmpty
              ? _empty(Icons.account_tree_outlined, 'لا توجد مجموعات بعد')
              : RefreshIndicator(
                  onRefresh: controller.loadProductSets,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
                    itemCount: controller.productSets.length,
                    itemBuilder: (_, index) {
                      final set = controller.productSets[index];
                      return Card(
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor:
                                set.sourceType == 'category' ? _dark : _green,
                            child: Icon(
                                set.sourceType == 'category'
                                    ? Icons.folder_outlined
                                    : Icons.subdirectory_arrow_left,
                                color: Colors.white),
                          ),
                          title: Text(set.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${set.sourceType == 'category' ? 'تصنيف رئيسي' : 'تصنيف فرعي'}'
                            '${set.metaProductSetId == null ? '' : ' • Meta ID: ${set.metaProductSetId}'}'
                            '${set.error == null ? '' : '\n${set.error}'}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: _badge(set.status),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ]);

  Widget _filter(String value, String label) => Obx(() => Padding(
        padding: const EdgeInsetsDirectional.only(end: 6),
        child: ChoiceChip(
          label: Text(label),
          selected: controller.productStatus.value == value,
          selectedColor: _green,
          labelStyle: TextStyle(
              color: controller.productStatus.value == value
                  ? Colors.white
                  : Colors.black87),
          onSelected: (_) {
            controller.productStatus.value = value;
            controller.loadProducts();
          },
        ),
      ));

  Widget _product(MetaCatalogProduct product) => Card(
        margin: const EdgeInsets.only(bottom: 7),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: _hasProductImage(product.image)
                  ? CachedNetworkImage(
                      imageUrl: ShowNetImage.getThumbnailPhoto(product.image),
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) {
                        final original = ShowNetImage.getPhoto(product.image);
                        return CachedNetworkImage(
                          imageUrl: original,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _imagePlaceholder(),
                        );
                      },
                    )
                  : _imagePlaceholder(),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text(product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                    _badge(product.status),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                      '${product.price.toStringAsFixed(2)} ILS  •  الكمية ${product.quantity}'
                      '${product.category == null ? '' : '  •  ${product.category}'}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54)),
                  if (product.error != null) ...[
                    InkWell(
                      onTap: () => Get.dialog(AlertDialog(
                          title: const Text('خطأ المزامنة'),
                          content: SelectableText(product.error!),
                          actions: [
                            TextButton(
                                onPressed: Get.back, child: const Text('إغلاق'))
                          ])),
                      child: Text(product.error!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: (value) =>
                          controller.productAction(product, value),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'sync', child: Text('مزامنة')),
                        PopupMenuItem(
                            value: 'resync', child: Text('إعادة مزامنة')),
                        PopupMenuItem(
                            value: 'disable', child: Text('تعطيل من الكتالوج')),
                      ],
                    ),
                  ),
                ])),
          ]),
        ),
      );

  Widget _logs() => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
          child: Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: controller.logStatus.value,
                isDense: true,
                decoration: const InputDecoration(
                    labelText: 'الحالة', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(value: 'success', child: Text('ناجحة')),
                  DropdownMenuItem(value: 'failed', child: Text('فاشلة')),
                  DropdownMenuItem(value: 'queued', child: Text('بالانتظار')),
                ],
                onChanged: (value) {
                  controller.logStatus.value = value ?? 'all';
                  controller.loadLogs();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: controller.logAction.value,
                isDense: true,
                decoration: const InputDecoration(
                    labelText: 'العملية', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(value: 'create', child: Text('إنشاء')),
                  DropdownMenuItem(value: 'update', child: Text('تحديث')),
                  DropdownMenuItem(value: 'disable', child: Text('تعطيل')),
                  DropdownMenuItem(
                      value: 'bulk_sync', child: Text('مزامنة شاملة')),
                  DropdownMenuItem(value: 'test', child: Text('اختبار')),
                ],
                onChanged: (value) {
                  controller.logAction.value = value ?? 'all';
                  controller.loadLogs();
                },
              ),
            ),
          ]),
        ),
        Expanded(
          child: controller.logs.isEmpty
              ? _empty(Icons.receipt_long_outlined, 'لا يوجد سجل مزامنة')
              : RefreshIndicator(
                  onRefresh: controller.loadLogs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: controller.logs.length,
                    itemBuilder: (_, index) {
                      final log = controller.logs[index];
                      return Card(
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: log.status == 'success'
                                ? Colors.green.shade50
                                : log.status == 'failed'
                                    ? Colors.red.shade50
                                    : Colors.orange.shade50,
                            child: Icon(
                                log.status == 'success'
                                    ? Icons.check
                                    : log.status == 'failed'
                                        ? Icons.close
                                        : Icons.schedule,
                                color: log.status == 'success'
                                    ? Colors.green
                                    : log.status == 'failed'
                                        ? Colors.red
                                        : Colors.orange),
                          ),
                          title: Text(log.productName ??
                              log.retailerId ??
                              'مزامنة شاملة'),
                          subtitle: Text(
                              '${_actionName(log.action)} • ${_date(log.createdAt)}${log.error == null ? '' : '\n${log.error}'}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis),
                          trailing: _badge(log.status),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ]);

  Widget _settings() {
    final value = controller.settings.value;
    if (value == null) {
      return _empty(Icons.settings_outlined, 'لا توجد إعدادات');
    }
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        SwitchListTile(
          activeThumbColor: _green,
          title: const Text('مزامنة تلقائية عند تعديل المنتج'),
          value: value.autoSync,
          onChanged: (v) {
            value.autoSync = v;
            controller.settings.refresh();
          },
        ),
        SwitchListTile(
          activeThumbColor: _green,
          title: const Text('إظهار الكمية داخل وصف المنتج'),
          value: value.showQuantity,
          onChanged: (v) {
            value.showQuantity = v;
            controller.settings.refresh();
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value.currency,
          decoration: const InputDecoration(
              labelText: 'العملة', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'ILS', child: Text('ILS - شيكل')),
            DropdownMenuItem(value: 'USD', child: Text('USD - دولار')),
            DropdownMenuItem(value: 'JOD', child: Text('JOD - دينار')),
          ],
          onChanged: (v) => value.currency = v ?? 'ILS',
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: value.defaultBrand,
          decoration: const InputDecoration(
              labelText: 'العلامة التجارية الافتراضية',
              border: OutlineInputBorder()),
          onChanged: (v) => value.defaultBrand = v,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: _green),
          onPressed: controller.saveSettings,
          icon: const Icon(Icons.save_outlined),
          label: const Text('حفظ الإعدادات'),
        ),
      ],
    );
  }

  Widget _stat(String label, int value, IconData icon, Color color,
          {String? subtitle}) =>
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(subtitle ?? '$value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label,
              maxLines: 1,
              style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ]),
      );

  Widget _badge(String status) {
    final color = status == 'synced' || status == 'success'
        ? Colors.green
        : status == 'failed'
            ? Colors.red
            : status == 'disabled'
                ? Colors.blueGrey
                : Colors.orange;
    final label = status == 'synced' || status == 'success'
        ? 'تمت'
        : status == 'failed'
            ? 'فشلت'
            : status == 'disabled'
                ? 'معطلة'
                : 'انتظار';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }

  Widget _imagePlaceholder() => Container(
      width: 58,
      height: 58,
      color: Colors.grey.shade100,
      child: const Icon(Icons.image_not_supported_outlined,
          color: Colors.black38));

  bool _hasProductImage(String? value) {
    final image = (value ?? '').trim().toLowerCase();
    return image.isNotEmpty &&
        image != 'no image' &&
        image != 'no img' &&
        image != 'null';
  }

  Widget _notice(String text, Color color) => Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: color)));

  Widget _empty(IconData icon, String text, {VoidCallback? action}) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: Colors.black26),
          const SizedBox(height: 8),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(text, textAlign: TextAlign.center)),
          if (action != null)
            TextButton(onPressed: action, child: const Text('إعادة المحاولة')),
        ]),
      );

  String _date(String? value) {
    if (value == null || value.isEmpty) return '-';
    return value.replaceFirst('T', ' ').split('.').first;
  }

  String _actionName(String action) =>
      const {
        'create': 'إنشاء',
        'update': 'تحديث',
        'delete': 'حذف',
        'disable': 'تعطيل',
        'bulk_sync': 'مزامنة شاملة',
        'test': 'اختبار',
      }[action] ??
      action;
}
