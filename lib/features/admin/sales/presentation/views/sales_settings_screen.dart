import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:doctorbike/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/helpers/app_success_notice.dart';

import '../../../../../core/helpers/app_failure_notice.dart';
class SalesSettingsScreen extends StatefulWidget {
  const SalesSettingsScreen({Key? key}) : super(key: key);

  @override
  State<SalesSettingsScreen> createState() => _SalesSettingsScreenState();
}

class _SalesSettingsScreenState extends State<SalesSettingsScreen> {
  final DioConsumer _api = Get.find<DioConsumer>();
  Map<String, dynamic> _settings = <String, dynamic>{};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (canManageSalesSettings) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get(EndPoints.salesSettings);
      final raw = response.data is Map ? response.data['settings'] : null;
      if (raw is Map && mounted) {
        setState(() => _settings = Map<String, dynamic>.from(raw));
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(Map<String, dynamic> values) async {
    try {
      final response = await _api.put(EndPoints.salesSettings, data: values);
      final raw = response.data is Map ? response.data['settings'] : null;
      if (raw is Map && mounted) {
        setState(() => _settings = Map<String, dynamic>.from(raw));
      }
      Get.back();
      AppSuccessNotice.show(
        title: 'تم الحفظ',
        message: 'تم تحديث إعدادات المبيعات بنجاح',
      );
    } catch (error) {
      _showError(error);
    }
  }

  void _showDailyDialog() {
    final threshold = TextEditingController(
      text: '${_settings['sales_daily_variance_alert_threshold'] ?? 0}',
    );
    final rawFloats = _settings['sales_daily_max_float'];
    final floats = rawFloats is Map ? rawFloats : <String, dynamic>{};
    final currencies = floats.keys.map((e) => '$e').toList();
    final controllers = <String, TextEditingController>{
      for (final currency in currencies)
        currency: TextEditingController(text: '${floats[currency] ?? 0}'),
    };
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات صندوق المبيعات اليومي'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: threshold,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'حد تنبيه فرق الإغلاق',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                for (final entry in controllers.entries) ...[
                  TextField(
                    controller: entry.value,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'أعلى عهدة متبقية — ${entry.key}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final thresholdValue = double.tryParse(threshold.text.trim());
              final maxFloats = <String, double>{};
              for (final entry in controllers.entries) {
                final value = double.tryParse(entry.value.text.trim());
                if (value == null || value < 0) {
                  Get.snackbar('تنبيه', 'أدخل قيمة صحيحة لـ ${entry.key}');
                  return;
                }
                maxFloats[entry.key] = value;
              }
              if (thresholdValue == null || thresholdValue < 0) {
                Get.snackbar('تنبيه', 'أدخل حداً صحيحاً لفرق الإغلاق');
                return;
              }
              _save({
                'sales_daily_variance_alert_threshold': thresholdValue,
                'sales_daily_max_float': maxFloats,
              });
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showShiplyDialog() {
    final raw = _settings['shiply'];
    final shiply =
        raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    var enabled = shiply['shiply_enabled'] == true;
    var mode = shiply['shiply_mode'] == 'live' ? 'live' : 'test';
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إعدادات شيبلي'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تفعيل الربط مع شيبلي'),
                  value: enabled,
                  onChanged: (value) => setDialogState(() => enabled = value),
                ),
                DropdownButtonFormField<String>(
                  initialValue: mode,
                  decoration: const InputDecoration(
                    labelText: 'بيئة الربط',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'test', child: Text('تجريبية')),
                    DropdownMenuItem(value: 'live', child: Text('فعلية')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => mode = value ?? 'test'),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    shiply['shiply_api_configured'] == true
                        ? 'مفتاح الربط مضبوط على الخادم'
                        : 'مفتاح الربط غير مضبوط على الخادم',
                    style: TextStyle(
                      color: shiply['shiply_api_configured'] == true
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('إلغاء')),
            FilledButton(
              onPressed: () => _save({
                'shiply': {'shiply_enabled': enabled, 'shiply_mode': mode},
              }),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderMediaRequirementsDialog() {
    final raw = _settings['sales_order_media_requirements'];
    final source =
        raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final values = <String, Map<String, bool>>{};
    for (final stage in const ['visible', 'mark_ready', 'handover']) {
      final stageRaw = source[stage];
      final map = stageRaw is Map
          ? Map<String, dynamic>.from(stageRaw)
          : <String, dynamic>{};
      values[stage] = {
        'items_group': stage == 'visible'
            ? map['items_group'] != false
            : map['items_group'] == true,
        'packaged': stage == 'visible'
            ? map['packaged'] != false
            : map['packaged'] == true,
        'testing': stage == 'visible'
            ? map['testing'] != false
            : map['testing'] == true,
        'document': stage == 'visible'
            ? map['document'] != false
            : map['document'] == true,
      };
    }
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('صور مراحل الطلبيات'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'حدد ما يظهر للموظف، ثم اختر إن كان إلزامياً قبل مرحلة معينة.',
                  ),
                  const SizedBox(height: 12),
                  for (final category in const [
                    'items_group',
                    'packaged',
                    'testing',
                    'document',
                  ]) ...[
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                _mediaCategoryLabel(category),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                values['visible']![category] == true
                                    ? 'ظاهر في الطلبية'
                                    : 'مخفي ما لم توجد له صور مرفوعة',
                              ),
                              value: values['visible']![category] ?? true,
                              onChanged: (enabled) => setDialogState(() {
                                values['visible']![category] = enabled;
                                if (!enabled) {
                                  values['mark_ready']![category] = false;
                                  values['handover']![category] = false;
                                }
                              }),
                            ),
                            CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('إلزامي قبل حالة جاهزة'),
                              value: values['mark_ready']![category] ?? false,
                              onChanged: values['visible']![category] != true
                                  ? null
                                  : (required) => setDialogState(() =>
                                      values['mark_ready']![category] =
                                          required ?? false),
                            ),
                            CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('إلزامي قبل التسليم للتوصيل'),
                              value: values['handover']![category] ?? false,
                              onChanged: values['visible']![category] != true
                                  ? null
                                  : (required) => setDialogState(() =>
                                      values['handover']![category] =
                                          required ?? false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('إلغاء')),
            FilledButton(
              onPressed: () => _save({
                'sales_order_media_requirements': values,
              }),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  String _mediaCategoryLabel(String category) {
    switch (category) {
      case 'items_group':
        return 'صورة المنتجات مجتمعة';
      case 'packaged':
        return 'صورة الطلبية بعد التغليف';
      case 'testing':
        return 'صورة الفحص والتجربة';
      case 'document':
        return 'صورة مستند أو بوليصة';
      default:
        return category;
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    AppFailureNotice.show(
      title: 'تعذر إكمال العملية',
      message: error.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات المبيعات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (canManageDeliveryCompanyAccounts)
                    _SettingsCard(
                      icon: Icons.local_shipping_outlined,
                      title: 'حسابات شركات التوصيل',
                      subtitle:
                          'المديونيات، الطلبيات، والتسويات الجماعية والجزئية',
                      onTap: () => Get.toNamed(
                        AppRoutes.DELIVERYCOMPANYACCOUNTSSCREEN,
                      ),
                    ),
                  if (canManageSalesSettings) ...[
                    _SettingsCard(
                      icon: Icons.point_of_sale_outlined,
                      title: 'إعدادات صندوق المبيعات اليومي',
                      subtitle: 'حد فرق الإغلاق وأعلى عهدة لكل عملة',
                      onTap: _showDailyDialog,
                    ),
                    _SettingsCard(
                      icon: Icons.route_outlined,
                      title: 'إعدادات شيبلي',
                      subtitle:
                          'تفعيل الربط واختيار البيئة التجريبية أو الفعلية',
                      onTap: _showShiplyDialog,
                    ),
                    _SettingsCard(
                      icon: Icons.add_a_photo_outlined,
                      title: 'صور مراحل الطلبيات',
                      subtitle:
                          'تحديد الصور الإلزامية لكل مرحلة وتفعيلها أو تعطيلها',
                      onTap: _showOrderMediaRequirementsDialog,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
