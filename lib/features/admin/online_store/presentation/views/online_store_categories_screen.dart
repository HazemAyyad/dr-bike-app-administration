import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/online_store_models.dart';
import '../controllers/online_store_categories_controller.dart';
import '../utils/online_store_permissions.dart';
import '../widgets/online_store_resource_screen.dart';

class OnlineStoreCategoriesScreen
    extends GetView<OnlineStoreCategoriesController> {
  const OnlineStoreCategoriesScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) =>
      OnlineStoreResourceScreen<OnlineStoreCategoriesController>(
        title: 'تصنيفات المتجر',
        icon: Icons.account_tree_outlined,
        canManage: OnlineStorePermissions.canManageCategories,
        subtitle: 'تصنيف مستقل عن تصنيفات المخزون وأقسامه',
        inspectLabel: 'تعيين قوائم المنتجات',
        onInspect: (item) => _assignListings(item.id),
        actions: const {OnlineStoreResourceAction.delete},
        onReorder: controller.reorderCategories,
        editor: _editCategory,
      );

  Future<Map<String, dynamic>?> _editCategory(
    BuildContext context,
    OnlineStoreEntity? item,
  ) async {
    final nameAr = TextEditingController(
        text:
            '${onlineStoreMap(item?.values['name_translations'])['ar'] ?? ''}');
    final nameEn = TextEditingController(
        text:
            '${onlineStoreMap(item?.values['name_translations'])['en'] ?? ''}');
    final sortOrder = TextEditingController(
        text: '${item?.values['sort_order'] ?? controller.items.length}');
    int? parentId = int.tryParse('${item?.values['parent_id'] ?? ''}');
    var active = item == null || item.values['is_active'] == true;
    var showOnHome = item?.values['show_on_home'] == true;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(item == null ? 'إضافة تصنيف' : 'تعديل التصنيف'),
          content: SizedBox(
            width: 460,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameAr,
                decoration: const InputDecoration(labelText: 'الاسم العربي'),
              ),
              TextField(
                controller: nameEn,
                decoration: const InputDecoration(labelText: 'الاسم الإنجليزي'),
              ),
              DropdownButtonFormField<int?>(
                initialValue: parentId,
                decoration: const InputDecoration(labelText: 'التصنيف الأب'),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('بدون تصنيف أب')),
                  ...controller.items
                      .where((category) => category.id != item?.id)
                      .map((category) => DropdownMenuItem<int?>(
                            value: category.id,
                            child: Text(category.label),
                          )),
                ],
                onChanged: (value) => setState(() => parentId = value),
              ),
              TextField(
                controller: sortOrder,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الترتيب'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('نشط'),
                value: active,
                onChanged: (value) => setState(() => active = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('يظهر في الرئيسية'),
                value: showOnHome,
                onChanged: (value) => setState(() => showOnHome = value),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, {
                'name_translations': {
                  'ar': nameAr.text.trim(),
                  'en': nameEn.text.trim(),
                },
                'parent_id': parentId,
                'is_active': active,
                'show_on_home': showOnHome,
                'sort_order': int.tryParse(sortOrder.text.trim()) ?? 0,
              }),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    nameAr.dispose();
    nameEn.dispose();
    sortOrder.dispose();
    return result;
  }

  Future<void> _assignListings(int categoryId) async {
    final listings = await controller.pickerListings();
    final selected = <int>{};
    final accepted = await Get.dialog<bool>(StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('تعيين قوائم للتصنيف'),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: listings
                .map((listing) => CheckboxListTile(
                      value: selected.contains(listing.id),
                      onChanged: (value) => setState(() {
                        value == true
                            ? selected.add(listing.id)
                            : selected.remove(listing.id);
                      }),
                      title: Text(listing.productName.isEmpty
                          ? 'قائمة #${listing.id}'
                          : listing.productName),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Get.back(result: true),
              child: const Text('حفظ')),
        ],
      ),
    ));
    if (accepted == true) {
      await controller.replaceListings(categoryId, selected.toList());
      await controller.load();
    }
  }
}
