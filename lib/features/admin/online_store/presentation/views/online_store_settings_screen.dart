import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/online_store_settings_controller.dart';
import '../utils/online_store_permissions.dart';
import '../utils/online_store_admin_ui.dart';

class OnlineStoreSettingsScreen extends GetView<OnlineStoreSettingsController> {
  const OnlineStoreSettingsScreen({Key? key}) : super(key: key);

  static const _languages = {
    'ar': 'العربية',
    'en': 'English',
    'he': 'עברית',
  };

  static const _policies = {
    'cancellation_policy_translations': 'سياسة الإلغاء',
    'return_policy_translations': 'سياسة الإرجاع',
    'warranty_policy_translations': 'سياسة الضمان',
    'terms_translations': 'الشروط والأحكام',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('إعدادات المتجر')),
        body: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final enabledLanguages = _enabledLanguages;
          return ListView(padding: const EdgeInsets.all(14), children: [
            Card(
              color: OnlineStoreAdminUi.surfaceMuted,
              child: ListTile(
                leading: const Icon(Icons.power_settings_new),
                title: const Text('الحالة التشغيلية الفعلية'),
                subtitle: Text(_stateLabel(controller.effectiveOperatingState)),
              ),
            ),
            _switch('store_enabled', 'المتجر مفعّل'),
            _switch('maintenance_mode', 'وضع الصيانة'),
            _switch('checkout_enabled', 'إتمام الطلبات مفعّل'),
            _switch('cod_enabled', 'الدفع عند الاستلام'),
            _switch('guest_browsing_enabled', 'تصفح الزوار'),
            _number('minimum_order', 'الحد الأدنى للطلب'),
            _text('support_phone', 'هاتف الدعم'),
            _text('whatsapp', 'واتساب'),
            const Divider(height: 28),
            const Text('لغات المتجر',
                style: TextStyle(fontWeight: FontWeight.w800)),
            Wrap(
              spacing: 8,
              children: _languages.entries
                  .map((entry) => FilterChip(
                        label: Text(entry.value),
                        selected: enabledLanguages.contains(entry.key),
                        onSelected: OnlineStorePermissions.canManageSettings
                            ? (selected) {
                                final next = {...enabledLanguages};
                                selected
                                    ? next.add(entry.key)
                                    : next.remove(entry.key);
                                if (next.isEmpty) {
                                  Get.snackbar('اللغات',
                                      'يجب اختيار لغة واحدة على الأقل',
                                      snackPosition: SnackPosition.BOTTOM);
                                  return;
                                }
                                controller.values['enabled_languages'] =
                                    _languages.keys
                                        .where(next.contains)
                                        .toList(growable: false);
                              }
                            : null,
                      ))
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            ..._policies.entries.expand((policy) => [
                  Text(policy.value,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  ...enabledLanguages.map((language) => _translation(
                        policy.key,
                        language,
                        '${policy.value} - ${_languages[language]}',
                      )),
                  const SizedBox(height: 10),
                ]),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.visibility_outlined),
              title: Text('سلوك نفاد المخزون'),
              subtitle: Text('ظاهر وغير قابل للشراء'),
              trailing: Text('visible_non_purchasable'),
            ),
            _number('low_stock_threshold', 'حد تنبيه انخفاض المخزون',
                integer: true),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_outline),
              title: Text('السعر الأساسي والمخزون للقراءة فقط'),
              subtitle: Text('تتم إدارتهما فقط من نظام المخزون'),
            ),
            if (controller.error.value != null)
              Text(controller.error.value!,
                  style: const TextStyle(color: Colors.red)),
            if (OnlineStorePermissions.canManageSettings)
              OutlinedButton.icon(
                style: OnlineStoreAdminUi.actionButtonStyle,
                onPressed: controller.saving.value ? null : controller.save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ الإعدادات'),
              ),
          ]);
        }),
      );

  Set<String> get _enabledLanguages {
    final raw = controller.values['enabled_languages'];
    if (raw is! List) return {'ar'};
    final result = raw.map((value) => '$value').toSet();
    return result.isEmpty ? {'ar'} : result;
  }

  Widget _switch(String key, String label) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: controller.values[key] == true,
        onChanged: OnlineStorePermissions.canManageSettings
            ? (value) => controller.values[key] = value
            : null,
      );

  Widget _text(String key, String label) => TextFormField(
        key: ValueKey(key),
        initialValue: '${controller.values[key] ?? ''}',
        enabled: OnlineStorePermissions.canManageSettings,
        decoration: InputDecoration(labelText: label, isDense: true),
        onChanged: (value) => controller.values[key] = value.trim(),
      );

  Widget _number(String key, String label, {bool integer = false}) =>
      TextFormField(
        key: ValueKey(key),
        initialValue: '${controller.values[key] ?? 0}',
        enabled: OnlineStorePermissions.canManageSettings,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, isDense: true),
        onChanged: (value) => controller.values[key] =
            integer ? (int.tryParse(value) ?? 0) : (num.tryParse(value) ?? 0),
      );

  Widget _translation(String policy, String language, String label) {
    final values = controller.values[policy];
    final current = values is Map ? values[language] : null;
    return TextFormField(
      key: ValueKey('$policy:$language'),
      initialValue: '$current' == 'null' ? '' : '$current',
      enabled: OnlineStorePermissions.canManageSettings,
      maxLines: 3,
      decoration: InputDecoration(labelText: label, isDense: true),
      onChanged: (value) {
        final translations = Map<String, dynamic>.from(
            controller.values[policy] is Map
                ? controller.values[policy] as Map
                : const {});
        translations[language] = value.trim();
        controller.values[policy] = translations;
      },
    );
  }

  String _stateLabel(String state) {
    switch (state) {
      case 'disabled':
        return 'المتجر مغلق';
      case 'maintenance':
        return 'وضع الصيانة';
      case 'browse_only':
        return 'تصفح فقط';
      default:
        return 'مفتوح للطلبات';
    }
  }
}
