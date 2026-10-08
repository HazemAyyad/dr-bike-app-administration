import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/online_store_models.dart';
import '../controllers/online_store_categories_controller.dart';
import '../utils/online_store_permissions.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_resource_screen.dart';
import '../widgets/online_store_network_image.dart';

Map<String, dynamic> onlineStoreCategoryPayload({
  required String nameAr,
  required String nameEn,
  required int? parentId,
  required bool isActive,
  required bool showOnHome,
  required String imagePath,
}) =>
    {
      'name_translations': {'ar': nameAr.trim(), 'en': nameEn.trim()},
      'parent_id': parentId,
      'is_active': isActive,
      'show_on_home': showOnHome,
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
        inspectLabel: 'تعيين قوائم المنتجات',
        onInspect: (item) => _assignListings(item.id),
        actions: const {OnlineStoreResourceAction.delete},
        onDelete: _confirmDeleteCategory,
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
    final products = int.tryParse('${item.values['memberships_count']}') ?? 0;
    return Card(
      color: OnlineStoreAdminUi.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: OnlineStoreAdminUi.border),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -1),
        onTap: OnlineStorePermissions.canManageCategories
            ? () => _editAndSave(context, item)
            : null,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.square(
            dimension: 48,
            child: imagePath.isEmpty
                ? const ColoredBox(
                    color: OnlineStoreAdminUi.surfaceMuted,
                    child: Icon(Icons.category_outlined),
                  )
                : OnlineStoreNetworkImage(path: imagePath),
          ),
        ),
        title: Text(item.label,
            style: const TextStyle(
                color: OnlineStoreAdminUi.textPrimary,
                fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Wrap(spacing: 6, runSpacing: 4, children: [
            _categoryBadge(
                active ? 'نشط' : 'متوقف',
                active
                    ? OnlineStoreAdminUi.success
                    : OnlineStoreAdminUi.textSecondary),
            if (home) _categoryBadge('في الرئيسية', OnlineStoreAdminUi.accent),
            _categoryBadge('$products منتج', const Color(0xFF1D5D9B)),
            if (parent.isNotEmpty)
              _categoryBadge(
                  'ضمن $parentName', OnlineStoreAdminUi.textSecondary),
          ]),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (OnlineStorePermissions.canManageCategories)
            IconButton(
              tooltip: active ? 'إيقاف التصنيف' : 'تنشيط التصنيف',
              visualDensity: VisualDensity.compact,
              onPressed: () => controller.updateItem(item.id, {
                'is_active': !active,
              }),
              icon: Icon(
                active ? Icons.pause_circle_outline : Icons.play_circle_outline,
                color: active
                    ? OnlineStoreAdminUi.textSecondary
                    : OnlineStoreAdminUi.success,
              ),
            ),
          trailing,
        ]),
      ),
    );
  }

  Widget _categoryBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .22)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      );

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
    int? parentId = int.tryParse('${item?.values['parent_id'] ?? ''}');
    var active = item == null ||
        item.values['is_active'] == true ||
        item.values['is_active'] == 1;
    var showOnHome = item?.values['show_on_home'] == true ||
        item?.values['show_on_home'] == 1;
    var imagePath = '${item?.values['image_path'] ?? ''}';
    XFile? pickedImage;
    var uploading = false;
    var closing = false;
    String? uploadError;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => OnlineStoreDialog(
          icon: Icons.category_outlined,
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
                          ? OnlineStoreNetworkImage(path: imagePath)
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
                            imagePath: imagePath,
                          ),
                        );
                        closing = true;
                      } catch (exception) {
                        if (dialogContext.mounted) {
                          setState(() => uploadError = exception.toString());
                        }
                      } finally {
                        if (!closing && dialogContext.mounted) {
                          setState(() => uploading = false);
                        }
                      }
                    },
              child: Text(uploading ? 'جارٍ الرفع...' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
    // showDialog completes when pop starts, while the route can still animate
    // TextFields out. Keep their controllers alive until that transition ends.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    nameAr.dispose();
    nameEn.dispose();
    return result;
  }

  Future<void> _assignListings(int categoryId) async {
    final listings = await controller.pickerListings();
    final selected = <int>{};
    final accepted = await Get.dialog<bool>(StatefulBuilder(
      builder: (context, setState) => OnlineStoreDialog(
        icon: Icons.inventory_2_outlined,
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

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    OnlineStoreEntity item,
  ) async {
    final productsCount =
        int.tryParse('${item.values['memberships_count'] ?? 0}') ?? 0;
    final childrenCount =
        int.tryParse('${item.values['children_count'] ?? 0}') ?? 0;
    int? replacementId;
    final candidates = controller.items
        .where((candidate) =>
            candidate.id != item.id &&
            (candidate.values['is_active'] == true ||
                candidate.values['is_active'] == 1))
        .toList(growable: false);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => OnlineStoreDialog(
          icon: Icons.delete_outline,
          title: const Text('حذف التصنيف ونقل المنتجات'),
          content: OnlineStoreDialogBody(
            maxWidth: OnlineStoreAdminUi.dialogCompactMaxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('سيتم حذف «${item.label}» بعد معالجة الارتباطات.'),
                if (childrenCount > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'يوجد $childrenCount تصنيف فرعي. يجب نقله أو حذفه أولاً.',
                    style: const TextStyle(color: OnlineStoreAdminUi.danger),
                  ),
                ],
                if (productsCount > 0) ...[
                  const SizedBox(height: 14),
                  Text('يوجد $productsCount منتج. اختر التصنيف البديل:'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: replacementId,
                    decoration: const InputDecoration(
                      labelText: 'نقل المنتجات إلى',
                      prefixIcon: Icon(Icons.drive_file_move_outline),
                    ),
                    items: candidates
                        .map((candidate) => DropdownMenuItem(
                              value: candidate.id,
                              child: Text(candidate.label),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => replacementId = value),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            OutlinedButton.icon(
              onPressed: childrenCount > 0 ||
                      (productsCount > 0 && replacementId == null)
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              style: OutlinedButton.styleFrom(
                foregroundColor: OnlineStoreAdminUi.danger,
                side: const BorderSide(color: OnlineStoreAdminUi.danger),
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('تأكيد الحذف'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true) {
      await controller.removeWithReplacement(item.id, replacementId);
    }
  }
}
