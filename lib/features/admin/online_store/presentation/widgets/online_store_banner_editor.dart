import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/databases/api/end_points.dart';
import 'online_store_network_image.dart';
import '../../data/online_store_models.dart';
import '../controllers/online_store_banners_controller.dart';
import 'online_store_target_picker.dart';
import '../utils/online_store_admin_ui.dart';
import 'online_store_form_widgets.dart';

Map<String, dynamic> onlineStoreBannerDestination(
  String actionType, {
  int? targetId,
  String? url,
}) =>
    {
      'action_type': actionType,
      'action_target_id':
          {'listing', 'category', 'promotion'}.contains(actionType)
              ? targetId
              : null,
      'action_url': actionType == 'url' ? url?.trim() : null,
    };

Future<Map<String, dynamic>?> showOnlineStoreBannerEditor(
  BuildContext context, {
  required OnlineStoreBannersController controller,
  OnlineStoreEntity? item,
}) async {
  final listings = await controller.repository.allListings();
  final categories =
      await controller.repository.allEntities(EndPoints.onlineStoreCategories);
  final promotions =
      await controller.repository.allEntities(EndPoints.onlineStorePromotions);
  final options = <OnlineStoreTargetOption>[
    ...listings.map((listing) => OnlineStoreTargetOption(
          type: 'listing',
          id: listing.id,
          label: listing.productName.isEmpty
              ? 'قائمة #${listing.id}'
              : listing.productName,
          subtitle: 'قائمة منتج',
        )),
    ...categories.map((category) => OnlineStoreTargetOption(
          type: 'category',
          id: category.id,
          label: category.label,
          subtitle: 'تصنيف متجر',
        )),
    ...promotions.map((promotion) => OnlineStoreTargetOption(
          type: 'promotion',
          id: promotion.id,
          label: promotion.label,
          subtitle: 'عرض ترويجي',
        )),
  ];
  if (!context.mounted) return null;
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _BannerEditorDialog(
      controller: controller,
      item: item,
      options: options,
    ),
  );
}

class _BannerEditorDialog extends StatefulWidget {
  const _BannerEditorDialog({
    required this.controller,
    required this.options,
    this.item,
  });

  final OnlineStoreBannersController controller;
  final OnlineStoreEntity? item;
  final List<OnlineStoreTargetOption> options;

  @override
  State<_BannerEditorDialog> createState() => _BannerEditorDialogState();
}

class _BannerEditorDialogState extends State<_BannerEditorDialog> {
  late final TextEditingController titleAr;
  late final TextEditingController titleEn;
  late final TextEditingController contentAr;
  late final TextEditingController contentEn;
  late final TextEditingController url;
  late final TextEditingController startsAt;
  late final TextEditingController endsAt;
  late final TextEditingController sortOrder;
  late String actionType;
  late String imagePath;
  late bool isActive;
  int? targetId;
  XFile? pickedImage;
  bool uploading = false;
  String? error;

  Map<String, dynamic> get values => widget.item?.values ?? const {};

  @override
  void initState() {
    super.initState();
    final titles = onlineStoreMap(values['title_translations']);
    final content = onlineStoreMap(values['content_translations']);
    titleAr = TextEditingController(text: '${titles['ar'] ?? ''}');
    titleEn = TextEditingController(text: '${titles['en'] ?? ''}');
    contentAr = TextEditingController(text: '${content['ar'] ?? ''}');
    contentEn = TextEditingController(text: '${content['en'] ?? ''}');
    url = TextEditingController(text: '${values['action_url'] ?? ''}');
    startsAt = TextEditingController(text: '${values['starts_at'] ?? ''}');
    endsAt = TextEditingController(text: '${values['ends_at'] ?? ''}');
    sortOrder = TextEditingController(text: '${values['sort_order'] ?? 0}');
    actionType = '${values['action_type'] ?? 'none'}';
    imagePath = '${values['image_path'] ?? ''}';
    isActive = values['is_active'] == true || values['is_active'] == 1;
    targetId = int.tryParse('${values['action_target_id'] ?? ''}');
  }

  @override
  void dispose() {
    for (final controller in [
      titleAr,
      titleEn,
      contentAr,
      contentEn,
      url,
      startsAt,
      endsAt,
      sortOrder,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) setState(() => pickedImage = picked);
  }

  Future<void> _pickTarget() async {
    final allowed = widget.options
        .where((option) => option.type == actionType)
        .toList(growable: false);
    final selected = await showOnlineStoreTargetPicker(
      context,
      title: 'اختيار الوجهة',
      options: allowed,
      selectedKeys: targetId == null ? const [] : ['$actionType:$targetId'],
      multiple: false,
    );
    if (selected != null && mounted) {
      setState(() => targetId = selected.isEmpty ? null : selected.single.id);
    }
  }

  String get _targetLabel {
    for (final option in widget.options) {
      if (option.type == actionType && option.id == targetId) {
        return option.label;
      }
    }
    return 'اختيار الوجهة';
  }

  Future<void> _submit() async {
    if (pickedImage == null && imagePath.isEmpty) {
      setState(() => error = 'اختر صورة للبانر.');
      return;
    }
    if ({'listing', 'category', 'promotion'}.contains(actionType) &&
        targetId == null) {
      setState(() => error = 'اختر وجهة البانر.');
      return;
    }
    if (actionType == 'url' && url.text.trim().isEmpty) {
      setState(() => error = 'أدخل رابط الوجهة.');
      return;
    }
    if (actionType == 'url') {
      final destination = Uri.tryParse(url.text.trim());
      if (destination == null ||
          !{'http', 'https'}.contains(destination.scheme)) {
        setState(() => error = 'استخدم رابطًا يبدأ بـ http أو https.');
        return;
      }
    }
    setState(() {
      uploading = true;
      error = null;
    });
    try {
      if (pickedImage != null) {
        imagePath = await widget.controller.uploadImage(pickedImage!);
      }
      if (!mounted) return;
      Navigator.pop(context, {
        'image_path': imagePath,
        'title_translations': {
          'ar': titleAr.text.trim(),
          'en': titleEn.text.trim(),
        },
        'content_translations': {
          'ar': contentAr.text.trim(),
          'en': contentEn.text.trim(),
        },
        ...onlineStoreBannerDestination(
          actionType,
          targetId: targetId,
          url: url.text,
        ),
        'starts_at': startsAt.text.trim().isEmpty ? null : startsAt.text.trim(),
        'ends_at': endsAt.text.trim().isEmpty ? null : endsAt.text.trim(),
        'is_active': isActive,
        'sort_order': int.tryParse(sortOrder.text.trim()) ?? 0,
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.item == null ? 'إضافة بانر' : 'تعديل البانر'),
        content: OnlineStoreDialogBody(
          maxWidth: OnlineStoreAdminUi.dialogWideMaxWidth,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            InkWell(
              onTap: uploading ? null : _pickImage,
              child: Container(
                height: 140,
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
                              Text('اختيار صورة البانر (حتى 10 MB)'),
                            ],
                          ),
              ),
            ),
            _field(titleAr, 'العنوان العربي'),
            _field(titleEn, 'العنوان الإنجليزي'),
            _field(contentAr, 'المحتوى العربي'),
            _field(contentEn, 'المحتوى الإنجليزي'),
            DropdownButtonFormField<String>(
              initialValue: actionType,
              decoration: const InputDecoration(labelText: 'نوع الوجهة'),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('بدون وجهة')),
                DropdownMenuItem(value: 'listing', child: Text('قائمة منتج')),
                DropdownMenuItem(value: 'category', child: Text('تصنيف')),
                DropdownMenuItem(value: 'promotion', child: Text('عرض')),
                DropdownMenuItem(value: 'url', child: Text('رابط خارجي')),
              ],
              onChanged: (value) => setState(() {
                actionType = value ?? 'none';
                targetId = null;
              }),
            ),
            if ({'listing', 'category', 'promotion'}.contains(actionType))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_targetLabel),
                trailing: const Icon(Icons.chevron_left),
                onTap: _pickTarget,
              ),
            if (actionType == 'url') _field(url, 'رابط الوجهة'),
            OnlineStoreFormSection(
                title: 'مدة ظهور البانر',
                description:
                    'اختياري. اتركها فارغة ليظهر البانر دون مدة محددة.',
                icon: Icons.schedule_outlined,
                child: Row(children: [
                  Expanded(
                      child: OnlineStoreDateTimeField(
                    controller: startsAt,
                    label: 'تاريخ ووقت البداية',
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      child: OnlineStoreDateTimeField(
                    controller: endsAt,
                    label: 'تاريخ ووقت النهاية',
                  )),
                ])),
            _field(sortOrder, 'موضع البانر',
                numeric: true,
                helper:
                    'رقم أصغر يعني ظهوراً أبكر. يمكنك أيضاً السحب من قائمة البانرات.'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('نشط'),
              value: isActive,
              onChanged: (value) => setState(() => isActive = value),
            ),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: uploading ? null : () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          OutlinedButton.icon(
            style: OnlineStoreAdminUi.actionButtonStyle,
            onPressed: uploading ? null : _submit,
            icon: uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('حفظ'),
          ),
        ],
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    String? helper,
  }) =>
      TextField(
        controller: controller,
        keyboardType: numeric ? TextInputType.number : null,
        decoration: InputDecoration(
            labelText: label, helperText: helper, isDense: true),
      );
}
