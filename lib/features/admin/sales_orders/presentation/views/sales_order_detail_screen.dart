import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';
import 'package:doctorbike/core/helpers/video_view.dart';
import 'package:doctorbike/core/services/app_dependency_registry.dart';
import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../routes/app_routes.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../boxes/data/repositories/boxes_implement.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../../employee_section/data/repositorie_imp/employee_implement.dart';
import '../../../employee_section/domain/entities/employee_entity.dart';
import '../../../general_data_list/presentation/views/partner_addresses_sheet.dart';
import '../../data/models/sales_order_model.dart';
import '../controllers/sales_orders_controller.dart';
import '../widgets/sales_order_notice.dart';
import '../widgets/sales_order_invoice_pdf.dart';
import '../widgets/sales_order_shiply_address_dialog.dart';
import '../widgets/sales_order_shiply_customer_dialog.dart';
import '../widgets/sales_order_shiply_phone_dialog.dart';
import '../widgets/sales_order_shiply_qr.dart';
import '../widgets/sales_order_shiply_sandbox_badge.dart';
import '../widgets/sales_order_shiply_timeline.dart';
import '../widgets/sales_order_status_ui.dart';

class SalesOrderDetailScreen extends StatefulWidget {
  const SalesOrderDetailScreen({Key? key}) : super(key: key);

  @override
  State<SalesOrderDetailScreen> createState() => _SalesOrderDetailScreenState();
}

class _SalesOrderDetailScreenState extends State<SalesOrderDetailScreen> {
  late final int orderId;
  bool _requestedLoad = false;
  final _itemsKey = GlobalKey();
  final _mediaKey = GlobalKey();
  final _customerKey = GlobalKey();
  final _logisticsKey = GlobalKey();
  final _historyKey = GlobalKey();

  SalesOrdersController get controller => Get.find<SalesOrdersController>();

  @override
  void initState() {
    super.initState();
    orderId = Get.arguments as int;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  void _loadIfNeeded() {
    if (_requestedLoad) return;
    if (controller.detail.value?.id == orderId) return;
    _requestedLoad = true;
    controller.loadDetail(orderId).whenComplete(() {
      if (mounted) {
        _requestedLoad = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SalesOrdersController.surfaceGray,
      appBar: AppBar(
        backgroundColor: SalesOrdersController.cardGray,
        elevation: 0,
        centerTitle: true,
        iconTheme:
            const IconThemeData(color: SalesOrdersController.textPrimary),
        title: Text(
          'salesOrders'.tr,
          style: TextStyle(
            color: SalesOrdersController.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Obx(() {
            final order = controller.detail.value;
            if (order == null) return const SizedBox.shrink();
            return PopupMenuButton<String>(
              tooltip: 'فاتورة PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onSelected: (value) {
                if (value == 'print') {
                  SalesOrderInvoicePdf.print(order);
                } else {
                  SalesOrderInvoicePdf.share(order);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'print', child: Text('طباعة الفاتورة')),
                PopupMenuItem(value: 'share', child: Text('مشاركة PDF')),
              ],
            );
          }),
          Obx(() {
            final order = controller.detail.value;
            if (order == null ||
                !SalesOrdersController.canEditOrderStatus(order.status)) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: 'salesOrderEdit'.tr,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => controller.openEditSalesOrderFlow(order),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isDetailLoading.value &&
            controller.detail.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final order = controller.detail.value;
        if (order == null) {
          return Center(
            child: Text(
              'noData'.tr,
              style:
                  const TextStyle(color: SalesOrdersController.textSecondary),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.loadDetail(order.id),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                  children: [
                    _headerCard(order),
                    SizedBox(height: 8.h),
                    _quickNavigation(order),
                    SizedBox(height: 8.h),
                    KeyedSubtree(
                      key: _itemsKey,
                      child: _itemsSection(order),
                    ),
                    if (order.mediaRequirements.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      KeyedSubtree(
                        key: _mediaKey,
                        child: _mediaRequirementsCard(order),
                      ),
                    ],
                    if (_unassignedMedia(order).isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      KeyedSubtree(
                        key: order.mediaRequirements.isEmpty ? _mediaKey : null,
                        child: _mediaCard(order),
                      ),
                    ],
                    SizedBox(height: 12.h),
                    KeyedSubtree(
                      key: _customerKey,
                      child: _customerCard(order),
                    ),
                    if (_hasLogisticsInfo(order)) ...[
                      SizedBox(height: 12.h),
                      KeyedSubtree(
                        key: _logisticsKey,
                        child: _logisticsCard(order),
                      ),
                    ],
                    SizedBox(height: 12.h),
                    _nextStepCard(order),
                    if (order.childOrders.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      _childOrdersCard(order),
                    ],
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
            _bottomActions(order),
          ],
        );
      }),
    );
  }

  Widget _headerCard(SalesOrderDetailModel order) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: SalesOrdersController.cardGray,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: SalesOrdersController.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'salesOrderNumber'.tr,
                      style: TextStyle(
                        color: SalesOrdersController.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 5.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          order.serialNumber ?? '#${order.id}',
                          style: TextStyle(
                            color: SalesOrdersController.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 22.sp,
                          ),
                        ),
                        _deliveryIncludedBadge(order.priceIncludesDelivery),
                      ],
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showWorkflowDialog(order),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Padding(
                    padding: EdgeInsets.all(2.r),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SalesOrderStatusUi.statusBadge(
                          order.status,
                          controller,
                        ),
                        SizedBox(width: 3.w),
                        Icon(Icons.expand_more_rounded, size: 18.sp),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 18.sp, color: SalesOrdersController.textSecondary),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  order.customerName ?? 'زبون غير محدد',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SalesOrdersController.textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (order.instantSaleId != null) ...[
            SizedBox(height: 12.h),
            Material(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8.r),
              child: InkWell(
                onTap: () => controller.openOrderInvoice(order.instantSaleId),
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: const Color(0xFF6EE7B7)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 18.sp, color: const Color(0xFF059669)),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'salesOrderInvoiceNumber'.tr,
                              style: TextStyle(
                                color: const Color(0xFF047857),
                                fontSize: 10.sp,
                              ),
                            ),
                            Text(
                              order.instantSaleSerial ??
                                  '#${order.instantSaleId}',
                              style: TextStyle(
                                color: const Color(0xFF065F46),
                                fontWeight: FontWeight.w700,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_left,
                        color: const Color(0xFF059669),
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: 12.h),
          _totalsSummary(order),
        ],
      ),
    );
  }

  Widget _quickNavigation(SalesOrderDetailModel order) {
    final hasMedia =
        order.mediaRequirements.isNotEmpty || order.media.isNotEmpty;
    final items = <_OrderQuickLink>[
      _OrderQuickLink(
        label: 'المنتجات',
        icon: Icons.inventory_2_outlined,
        key: _itemsKey,
      ),
      _OrderQuickLink(
        label: 'الصور',
        icon: Icons.photo_library_outlined,
        key: _mediaKey,
        enabled: hasMedia,
      ),
      _OrderQuickLink(
        label: 'الزبون',
        icon: Icons.person_outline,
        key: _customerKey,
      ),
      _OrderQuickLink(
        label: 'التوصيل',
        icon: Icons.local_shipping_outlined,
        key: _logisticsKey,
        enabled: _hasLogisticsInfo(order),
      ),
      _OrderQuickLink(
        label: 'السجل',
        icon: Icons.route_outlined,
        key: _historyKey,
        enabled: order.statusLogs.isNotEmpty,
      ),
    ];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: SalesOrdersController.cardGray,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: SalesOrdersController.borderGray),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .map(
              (item) => Tooltip(
                message: item.label,
                child: InkWell(
                  onTap: item.enabled
                      ? () {
                          if (item.label == 'السجل') {
                            _showStatusHistoryModal(order);
                          } else {
                            _scrollTo(item.key);
                          }
                        }
                      : null,
                  borderRadius: BorderRadius.circular(10.r),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 20.sp,
                          color: item.enabled
                              ? SalesOrdersController.textPrimary
                              : SalesOrdersController.borderGray,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: item.enabled
                                ? SalesOrdersController.textSecondary
                                : SalesOrdersController.borderGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  Widget _nextStepCard(SalesOrderDetailModel order) {
    final step = _nextStepFor(order);
    final color = step.color;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(9.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, color: color, size: 17.sp),
              ),
              SizedBox(width: 7.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'salesOrderRequiredNow'.tr,
                      style: TextStyle(
                        color: color,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      step.title,
                      style: TextStyle(
                        color: SalesOrdersController.textPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Text(
            step.description,
            style: TextStyle(
              color: SalesOrdersController.textSecondary,
              fontSize: 10.sp,
              height: 1.25,
            ),
          ),
          if (step.actionId != null || step.mediaCategory != null) ...[
            SizedBox(height: 7.h),
            Obx(() {
              final busy = controller.isSubmitting.value;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: busy
                      ? null
                      : () {
                          if (step.mediaCategory != null) {
                            controller.pickAndUploadMedia(
                              order.id,
                              presetCategory: step.mediaCategory,
                            );
                            return;
                          }
                          _runAction(order.id, step.actionId!, order);
                        },
                  icon: busy
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(step.actionIcon, size: 18.sp),
                  label: Text(step.actionLabel ?? ''),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: color.withValues(alpha: 0.4),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  _SalesOrderNextStep _nextStepFor(SalesOrderDetailModel order) {
    const activeColor = Color(0xFF2563EB);
    const warningColor = Color(0xFFD97706);
    const successColor = Color(0xFF059669);
    const dangerColor = Color(0xFFDC2626);

    String statusDescriptionWithLatestNote(String description) {
      String? note;
      for (final log in order.statusLogs.reversed) {
        if (log.toStatus == order.status) {
          note = log.note?.trim();
          break;
        }
      }
      if (note == null || note.isEmpty) return description;
      return '$description\n${'salesOrderNextRecordedReason'.trParams({
            'reason': note
          })}';
    }

    String stuckDescription() {
      final details = <String>['salesOrderNextStuckHint'.tr];
      final reason = order.stuckReason?.trim();
      if (reason != null && reason.isNotEmpty) {
        details.add(
          'salesOrderNextRecordedReason'.trParams({'reason': reason}),
        );
      }
      final type = order.stuckType?.trim();
      if (type != null && type.isNotEmpty) {
        details.add(
          'salesOrderStuckTypeValue'.trParams({
            'type': 'salesOrderStuckType_$type'.tr,
          }),
        );
      }
      final assignedName = order.stuckAssignedToName?.trim();
      if (assignedName != null && assignedName.isNotEmpty) {
        details.add(
          'salesOrderStuckAssignedValue'.trParams({'name': assignedName}),
        );
      }
      final followUpRaw = order.stuckFollowUpAt?.trim();
      if (followUpRaw != null && followUpRaw.isNotEmpty) {
        final parsed = DateTime.tryParse(followUpRaw);
        details.add(
          'salesOrderStuckFollowUpValue'.trParams({
            'date': parsed == null ? followUpRaw : _displayDateTime(parsed),
          }),
        );
      }
      if (details.length == 1) {
        return statusDescriptionWithLatestNote(details.first);
      }
      return details.join('\n');
    }

    _SalesOrderNextStep requiredMedia(String category) {
      final requirement = order.mediaRequirements[category];
      final translatedKey = 'salesOrderMediaCategory_$category';
      final label = translatedKey.tr != translatedKey
          ? translatedKey.tr
          : (requirement?.label ?? category);
      return _SalesOrderNextStep(
        title: 'salesOrderNextUploadRequired'.trParams({'name': label}),
        description: 'salesOrderNextUploadRequiredHint'.tr,
        icon: Icons.add_a_photo_outlined,
        color: dangerColor,
        mediaCategory: category,
        actionLabel: 'salesOrderUploadNow'.tr,
        actionIcon: Icons.upload_outlined,
      );
    }

    if (order.status == 'confirmed' &&
        order.mediaRequirements['items_group']?.satisfied == false) {
      return requiredMedia('items_group');
    }
    if (order.status == 'ready') {
      for (final category in const ['items_group', 'packaged']) {
        if (order.mediaRequirements[category]?.satisfied == false) {
          return requiredMedia(category);
        }
      }
    }

    switch (order.status) {
      case 'unconfirmed':
        return _SalesOrderNextStep(
          title: 'salesOrderNextConfirmTitle'.tr,
          description: 'salesOrderNextConfirmHint'.tr,
          icon: Icons.fact_check_outlined,
          color: activeColor,
          actionId: SalesOrderActionId.confirm,
          actionLabel: 'confirm'.tr,
          actionIcon: _actionIcon(SalesOrderActionId.confirm),
        );
      case 'confirmed':
        return _SalesOrderNextStep(
          title: 'salesOrderNextPrepareTitle'.tr,
          description: 'salesOrderNextPrepareHint'.tr,
          icon: Icons.inventory_2_outlined,
          color: activeColor,
          actionId: SalesOrderActionId.markReady,
          actionLabel: 'salesOrderMarkReady'.tr,
          actionIcon: _actionIcon(SalesOrderActionId.markReady),
        );
      case 'ready':
        return _SalesOrderNextStep(
          title: 'salesOrderNextHandoverTitle'.tr,
          description: 'salesOrderNextHandoverHint'.tr,
          icon: Icons.local_shipping_outlined,
          color: activeColor,
          actionId: SalesOrderActionId.handover,
          actionLabel: 'salesOrderHandover'.tr,
          actionIcon: _actionIcon(SalesOrderActionId.handover),
        );
      case 'with_delivery':
        return _SalesOrderNextStep(
          title: order.isShiplyDelivery
              ? 'salesOrderNextTrackShiplyTitle'.tr
              : 'salesOrderNextDeliveryTitle'.tr,
          description: order.isShiplyDelivery
              ? 'salesOrderNextTrackShiplyHint'.tr
              : 'salesOrderNextDeliveryHint'.tr,
          icon: Icons.delivery_dining_outlined,
          color: warningColor,
          actionId: order.isShiplyDelivery
              ? SalesOrderActionId.partialDeliver
              : SalesOrderActionId.deliver,
          actionLabel: order.isShiplyDelivery
              ? 'salesOrderPartialDeliver'.tr
              : 'salesOrderDeliver'.tr,
          actionIcon: _actionIcon(
            order.isShiplyDelivery
                ? SalesOrderActionId.partialDeliver
                : SalesOrderActionId.deliver,
          ),
        );
      case 'partial_return':
      case 'review':
      case 'partial_delivered':
        return _SalesOrderNextStep(
          title: 'salesOrderNextCompleteRemainingTitle'.tr,
          description: 'salesOrderNextCompleteRemainingHint'.tr,
          icon: Icons.pending_actions_outlined,
          color: warningColor,
          actionId: SalesOrderActionId.partialDeliver,
          actionLabel: 'salesOrderPartialDeliver'.tr,
          actionIcon: _actionIcon(SalesOrderActionId.partialDeliver),
        );
      case 'delivered':
        final hasCarrierBalance = order.carrierReceivableBalance > 0.009;
        final hasCustomerDebt = order.customerDebtBalance > 0.009;
        if (hasCarrierBalance || hasCustomerDebt) {
          final balances = <String>[];
          if (hasCarrierBalance) {
            balances.add(
              'salesOrderNextCarrierBalance'.trParams({
                'amount': order.carrierReceivableBalance.toStringAsFixed(2),
              }),
            );
          }
          if (hasCustomerDebt) {
            balances.add(
              'salesOrderNextCustomerDebt'.trParams({
                'amount': order.customerDebtBalance.toStringAsFixed(2),
              }),
            );
          }
          return _SalesOrderNextStep(
            title: 'salesOrderNextSettlementTitle'.tr,
            description: balances.join(' • '),
            icon: Icons.account_balance_wallet_outlined,
            color: warningColor,
            actionId: SalesOrderActionId.settle,
            actionLabel: 'salesOrderSettle'.tr,
            actionIcon: _actionIcon(SalesOrderActionId.settle),
          );
        }
        return _SalesOrderNextStep(
          title: 'salesOrderNextArchiveTitle'.tr,
          description: 'salesOrderNextArchiveHint'.tr,
          icon: Icons.task_alt_outlined,
          color: successColor,
          actionId: SalesOrderActionId.archive,
          actionLabel: 'salesOrderArchive'.tr,
          actionIcon: _actionIcon(SalesOrderActionId.archive),
        );
      case 'stuck':
        return _SalesOrderNextStep(
          title: 'salesOrderNextStuckTitle'.tr,
          description: stuckDescription(),
          icon: Icons.report_problem_outlined,
          color: dangerColor,
          actionId: SalesOrderActionId.resolveStuck,
          actionLabel: 'salesOrderResolveStuck'.tr,
          actionIcon: _actionIcon(SalesOrderActionId.resolveStuck),
        );
      case 'postponed':
        return _SalesOrderNextStep(
          title: 'salesOrderNextPostponedTitle'.tr,
          description: statusDescriptionWithLatestNote(
            'salesOrderNextPostponedHint'.tr,
          ),
          icon: Icons.schedule_outlined,
          color: warningColor,
          actionId: SalesOrderActionId.revertStatus,
          actionLabel: 'salesOrderRevertStatus'.tr,
          actionIcon: _actionIcon(SalesOrderActionId.revertStatus),
        );
      case 'archived':
        return _SalesOrderNextStep(
          title: 'salesOrderNextArchivedTitle'.tr,
          description: 'salesOrderNextArchivedHint'.tr,
          icon: Icons.inventory_outlined,
          color: successColor,
        );
      case 'canceled':
      case 'returned':
        return _SalesOrderNextStep(
          title: order.status == 'canceled'
              ? 'salesOrderNextCanceledTitle'.tr
              : 'salesOrderNextReturnedTitle'.tr,
          description: order.status == 'canceled'
              ? 'salesOrderNextCanceledHint'.tr
              : 'salesOrderNextReturnedHint'.tr,
          icon: Icons.block_outlined,
          color: dangerColor,
        );
      default:
        return _SalesOrderNextStep(
          title: controller.statusLabel(order.status),
          description: 'salesOrderNextReviewHint'.tr,
          icon: Icons.info_outline,
          color: activeColor,
        );
    }
  }

  Widget _deliveryIncludedBadge(bool includesDelivery) {
    final color = includesDelivery
        ? const Color(0xFF6D28D9)
        : SalesOrdersController.textSecondary;
    final background = includesDelivery
        ? const Color(0xFFF3E8FF)
        : SalesOrdersController.surfaceGray;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 13.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            includesDelivery
                ? 'salesOrderIncludesDelivery'.tr
                : 'salesOrderExcludesDelivery'.tr,
            style: TextStyle(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalsSummary(SalesOrderDetailModel order) {
    final paid = order.paymentAmount;
    final remaining = (order.total - paid).clamp(0, double.infinity).toDouble();
    final quoted = order.shiplyQuotedDeliveryFee;
    final hasShiplyFeeBreakdown = order.isShiplyDelivery &&
        quoted != null &&
        (quoted > 0 || order.customerDeliveryFee > 0);
    return Column(
      children: [
        _totalLine('subtotal'.tr, order.subtotal),
        if (order.discount > 0)
          _totalLine('discount'.tr, -order.discount, muted: true),
        if (hasShiplyFeeBreakdown) ...[
          _totalLine('salesOrderShiplyQuotedFee'.tr, quoted!, muted: true),
          _totalLine(
              'salesOrderShiplyChargedFee'.tr, order.customerDeliveryFee),
          if (order.shiplyDeliveryFeeAdjustment != null &&
              order.shiplyDeliveryFeeAdjustment!.abs() >= 0.01)
            _totalLine(
              'salesOrderShiplyFeeDifference'.tr,
              order.shiplyDeliveryFeeAdjustment!,
              muted: true,
            ),
        ] else if (order.customerDeliveryFee > 0)
          _totalLine('salesOrderDeliveryFee'.tr, order.customerDeliveryFee),
        Divider(height: 16.h, color: SalesOrdersController.borderGray),
        _totalLine(
          'total'.tr,
          order.total,
          bold: true,
        ),
        if (paid > 0) ...[
          SizedBox(height: 6.h),
          _totalLine('paidAmount'.tr, paid, muted: true),
        ],
        if (remaining > 0) _totalLine('remainingAmount'.tr, remaining),
      ],
    );
  }

  Widget _totalLine(
    String label,
    double amount, {
    bool bold = false,
    bool muted = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: muted
                  ? SalesOrdersController.textSecondary
                  : SalesOrdersController.textPrimary,
              fontSize: bold ? 14.sp : 12.sp,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ₪',
            style: TextStyle(
              color: SalesOrdersController.textPrimary,
              fontSize: bold ? 15.sp : 12.sp,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasLogisticsInfo(SalesOrderDetailModel order) {
    final handover = order.latestHandover;
    return (order.trackingNumber != null && order.trackingNumber!.isNotEmpty) ||
        (order.deliveryCompanyName != null &&
            order.deliveryCompanyName!.isNotEmpty) ||
        handover != null ||
        order.shiplyTracking != null;
  }

  Widget _logisticsCard(SalesOrderDetailModel order) {
    final handover = order.latestHandover;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: SalesOrdersController.cardGray,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: SalesOrdersController.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'salesOrderLogistics'.tr,
            style: TextStyle(
              color: SalesOrdersController.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 8.h),
          if (order.deliveryCompanyName != null &&
              order.deliveryCompanyName!.isNotEmpty)
            _infoRow(Icons.local_shipping_outlined, order.deliveryCompanyName!),
          if (handover != null) ...[
            if (handover.isTaxi) ...[
              if ((handover.trackingNumber ?? '').isNotEmpty)
                _infoRow(Icons.local_taxi_outlined,
                    '${'salesOrderTaxiNumber'.tr}: ${handover.trackingNumber}'),
              if ((handover.carrierContactName ?? '').isNotEmpty)
                _infoRow(Icons.person_outline,
                    '${'salesOrderTaxiDriver'.tr}: ${handover.carrierContactName}'),
              if ((handover.carrierContactPhone ?? '').isNotEmpty)
                _infoRow(Icons.phone_outlined,
                    '${'salesOrderTaxiPhone'.tr}: ${handover.carrierContactPhone}'),
            ] else if (handover.isOffice) ...[
              if ((handover.carrierOfficeName ?? '').isNotEmpty)
                _infoRow(Icons.store_outlined,
                    '${'salesOrderOfficeName'.tr}: ${handover.carrierOfficeName}'),
              if ((handover.carrierContactName ?? '').isNotEmpty)
                _infoRow(Icons.person_outline,
                    '${'salesOrderOfficeDriver'.tr}: ${handover.carrierContactName}'),
              if ((handover.carrierContactPhone ?? '').isNotEmpty)
                _infoRow(Icons.phone_outlined,
                    '${'salesOrderOfficePhone'.tr}: ${handover.carrierContactPhone}'),
              if ((handover.carrierVehicleNumber ?? '').isNotEmpty)
                _infoRow(Icons.directions_car_outlined,
                    '${'salesOrderOfficeVehicle'.tr}: ${handover.carrierVehicleNumber}'),
            ] else if (handover.isShiply) ...[
              if ((handover.shiplyParcelCode ?? handover.trackingNumber ?? '')
                  .isNotEmpty)
                _infoRow(Icons.qr_code_2_outlined,
                    handover.shiplyParcelCode ?? handover.trackingNumber!),
              if ((handover.shiplyQrCode ?? '').isNotEmpty)
                SalesOrderShiplyQrTile(code: handover.shiplyQrCode!),
              if ((handover.shiplyParcelCode ?? handover.trackingNumber ?? '')
                  .isNotEmpty)
                SalesOrderShiplyLabelTile(
                  orderId: order.id,
                  parcelCode:
                      handover.shiplyParcelCode ?? handover.trackingNumber!,
                  version: 'v1',
                ),
              if ((handover.shiplyParcelCode ?? handover.trackingNumber ?? '')
                  .isNotEmpty)
                SalesOrderShiplyLabelTile(
                  orderId: order.id,
                  parcelCode:
                      handover.shiplyParcelCode ?? handover.trackingNumber!,
                  version: 'v2',
                ),
            ],
            if ((handover.handedOverAt ?? '').isNotEmpty)
              _infoRow(Icons.schedule_outlined,
                  '${'salesOrderHandedOverAt'.tr}: ${handover.handedOverAt}'),
          ] else ...[
            if (order.trackingNumber != null &&
                order.trackingNumber!.isNotEmpty)
              _infoRow(Icons.qr_code_2_outlined, order.trackingNumber!),
          ],
          if (order.shiplyTracking != null) ...[
            if (order.shiplyTracking!.shiplyMode == 'test') ...[
              SizedBox(height: 8.h),
              _shiplyTestModeChip(),
            ],
            SizedBox(height: 12.h),
            SalesOrderShiplyTimeline(tracking: order.shiplyTracking!),
          ],
        ],
      ),
    );
  }

  Widget _shiplyTestModeChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Text(
        'shiplySandboxShort'.tr,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE65100),
        ),
      ),
    );
  }

  Future<void> _showStatusHistoryModal(SalesOrderDetailModel order) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: SalesOrdersController.surfaceGray,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              Container(
                width: 42.w,
                height: 4.h,
                margin: EdgeInsets.symmetric(vertical: 9.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 20.h),
                  children: [_statusHistoryCard(order)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusHistoryCard(SalesOrderDetailModel order) {
    final logs = order.statusLogs.reversed.toList();
    return Container(
      decoration: BoxDecoration(
        color: SalesOrdersController.cardGray,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: SalesOrdersController.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 8.h),
            child: Row(
              children: [
                Icon(Icons.route_outlined,
                    size: 19.sp, color: SalesOrdersController.textPrimary),
                SizedBox(width: 7.w),
                Text(
                  'salesOrderStatusHistory'.tr,
                  style: TextStyle(
                    color: SalesOrdersController.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                  ),
                ),
                const Spacer(),
                Text(
                  '${logs.length}',
                  style: TextStyle(
                    color: SalesOrdersController.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          ...logs.asMap().entries.map((entry) {
            final log = entry.value;
            final label = controller.statusLabel(log.toStatus);
            final date = _historyDate(log.createdAt);
            final time = _historyTime(log.createdAt);
            final color = SalesOrderStatusUi.statusColor(log.toStatus);
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 11.h),
              color: entry.key.isEven
                  ? SalesOrdersController.surfaceGray.withValues(alpha: 0.72)
                  : SalesOrdersController.cardGray,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 92.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: SalesOrdersController.textSecondary,
                          ),
                        ),
                        if ((log.userName ?? '').trim().isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.person,
                                  size: 11.sp,
                                  color: SalesOrdersController.textSecondary),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                  log.userName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w700,
                                    color: SalesOrdersController.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: SalesOrdersController.textPrimary,
                      size: 25.sp,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            _historyStatusIcon(log.toStatus),
                            color: Colors.white,
                            size: 21.sp,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                  color: SalesOrdersController.textPrimary,
                                ),
                              ),
                              Text(
                                (log.note ?? '').trim().isEmpty
                                    ? 'لا توجد ملاحظات'
                                    : log.note!.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: SalesOrdersController.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _historyDate(String? raw) {
    final parsed = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return raw?.split(' ').first ?? '—';
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}/$month/$day';
  }

  String _historyTime(String? raw) {
    final parsed = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return '';
    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${parsed.hour >= 12 ? 'م' : 'ص'}';
  }

  IconData _historyStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.fact_check_outlined;
      case 'ready':
        return Icons.inventory_2_outlined;
      case 'with_delivery':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_rounded;
      case 'archived':
        return Icons.archive_outlined;
      case 'postponed':
        return Icons.schedule_outlined;
      case 'canceled':
      case 'returned':
        return Icons.close_rounded;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Widget _customerCard(SalesOrderDetailModel order) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: SalesOrdersController.cardGray,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: SalesOrdersController.borderGray),
      ),
      child: Column(
        children: [
          _infoRow(Icons.person_outline, order.customerName ?? '—'),
          if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
            _infoRow(Icons.phone_outlined, order.customerPhone!),
          if (order.shiplyAddressLabel != null &&
              order.shiplyAddressLabel!.isNotEmpty)
            _infoRow(Icons.location_on_outlined, order.shiplyAddressLabel!)
          else if (order.cityName != null)
            _infoRow(Icons.location_on_outlined, order.cityName!),
          if (order.customerAddress != null &&
              order.customerAddress!.trim().isNotEmpty)
            _infoRow(Icons.signpost_outlined, order.customerAddress!),
          if (order.notes != null && order.notes!.trim().isNotEmpty)
            _infoRow(Icons.notes_outlined, order.notes!),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: SalesOrdersController.textSecondary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: SalesOrdersController.textPrimary,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsSection(SalesOrderDetailModel order) {
    final displayItems = _displayItems(order.items);

    return Container(
      decoration: BoxDecoration(
        color: SalesOrdersController.cardGray,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: SalesOrdersController.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 4.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'salesOrderItems'.tr,
                    style: TextStyle(
                      color: SalesOrdersController.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
                Text(
                  '${displayItems.length}',
                  style: TextStyle(
                    color: SalesOrdersController.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'product'.tr,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: SalesOrdersController.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 36.w,
                  child: Text(
                    'quantity'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: SalesOrdersController.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 52.w,
                  child: Text(
                    'price'.tr,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: SalesOrdersController.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 58.w,
                  child: Text(
                    'total'.tr,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: SalesOrdersController.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...displayItems.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == displayItems.length - 1;
            return _compactItemRow(item, showDivider: !isLast);
          }),
        ],
      ),
    );
  }

  List<SalesOrderItemModel> _displayItems(List<SalesOrderItemModel> items) {
    final grouped = <String, SalesOrderItemModel>{};

    for (final item in items) {
      final key = [
        item.productId,
        item.sizeId ?? '',
        item.sizeColorId ?? '',
        item.productName ?? '',
        item.unitPrice,
      ].join('|');

      final current = grouped[key];
      if (current == null) {
        grouped[key] = item;
        continue;
      }

      grouped[key] = SalesOrderItemModel(
        id: current.id,
        productId: current.productId,
        productName: current.productName,
        productImage: current.productImage ?? item.productImage,
        sizeId: current.sizeId,
        sizeColorId: current.sizeColorId,
        sizeLabel: current.sizeLabel,
        colorLabel: current.colorLabel,
        quantity: current.quantity + item.quantity,
        deliveredQty: current.deliveredQty + item.deliveredQty,
        dispatchedQty: current.dispatchedQty + item.dispatchedQty,
        returnedQty: current.returnedQty + item.returnedQty,
        unitPrice: current.unitPrice,
        lineTotal: current.lineTotal + item.lineTotal,
      );
    }

    return grouped.values.toList();
  }

  Widget _compactItemRow(SalesOrderItemModel item, {bool showDivider = true}) {
    final variant = <String>[
      if (item.sizeLabel != null && item.sizeLabel!.isNotEmpty) item.sizeLabel!,
      if (item.colorLabel != null && item.colorLabel!.isNotEmpty)
        item.colorLabel!,
    ].join(' / ');

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _itemThumb(item),
              SizedBox(width: 8.w),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName ?? '#${item.productId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SalesOrdersController.textPrimary,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (variant.isNotEmpty)
                      Text(
                        variant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SalesOrdersController.textSecondary,
                          fontSize: 9.sp,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 36.w,
                child: Text(
                  '${item.quantity}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: SalesOrdersController.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                width: 52.w,
                child: Text(
                  item.unitPrice.toStringAsFixed(0),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: SalesOrdersController.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 58.w,
                child: Text(
                  item.lineTotal.toStringAsFixed(0),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: SalesOrdersController.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: SalesOrdersController.borderGray.withValues(alpha: 0.7),
          ),
      ],
    );
  }

  Widget _itemThumb(SalesOrderItemModel item) {
    final raw = item.productImage;
    if (raw == null || raw.trim().isEmpty) {
      return Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(Icons.image_not_supported_outlined,
            size: 16.sp, color: Colors.grey.shade500),
      );
    }

    final url = ShowNetImage.getThumbnailPhoto(raw);
    final zoomUrl = ShowNetImage.getPhoto(raw);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showImageZoom(zoomUrl),
        borderRadius: BorderRadius.circular(8.r),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: CachedNetworkImage(
            imageUrl: url,
            width: 34.w,
            height: 34.w,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Future<void> _showImageZoom(String url) async {
    await Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(16.w),
        child: AspectRatio(
          aspectRatio: 1,
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
          ),
        ),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.65),
    );
  }

  Widget _itemPlaceholder({double size = 56}) {
    return Container(
      width: size.w,
      height: size.w,
      color: SalesOrdersController.surfaceGray,
      child: Image.asset(
        AssetsManager.salesImage,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _childOrdersCard(SalesOrderDetailModel order) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: SalesOrdersController.cardGray,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: SalesOrdersController.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'salesOrderChildOrders'.tr,
            style: TextStyle(
              color: SalesOrdersController.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
          ...order.childOrders.map(
            (child) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 18.r,
                backgroundColor: SalesOrderStatusUi.statusBg(child.status),
                child: Icon(
                  Icons.subdirectory_arrow_left,
                  size: 16.sp,
                  color: SalesOrderStatusUi.statusColor(child.status),
                ),
              ),
              title: Text(
                child.serialNumber ?? '#${child.id}',
                style: TextStyle(
                  color: SalesOrdersController.textPrimary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                controller.statusLabel(child.status),
                style: TextStyle(
                  color: SalesOrdersController.textSecondary,
                  fontSize: 11.sp,
                ),
              ),
              trailing: Text(
                '${child.total.toStringAsFixed(2)} ₪',
                style: TextStyle(
                  color: SalesOrdersController.textPrimary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => Get.toNamed(AppRoutes.SALESORDERDETAILSCREEN,
                  arguments: child.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaRequirementsCard(SalesOrderDetailModel order) {
    final entries = order.mediaRequirements.entries.toList()
      ..sort((a, b) {
        if (a.value.optional != b.value.optional) {
          return a.value.optional ? 1 : -1;
        }
        return a.key.compareTo(b.key);
      });

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: SalesOrdersController.cardGray,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: SalesOrdersController.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'salesOrderMediaRequirements'.tr,
            style: TextStyle(
              color: SalesOrdersController.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 10.h),
          ...entries.map((entry) {
            final req = entry.value;
            final labelKey = 'salesOrderMediaCategory_${req.category}';
            final label = labelKey.tr != labelKey ? labelKey.tr : req.label;
            final color = req.satisfied
                ? const Color(0xFF059669)
                : req.optional
                    ? SalesOrdersController.textSecondary
                    : const Color(0xFFDC2626);
            final uploaded = order.media
                .where((media) => media.category == req.category)
                .toList();
            return Obx(() {
              final busy = controller.isSubmitting.value;
              return Container(
                margin: EdgeInsets.only(bottom: 7.h),
                padding: EdgeInsets.all(9.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.055),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          req.satisfied
                              ? Icons.check_circle
                              : Icons.photo_camera_outlined,
                          color: color,
                          size: 19.sp,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          uploaded.isEmpty
                              ? (req.optional ? 'اختياري' : 'مطلوب')
                              : '${uploaded.length} مرفوعة',
                          style: TextStyle(fontSize: 9.sp, color: color),
                        ),
                        SizedBox(width: 5.w),
                        InkWell(
                          onTap: busy
                              ? null
                              : () => controller.pickAndUploadMedia(
                                    order.id,
                                    presetCategory: req.category,
                                  ),
                          child: Icon(Icons.add_a_photo_outlined,
                              size: 19.sp, color: color),
                        ),
                      ],
                    ),
                    if (uploaded.isEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        'اضغط على أيقونة الكاميرا لرفع صورة لهذا المتطلب',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: SalesOrdersController.textSecondary,
                        ),
                      ),
                    ] else ...[
                      SizedBox(height: 7.h),
                      SizedBox(
                        height: 54.w,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: uploaded.length,
                          separatorBuilder: (_, __) => SizedBox(width: 5.w),
                          itemBuilder: (_, index) {
                            final media = uploaded[index];
                            final url = media.url;
                            if (url == null) return const SizedBox.shrink();
                            return InkWell(
                              onTap: () => _showImageZoom(url),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7.r),
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  width: 54.w,
                                  height: 54.w,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              );
            });
          }),
        ],
      ),
    );
  }

  Widget _mediaCard(SalesOrderDetailModel order) {
    final mediaRows = _unassignedMedia(order);
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: SalesOrdersController.cardGray,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: SalesOrdersController.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'salesOrderUploadMedia'.tr,
            style: TextStyle(
              color: SalesOrdersController.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: mediaRows.map((m) {
              if (m.url == null) return const SizedBox.shrink();
              final url = m.url!;
              if (m.type == 'video') {
                return Material(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8.r),
                  child: InkWell(
                    onTap: () => Get.to(() => VideoView(videoPath: url)),
                    borderRadius: BorderRadius.circular(8.r),
                    child: SizedBox(
                      width: 88.w,
                      height: 88.w,
                      child: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                );
              }
              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
                child: InkWell(
                  onTap: () => _showImageZoom(url),
                  borderRadius: BorderRadius.circular(8.r),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      width: 88.w,
                      height: 88.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<SalesOrderMediaModel> _unassignedMedia(SalesOrderDetailModel order) {
    if (order.mediaRequirements.isEmpty) return order.media;
    final categories = order.mediaRequirements.keys.toSet();
    return order.media
        .where((media) => !categories.contains(media.category))
        .toList();
  }

  Future<void> _showWorkflowDialog(SalesOrderDetailModel order) async {
    final currentIndex = SalesOrderStatusUi.workflowIndex(order.status);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مسار الطلبية'),
        contentPadding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: SalesOrderStatusUi.workflowSteps.length,
            separatorBuilder: (_, __) => Container(
              margin: EdgeInsetsDirectional.only(start: 18.w),
              width: 2,
              height: 10.h,
              color: SalesOrdersController.borderGray,
            ),
            itemBuilder: (_, index) {
              final status = SalesOrderStatusUi.workflowSteps[index];
              final current = index == currentIndex;
              final completed = index < currentIndex;
              final color = SalesOrderStatusUi.statusColor(status);
              return Material(
                color: current
                    ? color.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10.r),
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                  leading: CircleAvatar(
                    radius: 15.r,
                    backgroundColor: color.withValues(alpha: 0.13),
                    child: Icon(
                      completed
                          ? Icons.check_rounded
                          : current
                              ? Icons.radio_button_checked_rounded
                              : Icons.circle_outlined,
                      size: 17.sp,
                      color: color,
                    ),
                  ),
                  title: Text(
                    controller.statusLabel(status),
                    style: TextStyle(
                      fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    current
                        ? 'الحالة الحالية'
                        : completed
                            ? 'تمت هذه المرحلة'
                            : _workflowRequirement(status),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: index > currentIndex
                      ? const Icon(Icons.arrow_back_rounded)
                      : null,
                  onTap: index <= currentIndex
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                          _confirmWorkflowTarget(order, status);
                        },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  String _workflowRequirement(String status) {
    switch (status) {
      case 'confirmed':
        return 'تأكيد بيانات الزبون وحجز المنتجات';
      case 'ready':
        return 'تجهيز المنتجات وإرفاق صورة المنتجات المطلوبة';
      case 'with_delivery':
        return 'صورة التغليف وبيانات شركة التوصيل والعنوان';
      case 'delivered':
        return 'تأكيد التسليم وتسجيل المبالغ المستلمة';
      case 'archived':
        return 'إنهاء التسوية المالية ثم أرشفة الطلبية';
      default:
        return 'إكمال متطلبات المرحلة السابقة';
    }
  }

  Future<void> _confirmWorkflowTarget(
    SalesOrderDetailModel order,
    String target,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('الانتقال إلى ${controller.statusLabel(target)}'),
        content: Text(
          'سيتم تنفيذ المراحل المطلوبة بالترتيب حتى الوصول لهذه الحالة.\n\n'
          'المطلوب: ${_workflowRequirement(target)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ابدأ المتطلبات'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _advanceOrderTo(order.id, target);
    }
  }

  Future<void> _advanceOrderTo(int orderId, String target) async {
    final targetIndex = SalesOrderStatusUi.workflowSteps.indexOf(target);
    if (targetIndex < 0) return;
    for (var attempt = 0; attempt < 6; attempt++) {
      final order = controller.detail.value;
      if (order == null || order.id != orderId) return;
      final currentIndex = SalesOrderStatusUi.workflowIndex(order.status);
      if (currentIndex >= targetIndex) return;
      final before = order.status;
      switch (order.status) {
        case 'unconfirmed':
          await controller.confirmOrder(orderId);
          break;
        case 'confirmed':
          var current = order;
          if (current.mediaRequirements['items_group']?.satisfied == false) {
            await controller.pickAndUploadMedia(
              orderId,
              presetCategory: 'items_group',
            );
            await controller.loadDetail(orderId);
            current = controller.detail.value ?? current;
          }
          if (current.mediaRequirements['items_group']?.satisfied != false) {
            await controller.markReady(orderId);
          }
          break;
        case 'ready':
          var current = order;
          if (current.mediaRequirements['packaged']?.satisfied == false) {
            await controller.pickAndUploadMedia(
              orderId,
              presetCategory: 'packaged',
            );
            await controller.loadDetail(orderId);
            current = controller.detail.value ?? current;
          }
          if (current.mediaRequirements['packaged']?.satisfied != false) {
            await _startHandover(current);
          }
          break;
        case 'with_delivery':
          await controller.deliver(orderId);
          break;
        case 'delivered':
          await controller.archive(orderId);
          break;
        default:
          return;
      }
      final after = controller.detail.value?.status;
      if (after == null || after == before) return;
    }
  }

  Widget _bottomActions(SalesOrderDetailModel order) {
    final actions = SalesOrderActions.forStatus(
      order.status,
      isShiplyDelivery: order.isShiplyDelivery,
      needsSettlement: order.customerDebtBalance > 0.009 ||
          order.carrierReceivableBalance > 0.009,
    );
    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 7.h),
      decoration: BoxDecoration(
        color: SalesOrdersController.cardGray,
        border: const Border(
          top: BorderSide(color: SalesOrdersController.borderGray),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Obx(() {
          final busy = controller.isSubmitting.value;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: actions
                  .map(
                    (action) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: _actionIconTile(
                        action: action,
                        order: order,
                        busy: busy,
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        }),
      ),
    );
  }

  Widget _actionIconTile({
    required SalesOrderActionDef action,
    required SalesOrderDetailModel order,
    required bool busy,
  }) {
    final isDanger = action.isDanger;
    final isPrimary = action.isPrimary;
    final iconColor = isDanger
        ? const Color(0xFFDC2626)
        : isPrimary
            ? SalesOrdersController.cardGray
            : SalesOrdersController.textPrimary;
    final bgColor = isDanger
        ? const Color(0xFFDC2626).withValues(alpha: 0.1)
        : isPrimary
            ? SalesOrdersController.textPrimary
            : SalesOrdersController.surfaceGray;

    return SizedBox(
      width: 58.w,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : () => _runAction(order.id, action.id, order),
          borderRadius: BorderRadius.circular(10.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isDanger
                          ? const Color(0xFFDC2626).withValues(alpha: 0.35)
                          : isPrimary
                              ? SalesOrdersController.textPrimary
                              : SalesOrdersController.borderGray,
                    ),
                  ),
                  child: Icon(
                    _actionIcon(action.id),
                    color: busy ? iconColor.withValues(alpha: 0.35) : iconColor,
                    size: 19.sp,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.sp,
                    height: 1.2,
                    fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
                    color: isDanger
                        ? const Color(0xFFDC2626)
                        : SalesOrdersController.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _actionIcon(SalesOrderActionId id) {
    switch (id) {
      case SalesOrderActionId.confirm:
        return Icons.check_circle_outline;
      case SalesOrderActionId.markReady:
        return Icons.inventory_2_outlined;
      case SalesOrderActionId.handover:
        return Icons.local_shipping_outlined;
      case SalesOrderActionId.deliver:
        return Icons.done_all_outlined;
      case SalesOrderActionId.partialDeliver:
        return Icons.pie_chart_outline;
      case SalesOrderActionId.partialReturn:
        return Icons.undo_outlined;
      case SalesOrderActionId.followUp:
        return Icons.add_task_outlined;
      case SalesOrderActionId.settle:
        return Icons.account_balance_wallet_outlined;
      case SalesOrderActionId.archive:
        return Icons.archive_outlined;
      case SalesOrderActionId.share:
        return Icons.share_outlined;
      case SalesOrderActionId.uploadMedia:
        return Icons.photo_camera_outlined;
      case SalesOrderActionId.cancel:
        return Icons.cancel_outlined;
      case SalesOrderActionId.revertStatus:
        return Icons.undo_outlined;
      case SalesOrderActionId.postpone:
        return Icons.schedule_outlined;
      case SalesOrderActionId.markStuck:
        return Icons.report_problem_outlined;
      case SalesOrderActionId.resolveStuck:
        return Icons.task_alt_outlined;
      case SalesOrderActionId.alternativeReturn:
        return Icons.swap_horiz_outlined;
    }
  }

  void _runAction(
    int orderId,
    SalesOrderActionId actionId,
    SalesOrderDetailModel order,
  ) {
    switch (actionId) {
      case SalesOrderActionId.confirm:
        controller.confirmOrder(orderId);
        break;
      case SalesOrderActionId.markReady:
        final missingItems = order.mediaRequirements['items_group'];
        if (missingItems != null && !missingItems.satisfied) {
          controller.pickAndUploadMedia(
            orderId,
            presetCategory: 'items_group',
          );
        } else {
          controller.markReady(orderId);
        }
        break;
      case SalesOrderActionId.handover:
        final missingMedia = ['items_group', 'packaged'].firstWhereOrNull(
          (category) => order.mediaRequirements[category]?.satisfied == false,
        );
        if (missingMedia != null) {
          controller.pickAndUploadMedia(
            orderId,
            presetCategory: missingMedia,
          );
        } else {
          _startHandover(order);
        }
        break;
      case SalesOrderActionId.deliver:
        controller.deliver(orderId);
        break;
      case SalesOrderActionId.partialDeliver:
        _showQtySheet(order, 'deliver');
        break;
      case SalesOrderActionId.partialReturn:
        _showQtySheet(order, 'return');
        break;
      case SalesOrderActionId.followUp:
        controller.followUp(orderId);
        break;
      case SalesOrderActionId.settle:
        _showSettleSheet(orderId);
        break;
      case SalesOrderActionId.archive:
        controller.archive(orderId);
        break;
      case SalesOrderActionId.share:
        controller.showShareSheet(orderId);
        break;
      case SalesOrderActionId.uploadMedia:
        controller.pickAndUploadMedia(orderId);
        break;
      case SalesOrderActionId.cancel:
        _confirmCancellation(order);
        break;
      case SalesOrderActionId.revertStatus:
        controller.revertOrderStatus(orderId);
        break;
      case SalesOrderActionId.postpone:
        _showPostponeSheet(orderId);
        break;
      case SalesOrderActionId.markStuck:
        _showMarkStuckSheet(orderId);
        break;
      case SalesOrderActionId.resolveStuck:
        _showResolveStuckSheet(order);
        break;
      case SalesOrderActionId.alternativeReturn:
        _showQtySheet(order, 'alternative_return');
        break;
    }
  }

  Future<void> _confirmCancellation(SalesOrderDetailModel order) async {
    final isReturn = const {
      'with_delivery',
      'partial_return',
      'partial_delivered',
      'review',
    }.contains(order.status);
    final paidAmount = order.paymentAmount;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(isReturn ? 'تأكيد إرجاع الطلبية' : 'تأكيد إلغاء الطلبية'),
        content: Text(
          paidAmount > 0
              ? 'سيتم عكس مبلغ ${paidAmount.toStringAsFixed(2)} من صندوق الطلبيات وتصفير الدفعة والدين. تأكد أن المبلغ أُعيد للزبون.'
              : 'سيتم إلغاء الطلبية وتصفير أي مديونية مرتبطة بها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Get.back(result: true),
            child: Text(isReturn ? 'تأكيد الإرجاع' : 'تأكيد الإلغاء'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.cancelOrder(order.id);
    }
  }

  void _showQtySheet(SalesOrderDetailModel order, String mode) {
    final qtyControllers = <int, TextEditingController>{};
    for (final item in order.items) {
      final max =
          mode == 'deliver' ? item.pendingDeliverQty : item.returnableQty;
      if (max > 0) {
        qtyControllers[item.id] = TextEditingController(text: '0');
      }
    }

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: SalesOrdersController.surfaceGray,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              mode == 'deliver'
                  ? 'salesOrderPartialDeliver'.tr
                  : mode == 'alternative_return'
                      ? 'salesOrderAlternativeReturn'.tr
                      : 'salesOrderPartialReturn'.tr,
              style: TextStyle(
                color: SalesOrdersController.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: qtyControllers.entries.map((entry) {
                    final item =
                        order.items.firstWhere((i) => i.id == entry.key);
                    final max = mode == 'deliver'
                        ? item.pendingDeliverQty
                        : item.returnableQty;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Row(
                        children: [
                          _miniItemThumb(item),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              item.productName ?? '#${item.productId}',
                              style: TextStyle(
                                color: SalesOrdersController.textPrimary,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 72.w,
                            child: TextField(
                              controller: entry.value,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: '0/$max',
                                filled: true,
                                fillColor: SalesOrdersController.cardGray,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 8.h,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () {
                final lines = <Map<String, dynamic>>[];
                for (final entry in qtyControllers.entries) {
                  final qty = int.tryParse(entry.value.text.trim()) ?? 0;
                  if (qty > 0) {
                    lines.add({'item_id': entry.key, 'quantity': qty});
                  }
                }
                Get.back();
                if (lines.isEmpty) return;
                if (mode == 'deliver') {
                  controller.partialDeliver(order.id, lines);
                } else if (mode == 'alternative_return') {
                  controller.alternativeReturn(order.id, lines);
                } else {
                  controller.partialReturn(order.id, lines);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SalesOrdersController.textPrimary,
                foregroundColor: SalesOrdersController.cardGray,
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              child: Text('confirm'.tr),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _miniItemThumb(SalesOrderItemModel item) {
    final raw = item.productImage ?? '';
    final url = ShowNetImage.getThumbnailPhoto(raw);
    final has = url.isNotEmpty && raw != 'no image';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: has ? () => _showImageZoom(ShowNetImage.getPhoto(raw)) : null,
        borderRadius: BorderRadius.circular(6.r),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: has
              ? CachedNetworkImage(
                  imageUrl: url,
                  width: 36.w,
                  height: 36.w,
                  fit: BoxFit.cover,
                )
              : _itemPlaceholder(size: 36),
        ),
      ),
    );
  }

  Future<void> _startHandover(SalesOrderDetailModel order) async {
    if (controller.deliveryCompanies.isEmpty) {
      await controller.loadLookups();
    }
    _showHandoverSheet(order.id, order);
  }

  Future<bool> _selectPartnerAddressForHandover(
    SalesOrderDetailModel order,
  ) async {
    final partnerType =
        order.partnerType ?? (order.customerId != null ? 'customer' : null);
    final partnerId = order.partnerId ?? order.customerId;
    if (partnerType == null || partnerId == null) {
      return true;
    }

    final selected = await showPartnerAddressesSheet(
      context: context,
      partnerType: partnerType,
      partnerId: partnerId,
      selectionMode: true,
    );
    if (selected == null) return false;

    return controller.applyPartnerAddressToOrder(
      order,
      PartnerAddressModel.fromJson(selected),
    );
  }

  Future<bool> _prepareManualDeliveryHandover(
      SalesOrderDetailModel order) async {
    var current = controller.detail.value ?? order;
    final requiresFullAddress = controller.isSelectedCompanyTaxi ||
        controller.isSelectedCompanyOffice ||
        controller.isSelectedCompanyDoctorBike;

    await controller.loadShiplyPartners();

    if (controller.needsDeliveryCustomer(current)) {
      final customerResult = await Get.dialog<dynamic>(
        SalesOrderShiplyCustomerDialog(
          orderId: order.id,
          controller: controller,
          initialName: current.customerName,
        ),
        barrierDismissible: false,
      );
      if (customerResult == 'needs_phone') {
        final selection = controller.pendingShiplyPartner;
        if (selection == null) return false;
        final phoneSaved = await Get.dialog<bool>(
          SalesOrderShiplyPhoneDialog(
            orderId: order.id,
            controller: controller,
            selection: selection,
          ),
          barrierDismissible: false,
        );
        if (phoneSaved != true) return false;
      } else if (customerResult != true) {
        return false;
      }
      await controller.loadDetail(order.id);
      current = controller.detail.value ?? current;
    }

    if (controller.needsDeliveryPhone(current)) {
      final selection = controller.shiplyPartnerForPhonePrompt(current);
      if (selection == null) {
        SalesOrderNotice.error('salesOrderShiplyPhoneRequired'.tr);
        return false;
      }
      final phoneSaved = await Get.dialog<bool>(
        SalesOrderShiplyPhoneDialog(
          orderId: order.id,
          controller: controller,
          selection: selection,
        ),
        barrierDismissible: false,
      );
      if (phoneSaved != true) return false;
      await controller.loadDetail(order.id);
      current = controller.detail.value ?? current;
    }

    if (!await _selectPartnerAddressForHandover(current)) return false;
    current = controller.detail.value ?? current;

    if (!requiresFullAddress && controller.isDeliveryHandoverReady(current)) {
      return true;
    }

    if (controller.needsShiplyAddress(current)) {
      if (controller.shiplyCities.isEmpty) {
        await controller.loadLookups();
      }
      controller.preloadShiplyAddressFromOrder(current);
      final parcelPrice = current.subtotal - current.discount;
      final saved = await Get.dialog<bool>(
        SalesOrderShiplyAddressDialog(
          orderId: order.id,
          controller: controller,
          parcelPrice: parcelPrice > 0 ? parcelPrice : current.total,
          showShiplyBranding: false,
        ),
        barrierDismissible: false,
      );
      if (saved != true) return false;
      await controller.loadDetail(order.id);
    }

    return true;
  }

  Future<bool> _prepareShiplyHandover(SalesOrderDetailModel order) async {
    if (controller.shiplyCities.isEmpty) {
      await controller.loadLookups();
    }

    var current = controller.detail.value ?? order;

    await controller.loadShiplyPartners();

    if (controller.needsShiplyCustomerSelection(current)) {
      final customerResult = await Get.dialog<dynamic>(
        SalesOrderShiplyCustomerDialog(
          orderId: order.id,
          controller: controller,
          initialName: current.customerName,
        ),
        barrierDismissible: false,
      );
      if (customerResult == 'needs_phone') {
        final selection = controller.pendingShiplyPartner;
        if (selection == null) return false;
        final phoneSaved = await Get.dialog<bool>(
          SalesOrderShiplyPhoneDialog(
            orderId: order.id,
            controller: controller,
            selection: selection,
          ),
          barrierDismissible: false,
        );
        if (phoneSaved != true) return false;
      } else if (customerResult != true) {
        return false;
      }
      await controller.loadDetail(order.id);
      current = controller.detail.value ?? current;
    }

    if (controller.needsShiplyPhone(current)) {
      final selection = controller.shiplyPartnerForPhonePrompt(current);
      if (selection == null) {
        SalesOrderNotice.error('salesOrderShiplyPhoneRequired'.tr);
        return false;
      }
      final phoneSaved = await Get.dialog<bool>(
        SalesOrderShiplyPhoneDialog(
          orderId: order.id,
          controller: controller,
          selection: selection,
        ),
        barrierDismissible: false,
      );
      if (phoneSaved != true) return false;
      await controller.loadDetail(order.id);
      current = controller.detail.value ?? current;
    }

    if (!await _selectPartnerAddressForHandover(current)) return false;
    current = controller.detail.value ?? current;

    if (controller.isShiplyHandoverReady(current)) {
      return true;
    }

    if (controller.needsShiplyAddress(current)) {
      controller.preloadShiplyAddressFromOrder(current);
      final parcelPrice = current.subtotal - current.discount;
      final saved = await Get.dialog<bool>(
        SalesOrderShiplyAddressDialog(
          orderId: order.id,
          controller: controller,
          parcelPrice: parcelPrice > 0 ? parcelPrice : current.total,
        ),
        barrierDismissible: false,
      );
      if (saved != true) return false;
      await controller.loadDetail(order.id);
    }

    return true;
  }

  void _showHandoverSheet(int orderId, SalesOrderDetailModel order) {
    controller.pickDefaultHandoverCompany(order);
    controller.trackingController.clear();
    controller.carrierContactNameController.clear();
    controller.carrierContactPhoneController.clear();
    controller.carrierOfficeNameController.clear();
    controller.carrierVehicleNumberController.clear();
    Get.bottomSheet(
      Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height * 0.88),
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: SalesOrdersController.surfaceGray,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'salesOrderHandover'.tr,
                  style: TextStyle(
                    color: SalesOrdersController.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                Obx(() => DropdownButtonFormField<int>(
                      initialValue: controller.deliveryCompanies.any((c) =>
                              c.id ==
                              controller.selectedDeliveryCompanyId.value)
                          ? controller.selectedDeliveryCompanyId.value
                          : null,
                      dropdownColor: SalesOrdersController.cardGray,
                      style: TextStyle(
                        color: SalesOrdersController.textPrimary,
                        fontSize: 14.sp,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: SalesOrdersController.cardGray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(
                              color: SalesOrdersController.borderGray),
                        ),
                      ),
                      items: controller.deliveryCompanies
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(controller.deliveryCompanyLabel(c)),
                            ),
                          )
                          .toList(),
                      onChanged: controller.onDeliveryCompanyChanged,
                    )),
                Obx(() {
                  if (controller.isSelectedCompanyShiply) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 10.h),
                          child: SalesOrderShiplySandboxBadge(
                              controller: controller),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            'shiplyHandoverHint'.tr,
                            style: TextStyle(
                              color: SalesOrdersController.textSecondary,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            'المطلوب: اسم ورقم الزبون والمدينة والقرية. الشارع وملاحظات العنوان اختيارية.',
                            style: TextStyle(
                              color: SalesOrdersController.textSecondary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (controller.isSelectedCompanyTaxi) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 10.h),
                        TextField(
                          controller: controller.carrierVehicleNumberController,
                          style: TextStyle(
                            color: SalesOrdersController.textPrimary,
                            fontSize: 14.sp,
                          ),
                          decoration: InputDecoration(
                            labelText: '${'salesOrderTaxiNumber'.tr} *',
                            labelStyle: const TextStyle(
                              color: SalesOrdersController.textSecondary,
                            ),
                            filled: true,
                            fillColor: SalesOrdersController.cardGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        TextField(
                          controller: controller.carrierContactNameController,
                          style: TextStyle(
                            color: SalesOrdersController.textPrimary,
                            fontSize: 14.sp,
                          ),
                          decoration: InputDecoration(
                            labelText: '${'salesOrderTaxiDriver'.tr} *',
                            labelStyle: const TextStyle(
                              color: SalesOrdersController.textSecondary,
                            ),
                            filled: true,
                            fillColor: SalesOrdersController.cardGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        TextField(
                          controller: controller.carrierContactPhoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            color: SalesOrdersController.textPrimary,
                            fontSize: 14.sp,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                '${'salesOrderTaxiPhone'.tr} (${'optional'.tr})',
                            labelStyle: const TextStyle(
                              color: SalesOrdersController.textSecondary,
                            ),
                            filled: true,
                            fillColor: SalesOrdersController.cardGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: Text(
                            'salesOrderCarrierAddressHint'.tr,
                            style: TextStyle(
                              color: SalesOrdersController.textSecondary,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (controller.isSelectedCompanyOffice) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 10.h),
                        TextField(
                          controller: controller.carrierOfficeNameController,
                          style: TextStyle(
                            color: SalesOrdersController.textPrimary,
                            fontSize: 14.sp,
                          ),
                          decoration: InputDecoration(
                            labelText: '${'salesOrderOfficeName'.tr} *',
                            labelStyle: const TextStyle(
                              color: SalesOrdersController.textSecondary,
                            ),
                            filled: true,
                            fillColor: SalesOrdersController.cardGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        TextField(
                          controller: controller.carrierContactNameController,
                          style: TextStyle(
                            color: SalesOrdersController.textPrimary,
                            fontSize: 14.sp,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                '${'salesOrderOfficeDriver'.tr} (${'optional'.tr})',
                            labelStyle: const TextStyle(
                              color: SalesOrdersController.textSecondary,
                            ),
                            filled: true,
                            fillColor: SalesOrdersController.cardGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        TextField(
                          controller: controller.carrierContactPhoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            color: SalesOrdersController.textPrimary,
                            fontSize: 14.sp,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                '${'salesOrderOfficePhone'.tr} (${'optional'.tr})',
                            labelStyle: const TextStyle(
                              color: SalesOrdersController.textSecondary,
                            ),
                            filled: true,
                            fillColor: SalesOrdersController.cardGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        TextField(
                          controller: controller.carrierVehicleNumberController,
                          style: TextStyle(
                            color: SalesOrdersController.textPrimary,
                            fontSize: 14.sp,
                          ),
                          decoration: InputDecoration(
                            labelText: '${'salesOrderOfficeVehicle'.tr} *',
                            labelStyle: const TextStyle(
                              color: SalesOrdersController.textSecondary,
                            ),
                            filled: true,
                            fillColor: SalesOrdersController.cardGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: Text(
                            'salesOrderCarrierAddressHint'.tr,
                            style: TextStyle(
                              color: SalesOrdersController.textSecondary,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (controller.isSelectedCompanyDoctorBike) {
                    return Padding(
                      padding: EdgeInsets.only(top: 10.h),
                      child: Text(
                        'salesOrderCarrierAddressHint'.tr,
                        style: TextStyle(
                          color: SalesOrdersController.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 10.h),
                      TextField(
                        controller: controller.trackingController,
                        style: TextStyle(
                          color: SalesOrdersController.textPrimary,
                          fontSize: 14.sp,
                        ),
                        decoration: InputDecoration(
                          labelText: 'salesOrderTracking'.tr,
                          labelStyle: const TextStyle(
                            color: SalesOrdersController.textSecondary,
                          ),
                          filled: true,
                          fillColor: SalesOrdersController.cardGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: Text(
                          'salesOrderManualHandoverHint'.tr,
                          style: TextStyle(
                            color: SalesOrdersController.textSecondary,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () async {
                    final manualErr = controller.validateManualHandoverFields();
                    if (manualErr != null) {
                      SalesOrderNotice.error(manualErr);
                      return;
                    }

                    final isShiply = controller.isSelectedCompanyShiply;
                    Get.back();

                    final ready = isShiply
                        ? await _prepareShiplyHandover(order)
                        : await _prepareManualDeliveryHandover(order);
                    if (!ready) return;

                    await controller.loadDetail(orderId);
                    controller.handover(orderId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SalesOrdersController.textPrimary,
                    foregroundColor: SalesOrdersController.cardGray,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: Text('confirm'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showSettleSheet(int orderId) {
    AppDependencyRegistry.ensureBoxes();
    final currentOrder = controller.detail.value;
    final carrierBalance = currentOrder?.carrierReceivableBalance ?? 0;
    final customerDebt = currentOrder?.customerDebtBalance ?? 0;
    final settlementBalance =
        carrierBalance > 0 ? carrierBalance : customerDebt;
    controller.settleAmountController.text =
        settlementBalance.toStringAsFixed(2);
    controller.settleBoxIdController.clear();

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return FutureBuilder<List<ShownBoxesModel>>(
            future: GetShownBoxUsecase(
              boxesRepository: Get.find<BoxesImplement>(),
            ).call(screen: 0),
            builder: (context, snapshot) {
              final boxes = (snapshot.data ?? const <ShownBoxesModel>[])
                  .where((box) => box.boxName.contains('صندوق الطلبيات اليومي'))
                  .toList();
              ShownBoxesModel? selectedBox;
              final boxIdText = controller.settleBoxIdController.text.trim();
              if (boxIdText.isNotEmpty) {
                final id = int.tryParse(boxIdText);
                for (final box in boxes) {
                  if (box.boxId == id) {
                    selectedBox = box;
                    break;
                  }
                }
              }

              String boxLabel(ShownBoxesModel box) =>
                  '${box.boxName} (${box.totalBalance.toStringAsFixed(2)} ${box.currency})';

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: SalesOrdersController.surfaceGray,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16.r)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'salesOrderSettle'.tr,
                          style: TextStyle(
                            color: SalesOrdersController.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          carrierBalance > 0
                              ? 'المتبقي في ذمة شركة التوصيل: ${carrierBalance.toStringAsFixed(2)}'
                              : 'المتبقي ديناً على الزبون: ${customerDebt.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: SalesOrdersController.textSecondary,
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        TextField(
                          controller: controller.settleAmountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: SalesOrdersController.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'salesOrderSettleAmount'.tr,
                            filled: true,
                            fillColor: SalesOrdersController.cardGray,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(child: CircularProgressIndicator())
                        else if (boxes.isEmpty)
                          Text(
                            'سيتم الإيداع تلقائياً في صندوق الطلبيات اليومي للجلسة المفتوحة.',
                            style: TextStyle(
                              color: SalesOrdersController.textSecondary,
                              fontSize: 12.sp,
                            ),
                          )
                        else
                          DropdownButtonFormField<ShownBoxesModel>(
                            isExpanded: true,
                            initialValue: selectedBox,
                            decoration: InputDecoration(
                              labelText: 'salesOrderSettleBox'.tr,
                              filled: true,
                              fillColor: SalesOrdersController.cardGray,
                            ),
                            selectedItemBuilder: (context) => boxes
                                .map(
                                  (box) => Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      boxLabel(box),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            SalesOrdersController.textPrimary,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            items: boxes
                                .map(
                                  (box) => DropdownMenuItem(
                                    value: box,
                                    child: Text(
                                      boxLabel(box),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (box) {
                              controller.settleBoxIdController.text =
                                  box?.boxId.toString() ?? '';
                              setSheetState(() {});
                            },
                          ),
                        SizedBox(height: 12.h),
                        ElevatedButton(
                          onPressed: () {
                            final entered = double.tryParse(controller
                                    .settleAmountController.text
                                    .trim()) ??
                                0;
                            if (entered <= 0 || entered > settlementBalance) {
                              SalesOrderNotice.error(
                                'أدخل مبلغاً أكبر من صفر ولا يتجاوز الرصيد المستحق',
                              );
                              return;
                            }
                            Get.back();
                            controller.settle(orderId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SalesOrdersController.textPrimary,
                            foregroundColor: SalesOrdersController.cardGray,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          child: Text('confirm'.tr),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  void _showPostponeSheet(int orderId) {
    final reasonController = TextEditingController();
    var selectedDate = DateTime.now().add(const Duration(days: 1));

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: SalesOrdersController.surfaceGray,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'salesOrderPostpone'.tr,
                  style: TextStyle(
                    color: SalesOrdersController.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                      setSheetState(() {});
                    }
                  },
                  child: Text(
                    '${'salesOrderPostponeUntil'.tr}: ${selectedDate.toString().substring(0, 10)}',
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'note'.tr,
                    filled: true,
                    fillColor: SalesOrdersController.cardGray,
                  ),
                ),
                SizedBox(height: 12.h),
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                    controller.postponeOrder(
                      orderId,
                      selectedDate,
                      reason: reasonController.text.trim().isEmpty
                          ? null
                          : reasonController.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SalesOrdersController.textPrimary,
                    foregroundColor: SalesOrdersController.cardGray,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: Text('confirm'.tr),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _showMarkStuckSheet(int orderId) async {
    final reasonController = TextEditingController();
    var selectedType = 'delivery';
    int? selectedEmployeeId;
    DateTime? followUpAt;
    var employees = <EmployeeEntity>[];

    AppDependencyRegistry.ensureEmployeeSection();
    try {
      employees = await Get.find<EmployeeImplement>().getEmployees();
    } catch (_) {
      // Assignment stays on the current user when the employee list is not
      // available. The backend applies that safe default.
    }

    if (!mounted) return;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: SalesOrdersController.surfaceGray,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'salesOrderMarkStuck'.tr,
                      style: TextStyle(
                        color: SalesOrdersController.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'salesOrderMarkStuckHint'.tr,
                      style: TextStyle(
                        color: SalesOrdersController.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: 'salesOrderStuckType'.tr,
                        filled: true,
                        fillColor: SalesOrdersController.cardGray,
                      ),
                      items: const [
                        'customer',
                        'address',
                        'phone',
                        'delivery',
                        'collection',
                        'stock',
                        'other',
                      ]
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text('salesOrderStuckType_$type'.tr),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) selectedType = value;
                      },
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: '${'salesOrderStuckReason'.tr} *',
                        hintText: 'salesOrderStuckReasonHint'.tr,
                        filled: true,
                        fillColor: SalesOrdersController.cardGray,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    DropdownButtonFormField<int?>(
                      initialValue: selectedEmployeeId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'salesOrderStuckAssignedTo'.tr,
                        filled: true,
                        fillColor: SalesOrdersController.cardGray,
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('salesOrderStuckAssignCurrent'.tr),
                        ),
                        ...employees
                            .where((employee) => employee.userId != null)
                            .map(
                              (employee) => DropdownMenuItem<int?>(
                                value: employee.userId,
                                child: Text(
                                  employee.employeeName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                      ],
                      onChanged: (value) => selectedEmployeeId = value,
                    ),
                    SizedBox(height: 12.h),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              followUpAt ?? now.add(const Duration(days: 1)),
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (date == null || !context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            followUpAt ?? now.add(const Duration(hours: 1)),
                          ),
                        );
                        if (time == null) return;
                        setSheetState(() {
                          followUpAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        followUpAt == null
                            ? 'salesOrderStuckAddFollowUp'.tr
                            : 'salesOrderStuckFollowUpValue'.trParams({
                                'date': _displayDateTime(followUpAt!),
                              }),
                      ),
                    ),
                    if (followUpAt != null)
                      TextButton(
                        onPressed: () => setSheetState(() => followUpAt = null),
                        child: Text('salesOrderStuckRemoveFollowUp'.tr),
                      ),
                    SizedBox(height: 12.h),
                    ElevatedButton(
                      onPressed: () {
                        final reason = reasonController.text.trim();
                        if (reason.isEmpty) {
                          SalesOrderNotice.error(
                            'salesOrderStuckReasonRequired'.tr,
                          );
                          return;
                        }
                        if (followUpAt != null &&
                            !followUpAt!.isAfter(DateTime.now())) {
                          SalesOrderNotice.error(
                            'salesOrderStuckFollowUpFuture'.tr,
                          );
                          return;
                        }
                        Get.back();
                        controller.markStuckOrder(
                          orderId,
                          reason: reason,
                          stuckType: selectedType,
                          assignedTo: selectedEmployeeId,
                          followUpAt: followUpAt,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9333EA),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: Text('confirm'.tr),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  void _showResolveStuckSheet(SalesOrderDetailModel order) {
    final noteController = TextEditingController();
    const allowedStatuses = [
      'ready',
      'with_delivery',
      'review',
      'partial_delivered',
      'partial_return',
      'returned',
      'canceled',
    ];
    var targetStatus = allowedStatuses.contains(order.stuckPreviousStatus)
        ? order.stuckPreviousStatus!
        : 'with_delivery';

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: SalesOrdersController.surfaceGray,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'salesOrderResolveStuck'.tr,
                    style: TextStyle(
                      color: SalesOrdersController.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  if ((order.stuckReason ?? '').trim().isNotEmpty)
                    Text(
                      'salesOrderNextRecordedReason'.trParams({
                        'reason': order.stuckReason!.trim(),
                      }),
                      style: TextStyle(
                        color: SalesOrdersController.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  SizedBox(height: 12.h),
                  DropdownButtonFormField<String>(
                    initialValue: targetStatus,
                    decoration: InputDecoration(
                      labelText: 'salesOrderResolveTargetStatus'.tr,
                      filled: true,
                      fillColor: SalesOrdersController.cardGray,
                    ),
                    items: allowedStatuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(controller.statusLabel(status)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => targetStatus = value);
                      }
                    },
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: '${'salesOrderResolutionNote'.tr} *',
                      hintText: 'salesOrderResolutionNoteHint'.tr,
                      filled: true,
                      fillColor: SalesOrdersController.cardGray,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      final note = noteController.text.trim();
                      if (note.isEmpty) {
                        SalesOrderNotice.error(
                          'salesOrderResolutionNoteRequired'.tr,
                        );
                        return;
                      }
                      Get.back();
                      controller.resolveStuckOrder(
                        order.id,
                        targetStatus: targetStatus,
                        note: note,
                      );
                    },
                    icon: const Icon(Icons.task_alt_outlined),
                    label: Text('salesOrderResolveStuck'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _displayDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}

class _OrderQuickLink {
  const _OrderQuickLink({
    required this.label,
    required this.icon,
    required this.key,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final GlobalKey key;
  final bool enabled;
}

class _SalesOrderNextStep {
  const _SalesOrderNextStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.actionId,
    this.mediaCategory,
    this.actionLabel,
    this.actionIcon = Icons.arrow_forward,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final SalesOrderActionId? actionId;
  final String? mediaCategory;
  final String? actionLabel;
  final IconData actionIcon;
}
