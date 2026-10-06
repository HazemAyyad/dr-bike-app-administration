import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/helpers/show_net_image.dart';
import '../../data/online_store_models.dart';
import '../controllers/online_store_categories_controller.dart';
import '../utils/online_store_permissions.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_resource_screen.dart';

Map<String, dynamic> onlineStoreCategoryPayload({
  required String nameAr,
  required String nameEn,
  required int? parentId,
  required bool isActive,
  required bool showOnHome,
  required int sortOrder,
  required String imagePath,
}) =>
    {
      'name_translations': {'ar': nameAr.trim(), 'en': nameEn.trim()},
      'parent_id': parentId,
      'is_active': isActive,
      'show_on_home': showOnHome,
      'sort_order': sortOrder,
      'image_path': imagePath.isEmpty ? null : imagePath,
    };

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
        cardBuilder: _categoryCard,
      );

  Widget _categoryCard(
    BuildContext context,
    OnlineStoreEntity item,
    Widget trailing,
  ) {
    final imagePath = '${item.values['image_path'] ?? ''}';
    final parent = onlineStoreMap(item.values['parent']);
    final parentName = OnlineStoreEntity(parent).label;
    final active =
        item.values['is_active'] == true || item.values['is_active'] == 1;
    final home =
        item.values['show_on_home'] == true || item.values['show_on_home'] == 1;
    return Card(
      color: OnlineStoreAdminUi.surface,
      child: ListTile(
        onTap: OnlineStorePermissions.canManageCategories
            ? () => _editAndSave(context, item)
            : null,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.square(
            dimension: 56,
            child: imagePath.isEmpty
                ? const ColoredBox(
                    color: OnlineStoreAdminUi.surfaceMuted,
                    child: Icon(Icons.category_outlined),
                  )
                : Image.network(ShowNetImage.getPhoto(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined)),
          ),
        ),
        title: Text(item.label,
            style: const TextStyle(
                color: OnlineStoreAdminUi.textPrimary,
                fontWeight: FontWeight.w700)),
        subtitle: Text([
          if (parent.isNotEmpty) 'الأب: $parentName',
          active ? 'نشط' : 'غير نشط',
          home ? 'يظهر في الرئيسية' : 'لا يظهر في الرئيسية',
          'موضع العرض: ${(int.tryParse('${item.values['sort_order']}') ?? 0) + 1}',
        ].join(' • ')),
        trailing: trailing,
      ),
    );
  }

  Future<void> _editAndSave(
      BuildContext context, OnlineStoreEntity item) async {
    final payload = await _editCategory(context, item);
    if (payload != null) await controller.updateItem(item.id, payload);
  }

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
    var active = item == null ||
        item.values['is_active'] == true ||
        item.values['is_active'] == 1;
    var showOnHome = item?.values['show_on_home'] == true ||
        item?.values['show_on_home'] == 1;
    var imagePath = '${item?.values['image_path'] ?? ''}';
    XFile? pickedImage;
    var uploading = false;
    String? uploadError;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(item == null ? 'إضافة تصنيف' : 'تعديل التصنيف'),
          content: OnlineStoreDialogBody(
            maxWidth: OnlineStoreAdminUi.dialogWideMaxWidth,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              InkWell(
                onTap: uploading
                    ? null
                    : () async {
                        final file = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        if (file != null) setState(() => pickedImage = file);
                      },
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: OnlineStoreAdminUi.surfaceMuted,
                    border: Border.all(color: OnlineStoreAdminUi.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: pickedImage != null
                      ? Image.file(File(pickedImage!.path), fit: BoxFit.cover)
                      : imagePath.isNotEmpty
                          ? Image.network(ShowNetImage.getPhoto(imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image_outlined))
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined),
                                Text('اختيار صورة التصنيف'),
                              ],
                            ),
                ),
              ),
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
                decoration: const InputDecoration(
                  labelText: 'موضع التصنيف',
                  helperText:
                      'الرقم الأصغر يظهر أولاً. ويمكنك الترتيب بالسحب من القائمة.',
                ),
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
              if (uploadError != null)
                Text(uploadError!,
                    style: const TextStyle(color: OnlineStoreAdminUi.danger)),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء')),
            OutlinedButton(
              style: OnlineStoreAdminUi.actionButtonStyle,
              onPressed: uploading
                  ? null
                  : () async {
                      setState(() {
                        uploading = true;
                        uploadError = null;
                      });
                      try {
                        if (pickedImage != null) {
                          imagePath =
                              await controller.uploadImage(pickedImage!);
                        }
                        if (!dialogContext.mounted) return;
                        Navigator.pop(
                          dialogContext,
                          onlineStoreCategoryPayload(
                            nameAr: nameAr.text,
                            nameEn: nameEn.text,
                            parentId: parentId,
                            isActive: active,
                            showOnHome: showOnHome,
                            sortOrder: int.tryParse(sortOrder.text.trim()) ?? 0,
                            imagePath: imagePath,
                          ),
                        );
                      } catch (exception) {
                        setState(() => uploadError = exception.toString());
                      } finally {
                        setState(() => uploading = false);
                      }
                    },
              child: Text(uploading ? 'جارٍ الرفع...' : 'حفظ'),
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
          width: OnlineStoreAdminUi.dialogWidth(context),
          height: (MediaQuery.sizeOf(context).height * .65).clamp(280, 560),
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
          OutlinedButton(
              style: OnlineStoreAdminUi.actionButtonStyle,
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
