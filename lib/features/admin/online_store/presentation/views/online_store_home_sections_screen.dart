import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_home_sections_controller.dart';
import '../../data/online_store_models.dart';
import '../../../../../../core/databases/api/end_points.dart';
import '../utils/online_store_permissions.dart';
import '../utils/online_store_admin_ui.dart';
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
        subtitle: 'الأقسام التي يراها العميل في الصفحة الرئيسية',
        inspectLabel: 'إدارة العناصر اليدوية',
        onInspect: _manageItems,
        actions: const {OnlineStoreResourceAction.delete},
        onReorder: controller.reorderSections,
        fields: const [
          OnlineStoreFormField('key', 'رمز القسم',
              helperText: 'اسم تقني قصير وثابت، مثل featured_bikes.'),
          OnlineStoreFormField('section_type', 'محتوى القسم', options: [
            'hero',
            'categories',
            'best_sellers',
            'recent',
            'maintenance',
            'offers',
            'custom'
          ], optionLabels: {
            'hero': 'واجهة رئيسية بارزة',
            'categories': 'تصنيفات المتجر',
            'best_sellers': 'الأكثر مبيعاً',
            'recent': 'وصل حديثاً',
            'maintenance': 'خدمات الصيانة',
            'offers': 'العروض',
            'custom': 'قسم مخصص',
          }),
          OnlineStoreFormField('title_translations.ar', 'العنوان العربي'),
          OnlineStoreFormField('selection_mode', 'كيف تُختار العناصر؟',
              options: [
                'manual',
                'automatic',
                'dedicated_banners'
              ],
              optionLabels: {
                'manual': 'أختار العناصر بنفسي',
                'automatic': 'اختيار تلقائي من النظام',
                'dedicated_banners': 'بانرات مخصصة لهذا القسم',
              }),
          OnlineStoreFormField(
              'selection_config.selector', 'قاعدة الاختيار التلقائي',
              helperText: 'يُستخدم فقط عند اختيار الوضع التلقائي.'),
          OnlineStoreFormField('selection_config.limit', 'عدد العناصر المعروضة',
              numeric: true),
          OnlineStoreFormField('is_visible', 'ظاهر', boolean: true),
          OnlineStoreFormField('sort_order', 'موضع القسم',
              numeric: true,
              helperText:
                  'الرقم الأصغر يظهر أولاً، أو رتّب بالسحب من القائمة.'),
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
      builder: (context, setState) => OnlineStoreDialog(
        icon: Icons.view_carousel_outlined,
        title: const Text('اختيار عناصر متوافقة'),
        content: SizedBox(
          width: OnlineStoreAdminUi.dialogWidth(context),
          height: (MediaQuery.sizeOf(context).height * .65).clamp(280, 560),
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
          OutlinedButton(
              style: OnlineStoreAdminUi.actionButtonStyle,
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
