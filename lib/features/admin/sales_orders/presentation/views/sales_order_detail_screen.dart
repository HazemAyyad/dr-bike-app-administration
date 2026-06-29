import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';
import 'package:doctorbike/core/services/app_dependency_registry.dart';
import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../routes/app_routes.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../boxes/data/repositories/boxes_implement.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../data/models/sales_order_model.dart';
import '../controllers/sales_orders_controller.dart';
import '../widgets/sales_order_notice.dart';
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
                    SizedBox(height: 12.h),
                    SalesOrderStatusUi.workflowTimeline(
                      status: order.status,
                      controller: controller,
                    ),
                    if (order.mediaRequirements.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      _mediaRequirementsCard(order),
                    ],
                    SizedBox(height: 12.h),
                    _customerCard(order),
                    if (_hasLogisticsInfo(order)) ...[
                      SizedBox(height: 12.h),
                      _logisticsCard(order),
                    ],
                    SizedBox(height: 12.h),
                    _itemsSection(order),
                    if (order.statusLogs.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      _statusHistoryCard(order),
                    ],
                    if (order.childOrders.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      _childOrdersCard(order),
                    ],
                    if (order.media.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      _mediaCard(order),
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
              SalesOrderStatusUi.statusBadge(order.status, controller),
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

  Widget _statusHistoryCard(SalesOrderDetailModel order) {
    final logs = order.statusLogs.reversed.take(8).toList();
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
            'salesOrderStatusHistory'.tr,
            style: TextStyle(
              color: SalesOrdersController.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 8.h),
          ...logs.map((log) {
            final label = controller.statusLabel(log.toStatus);
            final when = log.createdAt ?? '';
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6.w,
                    height: 6.w,
                    margin: EdgeInsets.only(top: 5.h),
                    decoration: BoxDecoration(
                      color: SalesOrderStatusUi.statusColor(log.toStatus),
                      shape: BoxShape.circle,
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
                            fontWeight: FontWeight.w600,
                            color: SalesOrdersController.textPrimary,
                          ),
                        ),
                        if (log.note != null && log.note!.trim().isNotEmpty)
                          Text(
                            log.note!,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: SalesOrdersController.textSecondary,
                            ),
                          ),
                        if (when.isNotEmpty)
                          Text(
                            when,
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: SalesOrdersController.textSecondary,
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
                  '${order.items.length}',
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
          ...order.items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == order.items.length - 1;
            return _compactItemRow(item, showDivider: !isLast);
          }),
        ],
      ),
    );
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
            return Obx(() {
              final busy = controller.isSubmitting.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: !req.satisfied && !busy
                        ? () => controller.pickAndUploadMedia(
                              order.id,
                              presetCategory: req.category,
                            )
                        : null,
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Row(
                        children: [
                          Icon(
                            req.satisfied
                                ? Icons.check_circle
                                : req.optional
                                    ? Icons.radio_button_unchecked
                                    : Icons.error_outline,
                            color: color,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: SalesOrdersController.textPrimary,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          if (req.optional)
                            Text(
                              'salesOrderMediaOptional'.tr,
                              style: TextStyle(
                                color: SalesOrdersController.textSecondary,
                                fontSize: 10.sp,
                              ),
                            ),
                          if (!req.satisfied) ...[
                            SizedBox(width: 6.w),
                            Icon(
                              Icons.upload_outlined,
                              size: 18.sp,
                              color: busy
                                  ? SalesOrdersController.textSecondary
                                  : color,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            });
          }),
          SizedBox(height: 4.h),
          Obx(
            () => OutlinedButton.icon(
              onPressed: controller.isSubmitting.value
                  ? null
                  : () => controller.pickAndUploadMedia(order.id),
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text('salesOrderUploadMedia'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: SalesOrdersController.textPrimary,
                side: const BorderSide(color: SalesOrdersController.borderGray),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaCard(SalesOrderDetailModel order) {
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
            children: order.media.map((m) {
              if (m.url == null) return const SizedBox.shrink();
              return ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: CachedNetworkImage(
                  imageUrl: m.url!,
                  width: 88.w,
                  height: 88.w,
                  fit: BoxFit.cover,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _bottomActions(SalesOrderDetailModel order) {
    final actions = SalesOrderActions.forStatus(
      order.status,
      isShiplyDelivery: order.isShiplyDelivery,
    );
    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
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
      width: 72.w,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : () => _runAction(order.id, action.id, order),
          borderRadius: BorderRadius.circular(10.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12.r),
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
                    size: 22.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.sp,
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
        controller.markReady(orderId);
        break;
      case SalesOrderActionId.handover:
        _startHandover(order);
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
        controller.cancelOrder(orderId);
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
      case SalesOrderActionId.alternativeReturn:
        _showQtySheet(order, 'alternative_return');
        break;
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(6.r),
      child: has
          ? CachedNetworkImage(
              imageUrl: url, width: 36.w, height: 36.w, fit: BoxFit.cover)
          : _itemPlaceholder(size: 36),
    );
  }

  Future<void> _startHandover(SalesOrderDetailModel order) async {
    if (controller.deliveryCompanies.isEmpty) {
      await controller.loadLookups();
    }
    _showHandoverSheet(order.id, order);
  }

  Future<bool> _prepareManualDeliveryHandover(
      SalesOrderDetailModel order) async {
    var current = controller.detail.value ?? order;
    final requiresFullAddress = controller.isSelectedCompanyTaxi ||
        controller.isSelectedCompanyOffice ||
        controller.isSelectedCompanyDoctorBike;

    if (!requiresFullAddress && controller.isDeliveryHandoverReady(current)) {
      return true;
    }

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

    if (controller.isShiplyHandoverReady(current)) {
      return true;
    }

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
                      ],
                    );
                  }

                  if (controller.isSelectedCompanyTaxi) {
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
                            labelText: 'salesOrderTaxiNumber'.tr,
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
                            labelText: 'salesOrderTaxiDriver'.tr,
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
                            labelText: 'salesOrderTaxiPhone'.tr,
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
                            labelText: 'salesOrderOfficeName'.tr,
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
                            labelText: 'salesOrderOfficeDriver'.tr,
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
                            labelText: 'salesOrderOfficePhone'.tr,
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
                            labelText: 'salesOrderOfficeVehicle'.tr,
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
    controller.settleAmountController.text =
        controller.detail.value?.total.toStringAsFixed(2) ?? '';
    controller.settleBoxIdController.clear();

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return FutureBuilder<List<ShownBoxesModel>>(
            future: GetShownBoxUsecase(
              boxesRepository: Get.find<BoxesImplement>(),
            ).call(screen: 0),
            builder: (context, snapshot) {
              final boxes = snapshot.data ?? const <ShownBoxesModel>[];
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
                            'salesOrderSettleBoxHint'.tr,
                            style: TextStyle(
                              color: SalesOrdersController.textSecondary,
                              fontSize: 12.sp,
                            ),
                          )
                        else
                          DropdownButtonFormField<ShownBoxesModel>(
                            isExpanded: true,
                            value: selectedBox,
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

  void _showMarkStuckSheet(int orderId) {
    final reasonController = TextEditingController();

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
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'salesOrderStuckReason'.tr,
                filled: true,
                fillColor: SalesOrdersController.cardGray,
              ),
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () {
                Get.back();
                controller.markStuckOrder(
                  orderId,
                  reason: reasonController.text.trim().isEmpty
                      ? null
                      : reasonController.text.trim(),
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
      isScrollControlled: true,
    );
  }
}
