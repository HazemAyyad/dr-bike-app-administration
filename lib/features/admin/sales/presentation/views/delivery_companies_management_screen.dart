import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/features/admin/sales_orders/data/models/sales_order_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const Map<String, String> _deliveryTypeLabels = {
  'office': 'مكتب / شركة توصيل',
  'taxi': 'تكسي / سائق',
  'internal': 'توصيل داخلي',
  'pickup': 'استلام ذاتي',
  'shiply': 'Shiply (نظامي)',
};

Future<DeliveryCompanyModel?> showDeliveryCompanyEditorDialog(
  BuildContext context, {
  DeliveryCompanyModel? company,
}) async {
  final api = Get.find<DioConsumer>();
  final name = TextEditingController(text: company?.name ?? '');
  final fee = TextEditingController(
    text: company?.defaultCarrierFee?.toStringAsFixed(2) ?? '',
  );
  final contact = TextEditingController(text: company?.contactName ?? '');
  final phone = TextEditingController(text: company?.contactPhone ?? '');
  final vehicle = TextEditingController(text: company?.vehicleNumber ?? '');
  final notes = TextEditingController(text: company?.notes ?? '');
  var type = company?.deliveryType == 'shiply'
      ? 'shiply'
      : (company?.deliveryType ?? 'office');
  var active = company?.isActive ?? true;
  var saving = false;
  final canChangeType = company == null ||
      (company.code?.toLowerCase().startsWith('custom-') ?? false);

  final result = await showDialog<DeliveryCompanyModel>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(company == null ? 'إضافة جهة توصيل' : 'تعديل جهة التوصيل'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: company == null,
                  decoration: const InputDecoration(
                    labelText: 'اسم المكتب أو الجهة *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'نوع وسيلة التوصيل *',
                    border: OutlineInputBorder(),
                  ),
                  items: _deliveryTypeLabels.entries
                      .where(
                          (entry) => entry.key != 'shiply' || type == 'shiply')
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: !canChangeType
                      ? null
                      : (value) => setState(() => type = value ?? type),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fee,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'أجرة الجهة الافتراضية',
                    helperText: 'تكلفة الناقل، وليست سعر التوصيل على الزبون',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contact,
                  decoration: const InputDecoration(
                    labelText: 'اسم المسؤول / السائق',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: vehicle,
                  decoration: const InputDecoration(
                    labelText: 'رقم المركبة (إن وجد)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (company != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('جهة فعّالة وتظهر في الاختيار'),
                    value: active,
                    onChanged: (value) => setState(() => active = value),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    if (name.text.trim().isEmpty) return;
                    setState(() => saving = true);
                    try {
                      final data = <String, dynamic>{
                        'name': name.text.trim(),
                        'delivery_type': type,
                        'default_carrier_fee': fee.text.trim().isEmpty
                            ? null
                            : double.tryParse(fee.text.trim()),
                        'contact_name': contact.text.trim().isEmpty
                            ? null
                            : contact.text.trim(),
                        'contact_phone': phone.text.trim().isEmpty
                            ? null
                            : phone.text.trim(),
                        'vehicle_number': vehicle.text.trim().isEmpty
                            ? null
                            : vehicle.text.trim(),
                        'notes': notes.text.trim().isEmpty
                            ? null
                            : notes.text.trim(),
                        'is_active': active,
                      };
                      final response = company == null
                          ? await api.post(
                              EndPoints.manageDeliveryCompanies,
                              data: data,
                            )
                          : await api.put(
                              '${EndPoints.manageDeliveryCompanies}/${company.id}',
                              data: data,
                            );
                      final raw = response.data is Map
                          ? response.data['delivery_company']
                          : null;
                      if (raw is Map && dialogContext.mounted) {
                        Navigator.pop(
                          dialogContext,
                          DeliveryCompanyModel.fromJson(
                            Map<String, dynamic>.from(raw),
                          ),
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                        setState(() => saving = false);
                      }
                    }
                  },
            child: Text(saving ? 'جارٍ الحفظ...' : 'حفظ'),
          ),
        ],
      ),
    ),
  );

  name.dispose();
  fee.dispose();
  contact.dispose();
  phone.dispose();
  vehicle.dispose();
  notes.dispose();
  return result;
}

class DeliveryCompaniesManagementScreen extends StatefulWidget {
  const DeliveryCompaniesManagementScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryCompaniesManagementScreen> createState() =>
      _DeliveryCompaniesManagementScreenState();
}

class _DeliveryCompaniesManagementScreenState
    extends State<DeliveryCompaniesManagementScreen> {
  final DioConsumer _api = Get.find<DioConsumer>();
  List<DeliveryCompanyModel> _companies = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get(EndPoints.manageDeliveryCompanies);
      final raw =
          response.data is Map ? response.data['delivery_companies'] : null;
      if (raw is List && mounted) {
        setState(() {
          _companies = raw
              .map((item) => DeliveryCompanyModel.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ))
              .toList();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([DeliveryCompanyModel? company]) async {
    final saved = await showDeliveryCompanyEditorDialog(
      context,
      company: company,
    );
    if (saved != null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جهات ووسائل التوصيل')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.add),
        label: const Text('إضافة جهة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: _companies.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final company = _companies[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        company.deliveryType == 'taxi'
                            ? Icons.local_taxi_outlined
                            : Icons.local_shipping_outlined,
                      ),
                      title: Text(company.name),
                      subtitle: Text([
                        _deliveryTypeLabels[company.deliveryType] ??
                            company.deliveryType,
                        if (company.defaultCarrierFee != null)
                          'الأجرة الافتراضية: ${company.defaultCarrierFee!.toStringAsFixed(2)}',
                        if (!company.isActive) 'متوقفة',
                      ].join(' • ')),
                      trailing: company.deliveryType == 'shiply'
                          ? const Icon(Icons.lock_outline)
                          : const Icon(Icons.edit_outlined),
                      onTap: company.deliveryType == 'shiply'
                          ? null
                          : () => _edit(company),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
