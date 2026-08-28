import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:doctorbike/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      Get.snackbar('تم الحفظ', 'تم تحديث إعدادات المبيعات بنجاح');
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

  void _showError(Object error) {
    if (!mounted) return;
    Get.snackbar('تعذر إكمال العملية', error.toString());
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
