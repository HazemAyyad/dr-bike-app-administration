import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceDailyCloseScreen extends StatefulWidget {
  const MaintenanceDailyCloseScreen({Key? key}) : super(key: key);

  @override
  State<MaintenanceDailyCloseScreen> createState() =>
      _MaintenanceDailyCloseScreenState();
}

class _MaintenanceDailyCloseScreenState
    extends State<MaintenanceDailyCloseScreen> {
  final MaintenanceController controller = Get.find<MaintenanceController>();
  final _physicalCtrl = TextEditingController();
  final _floatCtrl = TextEditingController(text: '0');
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  ShownBoxesModel? _selectedBox;
  bool _submitting = false;
  bool _ready = false;

  Map<String, dynamic> get _args =>
      Get.arguments is Map ? Map<String, dynamic>.from(Get.arguments) : {};

  String get _mode =>
      _args['mode']?.toString() ?? (userType == 'admin' ? 'direct' : 'request');
  bool get _isReview => _mode == 'review';
  bool get _isDirect => _mode == 'direct';
  bool get _isAdminFlow => _isReview || _isDirect;
  bool get _isDark => ThemeService.isDark.value;
  Color get _pageBg =>
      _isDark ? AppColors.darkColor : AppColors.operationalSurface;
  Color get _cardBg => _isDark ? AppColors.customGreyColor4 : Colors.white;
  Color get _borderColor =>
      _isDark ? Colors.white12 : AppColors.operationalCardBorder;
  Color get _titleColor => _isDark ? Colors.white : AppColors.operationalNavy;
  Color get _mutedColor =>
      _isDark ? AppColors.customGreyColor5 : AppColors.customGreyColor2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    if (!_isAdminFlow && controller.dailyBoxPayload.isEmpty) {
      await controller.loadMaintenanceDailySession();
    }
    if (_isAdminFlow && controller.paymentBoxes.isEmpty) {
      await controller.loadMaintenanceDailyAdminData();
    }
    if (!mounted) return;
    _physicalCtrl.text = _money(_initialPhysical);
    _floatCtrl.text = _money(_initialFloat);
    _noteCtrl.text = _initialNote;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _physicalCtrl.dispose();
    _floatCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _source {
    if (_isReview && _args['request'] is Map) {
      return Map<String, dynamic>.from(_args['request']);
    }
    if (_isDirect && _args['session'] is Map) {
      return Map<String, dynamic>.from(_args['session']);
    }
    return Map<String, dynamic>.from(controller.dailyBoxPayload);
  }

  Map<String, dynamic> get _session {
    final direct = _source['session'];
    if (direct is Map) return Map<String, dynamic>.from(direct);
    return _source;
  }

  Map<String, dynamic> get _currencyRow {
    final rows = _source['currencies'];
    if (rows is List && rows.isNotEmpty && rows.first is Map) {
      return Map<String, dynamic>.from(rows.first);
    }
    final counts = _source['cash_counts'];
    if (counts is List && counts.isNotEmpty && counts.first is Map) {
      return Map<String, dynamic>.from(counts.first);
    }
    return {};
  }

  int? get _sessionId => _intFrom(
        _source['session_id'] ?? _session['session_id'] ?? _session['id'],
      );

  int? get _requestId => _intFrom(_source['id']);
  String get _currency =>
      (_source['currency'] ?? _currencyRow['currency'] ?? 'شيكل').toString();
  String get _employeeName => (_source['employee_name'] ??
          _session['employee_name'] ??
          _session['user_name'] ??
          'موظف الصيانة')
      .toString();
  String get _businessDate => (_source['business_date'] ??
          _session['business_date'] ??
          controller.dailyBoxSession?['business_date'] ??
          '')
      .toString();
  String get _boxName => (_source['box_name'] ??
          _currencyRow['daily_box_name'] ??
          controller.maintenanceDailyBoxName)
      .toString();
  double get _opening =>
      _doubleFrom(_source['opening_balance'] ?? _currencyRow['opening_float']);
  double get _cashTotal =>
      _doubleFrom(_source['cash_total'] ?? _currencyRow['sales_collected']);
  double get _systemBalance => _doubleFrom(
        _source['expected_closing_balance'] ??
            _currencyRow['system_balance'] ??
            controller.maintenanceDailyExpectedClosingBalance,
      );
  double get _initialPhysical => _doubleFrom(
        _currencyRow['physical_count'] ??
            _source['physical_count'] ??
            _systemBalance,
      );
  double get _initialFloat =>
      _doubleFrom(_currencyRow['float_to_keep'] ?? _source['float_to_keep']);
  String get _initialNote =>
      (_source['note'] ?? _currencyRow['employee_note'] ?? '').toString();

  double _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '')) ?? 0;

  double get _physical => _parse(_physicalCtrl);
  double get _floatToKeep => _parse(_floatCtrl);
  double get _variance => _physical - _systemBalance;
  double get _amountToTransfer =>
      (_physical - _floatToKeep).clamp(0.0, double.infinity).toDouble();

  List<ShownBoxesModel> get _transferBoxes => controller.paymentBoxes
      .where(
          (box) => box.currency == _currency && box.type != 'daily_maintenance')
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: const CustomAppBar(title: 'إغلاق يوم الصيانة', action: false),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(24.w, 14.h, 24.w, 28.h),
                children: [
                  _introCard(),
                  SizedBox(height: 12.h),
                  _statsRow(),
                  SizedBox(height: 14.h),
                  Text(
                    'الصندوق اليومي',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: _titleColor,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _boxCard(),
                  SizedBox(height: 22.h),
                  if (_isReview)
                    OutlinedButton(
                      onPressed: _submitting ? null : _reject,
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.fromHeight(48.h),
                      ),
                      child: const Text('رفض الطلب'),
                    ),
                  if (_isReview) SizedBox(height: 10.h),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(52.h),
                      backgroundColor: AppColors.operationalNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: _submitting
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isAdminFlow ? 'إغلاق وترحيل' : 'إرسال طلب الإغلاق',
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _introCard() {
    return _surfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 54.w,
                height: 54.w,
                decoration: BoxDecoration(
                  color: _isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(Icons.point_of_sale_outlined, size: 28.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _employeeName,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w900,
                        color: _titleColor,
                      ),
                    ),
                    if (_businessDate.isNotEmpty)
                      Text(
                        'تاريخ اليوم: $_businessDate',
                        style: TextStyle(fontSize: 12.sp, color: _mutedColor),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(height: 1, color: _borderColor),
          SizedBox(height: 12.h),
          Text(
            _isAdminFlow
                ? 'راجع العد الفعلي وحدد فكة الغد وصندوق الترحيل لإغلاق صندوق الصيانة.'
                : 'عد الكاش فعلياً وحدد الفكة التي تبقى للغد. الباقي يرسل للإدارة للاعتماد.',
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.55,
              color: _isDark ? Colors.white70 : AppColors.operationalNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
          child: _statChip(
            icon: Icons.receipt_long_outlined,
            label: 'إجمالي الصيانة',
            value:
                '${_intFrom(_source['maintenances_count'] ?? _source['instant_sales_count']) ?? 0}',
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _statChip(
            icon: Icons.payments_outlined,
            label: 'ربح نقدي',
            value: _money(_cashTotal),
          ),
        ),
      ],
    );
  }

  Widget _boxCard() {
    return _surfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: _isDark ? Colors.white10 : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
              border: Border(bottom: BorderSide(color: _borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _boxName,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: _titleColor,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.operationalNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    _currency,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: _titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              children: [
                _balancePanel(),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: _numberField(
                        label: 'المعدود فعلياً',
                        controller: _physicalCtrl,
                        readOnly: _isReview,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _numberField(
                        label: 'فكة الغد',
                        controller: _floatCtrl,
                        readOnly: _isReview,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _resultPanel(),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _noteCtrl,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_isAdminFlow && _amountToTransfer > 0) ...[
                  SizedBox(height: 12.h),
                  CustomDropdownFieldWithSearch(
                    tital: 'صندوق الترحيل',
                    hint: 'اختر صندوق الترحيل',
                    items: _transferBoxes,
                    value: _selectedBox,
                    onChanged: (value) {
                      setState(() => _selectedBox = value as ShownBoxesModel?);
                    },
                    itemAsString: (item) => item.boxName,
                    compareFn: (a, b) => a.boxId == b.boxId,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _balancePanel() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: _isDark ? Colors.black26 : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          _infoRow('فكة افتتاح', _opening),
          SizedBox(height: 6.h),
          _infoRow('قبض صيانة اليوم', _cashTotal),
          SizedBox(height: 6.h),
          _infoRow('رصيد النظام', _systemBalance, emphasize: true),
        ],
      ),
    );
  }

  Widget _resultPanel() {
    final alert = _variance.abs() > 0.01;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: alert
            ? Colors.red.shade50
            : (_isDark ? Colors.white10 : const Color(0xFFF9FAFB)),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: alert ? Colors.red.shade200 : _borderColor),
      ),
      child: Column(
        children: [
          _infoRow(
            'الفرق',
            _variance,
            emphasize: alert,
            valueColor: alert ? Colors.red.shade800 : null,
          ),
          SizedBox(height: 6.h),
          _infoRow('يرحل', _amountToTransfer, emphasize: true),
        ],
      ),
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      onChanged: (_) => setState(() {}),
      validator: (value) {
        final amount = double.tryParse((value ?? '').replaceAll(',', ''));
        if (amount == null || amount < 0) return 'قيمة غير صحيحة';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return _surfaceCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: _mutedColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.sp, color: _mutedColor),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: _titleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    double value, {
    bool emphasize = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: _mutedColor),
          ),
        ),
        Text(
          _money(value),
          style: TextStyle(
            fontSize: emphasize ? 14.sp : 12.sp,
            fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600,
            color: valueColor ?? _titleColor,
          ),
        ),
      ],
    );
  }

  Widget _surfaceCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ?? EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _borderColor),
        boxShadow: [
          if (!_isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_floatToKeep > _physical) {
      Get.snackbar('خطأ', 'فكة الغد لا يمكن أن تكون أكبر من المعدود فعلياً');
      return;
    }
    if (_isAdminFlow && _amountToTransfer > 0 && _selectedBox == null) {
      Get.snackbar('خطأ', 'يجب اختيار صندوق الترحيل');
      return;
    }

    setState(() => _submitting = true);
    var ok = false;
    if (_isReview) {
      final requestId = _requestId;
      if (requestId != null) {
        ok = await controller.approveMaintenanceDailyClosing(
          requestId,
          toBoxId: _selectedBox?.boxId,
          note: _noteCtrl.text,
        );
      }
    } else if (_isDirect) {
      final sessionId = _sessionId;
      if (sessionId != null) {
        ok = await controller.directCloseMaintenanceDailySession(
          sessionId,
          toBoxId: _selectedBox?.boxId,
          note: _noteCtrl.text,
          physicalCount: _physical,
          floatToKeep: _floatToKeep,
        );
      }
    } else {
      ok = await controller.requestMaintenanceDailySessionClosing(
        note: _noteCtrl.text,
        physicalCount: _physical,
        floatToKeep: _floatToKeep,
      );
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Get.back(result: true);
  }

  Future<void> _reject() async {
    final requestId = _requestId;
    if (requestId == null) return;
    setState(() => _submitting = true);
    final ok = await controller.rejectMaintenanceDailyClosing(
      requestId,
      note: _noteCtrl.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Get.back(result: true);
  }
}

int? _intFrom(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double _doubleFrom(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _money(dynamic value) => _doubleFrom(value).toStringAsFixed(2);
