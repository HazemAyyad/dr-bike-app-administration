import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/helpers/json_safe_parser.dart';
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
              _DetailsCard(
                  child: Column(children: [
                _InfoLine(label: 'رقم المرتجع', value: row.number),
                _InfoLine(label: 'فاتورة الشراء', value: '#${row.billId}'),
                _InfoLine(label: 'الطرف', value: row.seller.name),
                _InfoLine(label: 'الحالة', value: _statusLabel(row.status)),
                _InfoLine(
                    label: 'الإجمالي',
                    value:
                        '${NumberFormat('#,##0.00').format(double.tryParse(row.total) ?? 0)} ${row.currency}'),
                if (asString(details['reason']).isNotEmpty)
                  _InfoLine(
                      label: 'سبب المرتجع', value: asString(details['reason'])),
                if (asString(details['notes'], asString(details['note']))
                    .isNotEmpty)
                  _InfoLine(
                      label: 'الملاحظات',
                      value: asString(
                          details['notes'], asString(details['note']))),
              ])),
              SizedBox(height: 12.h),
              _Title(text: 'الأصناف (${items.length})'),
              ...items.map((raw) => _ItemCard(item: asMap(raw))),
              SizedBox(height: 12.h),
              Row(children: [
                const Expanded(child: _Title(text: 'المرفقات')),
                IconButton(
                  tooltip: 'رفع مرفق',
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.addDetailsAttachments(
                          context, row.id.toString()),
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
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});
  final Map<String, dynamic> item;
  @override
  Widget build(BuildContext context) => _DetailsCard(
        margin: EdgeInsets.only(bottom: 8.h),
        child: Row(children: [
          Container(
            width: 58.w,
            height: 58.w,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(10.r)),
            child: asString(item['product_image']).isEmpty
                ? const Icon(Icons.inventory_2_outlined)
                : Image.network(asString(item['product_image']),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.inventory_2_outlined)),
          ),
          SizedBox(width: 10.w),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    asString(asMap(item['product'])['nameAr'],
                        asString(item['product_name'])),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text([
                  asString(asMap(item['size'])['size'],
                      asString(item['size_label'])),
                  asString(asMap(item['size_color'])['colorAr'],
                      asString(item['color_label']))
                ].where((v) => v.isNotEmpty).join(' / ')),
                Text(
                    '${asString(item['quantity'])} × ${asString(item['price'])}'),
              ])),
          Text(asString(item['line_total']),
              style: const TextStyle(fontWeight: FontWeight.w900)),
        ]),
      );
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
  const _DetailsCard({required this.child, this.margin});
  final Widget child;
  final EdgeInsetsGeometry? margin;
  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade200)),
        child: child,
      );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 5.h),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 110.w,
              child:
                  Text(label, style: TextStyle(color: Colors.grey.shade700))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );
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
