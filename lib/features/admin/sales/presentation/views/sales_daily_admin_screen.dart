import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../data/models/daily_session_model.dart';
import '../controllers/sales_daily_admin_controller.dart';
import '../widgets/sales_daily_session_sales_log.dart';
import '../widgets/sales_skeleton_widgets.dart';

class SalesDailyAdminScreen extends GetView<SalesDailyAdminController> {
  const SalesDailyAdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: _initialTabIndex(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'salesDailyAdminTitle',
          action: false,
          bottom: TabBar(
            labelColor: AppColors.primaryColor,
            isScrollable: true,
            tabs: [
              Tab(text: 'salesDailyOpenDrawersTab'.tr),
              Tab(text: 'salesDailyClosingRequests'.tr),
              Tab(text: 'salesDailyCancelRequests'.tr),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const SalesDailyAdminRequestsSkeleton();
          }
          return TabBarView(
            children: [
              _OpenSessionsList(controller: controller),
              _ClosingList(controller: controller),
              _CancellationList(controller: controller),
            ],
          );
        }),
      ),
    );
  }

  int _initialTabIndex() {
    final args = Get.arguments;
    final raw = args is Map
        ? args['initialTab']
        : args is int
            ? args
            : null;
    final index = raw is int ? raw : int.tryParse('${raw ?? ''}') ?? 0;
    if (index < 0 || index > 2) return 0;
    return index;
  }
}

class _OpenSessionsList extends StatelessWidget {
  const _OpenSessionsList({required this.controller});

  final SalesDailyAdminController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.openSessions.isEmpty) {
      return Center(child: Text('noData'.tr));
    }

    return RefreshIndicator(
      onRefresh: controller.loadAll,
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: controller.openSessions.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final item = controller.openSessions[index];
          return Card(
            child: ListTile(
              title: Text(item.employeeName ?? '—'),
              subtitle: Text(
                [
                  item.businessDate,
                  '${'instant_sales'.tr}: ${item.instantSalesCount}',
                  '${'cashProfit'.tr}: ${item.profitSalesCount}',
                  if (item.isClosingRequested) 'salesDailyClosingPending'.tr,
                ].join('\n'),
              ),
              isThreeLine: true,
              trailing: item.canClose
                  ? TextButton(
                      onPressed: () => controller.openSessionClose(item.id),
                      child: Text('salesDailyCloseDay'.tr),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: () {
                if (item.isClosingRequested &&
                    item.pendingClosingRequestId != null) {
                  final pending = controller.closingRequests.firstWhereOrNull(
                    (r) => r.id == item.pendingClosingRequestId,
                  );
                  if (pending != null) {
                    _ClosingList.showClosingSheet(context, controller, pending);
                    return;
                  }
                }
                controller.openSessionClose(item.id);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ClosingList extends StatelessWidget {
  const _ClosingList({required this.controller});

  final SalesDailyAdminController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.closingRequests.isEmpty) {
      return Center(child: Text('noData'.tr));
    }
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: controller.closingRequests.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final item = controller.closingRequests[index];
        return Card(
          child: ListTile(
            title: Text(item.employeeName ?? '—'),
            subtitle: Text(
              [
                item.businessDate ?? '',
                if (item.isLateClose)
                  item.requestedDate != null
                      ? 'salesDailyLateCloseOnDate'.trParams({
                          'date': item.requestedDate!,
                        })
                      : 'salesDailyClosedOnNextDay'.tr,
                '${'instant_sales'.tr}: ${item.instantSalesCount} — ${'cashProfit'.tr}: ${item.profitSalesCount}',
              ].join('\n'),
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _ClosingList.showClosingSheet(context, controller, item),
          ),
        );
      },
    );
  }

  static Future<void> showClosingSheet(
    BuildContext context,
    SalesDailyAdminController controller,
    DailyClosingRequestModel item,
  ) async {
    final transfers = <String, int?>{};
    for (final row in item.cashCounts) {
      if (row.amountToTransfer > 0) {
        transfers[row.currency] = null;
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
          padding: EdgeInsets.only(
            left: 14.w,
            right: 14.w,
            top: 14.h,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 14.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.employeeName ?? '',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.isLateClose) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.requestedDate != null
                                  ? 'salesDailyLateCloseOnDate'.trParams({
                                      'date': item.requestedDate!,
                                    })
                                  : 'salesDailyClosedOnNextDay'.tr,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange.shade900,
                              ),
                            ),
                            if (item.lateCloseReason != null &&
                                item.lateCloseReason!.trim().isNotEmpty) ...[
                              SizedBox(height: 4.h),
                              Text(
                                '${'salesDailyLateCloseReason'.tr}: ${item.lateCloseReason}',
                                style: TextStyle(fontSize: 12.sp),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 12.h),
                    _ClosingRequestTotals(item: item),
                    SizedBox(height: 12.h),
                    ...item.cashCounts.map((row) {
                      final boxes = controller.shownBoxes
                          .where((b) => b.currency == row.currency)
                          .toList();
                      ShownBoxesModel? selected;
                      final selectedId = transfers[row.currency];
                      if (selectedId != null) {
                        selected = boxes.firstWhereOrNull(
                          (b) => b.boxId == selectedId,
                        );
                      }
                      return Card(
                        child: Padding(
                          padding: EdgeInsets.all(10.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.currency,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${'salesDailyPhysicalCount'.tr}: ${row.physicalCount}',
                              ),
                              Text(
                                '${'salesDailyAmountToTransfer'.tr}: ${row.amountToTransfer}',
                              ),
                              if (row.varianceAlert)
                                Text(
                                  '${'salesDailyVariance'.tr}: ${row.variance}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              if (row.employeeNote.isNotEmpty)
                                Text(row.employeeNote),
                              if (row.amountToTransfer > 0) ...[
                                SizedBox(height: 8.h),
                                CustomDropdownFieldWithSearch(
                                  tital: 'boxName'.tr,
                                  hint: 'boxNameExample',
                                  items: boxes,
                                  value: selected,
                                  onChanged: (value) {
                                    setState(() {
                                      transfers[row.currency] =
                                          (value as ShownBoxesModel?)?.boxId;
                                    });
                                  },
                                  itemAsString: (item) => item.boxName,
                                  compareFn: (a, b) => a.boxId == b.boxId,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: 12.h),
                    SalesDailySessionSalesLog(
                      instantSales: item.instantSales,
                      profitSales: item.profitSales,
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: controller.isProcessing.value
                                ? null
                                : () async {
                                    Navigator.pop(ctx);
                                    await controller.rejectClosing(item.id);
                                  },
                            child: Text('reject'.tr),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: controller.isProcessing.value
                                ? null
                                : () async {
                                    final missingTransfer = item.cashCounts.any(
                                      (row) =>
                                          row.amountToTransfer > 0 &&
                                          transfers[row.currency] == null,
                                    );
                                    if (missingTransfer) {
                                      Get.snackbar(
                                        'error'.tr,
                                        'salesDailyTransferTargetRequired'.tr,
                                      );
                                      return;
                                    }
                                    final list = <Map<String, dynamic>>[];
                                    for (final row in item.cashCounts) {
                                      if (row.amountToTransfer <= 0) continue;
                                      final toBoxId = transfers[row.currency];
                                      if (toBoxId == null) continue;
                                      list.add({
                                        'currency': row.currency,
                                        'to_box_id': toBoxId,
                                      });
                                    }
                                    Navigator.pop(ctx);
                                    await controller.approveClosing(
                                      requestId: item.id,
                                      transfers: list,
                                    );
                                  },
                            child: Text('approve'.tr),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ClosingRequestTotals extends StatelessWidget {
  const _ClosingRequestTotals({required this.item});

  final DailyClosingRequestModel item;

  @override
  Widget build(BuildContext context) {
    final opening = _sum((row) => row.openingFloat);
    final sold = _sum((row) => row.salesCollected);
    final counted = _sum((row) => row.physicalCount);
    final transfer = _sum((row) => row.amountToTransfer);

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        _TotalChip(label: 'salesDailyOpeningFloat'.tr, value: opening),
        _TotalChip(label: 'salesDailySalesCollected'.tr, value: sold),
        _TotalChip(label: 'salesDailyPhysicalCount'.tr, value: counted),
        _TotalChip(label: 'salesDailyAmountToTransfer'.tr, value: transfer),
      ],
    );
  }

  double _sum(double Function(DailyCashCountRow row) selector) {
    return item.cashCounts.fold<double>(0, (sum, row) => sum + selector(row));
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

class _CancellationList extends StatelessWidget {
  const _CancellationList({required this.controller});

  final SalesDailyAdminController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.cancellationRequests.isEmpty) {
      return Center(child: Text('noData'.tr));
    }
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: controller.cancellationRequests.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final item = controller.cancellationRequests[index];
        final typeLabel =
            item.saleType == 'instant' ? 'instantSale'.tr : 'cashProfit'.tr;
        return Card(
          child: ListTile(
            title: Text('$typeLabel #${item.saleId}'),
            subtitle: Text(
              '${item.employeeName ?? ''}\n${item.businessDate ?? ''}\n${item.reason}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => controller.rejectCancellation(item.id),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => controller.approveCancellation(item.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
