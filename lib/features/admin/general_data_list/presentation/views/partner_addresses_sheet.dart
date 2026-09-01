import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../sales_orders/data/models/sales_order_model.dart';

class _PartnerAddressOption {
  const _PartnerAddressOption({required this.city, required this.village});
  final ShiplyCityModel city;
  final ShiplyVillageModel village;

  String get label => '${village.name} — ${city.name}';
  String get key => '${city.id}_${village.id}';
}

InputDecoration _addressInput({
  required String label,
  required String hint,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: AppColors.primaryColor),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDDE5EA)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
  );
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
        builder: (_, setLocal) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FA),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  color: const Color(0xFF12304A),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_location_alt_outlined,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row == null ? 'إضافة عنوان جديد' : 'تعديل العنوان',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'احفظ موقع التوصيل لاستخدامه في الطلبيات',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ]),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Form(
                      key: formKey,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: label,
                              textInputAction: TextInputAction.next,
                              decoration: _addressInput(
                                label: 'اسم العنوان',
                                hint: 'مثال: المنزل، المكتب، المستودع',
                                icon: Icons.bookmark_border_rounded,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownSearch<_PartnerAddressOption>(
                              selectedItem: selectedOption(),
                              items: (filter, _) async {
                                final query = filter.trim().toLowerCase();
                                if (query.isEmpty) return options();
                                return options()
                                    .where((option) =>
                                        option.city.name
                                            .toLowerCase()
                                            .contains(query) ||
                                        option.village.name
                                            .toLowerCase()
                                            .contains(query))
                                    .toList();
                              },
                              itemAsString: (option) => option.label,
                              compareFn: (a, b) => a.key == b.key,
                              validator: (value) => value == null
                                  ? 'اختر القرية أو المنطقة مع المدينة قبل الحفظ'
                                  : null,
                              decoratorProps: DropDownDecoratorProps(
                                decoration: _addressInput(
                                  label: 'المدينة أو القرية *',
                                  hint: 'ابحث باسم المدينة أو القرية',
                                  icon: Icons.location_city_outlined,
                                ),
                              ),
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchDelay: const Duration(milliseconds: 120),
                                constraints:
                                    const BoxConstraints(maxHeight: 360),
                                menuProps: const MenuProps(
                                  backgroundColor: Colors.white,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(14)),
                                ),
                                searchFieldProps: TextFieldProps(
                                  decoration: const InputDecoration(
                                    labelText: 'بحث',
                                    hintText: 'مثال: الخليل أو القريبة',
                                    prefixIcon: Icon(Icons.search),
                                    filled: true,
                                    fillColor: Color(0xFFF6F8FA),
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
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: street,
                              textInputAction: TextInputAction.next,
                              decoration: _addressInput(
                                label: 'تفاصيل الشارع (اختياري)',
                                hint: 'اسم الشارع أو أقرب معلم',
                                icon: Icons.signpost_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: phone,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: _addressInput(
                                label: 'هاتف المستلم (اختياري)',
                                hint: 'رقم خاص بهذا العنوان',
                                icon: Icons.phone_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: notes,
                              maxLines: 2,
                              decoration: _addressInput(
                                label: 'ملاحظات التوصيل (اختياري)',
                                hint: 'الطابق، علامة مميزة أو وقت مناسب',
                                icon: Icons.notes_rounded,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFDDE5EA)),
                              ),
                              child: SwitchListTile(
                                activeThumbColor: AppColors.primaryColor,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                secondary: const Icon(
                                    Icons.star_outline_rounded,
                                    color: AppColors.primaryColor),
                                title: const Text('العنوان الافتراضي',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: const Text(
                                    'يُختار تلقائياً عند إنشاء طلبية جديدة'),
                                value: isDefault,
                                onChanged: (value) =>
                                    setLocal(() => isDefault = value),
                              ),
                            ),
                          ]),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          foregroundColor: const Color(0xFF12304A),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF12304A),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () {
                          if (formKey.currentState?.validate() != true) return;
                          Navigator.pop(dialogContext, true);
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('حفظ العنوان'),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
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
