import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../../core/helpers/show_net_image.dart';
import '../../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/return_purchases_controller.dart';
import '../../../data/models/return_purchases_models/return_products_model.dart';

class PurchaseReturnDetailsScreen extends StatefulWidget {
  const PurchaseReturnDetailsScreen({Key? key}) : super(key: key);

  @override
  State<PurchaseReturnDetailsScreen> createState() =>
      _PurchaseReturnDetailsScreenState();
}

class _PurchaseReturnDetailsScreenState
    extends State<PurchaseReturnDetailsScreen> {
  final controller = Get.find<ReturnPurchasesController>();
  late final ReturnProduct row;

  @override
  void initState() {
    super.initState();
    row = Get.arguments as ReturnProduct;
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.loadReturnDetails(row.id.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(row.number),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.secondaryColor,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'PDF',
            onPressed: () =>
                controller.downloadPdf(row.id.toString(), row.number),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: GetBuilder<ReturnPurchasesController>(builder: (_) {
        if (controller.detailsLoading.value &&
            controller.returnDetails.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final envelope = controller.returnDetails;
        final details = asMap(envelope['purchase_return']);
        final items = asMapList(details['items']);
        final attachments = asMapList(envelope['attachments']);
        final timeline = asMapList(envelope['timeline']);
        return RefreshIndicator(
          onRefresh: () => controller.loadReturnDetails(row.id.toString()),
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              _CompactHeader(
                number: row.number,
                bill: '#${row.billId}',
                party: row.seller.name,
                status: _statusLabel(row.status),
                total:
                    '${NumberFormat('#,##0.00').format(double.tryParse(row.total) ?? 0)} ${row.currency}',
                reason: asString(details['reason']),
                notes: asString(details['notes'], asString(details['note'])),
              ),
              SizedBox(height: 8.h),
              _ReturnActions(row: row, controller: controller),
              SizedBox(height: 10.h),
              _Title(text: 'الأصناف (${items.length})'),
              _ProductsTable(items: items),
              SizedBox(height: 12.h),
              Row(children: [
                const Expanded(child: _Title(text: 'المرفقات')),
                IconButton(
                  tooltip: 'رفع مرفق',
                  onPressed: controller.isLoading.value
                      ? null
                      : () => _showAttachmentSheet(context),
                  icon: const Icon(Icons.upload_file_outlined,
                      color: AppColors.primaryColor),
                ),
              ]),
              if (attachments.isEmpty)
                const _Empty(text: 'لا توجد مرفقات')
              else
                _DetailsCard(
                    child: Column(
                        children: attachments
                            .map((raw) => _AttachmentTile(data: asMap(raw)))
                            .toList())),
              SizedBox(height: 12.h),
              const _Title(text: 'سجل حركات المرتجع'),
              if (timeline.isEmpty)
                const _Empty(text: 'لا توجد حركات مسجلة')
              else
                ...timeline.map((raw) => _TimelineTile(data: asMap(raw))),
              SizedBox(height: 90.h),
            ],
          ),
        );
      }),
    );
  }

  String _statusLabel(String status) {
    const labels = {
      'draft': 'مسودة',
      'confirmed': 'قيد التسليم',
      'pending': 'قيد التسليم',
      'delivered': 'قيد التسوية',
      'settled': 'مكتمل',
      'cancelled': 'ملغى',
    };
    return labels[status] ?? status;
  }

  Future<void> _showAttachmentSheet(BuildContext context) async {
    var files = <File>[];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setState) => Padding(
          padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w,
              MediaQuery.of(sheetContext).viewInsets.bottom + 18.h),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            MediaUploadButton(
              title: 'إضافة صور المرتجع',
              allowedType: MediaType.image,
              isShowPreview: true,
              initialFiles: files,
              onFilesChanged: (value) => setState(() => files = value),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: files.isEmpty
                    ? null
                    : () async {
                        Navigator.pop(sheetContext);
                        await controller.uploadDetailsFiles(
                            context, row.id.toString(), files);
                      },
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('رفع المرفقات'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ProductsTable extends StatelessWidget {
  const _ProductsTable({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey.shade300)),
        child: Column(children: [
          Container(
            height: 36.h,
            color: AppColors.primaryColor.withValues(alpha: .09),
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: const Row(children: [
              _TableHead('الصنف', flex: 48),
              _TableHead('الكمية', flex: 15),
              _TableHead('السعر', flex: 18),
              _TableHead('الإجمالي', flex: 19),
            ]),
          ),
          ...items.map((item) => Container(
                constraints: BoxConstraints(minHeight: 62.h),
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 5.h),
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200))),
                child: Row(children: [
                  Expanded(
                    flex: 48,
                    child: Row(children: [
                      Container(
                        width: 44.w,
                        height: 44.w,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                            color:
                                AppColors.primaryColor.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(7.r)),
                        child: Image.network(
                          ShowNetImage.getPhoto(
                              asNullableString(item['product_image'])),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.inventory_2_outlined, size: 20),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                              asString(asMap(item['product'])['nameAr'],
                                  asString(item['product_name'])),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 10.sp, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              [
                                asString(asMap(item['size'])['size'],
                                    asString(item['size_label'])),
                                asString(asMap(item['size_color'])['colorAr'],
                                    asString(item['color_label']))
                              ].where((v) => v.isNotEmpty).join(' / '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 8.sp, color: Colors.grey.shade700),
                            ),
                          ])),
                    ]),
                  ),
                  _TableValue(asString(item['quantity']), flex: 15),
                  _TableValue(asString(item['price']), flex: 18),
                  _TableValue(asString(item['line_total']),
                      flex: 19, bold: true),
                ]),
              )),
        ]),
      );
}

class _TableHead extends StatelessWidget {
  const _TableHead(this.text, {required this.flex});
  final String text;
  final int flex;
  @override
  Widget build(BuildContext context) => Expanded(
      flex: flex,
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryColor)));
}

class _TableValue extends StatelessWidget {
  const _TableValue(this.text, {required this.flex, this.bold = false});
  final String text;
  final int flex;
  final bool bold;
  @override
  Widget build(BuildContext context) => Expanded(
      flex: flex,
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 9.sp,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600)));
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.attach_file, color: AppColors.primaryColor),
        title: Text(asString(data['file_name'], 'مرفق')),
        subtitle: Text(asString(data['created_at'])),
        trailing: const Icon(Icons.open_in_new_rounded),
        onTap: () {
          final uri = Uri.tryParse(asString(data['url']));
          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      );
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              margin: EdgeInsets.only(top: 3.h),
              width: 12.w,
              height: 12.w,
              decoration: const BoxDecoration(
                  color: AppColors.primaryColor, shape: BoxShape.circle)),
          SizedBox(width: 10.w),
          Expanded(
              child: _DetailsCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                Text(asString(data['title']),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                if (asString(data['description']).isNotEmpty)
                  Text(asString(data['description'])),
                Text(asString(data['created_at']),
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
              ]))),
        ]),
      );
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade200)),
        child: child,
      );
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.number,
    required this.bill,
    required this.party,
    required this.status,
    required this.total,
    required this.reason,
    required this.notes,
  });
  final String number;
  final String bill;
  final String party;
  final String status;
  final String total;
  final String reason;
  final String notes;

  @override
  Widget build(BuildContext context) => _DetailsCard(
        child: Column(children: [
          Row(children: [
            Expanded(child: _CompactInfo(label: 'المرتجع', value: number)),
            Expanded(child: _CompactInfo(label: 'فاتورة الشراء', value: bill)),
          ]),
          Divider(height: 12.h),
          Row(children: [
            Expanded(child: _CompactInfo(label: 'الطرف', value: party)),
            Expanded(child: _CompactInfo(label: 'الحالة', value: status)),
          ]),
          Divider(height: 12.h),
          Row(children: [
            Expanded(child: _CompactInfo(label: 'الإجمالي', value: total)),
            if (reason.isNotEmpty)
              Expanded(child: _CompactInfo(label: 'السبب', value: reason)),
          ]),
          if (notes.isNotEmpty) ...[
            Divider(height: 12.h),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _CompactInfo(label: 'الملاحظات', value: notes),
            ),
          ],
        ]),
      );
}

class _CompactInfo extends StatelessWidget {
  const _CompactInfo({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade600)),
          SizedBox(height: 2.h),
          Text(value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _ReturnActions extends StatelessWidget {
  const _ReturnActions({required this.row, required this.controller});
  final ReturnProduct row;
  final ReturnPurchasesController controller;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];
    if (row.status == 'draft') {
      actions.add(_action(context, 'اعتماد المرتجع', Icons.verified_outlined,
          Colors.green, 'confirm'));
    }
    if (row.status == 'confirmed' || row.status == 'pending') {
      actions.add(_action(context, 'تسجيل التسليم',
          Icons.local_shipping_outlined, Colors.indigo, 'deliver'));
    }
    if (row.status == 'draft' || row.status == 'confirmed') {
      actions.add(_action(
          context, 'إلغاء المرتجع', Icons.cancel_outlined, Colors.red, 'cancel',
          data: const {'reason': 'إلغاء من تطبيق الإدارة'}));
    }
    if (row.status == 'delivered') {
      actions.add(OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange.shade800,
            visualDensity: VisualDensity.compact),
        onPressed: () => controller.showSettlementDialog(context, row),
        icon: Icon(Icons.account_balance_wallet_outlined, size: 17.sp),
        label: Text('تسوية المرتجع', style: TextStyle(fontSize: 11.sp)),
      ));
    }
    if (actions.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8.w, runSpacing: 8.h, children: actions);
  }

  Widget _action(BuildContext context, String label, IconData icon, Color color,
      String action,
      {Map<String, dynamic> data = const {}}) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: .45)),
          visualDensity: VisualDensity.compact),
      onPressed: controller.isLoading.value
          ? null
          : () async {
              await controller.runAction(context, row, action, data: data);
              await controller.loadReturnDetails(row.id.toString());
            },
      icon: Icon(icon, size: 17.sp),
      label: Text(label, style: TextStyle(fontSize: 11.sp)),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(text,
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)));
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => _DetailsCard(
      child: Center(
          child: Text(text, style: TextStyle(color: Colors.grey.shade600))));
}
