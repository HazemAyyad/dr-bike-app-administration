import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceDailyAdminScreen extends StatefulWidget {
  const MaintenanceDailyAdminScreen({Key? key}) : super(key: key);

  @override
  State<MaintenanceDailyAdminScreen> createState() =>
      _MaintenanceDailyAdminScreenState();
}

class _MaintenanceDailyAdminScreenState
    extends State<MaintenanceDailyAdminScreen> {
  final MaintenanceController controller = Get.find<MaintenanceController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadMaintenanceDailyAdminData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'صناديق الصيانة اليومية',
          action: false,
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'الصناديق المفتوحة'),
              Tab(text: 'طلبات الإغلاق'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isDailyClosingReviewLoading.value &&
              controller.dailyOpenSessions.isEmpty &&
              controller.dailyClosingRequests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: [
              _OpenMaintenanceSessions(controller: controller),
              _MaintenanceClosingRequests(controller: controller),
            ],
          );
        }),
      ),
    );
  }
}

class _OpenMaintenanceSessions extends StatelessWidget {
  const _OpenMaintenanceSessions({required this.controller});

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.dailyOpenSessions.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.loadMaintenanceDailyAdminData,
        child: ListView(
          children: [
            SizedBox(height: 0.35.sh),
            const Center(child: Text('لا يوجد صناديق صيانة مفتوحة')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadMaintenanceDailyAdminData,
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: controller.dailyOpenSessions.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final item = controller.dailyOpenSessions[index];
          final isPending = item['status']?.toString() == 'closing_requested';
          final canClose = item['can_close'] == true || item['can_close'] == 1;
          final pendingId = _intFrom(item['pending_closing_request_id']);

          return Card(
            child: ListTile(
              title: Text(item['employee_name']?.toString() ?? '-'),
              subtitle: Text(
                [
                  'التاريخ: ${item['business_date'] ?? '-'}',
                  'كاش: ${_money(item['cash_total'])} | فيزا: ${_money(item['visa_total'])} | حوالات: ${_money(item['transfer_total'])} | دين: ${_money(item['debt_total'])}',
                  'المطلوب ترحيله: ${_money(item['expected_closing_balance'])} ${item['currency'] ?? ''}',
                  if (isPending) 'طلب الإغلاق معلق',
                ].join('\n'),
              ),
              isThreeLine: true,
              trailing: canClose
                  ? TextButton(
                      onPressed: () => _showCloseSheet(context, item),
                      child: const Text('إغلاق اليوم'),
                    )
                  : const Icon(Icons.chevron_left),
              onTap: () {
                if (isPending && pendingId != null) {
                  final request = controller.dailyClosingRequests
                      .firstWhereOrNull(
                          (row) => _intFrom(row['id']) == pendingId);
                  if (request != null) {
                    _showRequestSheet(context, request);
                    return;
                  }
                }
                if (canClose) {
                  _showCloseSheet(context, item);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCloseSheet(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final amount = _doubleFrom(item['expected_closing_balance']);
    final currency = item['currency']?.toString() ?? 'شيكل';
    final sessionId = _intFrom(item['session_id'] ?? item['id']);
    await _MaintenanceDailyCloseSheet.show(
      context,
      controller: controller,
      title: item['employee_name']?.toString() ?? '-',
      amount: amount,
      currency: currency,
      onSubmit: (boxId, note) async {
        if (sessionId == null) return false;
        return controller.directCloseMaintenanceDailySession(
          sessionId,
          toBoxId: boxId,
          note: note,
        );
      },
    );
  }

  Future<void> _showRequestSheet(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final amount = _doubleFrom(
      item['amount_to_transfer'] ?? item['expected_closing_balance'],
    );
    final currency = item['currency']?.toString() ?? 'شيكل';
    final requestId = _intFrom(item['id']);
    await _MaintenanceDailyCloseSheet.show(
      context,
      controller: controller,
      title: item['employee_name']?.toString() ?? '-',
      amount: amount,
      currency: currency,
      allowReject: true,
      onReject: (note) async {
        if (requestId == null) return false;
        return controller.rejectMaintenanceDailyClosing(requestId, note: note);
      },
      onSubmit: (boxId, note) async {
        if (requestId == null) return false;
        return controller.approveMaintenanceDailyClosing(
          requestId,
          toBoxId: boxId,
          note: note,
        );
      },
    );
  }
}

class _MaintenanceClosingRequests extends StatelessWidget {
  const _MaintenanceClosingRequests({required this.controller});

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.dailyClosingRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.loadMaintenanceDailyAdminData,
        child: ListView(
          children: [
            SizedBox(height: 0.35.sh),
            const Center(child: Text('لا يوجد طلبات إغلاق معلقة')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadMaintenanceDailyAdminData,
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: controller.dailyClosingRequests.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final item = controller.dailyClosingRequests[index];
          return Card(
            child: ListTile(
              title: Text(item['employee_name']?.toString() ?? '-'),
              subtitle: Text(
                [
                  'التاريخ: ${item['business_date'] ?? '-'}',
                  'كاش: ${_money(item['cash_total'])} | فيزا: ${_money(item['visa_total'])} | حوالات: ${_money(item['transfer_total'])} | دين: ${_money(item['debt_total'])}',
                  'المطلوب ترحيله: ${_money(item['amount_to_transfer'] ?? item['expected_closing_balance'])} ${item['currency'] ?? ''}',
                ].join('\n'),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_left),
              onTap: () async {
                final requestId = _intFrom(item['id']);
                await _MaintenanceDailyCloseSheet.show(
                  context,
                  controller: controller,
                  title: item['employee_name']?.toString() ?? '-',
                  amount: _doubleFrom(
                    item['amount_to_transfer'] ??
                        item['expected_closing_balance'],
                  ),
                  currency: item['currency']?.toString() ?? 'شيكل',
                  allowReject: true,
                  onReject: (note) async {
                    if (requestId == null) return false;
                    return controller.rejectMaintenanceDailyClosing(
                      requestId,
                      note: note,
                    );
                  },
                  onSubmit: (boxId, note) async {
                    if (requestId == null) return false;
                    return controller.approveMaintenanceDailyClosing(
                      requestId,
                      toBoxId: boxId,
                      note: note,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MaintenanceDailyCloseSheet extends StatefulWidget {
  const _MaintenanceDailyCloseSheet({
    required this.controller,
    required this.title,
    required this.amount,
    required this.currency,
    required this.onSubmit,
    this.allowReject = false,
    this.onReject,
  });

  final MaintenanceController controller;
  final String title;
  final double amount;
  final String currency;
  final bool allowReject;
  final Future<bool> Function(int? boxId, String? note) onSubmit;
  final Future<bool> Function(String? note)? onReject;

  static Future<void> show(
    BuildContext context, {
    required MaintenanceController controller,
    required String title,
    required double amount,
    required String currency,
    required Future<bool> Function(int? boxId, String? note) onSubmit,
    bool allowReject = false,
    Future<bool> Function(String? note)? onReject,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MaintenanceDailyCloseSheet(
        controller: controller,
        title: title,
        amount: amount,
        currency: currency,
        onSubmit: onSubmit,
        allowReject: allowReject,
        onReject: onReject,
      ),
    );
  }

  @override
  State<_MaintenanceDailyCloseSheet> createState() =>
      _MaintenanceDailyCloseSheetState();
}

class _MaintenanceDailyCloseSheetState
    extends State<_MaintenanceDailyCloseSheet> {
  final TextEditingController noteController = TextEditingController();
  ShownBoxesModel? selectedBox;

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boxes = widget.controller.paymentBoxes
        .where(
          (box) =>
              box.currency == widget.currency &&
              box.type != 'daily_maintenance',
        )
        .toList();

    return Container(
      margin: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
      padding: EdgeInsets.only(
        left: 14.w,
        right: 14.w,
        top: 14.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 14.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _TotalChip(label: 'المبلغ النقدي', value: widget.amount),
                _TotalChip(label: 'المطلوب ترحيله', value: widget.amount),
              ],
            ),
            if (widget.amount > 0) ...[
              SizedBox(height: 12.h),
              CustomDropdownFieldWithSearch(
                tital: 'صندوق الترحيل',
                hint: 'اختر صندوق الترحيل',
                items: boxes,
                value: selectedBox,
                onChanged: (value) {
                  setState(() => selectedBox = value as ShownBoxesModel?);
                },
                itemAsString: (item) => item.boxName,
                compareFn: (a, b) => a.boxId == b.boxId,
              ),
            ],
            SizedBox(height: 12.h),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظة',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                if (widget.allowReject) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final ok =
                            await widget.onReject?.call(noteController.text);
                        if (ok == true && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('رفض'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (widget.amount > 0 && selectedBox == null) {
                        Get.snackbar('خطأ', 'يجب اختيار صندوق الترحيل');
                        return;
                      }
                      final ok = await widget.onSubmit(
                        selectedBox?.boxId,
                        noteController.text,
                      );
                      if (ok && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('اعتماد الإغلاق'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
            value.toStringAsFixed(2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
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
