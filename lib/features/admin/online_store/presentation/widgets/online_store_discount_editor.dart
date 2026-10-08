import 'package:flutter/material.dart';

import '../../../../../../core/databases/api/end_points.dart';
import '../../data/online_store_models.dart';
import '../controllers/online_store_resource_controller.dart';
import 'online_store_target_picker.dart';
import '../utils/online_store_admin_ui.dart';
import 'online_store_form_widgets.dart';

enum OnlineStoreDiscountKind { promotion, coupon }

List<Map<String, dynamic>> onlineStoreDiscountTargets(
  String scope,
  Iterable<OnlineStoreTargetOption> targets,
) =>
    scope == 'global'
        ? <Map<String, dynamic>>[]
        : targets.map((target) => target.toJson()).toList(growable: false);

Future<Map<String, dynamic>?> showOnlineStoreDiscountEditor(
  BuildContext context, {
  required OnlineStoreResourceController controller,
  required OnlineStoreDiscountKind kind,
  OnlineStoreEntity? item,
}) async {
  final listings = await controller.repository.allListings();
  final categories =
      await controller.repository.allEntities(EndPoints.onlineStoreCategories);
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
  ];
  if (!context.mounted) return null;
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _DiscountEditorDialog(
      kind: kind,
      item: item,
      options: options,
    ),
  );
}

class _DiscountEditorDialog extends StatefulWidget {
  const _DiscountEditorDialog({
    required this.kind,
    required this.options,
    this.item,
  });

  final OnlineStoreDiscountKind kind;
  final OnlineStoreEntity? item;
  final List<OnlineStoreTargetOption> options;

  @override
  State<_DiscountEditorDialog> createState() => _DiscountEditorDialogState();
}

class _DiscountEditorDialogState extends State<_DiscountEditorDialog> {
  final controllers = <String, TextEditingController>{};
  late String discountType;
  late String appliesTo;
  late String scope;
  late String eligibility;
  late bool active;
  late List<OnlineStoreTargetOption> targets;
  String? error;

  Map<String, dynamic> get values => widget.item?.values ?? const {};
  bool get isCoupon => widget.kind == OnlineStoreDiscountKind.coupon;

  @override
  void initState() {
    super.initState();
    for (final key in [
      if (isCoupon) 'code' else 'name',
      'discount_value',
      'starts_at',
      'ends_at',
      if (!isCoupon) 'priority',
      if (isCoupon) 'minimum_order',
      if (isCoupon) 'total_usage_limit',
      if (isCoupon) 'per_user_usage_limit',
    ]) {
      controllers[key] = TextEditingController(text: '${values[key] ?? ''}');
    }
    discountType = '${values['discount_type'] ?? 'percentage'}';
    appliesTo = '${values['applies_to'] ?? 'both'}';
    scope = '${values['scope'] ?? 'global'}';
    eligibility = '${values['eligible_account_type'] ?? 'both'}';
    active = values['is_active'] == true || values['is_active'] == 1;
    final selected = onlineStoreTargetKeys(values['targets']).toSet();
    targets = widget.options
        .where((option) => selected.contains(option.key))
        .toList(growable: true);
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectTargets() async {
    final selected = await showOnlineStoreTargetPicker(
      context,
      title: 'اختيار قوائم المنتجات والتصنيفات',
      options: widget.options,
      selectedKeys: targets.map((target) => target.key),
    );
    if (selected != null && mounted) setState(() => targets = selected);
  }

  void _submit() {
    final nameKey = isCoupon ? 'code' : 'name';
    if (controllers[nameKey]!.text.trim().isEmpty) {
      setState(
          () => error = isCoupon ? 'أدخل رمز الكوبون.' : 'أدخل اسم العرض.');
      return;
    }
    if (scope == 'targeted' && targets.isEmpty) {
      setState(() => error = 'النطاق المستهدف يحتاج هدفًا واحدًا على الأقل.');
      return;
    }
    final discountValue = _numberValue('discount_value');
    if (discountValue == null ||
        discountValue <= 0 ||
        (discountType == 'percentage' && discountValue > 100)) {
      setState(() => error = 'أدخل قيمة خصم صحيحة. النسبة لا تتجاوز 100.');
      return;
    }
    final payload = <String, dynamic>{
      nameKey: controllers[nameKey]!.text.trim(),
      'discount_type': discountType,
      'discount_value': discountValue,
      'applies_to': appliesTo,
      'scope': scope,
      'targets': onlineStoreDiscountTargets(scope, targets),
      'starts_at': _nullable('starts_at'),
      'ends_at': _nullable('ends_at'),
      'is_active': active,
    };
    if (isCoupon) {
      payload.addAll({
        'eligible_account_type': eligibility,
        'minimum_order': _numberValue('minimum_order') ?? 0,
        'total_usage_limit': _intValue('total_usage_limit'),
        'per_user_usage_limit': _intValue('per_user_usage_limit'),
      });
    } else {
      payload['priority'] = _numberValue('priority')?.toInt() ?? 0;
    }
    Navigator.pop(context, payload);
  }

  String? _nullable(String key) {
    final value = controllers[key]!.text.trim();
    return value.isEmpty ? null : value;
  }

  num? _numberValue(String key) => num.tryParse(controllers[key]!.text.trim());

  int? _intValue(String key) {
    final value = controllers[key]!.text.trim();
    return value.isEmpty ? null : int.tryParse(value);
  }

  @override
  Widget build(BuildContext context) => OnlineStoreDialog(
        icon: widget.kind == OnlineStoreDiscountKind.coupon
            ? Icons.confirmation_number_outlined
            : Icons.local_offer_outlined,
        title: Text(widget.item == null
            ? (isCoupon ? 'إضافة كوبون' : 'إضافة عرض')
            : (isCoupon ? 'تعديل الكوبون' : 'تعديل العرض')),
        content: OnlineStoreDialogBody(
          maxWidth: OnlineStoreAdminUi.dialogWideMaxWidth,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(isCoupon ? 'code' : 'name',
                isCoupon ? 'رمز الكوبون' : 'اسم العرض'),
            _dropdown(
              'نوع الخصم',
              discountType,
              const {'percentage': 'نسبة مئوية', 'fixed': 'قيمة ثابتة'},
              (value) => setState(() => discountType = value),
            ),
            _field('discount_value', 'قيمة الخصم', numeric: true),
            _dropdown(
              'السعر المستهدف',
              appliesTo,
              const {'retail': 'تجزئة', 'wholesale': 'جملة', 'both': 'كلاهما'},
              (value) => setState(() => appliesTo = value),
            ),
            if (isCoupon)
              _dropdown(
                'أهلية الحساب',
                eligibility,
                const {'customer': 'عميل', 'seller': 'مورد', 'both': 'كلاهما'},
                (value) => setState(() => eligibility = value),
              ),
            _dropdown(
              'النطاق',
              scope,
              const {'global': 'جميع المتجر', 'targeted': 'أهداف محددة'},
              (value) => setState(() {
                scope = value;
                if (value == 'global') targets = [];
              }),
            ),
            if (scope == 'targeted')
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.filter_alt_outlined),
                title: Text(targets.isEmpty
                    ? 'اختيار القوائم والتصنيفات'
                    : 'الأهداف المختارة: ${targets.length}'),
                subtitle: targets.isEmpty
                    ? null
                    : Text(targets.map((target) => target.label).join('، '),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_left),
                onTap: _selectTargets,
              ),
            OnlineStoreFormSection(
              title: 'مدة التشغيل',
              description:
                  'اترك التاريخين فارغين ليبقى ${isCoupon ? 'الكوبون' : 'العرض'} متاحاً دون مدة محددة.',
              icon: Icons.schedule_outlined,
              child: Row(children: [
                Expanded(
                  child: OnlineStoreDateTimeField(
                    controller: controllers['starts_at']!,
                    label: 'تاريخ ووقت البداية',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OnlineStoreDateTimeField(
                    controller: controllers['ends_at']!,
                    label: 'تاريخ ووقت النهاية',
                  ),
                ),
              ]),
            ),
            if (isCoupon) ...[
              _field('minimum_order', 'الحد الأدنى للطلب', numeric: true),
              _field('total_usage_limit', 'حد الاستخدام الكلي', numeric: true),
              _field('per_user_usage_limit', 'حد الاستخدام لكل مستخدم',
                  numeric: true),
            ] else
              _field(
                'priority',
                'أولوية العرض',
                numeric: true,
                helper: 'عند انطباق أكثر من عرض، الرقم الأكبر يُفحص أولاً.',
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('نشط'),
              value: active,
              onChanged: (value) => setState(() => active = value),
            ),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          OutlinedButton(
            style: OnlineStoreAdminUi.actionButtonStyle,
            onPressed: _submit,
            child: const Text('حفظ'),
          ),
        ],
      );

  Widget _field(String key, String label,
          {bool numeric = false, String? helper}) =>
      TextField(
        controller: controllers[key],
        keyboardType: numeric ? TextInputType.number : null,
        decoration: InputDecoration(
            labelText: label, helperText: helper, isDense: true),
      );

  Widget _dropdown(
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String> changed,
  ) =>
      DropdownButtonFormField<String>(
        initialValue: options.containsKey(value) ? value : options.keys.first,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: options.entries
            .map((entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value)))
            .toList(growable: false),
        onChanged: (value) {
          if (value != null) changed(value);
        },
      );
}
