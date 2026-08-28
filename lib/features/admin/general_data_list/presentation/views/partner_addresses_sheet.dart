import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> showPartnerAddressesSheet({
  required BuildContext context,
  required String partnerType,
  required int partnerId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PartnerAddressesSheet(
      partnerType: partnerType,
      partnerId: partnerId,
    ),
  );
}

class _PartnerAddressesSheet extends StatefulWidget {
  const _PartnerAddressesSheet(
      {required this.partnerType, required this.partnerId});
  final String partnerType;
  final int partnerId;

  @override
  State<_PartnerAddressesSheet> createState() => _PartnerAddressesSheetState();
}

class _PartnerAddressesSheetState extends State<_PartnerAddressesSheet> {
  final DioConsumer _api = Get.find<DioConsumer>();
  List<Map<String, dynamic>> _rows = const [];
  bool _loading = true;

  Map<String, dynamic> get _partner => {
        'partner_type': widget.partnerType,
        'partner_id': widget.partnerId,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final response =
          await _api.get(EndPoints.partnerAddresses, queryParameters: _partner);
      _rows = mapList(asMap(response.data)['data'], (row) => row);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    final currentLabel = asString(row?['label']);
    final label = TextEditingController(
        text: currentLabel.isEmpty ? 'العنوان الرئيسي' : currentLabel);
    final street = TextEditingController(
        text: asString(row?['street_address']) == '----'
            ? ''
            : asString(row?['street_address']));
    final phone = TextEditingController(text: asString(row?['phone']));
    final notes = TextEditingController(text: asString(row?['delivery_notes']));
    var isDefault = row?['is_default'] == true || row?['is_default'] == 1;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setLocal) => AlertDialog(
          title: Text(row == null ? 'إضافة عنوان' : 'تعديل العنوان'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: label,
                  decoration: const InputDecoration(labelText: 'اسم العنوان')),
              TextField(
                  controller: street,
                  decoration:
                      const InputDecoration(labelText: 'الشارع (اختياري)')),
              TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'الهاتف (اختياري)')),
              TextField(
                  controller: notes,
                  decoration:
                      const InputDecoration(labelText: 'ملاحظات التوصيل')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('العنوان الافتراضي'),
                value: isDefault,
                onChanged: (value) => setLocal(() => isDefault = value),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final data = {
      ..._partner,
      if (row != null) 'address_id': asInt(row['id']),
      'label':
          label.text.trim().isEmpty ? 'العنوان الرئيسي' : label.text.trim(),
      'street_address':
          street.text.trim().isEmpty ? '----' : street.text.trim(),
      'phone': phone.text.trim(),
      'delivery_notes': notes.text.trim(),
      'is_default': isDefault,
    };
    await _api.post(
        row == null ? EndPoints.partnerAddress : EndPoints.partnerAddressUpdate,
        data: data);
    await _load();
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العنوان؟'),
        content: const Text('سيتم حذف العنوان من حساب الشخص.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _api.post(EndPoints.partnerAddressDelete,
        data: {..._partner, 'address_id': asInt(row['id'])});
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(children: [
            ListTile(
              title: const Text('عناوين الزبون / المورد',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: FilledButton.icon(
                  onPressed: () => _edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة')),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _rows.isEmpty
                      ? const Center(child: Text('لا توجد عناوين محفوظة'))
                      : ListView.builder(
                          itemCount: _rows.length,
                          itemBuilder: (_, index) {
                            final row = _rows[index];
                            final isDefault = row['is_default'] == true ||
                                row['is_default'] == 1;
                            return ListTile(
                              leading: Icon(isDefault
                                  ? Icons.home
                                  : Icons.location_on_outlined),
                              title: Text(
                                  '${asString(row['label'])}${isDefault ? ' • افتراضي' : ''}'),
                              subtitle: Text(
                                asString(row['street_address']).isEmpty
                                    ? '----'
                                    : asString(row['street_address']),
                              ),
                              onTap: () => _edit(row),
                              trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _delete(row)),
                            );
                          },
                        ),
            ),
          ]),
        ),
      ),
    );
  }
}
