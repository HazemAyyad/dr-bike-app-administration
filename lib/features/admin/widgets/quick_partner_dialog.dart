import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../../../../core/databases/api/api_consumer.dart';
import '../../../../core/databases/api/dio_consumer.dart';
import '../../../../core/databases/api/end_points.dart';
import '../../../../core/helpers/phone_format_helper.dart';
import '../../../../core/errors/expentions.dart';
import '../checks/data/models/check_model.dart';
import '../general_data_list/data/datasources/general_data_list_datasource.dart';
import '../general_data_list/domain/entity/add_person_entity.dart';
import '../sales_orders/data/models/sales_order_model.dart';

class QuickPartnerResult {
  const QuickPartnerResult(this.partner, this.address);
  final SellerModel partner;
  final PartnerAddressModel? address;
}

Future<QuickPartnerResult?> showQuickPartnerDialog({
  required bool isCustomer,
}) =>
    Get.dialog<QuickPartnerResult>(
      QuickPartnerDialog(isCustomer: isCustomer),
      barrierDismissible: false,
    );

class QuickPartnerDialog extends StatefulWidget {
  const QuickPartnerDialog({Key? key, required this.isCustomer, this.api})
      : super(key: key);
  final bool isCustomer;
  final ApiConsumer? api;

  @override
  State<QuickPartnerDialog> createState() => _QuickPartnerDialogState();
}

class _AddressOption {
  const _AddressOption(this.city, this.village);
  final ShiplyCityModel city;
  final ShiplyVillageModel village;
  String get label => '${village.name} — ${city.name}';
}

class _QuickPartnerDialogState extends State<QuickPartnerDialog> {
  static const _surface = Color(0xFFF4F5F7);
  static const _fieldSurface = Color(0xFFEBEDF0);
  static const _ink = Color(0xFF17232E);
  static const _mutedInk = Color(0xFF475462);
  static const _border = Color(0xFF8793A0);
  static const _action = Color(0xFFCBDDEC);
  static const _outline = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    borderSide: BorderSide(color: _border),
  );

  static final _dialogTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      surface: _surface,
      onSurface: _ink,
      onSurfaceVariant: _mutedInk,
      outline: _border,
      outlineVariant: _border,
      primary: Color(0xFF284862),
      onPrimary: _surface,
    ),
    dividerColor: _border,
    disabledColor: _mutedInk,
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _fieldSurface,
      labelStyle: TextStyle(color: _mutedInk),
      hintStyle: TextStyle(color: _mutedInk),
      border: _outline,
      enabledBorder: _outline,
      disabledBorder: _outline,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Color(0xFF284862), width: 2),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(_ink),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _action : _fieldSurface),
    ),
  );

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _label = TextEditingController(text: 'العنوان الرئيسي');
  final _street = TextEditingController();
  final _recipientPhone = TextEditingController();
  final _notes = TextEditingController();
  late final ApiConsumer _api = widget.api ?? Get.find<DioConsumer>();
  late String _type = widget.isCustomer ? 'retail' : 'wholesale';
  List<_AddressOption> _options = [];
  _AddressOption? _selected;
  bool _default = false;
  bool _saving = false;
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  String? _addressError;
  SellerModel? _created;

  bool get _hasAddress =>
      _selected != null ||
      _street.text.trim().isNotEmpty ||
      _recipientPhone.text.trim().isNotEmpty ||
      _notes.text.trim().isNotEmpty ||
      _label.text.trim() != 'العنوان الرئيسي' ||
      _default;

  Future<void> _loadOptions() async {
    if (_loaded || _loading) return;
    setState(() {
      _loading = true;
      _addressError = null;
    });
    try {
      final response = await _api.get(EndPoints.shiplyAddressOptions);
      final cities = (response.data['cities'] as List).map(
          (row) => ShiplyCityModel.fromJson(Map<String, dynamic>.from(row)));
      if (!mounted) return;
      setState(() {
        _options = [
          for (final city in cities)
            for (final village in city.villages)
              if (!village.isClosed) _AddressOption(city, village)
        ];
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _addressError = 'تعذر تحميل المدن والقرى');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validatePhone(String? value) {
    final raw = value?.trim() ?? '';
    return raw.isEmpty ||
            PhoneFormatHelper.isValidApiPhone(PhoneFormatHelper.forApi(raw))
        ? null
        : 'أدخل رقم هاتف صحيح';
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (_hasAddress && _selected == null) {
      setState(() => _error = 'اختر القرية أو المنطقة مع المدينة قبل الحفظ');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_created == null) {
        final response = await GeneralDataListDatasource(api: _api).addPerson(
          data: AddPersonEntity(
            isEdit: false,
            personType: widget.isCustomer ? 'customer' : 'seller',
            customerCategory: _type,
            name: _name.text.trim(),
            phone: PhoneFormatHelper.forApi(_phone.text),
            subPhone: '',
            address: '',
            jobTitle: '',
            facebookUsername: '',
            facebookLink: '',
            instagramUsername: '',
            instagramLink: '',
            relatedPeople: '',
            relativePhone: '',
            relativeJobTitle: '',
            workAddress: '',
            iDImage: const [],
            licenseImage: const [],
          ),
          customerId: '',
          sellerId: '',
        );
        if (response is! Map || response['status'] != 'success') {
          throw Exception(response is Map
              ? response['message'] ?? 'تعذر إضافة الزبون'
              : 'تعذر إضافة الزبون');
        }
        final id = int.tryParse(
            '${response[widget.isCustomer ? 'customer_id' : 'seller_id']}');
        if (id == null || id <= 0) {
          throw Exception('تعذر الحصول على رقم الشخص المضاف');
        }
        // Keep the created person on address failure so retry never duplicates it.
        _created = SellerModel(
            id: id,
            name: _name.text.trim(),
            phone: PhoneFormatHelper.forApi(_phone.text));
      }
      PartnerAddressModel? address;
      if (_hasAddress) {
        final option = _selected!;
        final response = await _api.post(EndPoints.partnerAddress, data: {
          'partner_type': widget.isCustomer ? 'customer' : 'seller',
          'partner_id': _created!.id,
          'label': _label.text.trim().isEmpty
              ? 'العنوان الرئيسي'
              : _label.text.trim(),
          'city_id': null,
          'shiply_city_id': option.city.id,
          'shiply_village_id': option.village.id,
          'shiply_city_name': option.city.name,
          'shiply_village_name': option.village.name,
          'street_address': _street.text.trim(),
          'phone': PhoneFormatHelper.forApi(_recipientPhone.text),
          'delivery_notes': _notes.text.trim(),
          'is_default': _default,
        });
        if (response.data['status'] != 'success') {
          throw Exception(response.data['message'] ?? 'تعذر حفظ العنوان');
        }
        address = PartnerAddressModel.fromJson(
            Map<String, dynamic>.from(response.data['data']));
      }
      if (mounted) {
        Navigator.pop(context, QuickPartnerResult(_created!, address));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is ServerException
            ? error.errorModel.errorMessage
            : error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(TextEditingController controller, String label,
          {bool phone = false,
          bool required = false,
          bool enabled = true,
          int lines = 1}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            enabled: enabled && !_saving,
            maxLines: lines,
            keyboardType: phone ? TextInputType.phone : TextInputType.text,
            textDirection: phone ? TextDirection.ltr : null,
            decoration: InputDecoration(labelText: label),
            validator: (value) => required && (value?.trim().isEmpty ?? true)
                ? 'أدخل الاسم'
                : phone
                    ? _validatePhone(value)
                    : null,
          ));

  @override
  Widget build(BuildContext context) => Theme(
        data: _dialogTheme.copyWith(
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: _ink,
                displayColor: _ink,
              ),
        ),
        child: _buildDialog(),
      );

  Widget _buildDialog() => PopScope(
        canPop: !_saving && _created == null,
        child: Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: _surface,
              surfaceTintColor: Colors.transparent,
              title:
                  Text(widget.isCustomer ? 'إضافة زبون' : 'إضافة مورد / تاجر'),
              content: SizedBox(
                  width: 480,
                  child: SingleChildScrollView(
                      child: Form(
                    key: _form,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      _field(_name, 'الاسم *',
                          required: true, enabled: _created == null),
                      _field(_phone, 'رقم الهاتف',
                          phone: true, enabled: _created == null),
                      DropdownButtonFormField<String>(
                        initialValue: _type,
                        dropdownColor: _surface,
                        decoration: const InputDecoration(labelText: 'النوع'),
                        items: const [
                          DropdownMenuItem(
                              value: 'retail', child: Text('مفرق')),
                          DropdownMenuItem(
                              value: 'wholesale', child: Text('جملة'))
                        ],
                        onChanged: _saving || _created != null
                            ? null
                            : (value) => setState(() => _type = value!),
                      ),
                      ExpansionTile(
                        title: const Text('إضافة عنوان توصيل — اختياري'),
                        tilePadding: EdgeInsets.zero,
                        textColor: _ink,
                        collapsedTextColor: _ink,
                        iconColor: _mutedInk,
                        collapsedIconColor: _mutedInk,
                        onExpansionChanged: (expanded) {
                          if (expanded) _loadOptions();
                        },
                        children: [
                          _field(_label, 'اسم العنوان'),
                          if (_loading) const LinearProgressIndicator(),
                          if (_addressError != null)
                            TextButton(
                                onPressed: _loadOptions,
                                child: Text('$_addressError — إعادة المحاولة')),
                          DropdownSearch<_AddressOption>(
                            enabled: !_saving,
                            selectedItem: _selected,
                            items: (filter, _) async => _options
                                .where((option) =>
                                    option.label.contains(filter.trim()))
                                .toList(),
                            itemAsString: (option) => option.label,
                            compareFn: (a, b) =>
                                a.city.id == b.city.id &&
                                a.village.id == b.village.id,
                            popupProps: const PopupProps.menu(
                                showSearchBox: true,
                                menuProps: MenuProps(backgroundColor: _surface),
                                constraints: BoxConstraints(maxHeight: 300)),
                            decoratorProps: const DropDownDecoratorProps(
                                decoration: InputDecoration(
                                    labelText: 'المدينة أو القرية')),
                            onChanged: (option) =>
                                setState(() => _selected = option),
                          ),
                          const SizedBox(height: 12),
                          _field(
                              _street, 'تفاصيل الشارع أو أقرب معلم (اختياري)'),
                          _field(_recipientPhone, 'هاتف المستلم (اختياري)',
                              phone: true),
                          _field(_notes, 'ملاحظات التوصيل (اختياري)', lines: 2),
                          SwitchListTile(
                              title: const Text('العنوان الافتراضي'),
                              value: _default,
                              onChanged: _saving
                                  ? null
                                  : (value) =>
                                      setState(() => _default = value)),
                        ],
                      ),
                      if (_error != null)
                        Text(_error!,
                            style: TextStyle(
                                color: _dialogTheme.colorScheme.error)),
                      if (_created != null)
                        const Text(
                            'تمت إضافة الشخص. أعد محاولة حفظ العنوان أو أكمل بدونه.'),
                    ]),
                  ))),
              actions: [
                TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.pop(
                            context,
                            _created == null
                                ? null
                                : QuickPartnerResult(_created!, null)),
                    child: Text(
                        _created == null ? 'إلغاء' : 'المتابعة بدون عنوان')),
                FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _action,
                      foregroundColor: _ink,
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_created == null ? 'إضافة' : 'حفظ العنوان')),
              ],
            )),
      );

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _label,
      _street,
      _recipientPhone,
      _notes
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}
