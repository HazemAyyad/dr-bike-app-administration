import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../sales_orders/data/models/sales_order_model.dart';

class _PartnerAddressOption {
  const _PartnerAddressOption({required this.city, required this.village});
  final ShiplyCityModel city;
  final ShiplyVillageModel village;

  String get label => '${village.name} — ${city.name}';
  String get key => '${city.id}_${village.id}';
}

Future<Map<String, dynamic>?> showPartnerAddressesSheet({
  required BuildContext context,
  required String partnerType,
  required int partnerId,
  bool selectionMode = false,
}) async {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PartnerAddressesSheet(
      partnerType: partnerType,
      partnerId: partnerId,
      selectionMode: selectionMode,
    ),
  );
}

class _PartnerAddressesSheet extends StatefulWidget {
  const _PartnerAddressesSheet(
      {required this.partnerType,
      required this.partnerId,
      required this.selectionMode});
  final String partnerType;
  final int partnerId;
  final bool selectionMode;

  @override
  State<_PartnerAddressesSheet> createState() => _PartnerAddressesSheetState();
}

class _PartnerAddressesSheetState extends State<_PartnerAddressesSheet> {
  final DioConsumer _api = Get.find<DioConsumer>();
  List<Map<String, dynamic>> _rows = const [];
  List<ShiplyCityModel> _shiplyCities = const [];
  bool _loading = true;

  Map<String, dynamic> get _partner => {
        'partner_type': widget.partnerType,
        'partner_id': widget.partnerId,
      };

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (mounted) setState(() => _loading = true);
    try {
      await Future.wait([_loadAddresses(), _loadAddressOptions()]);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAddresses() async {
    final response =
        await _api.get(EndPoints.partnerAddresses, queryParameters: _partner);
    _rows = mapList(asMap(response.data)['data'], (row) => row);
  }

  Future<void> _loadAddressOptions() async {
    final response = await _api.get(EndPoints.shiplyAddressOptions);
    _shiplyCities = mapList(
      asMap(response.data)['cities'],
      (row) => ShiplyCityModel.fromJson(row),
    );
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    final formKey = GlobalKey<FormState>();
    final currentLabel = asString(row?['label']);
    final label = TextEditingController(
        text: currentLabel.isEmpty ? 'العنوان الرئيسي' : currentLabel);
    final street = TextEditingController(
        text: asString(row?['street_address']) == '----'
            ? ''
            : asString(row?['street_address']));
    final phone = TextEditingController(text: asString(row?['phone']));
    final notes = TextEditingController(text: asString(row?['delivery_notes']));
    int? shiplyCityId = asInt(row?['shiply_city_id']);
    if (shiplyCityId == 0 ||
        !_shiplyCities.any((city) => city.id == shiplyCityId)) {
      shiplyCityId = null;
    }
    int? shiplyVillageId = asInt(row?['shiply_village_id']);
    List<ShiplyVillageModel> villagesFor(int? selectedCityId) {
      if (selectedCityId == null) return const [];
      for (final city in _shiplyCities) {
        if (city.id == selectedCityId) return city.villages;
      }
      return const [];
    }

    if (!villagesFor(shiplyCityId)
        .any((village) => village.id == shiplyVillageId)) {
      shiplyVillageId = null;
    }
    List<_PartnerAddressOption> options() => [
          for (final city in _shiplyCities)
            for (final village in city.villages)
              if (!village.isClosed)
                _PartnerAddressOption(city: city, village: village),
        ];
    _PartnerAddressOption? selectedOption() {
      return options().firstWhereOrNull(
        (option) =>
            option.city.id == shiplyCityId &&
            option.village.id == shiplyVillageId,
      );
    }

    var isDefault = row?['is_default'] == true || row?['is_default'] == 1;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setLocal) => AlertDialog(
          title: Text(row == null ? 'إضافة عنوان' : 'تعديل العنوان'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: label,
                  decoration: const InputDecoration(
                    labelText: 'اسم العنوان',
                    hintText: 'مثال: المنزل أو المكتب',
                  ),
                ),
                DropdownSearch<_PartnerAddressOption>(
                  selectedItem: selectedOption(),
                  items: (filter, _) async {
                    final query = filter.trim().toLowerCase();
                    if (query.isEmpty) return options();
                    return options()
                        .where((option) =>
                            option.city.name.toLowerCase().contains(query) ||
                            option.village.name.toLowerCase().contains(query))
                        .toList();
                  },
                  itemAsString: (option) => option.label,
                  compareFn: (a, b) => a.key == b.key,
                  validator: (value) => value == null
                      ? 'اختر القرية أو المنطقة مع المدينة قبل الحفظ'
                      : null,
                  decoratorProps: const DropDownDecoratorProps(
                    decoration: InputDecoration(
                      labelText: 'ابحث عن المدينة أو القرية *',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchDelay: Duration.zero,
                    constraints: BoxConstraints(maxHeight: 360),
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'مثال: الخليل أو القريبة',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  onChanged: (option) => setLocal(() {
                    shiplyCityId = option?.city.id;
                    shiplyVillageId = option?.village.id;
                    if (option != null) {
                      street.text =
                          '${option.village.name}، ${option.city.name}';
                    }
                  }),
                ),
                TextFormField(
                  controller: street,
                  decoration: const InputDecoration(
                    labelText: 'الشارع (اختياري)',
                    hintText: 'اتركه فارغاً إذا لم يكن معروفاً',
                  ),
                ),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'الهاتف (اختياري)'),
                ),
                TextFormField(
                  controller: notes,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات التوصيل (اختياري)',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('العنوان الافتراضي'),
                  value: isDefault,
                  onChanged: (value) => setLocal(() => isDefault = value),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final selectedShiplyCity =
        _shiplyCities.firstWhereOrNull((city) => city.id == shiplyCityId);
    final selectedVillage = villagesFor(shiplyCityId)
        .firstWhereOrNull((village) => village.id == shiplyVillageId);
    final data = {
      ..._partner,
      if (row != null) 'address_id': asInt(row['id']),
      'label':
          label.text.trim().isEmpty ? 'العنوان الرئيسي' : label.text.trim(),
      'city_id': null,
      'shiply_city_id': shiplyCityId,
      'shiply_village_id': shiplyVillageId,
      'shiply_city_name': selectedShiplyCity?.name,
      'shiply_village_name': selectedVillage?.name,
      'street_address': street.text.trim(),
      'phone': phone.text.trim(),
      'delivery_notes': notes.text.trim(),
      'is_default': isDefault,
    };
    final response = await _api.post(
        row == null ? EndPoints.partnerAddress : EndPoints.partnerAddressUpdate,
        data: data);
    final savedAddress = asMap(asMap(response.data)['data']);
    await _loadAddresses();
    if (!mounted) return;
    setState(() {});
    if (widget.selectionMode && savedAddress.isNotEmpty) {
      Navigator.pop(context, savedAddress);
    }
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
    await _loadAddresses();
    if (mounted) setState(() {});
  }

  Future<void> _selectAddress(Map<String, dynamic> row) async {
    final cityId = asInt(row['shiply_city_id']);
    final villageId = asInt(row['shiply_village_id']);
    if (cityId <= 0 || villageId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'أكمل مدينة وقرية التوصيل المطلوبة قبل اختيار العنوان',
          ),
        ),
      );
      await _edit(row);
      return;
    }
    if (mounted) Navigator.pop(context, row);
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
              title: Text(
                widget.selectionMode
                    ? 'اختر عنوان التوصيل'
                    : 'عناوين الزبون / المورد',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: widget.selectionMode
                  ? const Text('اختر عنواناً محفوظاً أو أضف عنواناً جديداً')
                  : null,
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
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_off_outlined, size: 42),
                              const SizedBox(height: 8),
                              const Text('لا توجد عناوين محفوظة'),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => _edit(),
                                icon: const Icon(Icons.add_location_alt),
                                label: const Text('إضافة عنوان جديد'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _rows.length,
                          itemBuilder: (_, index) {
                            final row = _rows[index];
                            final isDefault = row['is_default'] == true ||
                                row['is_default'] == 1;
                            final city = asString(row['shiply_city_name']);
                            final village =
                                asString(row['shiply_village_name']);
                            final street =
                                asString(row['street_address']).trim();
                            final addressParts = <String>[
                              if (city.isNotEmpty) city,
                              if (village.isNotEmpty) village,
                              if (street.isNotEmpty && street != '----') street,
                            ];
                            return ListTile(
                              leading: Icon(isDefault
                                  ? Icons.home
                                  : Icons.location_on_outlined),
                              title: Text(
                                  '${asString(row['label'])}${isDefault ? ' • افتراضي' : ''}'),
                              subtitle: Text(
                                addressParts.isEmpty
                                    ? 'الشارع غير محدد'
                                    : addressParts.join(' — '),
                              ),
                              onTap: widget.selectionMode
                                  ? () => _selectAddress(row)
                                  : () => _edit(row),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'تعديل',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _edit(row),
                                  ),
                                  IconButton(
                                    tooltip: 'حذف',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _delete(row),
                                  ),
                                ],
                              ),
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
