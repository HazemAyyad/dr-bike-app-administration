import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../boxes/data/repositories/boxes_implement.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../data/datasources/sales_datasources.dart';
import '../../data/models/daily_session_model.dart';
import '../controllers/sales_controller.dart';
import '../utils/sales_amount_format.dart';
import '../widgets/sales_skeleton_widgets.dart';

class SalesDailyCloseScreen extends StatefulWidget {
  const SalesDailyCloseScreen({Key? key}) : super(key: key);

  @override
  State<SalesDailyCloseScreen> createState() => _SalesDailyCloseScreenState();
}

class _SalesDailyCloseScreenState extends State<SalesDailyCloseScreen> {
  SalesController get controller => Get.find<SalesController>();

  final Map<String, TextEditingController> _physical = {};
  final Map<String, TextEditingController> _float = {};
  final Map<String, TextEditingController> _notes = {};
  final _lateReasonCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _controllersReady = false;
  bool _loadingPayload = false;
  String? _loadError;
  DailySessionPayload? _adminPayload;
  int? _targetSessionId;
  final Set<String> _expandedCurrencies = {};
  final Map<String, int?> _transferTargets = {};
  List<ShownBoxesModel> _shownBoxes = [];
  bool _loadingBoxes = false;

  bool get _canFinalizeClosing => _payload?.canFinalizeClosing ?? false;

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
    _targetSessionId = _resolveSessionId();
    if (_targetSessionId != null) {
      _loadAdminPayload();
    } else {
      _initControllers();
    }
  }

  int? _resolveSessionId() {
    final args = Get.arguments;
    if (args is int) return args;
    if (args is Map && args['sessionId'] != null) {
      return int.tryParse('${args['sessionId']}');
    }
    return null;
  }

  Future<void> _loadAdminPayload() async {
    final sessionId = _targetSessionId;
    if (sessionId == null) return;

    setState(() {
      _loadingPayload = true;
      _loadError = null;
    });

    try {
      AppDependencyRegistry.ensureSales();
      final ds = Get.find<SalesDatasource>();
      final payload = await ds.getDailySessionClosePayload(sessionId);
      if (!mounted) return;
      setState(() {
        _adminPayload = payload;
        _loadingPayload = false;
      });
      _initControllers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPayload = false;
        _loadError = e.toString();
      });
    }
  }

  DailySessionPayload? get _payload =>
      _adminPayload ?? controller.dailySessionPayload.value;

  void _initControllers() {
    final payload = _payload;
    if (payload == null || payload.isClosingRequested) return;

    for (final c in _physical.values) {
      c.dispose();
    }
    for (final c in _float.values) {
      c.dispose();
    }
    for (final c in _notes.values) {
      c.dispose();
    }
    _physical.clear();
    _float.clear();
    _notes.clear();

    for (final row in payload.currencies) {
      _physical[row.currency] = TextEditingController(
        text: SalesAmountFormat.display(row.systemBalance),
      );
      _float[row.currency] = TextEditingController(text: '0');
      _notes[row.currency] = TextEditingController();
    }
    _controllersReady = _physical.isNotEmpty;
    if (_canFinalizeClosing) {
      _loadShownBoxes();
    }
  }

  Future<void> _loadShownBoxes() async {
    setState(() => _loadingBoxes = true);
    try {
      AppDependencyRegistry.ensureBoxes();
      final boxes = await GetShownBoxUsecase(
        boxesRepository: Get.find<BoxesImplement>(),
      ).call(screen: 0);
      if (!mounted) return;
      setState(() {
        _shownBoxes = boxes;
        _loadingBoxes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingBoxes = false);
    }
  }

  @override
  void dispose() {
    for (final c in _physical.values) {
      c.dispose();
    }
    for (final c in _float.values) {
      c.dispose();
    }
    for (final c in _notes.values) {
      c.dispose();
    }
    _lateReasonCtrl.dispose();
    super.dispose();
  }

  double _parse(String? text) => SalesAmountFormat.parse(text?.trim() ?? '');

  void _showSuccess(String message) {
    final overlayContext = Get.overlayContext;
    if (overlayContext != null) {
      Helpers.showCustomDialogSuccess(
        context: overlayContext,
        title: 'success'.tr,
        message: message,
        autoCloseAfter: const Duration(seconds: 2),
      );
      return;
    }
    Get.snackbar('success'.tr, message);
  }

  @override
  Widget build(BuildContext context) {
    if (_targetSessionId != null) {
      return _buildWithPayload(_payload);
    }

    return Obx(() {
      if (controller.isDailySessionLoading.value &&
          controller.dailySessionPayload.value == null) {
        return _scaffold(const SalesDailyCloseSkeleton());
      }
      return _buildWithPayload(controller.dailySessionPayload.value);
    });
  }

  Widget _scaffold(Widget body, {PreferredSizeWidget? appBar}) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: appBar ??
          const CustomAppBar(title: 'salesDailyCloseDay', action: false),
      body: body,
    );
  }

  Widget _buildWithPayload(DailySessionPayload? payload) {
    if (_loadingPayload || (payload == null && _loadError == null)) {
      return _scaffold(const SalesDailyCloseSkeleton());
    }

    if (_loadError != null) {
      return _scaffold(
        Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Text(_loadError!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (payload == null) {
      return _scaffold(const SalesDailyCloseSkeleton());
    }

    if (payload.isClosingRequested) {
      return _scaffold(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                size: 64.sp,
                color: Colors.orange.shade700,
              ),
              SizedBox(height: 16.h),
              Text(
                'salesDailyClosingPending'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'salesDailyClosingPendingHint'.tr,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13.sp, height: 1.5, color: _mutedColor),
              ),
              SizedBox(height: 24.h),
              AppButton(text: 'back'.tr, onPressed: Get.back),
            ],
          ),
        ),
      );
    }

    if (!_controllersReady) {
      _initControllers();
    }

    if (!_controllersReady) {
      return _scaffold(const SalesDailyCloseSkeleton());
    }

    final session = payload.session;

    return _scaffold(
      Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 24.h),
          children: [
            _headerCard(payload, session),
            SizedBox(height: 8.h),
            _salesCountRow(payload),
            if (payload.requiresLateCloseReason) ...[
              SizedBox(height: 8.h),
              _lateReasonCard(),
            ],
            SizedBox(height: 10.h),
            _sectionLabel('salesDailyBox'.tr),
            SizedBox(height: 6.h),
            ...payload.currencies.map(_currencySection),
            SizedBox(height: 24.h),
            AppButton(
              text: _canFinalizeClosing
                  ? 'salesDailyFinalizeClosing'.tr
                  : 'salesDailySubmitClosing'.tr,
              onPressed: _submitting || _loadingBoxes ? null : _submit,
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w800,
        color: _titleColor,
      ),
    );
  }

  Widget _surfaceCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _borderColor),
        boxShadow: _isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.operationalNavy.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _headerCard(DailySessionPayload payload, DailySessionInfo? session) {
    final employeeLabel = session?.employeeName;
    final businessDate = session?.businessDate;

    return _surfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: _isDark
                      ? Colors.white10
                      : AppColors.operationalNavy.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.point_of_sale_outlined,
                  size: 22.sp,
                  color: _titleColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (employeeLabel != null && employeeLabel.isNotEmpty)
                      Text(
                        employeeLabel,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: _titleColor,
                        ),
                      ),
                    if (businessDate != null && businessDate.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        '${'salesDailyBusinessDate'.tr}: $businessDate',
                        style: TextStyle(fontSize: 12.sp, color: _mutedColor),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(height: 1, color: _borderColor),
          SizedBox(height: 12.h),
          Text(
            payload.isBlockingPreviousDay
                ? 'salesDailyClosePreviousDayIntro'.tr
                : 'salesDailyCloseIntro'.tr,
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

  Widget _salesCountRow(DailySessionPayload payload) {
    return Row(
      children: [
        Expanded(
          child: _statChip(
            icon: Icons.receipt_long_outlined,
            label: 'instant_sales'.tr,
            value: '${payload.instantSalesCount}',
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _statChip(
            icon: Icons.payments_outlined,
            label: 'cashProfit'.tr,
            value: '${payload.profitSalesCount}',
          ),
        ),
      ],
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

  Widget _lateReasonCard() {
    return _surfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 18.sp, color: Colors.orange.shade800),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'salesDailyLateCloseReasonRequiredTitle'.tr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          CustomTextField(
            label: 'salesDailyLateCloseReason'.tr,
            hintText: 'salesDailyLateCloseReasonHint'.tr,
            controller: _lateReasonCtrl,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  bool _isPrimaryCurrency(String currency) => currency == 'شيكل';

  void _toggleCurrencyExpanded(String currency) {
    if (_isPrimaryCurrency(currency)) return;
    setState(() {
      if (_expandedCurrencies.contains(currency)) {
        _expandedCurrencies.remove(currency);
      } else {
        _expandedCurrencies.add(currency);
      }
    });
  }

  Widget _currencySection(DailyCurrencyRow row) {
    final physicalCtrl = _physical[row.currency]!;
    final floatCtrl = _float[row.currency]!;
    final noteCtrl = _notes[row.currency]!;
    final physical = _parse(physicalCtrl.text);
    final floatKeep = _parse(floatCtrl.text);
    final variance = physical - row.systemBalance;
    final transfer =
        (physical - floatKeep).clamp(0.0, double.infinity).toDouble();
    final payload = _payload!;
    final alert = variance.abs() >= payload.config.varianceAlertThreshold;
    final isPrimary = _isPrimaryCurrency(row.currency);
    final isExpanded = isPrimary || _expandedCurrencies.contains(row.currency);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: _surfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isPrimary
                    ? null
                    : () => _toggleCurrencyExpanded(row.currency),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(14.r),
                  bottom: isExpanded ? Radius.zero : Radius.circular(14.r),
                ),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: _isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14.r),
                      bottom: isExpanded ? Radius.zero : Radius.circular(14.r),
                    ),
                    border: isExpanded
                        ? Border(bottom: BorderSide(color: _borderColor))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        row.currency,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: _titleColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (isPrimary) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: _isDark
                                ? Colors.white12
                                : AppColors.operationalNavy
                                    .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'salesDailyPrimaryCurrency'.tr,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: _titleColor,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (!isExpanded)
                        Text(
                          row.systemBalance.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: _mutedColor,
                          ),
                        ),
                      if (alert && isExpanded)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            'salesDailyVariance'.tr,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ),
                      if (!isPrimary) ...[
                        SizedBox(width: 6.w),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: _mutedColor,
                          size: 22.sp,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (isExpanded)
              Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _balancePanel(row),
                    SizedBox(height: 8.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'salesDailyPhysicalCount'.tr,
                            hintText: '0',
                            controller: physicalCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: CustomTextField(
                            label: 'salesDailyFloatToKeep'.tr,
                            hintText: '0',
                            controller: floatCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    _resultPanel(
                      variance: variance,
                      transfer: transfer,
                      alert: alert,
                    ),
                    if (variance.abs() > 0.01) ...[
                      SizedBox(height: 8.h),
                      CustomTextField(
                        label: 'salesDailyVarianceNote'.tr,
                        hintText: 'salesDailyVarianceNote'.tr,
                        controller: noteCtrl,
                        maxLines: 2,
                      ),
                    ],
                    if (_canFinalizeClosing && transfer > 0) ...[
                      SizedBox(height: 8.h),
                      _transferPicker(row.currency, transfer),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _transferPicker(String currency, double transferAmount) {
    final boxes = _shownBoxes.where((box) => box.currency == currency).toList();
    final selectedId = _transferTargets[currency];
    ShownBoxesModel? selected;
    if (selectedId != null) {
      selected = boxes.firstWhereOrNull((box) => box.boxId == selectedId);
    }

    return CustomDropdownFieldWithSearch(
      tital: 'boxName'.tr,
      hint: 'boxNameExample',
      items: boxes,
      value: selected,
      onChanged: (value) {
        setState(() {
          _transferTargets[currency] = (value as ShownBoxesModel?)?.boxId;
        });
      },
      itemAsString: (item) => item.boxName,
      compareFn: (a, b) => a.boxId == b.boxId,
    );
  }

  Widget _balancePanel(DailyCurrencyRow row) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: _isDark ? Colors.black26 : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          _infoRow('salesDailyOpeningFloat'.tr, row.openingFloat),
          SizedBox(height: 4.h),
          _infoRow('salesDailySalesCollected'.tr, row.salesCollected),
          SizedBox(height: 4.h),
          _infoRow(
            'salesDailySystemBalance'.tr,
            row.systemBalance,
            emphasize: true,
          ),
        ],
      ),
    );
  }

  Widget _resultPanel({
    required double variance,
    required double transfer,
    required bool alert,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: alert
            ? Colors.red.shade50
            : (_isDark ? Colors.white10 : const Color(0xFFF9FAFB)),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: alert ? Colors.red.shade200 : _borderColor,
        ),
      ),
      child: Column(
        children: [
          _infoRow(
            'salesDailyVariance'.tr,
            variance,
            emphasize: alert,
            valueColor: alert ? Colors.red.shade800 : null,
          ),
          SizedBox(height: 4.h),
          _infoRow('salesDailyAmountToTransfer'.tr, transfer, emphasize: true),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: _mutedColor, height: 1.3),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value.toStringAsFixed(2),
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: emphasize ? 13.sp : 12.sp,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? _titleColor,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final payload = _payload;
    if (payload == null) return;

    if (payload.requiresLateCloseReason &&
        _lateReasonCtrl.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'salesDailyLateCloseReasonRequired'.tr);
      return;
    }

    final counts = <Map<String, dynamic>>[];
    for (final row in payload.currencies) {
      final physical = _parse(_physical[row.currency]?.text);
      final floatKeep = _parse(_float[row.currency]?.text);
      final variance = physical - row.systemBalance;
      final note = _notes[row.currency]?.text.trim() ?? '';

      if (floatKeep > physical) {
        Get.snackbar('error'.tr, 'salesDailyFloatExceedsCounted'.tr);
        return;
      }

      final maxFloat = payload.config.maxFloat[row.currency] ?? 500;
      if (floatKeep > maxFloat) {
        Get.snackbar(
          'error'.tr,
          'salesDailyFloatExceedsMax'.trParams({
            'max': '$maxFloat',
            'currency': row.currency,
          }),
        );
        return;
      }

      if (variance.abs() > 0.01 && note.isEmpty) {
        Get.snackbar('error'.tr, 'salesDailyVarianceNoteRequired'.tr);
        return;
      }

      counts.add(
        DailyCashCountRow(currency: row.currency).toRequestJson(
          physical: _physical[row.currency]!.text,
          floatKeep: _float[row.currency]!.text,
          note: note,
        ),
      );
    }

    if (_canFinalizeClosing) {
      for (final row in payload.currencies) {
        final physical = _parse(_physical[row.currency]?.text);
        final floatKeep = _parse(_float[row.currency]?.text);
        final transfer =
            (physical - floatKeep).clamp(0.0, double.infinity).toDouble();
        if (transfer > 0 && _transferTargets[row.currency] == null) {
          Get.snackbar('error'.tr, 'salesDailyTransferTargetRequired'.tr);
          return;
        }
      }
    }

    final transfers = <Map<String, dynamic>>[];
    if (_canFinalizeClosing) {
      for (final row in payload.currencies) {
        final physical = _parse(_physical[row.currency]?.text);
        final floatKeep = _parse(_float[row.currency]?.text);
        final transfer =
            (physical - floatKeep).clamp(0.0, double.infinity).toDouble();
        if (transfer <= 0) continue;
        final toBoxId = _transferTargets[row.currency];
        if (toBoxId == null) continue;
        transfers.add({
          'currency': row.currency,
          'to_box_id': toBoxId,
        });
      }
    }

    setState(() => _submitting = true);
    try {
      final lateReason =
          payload.requiresLateCloseReason ? _lateReasonCtrl.text.trim() : null;
      final sessionId = _targetSessionId ?? payload.session?.id;
      if (sessionId == null) {
        Get.snackbar('error'.tr, 'salesDailyNoSessionOpen'.tr);
        return;
      }

      final message = _canFinalizeClosing
          ? await controller.directCloseDailySession(
              cashCounts: counts,
              sessionId: sessionId,
              transfers: transfers,
            )
          : await controller.submitDailyClosing(
              cashCounts: counts,
              lateCloseReason: lateReason,
              sessionId: sessionId,
            );
      if (!mounted) return;
      Get.back();
      _showSuccess(message);
    } catch (e) {
      if (!mounted) return;
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
