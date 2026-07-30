import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/costom_dialog_filter.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../controllers/maintenance_controller.dart';
import '../widgets/maintenance_data_widget.dart';

class MaintenanceScreen extends GetView<MaintenanceController> {
  const MaintenanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'maintenance',
        employeeNameController: controller.employeeNameController,
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
        onPressedFilter: () {
          controller.filterAllMaintenances();
        },
        action: false,
        actions: [
          IconButton(
            tooltip: 'صناديق الصيانة اليومية',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Get.toNamed(
              AppRoutes.DAILYBOXESSCREEN,
              arguments: {'filter': 'maintenance'},
            ),
          ),
          if (userType == 'admin')
            IconButton(
              tooltip: 'إدارة إغلاق صناديق الصيانة اليومية',
              icon: const Icon(Icons.pending_actions_outlined),
              onPressed: () async {
                await Get.toNamed(AppRoutes.MAINTENANCEDAILYADMINSCREEN);
                await controller.loadMaintenanceDailySession();
              },
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () {
              showCustomDialog(
                context,
                fromDateController: controller.fromDateController,
                toDateController: controller.toDateController,
                employeeNameController: controller.employeeNameController,
                label: 'employeeName',
                onPressed: controller.filterAllMaintenances,
              );
            },
          ),
          SizedBox(width: 10.w),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
              height: 42.h,
              tabHorizontalPadding: 4.w,
              tabVerticalPadding: 8.h,
              tabHorizontalMargin: 2.w,
              fontSize: 13.sp,
              fitToWidthUpToCount: 4,
            ),
          ),
          const SliverToBoxAdapter(child: _MaintenanceDailyBoxStatus()),
          const MaintenanceDataWidget(),
          SliverToBoxAdapter(child: SizedBox(height: 60.h)),
        ],
      ),
      floatingActionButton: AddFloatingActionButton(
        onPressed: () {
          controller.clearControllers();
          Get.toNamed(AppRoutes.NEWMAINTENANCESCREEN);
        },
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}

class _MaintenanceDailyBoxStatus extends GetView<MaintenanceController> {
  const _MaintenanceDailyBoxStatus();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOpen = controller.isMaintenanceDailyBoxOpen;
      final isClosingRequested =
          controller.isMaintenanceDailyBoxClosingRequested;
      final isLoading = controller.isDailyBoxLoading.value;
      final canOpen = controller.canRequestMaintenanceDailyOpen;
      final canClose = controller.canRequestMaintenanceDailyClosing;
      final canReview =
          isClosingRequested && controller.canFinalizeMaintenanceDailyClosing;
      final color = isOpen
          ? AppColors.customGreen1
          : isClosingRequested
              ? Colors.orange
              : controller.isMaintenanceDailyBlockedByOther
                  ? AppColors.primaryColor
                  : Colors.blueGrey;
      final label = isOpen
          ? 'صندوق الصيانة اليومي مفتوح'
          : isClosingRequested
              ? 'طلب إغلاق صندوق الصيانة معلق'
              : controller.isMaintenanceDailyBlockedByOther
                  ? 'صندوق صيانة مفتوح'
                  : 'صندوق الصيانة اليومي غير مفتوح';

      return GestureDetector(
        onTap: () => Get.toNamed(
          AppRoutes.DAILYBOXESSCREEN,
          arguments: {'filter': 'maintenance'},
        ),
        child: Container(
          margin: EdgeInsets.fromLTRB(24.w, 0, 24.w, 8.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: color,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    if (isClosingRequested)
                      Text(
                        'بانتظار مراجعة طلب الإغلاق',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade700,
                        ),
                      )
                    else if (controller.isMaintenanceDailyBlockedByOther)
                      Text(
                        'الموظف: ${controller.maintenanceDailyBlockedByEmployeeName ?? '-'}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade700,
                        ),
                      )
                    else if (controller.dailyBoxSession != null)
                      Text(
                        'تاريخ اليوم: ${controller.dailyBoxSession?['business_date'] ?? ''}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    Text(
                      'رصيد النظام: ${_money(controller.maintenanceDailyExpectedClosingBalance)} شيكل',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    Text(
                      'كاش: ${_money(controller.maintenanceDailyCashTotal)} | فيزا: ${_money(controller.maintenanceDailyVisaTotal)} | حوالة: ${_money(controller.maintenanceDailyTransferTotal)} | دين: ${_money(controller.maintenanceDailyDebtTotal)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (canOpen)
                TextButton(
                  onPressed: isLoading ? null : () => _showOpenDialog(context),
                  child: isLoading
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('فتح الصندوق'),
                ),
              if (canClose)
                TextButton(
                  onPressed:
                      isLoading ? null : () => _showRequestCloseDialog(context),
                  child: isLoading
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('إغلاق اليوم'),
                ),
              if (canReview)
                TextButton(
                  onPressed: controller.isDailyClosingReviewLoading.value
                      ? null
                      : () => _showClosingRequestsSheet(context),
                  child: const Text('مراجعة الإغلاق'),
                ),
              Icon(Icons.chevron_left, color: color, size: 20.sp),
            ],
          ),
        ),
      );
    });
  }

  String _money(double value) => value.toStringAsFixed(2);

  Future<void> _showOpenDialog(BuildContext context) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _MaintenanceOpenBoxDialog(
        initialAmount: controller.maintenanceDailyOpeningBalance,
      ),
    );
    if (amount == null) return;
    await controller.openMaintenanceDailySession(openingBalance: amount);
  }

  Future<void> _showRequestCloseDialog(BuildContext context) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _MaintenanceRequestCloseDialog(
        expectedClosingBalance:
            controller.maintenanceDailyExpectedClosingBalance,
      ),
    );
    if (note == null) return;
    await controller.requestMaintenanceDailySessionClosing(note: note);
  }

  Future<void> _showClosingRequestsSheet(BuildContext context) async {
    await controller.loadMaintenanceDailyClosingRequests();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MaintenanceClosingRequestsSheet(
        controller: controller,
      ),
    );
  }
}

class _MaintenanceOpenBoxDialog extends StatefulWidget {
  const _MaintenanceOpenBoxDialog({required this.initialAmount});

  final double initialAmount;

  @override
  State<_MaintenanceOpenBoxDialog> createState() =>
      _MaintenanceOpenBoxDialogState();
}

class _MaintenanceOpenBoxDialogState extends State<_MaintenanceOpenBoxDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount > 0
          ? widget.initialAmount.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('فتح صندوق الصيانة'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'الفكة المستلمة',
          hintText: '0.00',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            double.tryParse(_controller.text.trim()) ?? 0,
          ),
          child: Text('confirm'.tr),
        ),
      ],
    );
  }
}

class _MaintenanceRequestCloseDialog extends StatefulWidget {
  const _MaintenanceRequestCloseDialog({
    required this.expectedClosingBalance,
  });

  final double expectedClosingBalance;

  @override
  State<_MaintenanceRequestCloseDialog> createState() =>
      _MaintenanceRequestCloseDialogState();
}

class _MaintenanceRequestCloseDialogState
    extends State<_MaintenanceRequestCloseDialog> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('طلب إغلاق صندوق الصيانة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المطلوب يسكر: ${widget.expectedClosingBalance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'ملاحظة',
              hintText: 'اختياري',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _noteController.text.trim()),
          child: const Text('إرسال الطلب'),
        ),
      ],
    );
  }
}

class _MaintenanceClosingRequestsSheet extends StatelessWidget {
  const _MaintenanceClosingRequestsSheet({required this.controller});

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
      padding: EdgeInsets.only(
        left: 14.w,
        right: 14.w,
        top: 14.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 14.h,
      ),
      constraints: BoxConstraints(maxHeight: 0.82.sh),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Obx(() {
        if (controller.isDailyClosingReviewLoading.value) {
          return SizedBox(
            height: 180.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final requests = controller.dailyClosingRequests;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'طلبات إغلاق صندوق الصيانة',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.operationalNavy,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            if (requests.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 44.h),
                child: Center(child: Text('noData'.tr)),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final item = requests[index];
                    return _MaintenanceClosingRequestCard(
                      item: item,
                      controller: controller,
                    );
                  },
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _MaintenanceClosingRequestCard extends StatefulWidget {
  const _MaintenanceClosingRequestCard({
    required this.item,
    required this.controller,
  });

  final Map<String, dynamic> item;
  final MaintenanceController controller;

  @override
  State<_MaintenanceClosingRequestCard> createState() =>
      _MaintenanceClosingRequestCardState();
}

class _MaintenanceClosingRequestCardState
    extends State<_MaintenanceClosingRequestCard> {
  ShownBoxesModel? _selectedTransferBox;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final controller = widget.controller;
    final requestId = int.tryParse('${item['id']}') ?? 0;
    final amountToTransfer = _num(item['amount_to_transfer'] ??
        item['expected_closing_balance'] ??
        item['closing_balance']);
    final currency = item['currency']?.toString() ?? 'شيكل';
    final boxes = controller.paymentBoxes
        .where((box) =>
            box.currency == currency && box.type != 'daily_maintenance')
        .toList();
    if (_selectedTransferBox != null &&
        !boxes.any((box) => box.boxId == _selectedTransferBox!.boxId)) {
      _selectedTransferBox = null;
    }

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.operationalCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['employee_name']?.toString() ?? '-',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.operationalNavy,
            ),
          ),
          SizedBox(height: 4.h),
          _MaintenanceClosingTotals(item: item),
          SizedBox(height: 8.h),
          Text(
            [
              item['business_date']?.toString() ?? '',
              'مبلغ الترحيل: ${amountToTransfer.toStringAsFixed(2)} $currency',
              if ((item['note']?.toString() ?? '').isNotEmpty)
                'ملاحظة: ${item['note']}',
            ].where((line) => line.trim().isNotEmpty).join('\n'),
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.35,
              color: AppColors.customGreyColor,
            ),
          ),
          if (amountToTransfer > 0) ...[
            SizedBox(height: 8.h),
            CustomDropdownFieldWithSearch(
              tital: 'boxName'.tr,
              hint: 'boxNameExample',
              items: boxes,
              value: _selectedTransferBox,
              onChanged: (value) {
                setState(() {
                  _selectedTransferBox = value as ShownBoxesModel?;
                });
              },
              itemAsString: (item) => item.boxName,
              compareFn: (a, b) => a.boxId == b.boxId,
            ),
          ],
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: requestId == 0
                      ? null
                      : () async {
                          final ok = await widget.controller
                              .rejectMaintenanceDailyClosing(requestId);
                          if (ok && context.mounted) Navigator.pop(context);
                        },
                  child: const Text('رفض'),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: requestId == 0
                      ? null
                      : () async {
                          if (amountToTransfer > 0 &&
                              _selectedTransferBox == null) {
                            Get.snackbar(
                              'error'.tr,
                              'اختر صندوق الترحيل',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }
                          final ok = await widget.controller
                              .approveMaintenanceDailyClosing(
                            requestId,
                            toBoxId: _selectedTransferBox?.boxId,
                          );
                          if (ok && context.mounted) Navigator.pop(context);
                        },
                  child: const Text('اعتماد الإغلاق'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _num(dynamic value) {
    return value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _MaintenanceClosingTotals extends StatelessWidget {
  const _MaintenanceClosingTotals({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        _TotalChip(label: 'استلم فكة', value: _num(item['opening_balance'])),
        _TotalChip(label: 'كاش اليوم', value: _num(item['cash_total'])),
        _TotalChip(label: 'فيزا', value: _num(item['visa_total'])),
        _TotalChip(label: 'حوالة', value: _num(item['transfer_total'])),
        _TotalChip(label: 'دين', value: _num(item['debt_total'])),
        _TotalChip(
          label: 'المطلوب يسكر',
          value: _num(item['expected_closing_balance']),
        ),
      ],
    );
  }

  double _num(dynamic value) {
    return value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.42.sw,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade700),
          ),
          SizedBox(height: 2.h),
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
