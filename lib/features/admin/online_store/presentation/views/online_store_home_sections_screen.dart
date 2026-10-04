import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_home_sections_controller.dart';
import '../../data/online_store_models.dart';
import '../../../../../../core/databases/api/end_points.dart';
import '../utils/online_store_permissions.dart';
import '../widgets/online_store_resource_screen.dart';

class OnlineStoreHomeSectionsScreen
    extends GetView<OnlineStoreHomeSectionsController> {
  const OnlineStoreHomeSectionsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) =>
      OnlineStoreResourceScreen<OnlineStoreHomeSectionsController>(
        title: 'أقسام واجهة المتجر',
        icon: Icons.view_carousel_outlined,
        canManage: OnlineStorePermissions.canManageContent,
        subtitle: 'يدوي أو تلقائي بترتيب حتمي',
        inspectLabel: 'إدارة العناصر اليدوية',
        onInspect: _manageItems,
        actions: const {OnlineStoreResourceAction.delete},
        onReorder: controller.reorderSections,
        fields: const [
          OnlineStoreFormField('key', 'المفتاح'),
          OnlineStoreFormField('section_type', 'النوع', options: [
            'hero',
            'categories',
            'best_sellers',
            'recent',
            'maintenance',
            'offers',
            'custom'
          ]),
          OnlineStoreFormField('title_translations.ar', 'العنوان العربي'),
          OnlineStoreFormField('selection_mode', 'نمط الاختيار',
              options: ['manual', 'automatic', 'dedicated_banners']),
          OnlineStoreFormField('selection_config.selector', 'المحدد التلقائي'),
          OnlineStoreFormField('selection_config.limit', 'حد العناصر',
              numeric: true),
          OnlineStoreFormField('is_visible', 'ظاهر', boolean: true),
          OnlineStoreFormField('sort_order', 'الترتيب', numeric: true),
        ],
      );

  Future<void> _manageItems(OnlineStoreEntity section) async {
    final listings = await controller.pickerListings();
    final categoryJson =
        await controller.repository.get(EndPoints.onlineStoreCategories);
    final categories = onlineStoreRows(categoryJson['data'])
        .map((row) => OnlineStoreEntity.fromJson(row))
        .toList();
    final selected = <String>{};
    final categoryTargets = section.values['section_type'] == 'categories';
    for (final row in onlineStoreRows(section.values['items'])) {
      selected.add('${row['target_type']}:${row['target_id']}');
    }
    final accepted = await Get.dialog<bool>(StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('اختيار عناصر متوافقة'),
        content: SizedBox(
          width: 430,
          child: ListView(shrinkWrap: true, children: [
            if (!categoryTargets) const ListTile(title: Text('قوائم المنتجات')),
            if (!categoryTargets)
              ...listings.map((listing) => CheckboxListTile(
                    value: selected.contains('listing:${listing.id}'),
                    title: Text(listing.productName.isEmpty
                        ? 'قائمة #${listing.id}'
                        : listing.productName),
                    onChanged: (v) => setState(() => v == true
                        ? selected.add('listing:${listing.id}')
                        : selected.remove('listing:${listing.id}')),
                  )),
            if (categoryTargets) const ListTile(title: Text('التصنيفات')),
            if (categoryTargets)
              ...categories.map((category) => CheckboxListTile(
                    value: selected.contains('category:${category.id}'),
                    title: Text(category.label),
                    onChanged: (v) => setState(() => v == true
                        ? selected.add('category:${category.id}')
                        : selected.remove('category:${category.id}')),
                  )),
          ]),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Get.back(result: true),
              child: const Text('حفظ الترتيب')),
        ],
      ),
    ));
    if (accepted == true) {
      final items = selected.toList().asMap().entries.map((entry) {
        final parts = entry.value.split(':');
        return <String, dynamic>{
          'target_type': parts.first,
          'target_id': int.parse(parts.last),
          'sort_order': entry.key,
        };
      }).toList();
      await controller.replaceItems(section.id, items);
      await controller.load();
    }
  }
}
