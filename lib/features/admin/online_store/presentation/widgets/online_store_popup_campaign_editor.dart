import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/databases/api/end_points.dart';
import '../../data/online_store_models.dart';
import '../controllers/online_store_popup_campaigns_controller.dart';
import '../utils/online_store_admin_ui.dart';
import 'online_store_form_widgets.dart';
import 'online_store_network_image.dart';
import 'online_store_target_picker.dart';

Future<Map<String, dynamic>?> showOnlineStorePopupCampaignEditor(
  BuildContext context, {
  required OnlineStorePopupCampaignsController controller,
  OnlineStoreEntity? item,
}) async {
  final listings = await controller.repository.allListings();
  final groups = await Future.wait([
    controller.repository.allEntities(EndPoints.onlineStoreCategories),
    controller.repository.allEntities(EndPoints.onlineStorePromotions),
    controller.repository.allEntities(EndPoints.onlineStoreCoupons),
  ]);
  final options = <OnlineStoreTargetOption>[
    ...listings.map((value) => OnlineStoreTargetOption(
          type: 'listing',
          id: value.id,
          label: value.productName.isEmpty
              ? 'منتج #${value.productId}'
              : value.productName,
          subtitle: 'منتج معروض',
        )),
    ...groups[0].map((value) => OnlineStoreTargetOption(
          type: 'category',
          id: value.id,
          label: value.label,
          subtitle: 'تصنيف متجر',
        )),
    ...groups[1].map((value) => OnlineStoreTargetOption(
          type: 'promotion',
          id: value.id,
          label: value.label,
          subtitle: 'عرض متجر',
        )),
    ...groups[2].map((value) => OnlineStoreTargetOption(
          type: 'coupon',
          id: value.id,
          label: value.label,
          subtitle: 'كوبون',
        )),
  ];
  if (!context.mounted) return null;
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _PopupCampaignEditor(
        item: item, controller: controller, options: options),
  );
}

class _PopupCampaignEditor extends StatefulWidget {
  const _PopupCampaignEditor(
      {required this.controller, required this.options, this.item});

  final OnlineStorePopupCampaignsController controller;
  final List<OnlineStoreTargetOption> options;
  final OnlineStoreEntity? item;

  @override
  State<_PopupCampaignEditor> createState() => _PopupCampaignEditorState();
}

class _PopupCampaignEditorState extends State<_PopupCampaignEditor> {
  final locales = const ['ar', 'en', 'he'];
  final localeLabels = const {'ar': 'العربية', 'en': 'English', 'he': 'עברית'};
  late final TextEditingController name;
  late final TextEditingController url;
  late final TextEditingController days;
  late final TextEditingController priority;
  late final TextEditingController startsAt;
  late final TextEditingController endsAt;
  final titles = <String, TextEditingController>{};
  final contents = <String, TextEditingController>{};
  final buttons = <String, TextEditingController>{};
  late String imagePath;
  late String theme;
  late String audience;
  late String frequency;
  late String actionType;
  late bool isActive;
  late bool sendPush;
  int? targetId;
  XFile? pickedImage;
  bool saving = false;
  String? error;

  Map<String, dynamic> get values => widget.item?.values ?? const {};

  @override
  void initState() {
    super.initState();
    final titleValues = onlineStoreMap(values['title_translations']);
    final contentValues = onlineStoreMap(values['content_translations']);
    final buttonValues = onlineStoreMap(values['button_translations']);
    for (final locale in locales) {
      titles[locale] =
          TextEditingController(text: '${titleValues[locale] ?? ''}');
      contents[locale] =
          TextEditingController(text: '${contentValues[locale] ?? ''}');
      buttons[locale] =
          TextEditingController(text: '${buttonValues[locale] ?? ''}');
    }
    name = TextEditingController(text: '${values['name'] ?? ''}');
    url = TextEditingController(text: '${values['action_url'] ?? ''}');
    days = TextEditingController(text: '${values['audience_days'] ?? 14}');
    priority = TextEditingController(text: '${values['priority'] ?? 0}');
    startsAt = TextEditingController(text: '${values['starts_at'] ?? ''}');
    endsAt = TextEditingController(text: '${values['ends_at'] ?? ''}');
    imagePath = '${values['image_path'] ?? ''}';
    theme = '${values['theme'] ?? 'brand'}';
    audience = '${values['audience_type'] ?? 'all'}';
    frequency = '${values['display_frequency'] ?? 'once'}';
    actionType = '${values['action_type'] ?? 'none'}';
    targetId = int.tryParse('${values['action_target_id'] ?? ''}');
    isActive = widget.item == null ||
        values['is_active'] == true ||
        values['is_active'] == 1;
    sendPush = widget.item == null;
  }

  @override
  void dispose() {
    for (final controller in [
      name,
      url,
      days,
      priority,
      startsAt,
      endsAt,
      ...titles.values,
      ...contents.values,
      ...buttons.values
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null && mounted) setState(() => pickedImage = file);
  }

  Future<void> _pickTarget() async {
    final selected = await showOnlineStoreTargetPicker(
      context,
      title: 'اختر وجهة الزر',
      options:
          widget.options.where((value) => value.type == actionType).toList(),
      selectedKeys: targetId == null ? const [] : ['$actionType:$targetId'],
      multiple: false,
    );
    if (selected != null && mounted) {
      setState(() => targetId = selected.isEmpty ? null : selected.single.id);
    }
  }

  String get targetLabel {
    for (final option in widget.options) {
      if (option.type == actionType && option.id == targetId) {
        return option.label;
      }
    }
    return 'اضغط لاختيار الوجهة';
  }

  Future<void> _submit() async {
    if (name.text.trim().isEmpty || titles['ar']!.text.trim().isEmpty) {
      setState(() => error = 'أدخل اسم الحملة والعنوان العربي.');
      return;
    }
    if ({'listing', 'category', 'promotion', 'coupon'}.contains(actionType) &&
        targetId == null) {
      setState(() => error = 'اختر وجهة الزر.');
      return;
    }
    if (actionType == 'url') {
      final uri = Uri.tryParse(url.text.trim());
      if (uri == null || !{'http', 'https'}.contains(uri.scheme)) {
        setState(() => error = 'أدخل رابطاً صحيحاً يبدأ بـ http أو https.');
        return;
      }
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      if (pickedImage != null) {
        imagePath = await widget.controller.uploadImage(pickedImage!);
      }
      if (!mounted) return;
      Map<String, String> localized(
              Map<String, TextEditingController> source) =>
          {for (final locale in locales) locale: source[locale]!.text.trim()};
      Navigator.pop(context, {
        'name': name.text.trim(),
        'image_path': imagePath.isEmpty ? null : imagePath,
        'title_translations': localized(titles),
        'content_translations': localized(contents),
        'button_translations': localized(buttons),
        'theme': theme,
        'audience_type': audience,
        'audience_days':
            audience == 'new_users' ? int.tryParse(days.text) ?? 14 : null,
        'display_frequency': frequency,
        'action_type': actionType,
        'action_target_id':
            {'listing', 'category', 'promotion', 'coupon'}.contains(actionType)
                ? targetId
                : null,
        'action_url': actionType == 'url' ? url.text.trim() : null,
        'is_active': isActive,
        'starts_at': startsAt.text.trim().isEmpty ? null : startsAt.text.trim(),
        'ends_at': endsAt.text.trim().isEmpty ? null : endsAt.text.trim(),
        'priority': int.tryParse(priority.text) ?? 0,
        'send_push': sendPush,
      });
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => OnlineStoreDialog(
        icon: Icons.campaign_outlined,
        title: Text(widget.item == null
            ? 'إضافة إعلان منبثق'
            : 'تعديل الإعلان المنبثق'),
        content: OnlineStoreDialogBody(
          maxWidth: OnlineStoreAdminUi.dialogWideMaxWidth,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(
                    labelText: 'اسم داخلي للحملة',
                    prefixIcon: Icon(Icons.badge_outlined))),
            const SizedBox(height: 10),
            InkWell(
              onTap: saving ? null : _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: OnlineStoreAdminUi.surfaceMuted,
                    border: Border.all(color: OnlineStoreAdminUi.border),
                    borderRadius: BorderRadius.circular(14)),
                clipBehavior: Clip.antiAlias,
                child: pickedImage != null
                    ? Image.file(File(pickedImage!.path), fit: BoxFit.cover)
                    : imagePath.isNotEmpty
                        ? OnlineStoreNetworkImage(path: imagePath)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 34),
                                SizedBox(height: 6),
                                Text('إضافة صورة جذابة للإعلان')
                              ]),
              ),
            ),
            const SizedBox(height: 14),
            DefaultTabController(
              length: locales.length,
              child: Column(children: [
                TabBar(
                    tabs: locales
                        .map((locale) => Tab(text: localeLabels[locale]))
                        .toList()),
                SizedBox(
                  height: 280,
                  child: TabBarView(
                      children: locales
                          .map((locale) => Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(children: [
                                  TextField(
                                      controller: titles[locale],
                                      decoration: const InputDecoration(
                                          labelText: 'العنوان')),
                                  const SizedBox(height: 10),
                                  TextField(
                                      controller: contents[locale],
                                      minLines: 3,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                          labelText: 'النص')),
                                  const SizedBox(height: 10),
                                  TextField(
                                      controller: buttons[locale],
                                      decoration: const InputDecoration(
                                          labelText: 'نص الزر')),
                                ]),
                              ))
                          .toList()),
                ),
              ]),
            ),
            _dropdown(
                'شكل الإعلان',
                theme,
                const {
                  'brand': 'بنفسجي أنيق',
                  'success': 'أخضر نجاح',
                  'warm': 'دافئ للعروض',
                  'dark': 'داكن فاخر'
                },
                (value) => setState(() => theme = value)),
            _dropdown(
                'الجمهور المستهدف',
                audience,
                const {
                  'all': 'الجميع',
                  'guests': 'الزوار بدون تسجيل',
                  'registered': 'المستخدمون المسجلون',
                  'new_users': 'المستخدمون الجدد',
                  'no_orders': 'من لم يطلبوا بعد',
                  'customers': 'من لديهم طلبات'
                },
                (value) => setState(() => audience = value)),
            if (audience == 'new_users')
              TextField(
                  controller: days,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'يُعتبر جديداً خلال عدد أيام',
                      prefixIcon: Icon(Icons.today_outlined))),
            _dropdown(
                'تكرار الظهور',
                frequency,
                const {
                  'once': 'مرة واحدة لكل مستخدم',
                  'once_per_session': 'مرة عند كل دخول للتطبيق',
                  'always': 'في كل دخول حتى يخفيه المستخدم'
                },
                (value) => setState(() => frequency = value)),
            _dropdown(
                'وجهة الزر',
                actionType,
                const {
                  'none': 'إغلاق وبدء التصفح',
                  'listing': 'منتج',
                  'category': 'تصنيف',
                  'promotion': 'عرض',
                  'coupon': 'كوبون',
                  'url': 'رابط خارجي'
                },
                (value) => setState(() {
                      actionType = value;
                      targetId = null;
                    })),
            if ({'listing', 'category', 'promotion', 'coupon'}
                .contains(actionType))
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.ads_click_outlined),
                  title: Text(targetLabel),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: _pickTarget),
            if (actionType == 'url')
              TextField(
                  controller: url,
                  keyboardType: TextInputType.url,
                  decoration:
                      const InputDecoration(labelText: 'الرابط الخارجي')),
            OnlineStoreFormSection(
              title: 'جدولة الإعلان',
              description:
                  'اترك التاريخ فارغاً إذا أردت أن يبدأ أو ينتهي دون موعد محدد.',
              icon: Icons.schedule_outlined,
              child: OnlineStoreDateRangeFields(
                  fromController: startsAt,
                  toController: endsAt,
                  fromLabel: 'بداية الظهور',
                  toLabel: 'نهاية الظهور',
                  includeTime: true),
            ),
            TextField(
                controller: priority,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'أولوية الظهور',
                    helperText:
                        'الرقم الأعلى يظهر أولاً عندما ينطبق أكثر من إعلان.')),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('الحملة نشطة'),
                subtitle: const Text('يمكن حفظها متوقفة وتجهيزها قبل النشر.'),
                value: isActive,
                onChanged: (value) => setState(() {
                      isActive = value;
                      if (!value) sendPush = false;
                    })),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('إرسال Push للمستخدمين عند الحفظ'),
                subtitle: Text(widget.item == null
                    ? 'سيصل إشعار مرة واحدة لنفس جمهور الإعلان.'
                    : 'فعّل هذا الخيار فقط إذا أردت إعادة إرسال الإعلان.'),
                value: sendPush,
                onChanged: isActive
                    ? (value) => setState(() => sendPush = value)
                    : null),
            if (error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child:
                      Text(error!, style: const TextStyle(color: Colors.red))),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('إلغاء')),
          OutlinedButton.icon(
              style: OnlineStoreAdminUi.actionButtonStyle,
              onPressed: saving ? null : _submit,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: const Text('حفظ الحملة')),
        ],
      );

  Widget _dropdown(String label, String value, Map<String, String> options,
          ValueChanged<String> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: options.entries
              .map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      );
}
