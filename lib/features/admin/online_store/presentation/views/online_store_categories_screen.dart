import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        fields: const [
          OnlineStoreFormField('name_translations.ar', 'الاسم العربي'),
          OnlineStoreFormField('name_translations.en', 'الاسم الإنجليزي'),
          OnlineStoreFormField('parent_id', 'رقم التصنيف الأب', numeric: true),
          OnlineStoreFormField('image_path', 'مسار الصورة'),
          OnlineStoreFormField('is_active', 'نشط', boolean: true),
          OnlineStoreFormField('show_on_home', 'يظهر في الرئيسية',
              boolean: true),
          OnlineStoreFormField('sort_order', 'الترتيب', numeric: true),
        ],
      );

  Future<void> _assignListings(int categoryId) async {
    final listings = (await controller.repository.listings()).items;
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
