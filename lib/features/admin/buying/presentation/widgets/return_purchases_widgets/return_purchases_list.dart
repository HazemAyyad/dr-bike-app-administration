import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/return_purchases_controller.dart';
import '../../controllers/bills_controller.dart';
import '../../../../../../routes/app_routes.dart';

class ReturnPurchasesList extends StatelessWidget {
  const ReturnPurchasesList({
    Key? key,
    required this.month,
    required this.bills,
  }) : super(key: key);

  final String month;
  final List bills;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(children: [
          _ReturnMonthDivider(month: month, count: bills.length),
          ...bills.map((bill) => _ReturnPurchaseCard(bill: bill)),
        ]),
      ),
    );
  }
}

class PurchaseReturnsTableHeader extends StatelessWidget {
  const PurchaseReturnsTableHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Container(
            height: 42.h,
            color: AppColors.primaryColor.withValues(alpha: 0.09),
            padding: EdgeInsets.symmetric(horizontal: 7.w),
            child: const Row(children: [
              _ReturnHeaderCell('مرتجع', flex: 19),
              _ReturnHeaderCell('الإجمالي', flex: 27),
              _ReturnHeaderCell('القطع', flex: 11),
              _ReturnHeaderCell('الطرف', flex: 31),
              _ReturnHeaderCell('الحالة', flex: 22),
            ]),
          ),
        ),
      );
}

class _ReturnHeaderCell extends StatelessWidget {
  const _ReturnHeaderCell(this.text, {required this.flex});
  final String text;
  final int flex;
  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w800,
                fontSize: 11.sp)),
      );
}

class _ReturnMonthDivider extends StatelessWidget {
  const _ReturnMonthDivider({required this.month, required this.count});
  final String month;
  final int count;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.04),
          border: Border(
            top: BorderSide(color: Colors.grey.shade300),
            bottom: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Text('$month · $count مرتجعات',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w800,
                fontSize: 13.sp)),
      );
}

class _ReturnPurchaseCard extends StatelessWidget {
  const _ReturnPurchaseCard({required this.bill});

  final dynamic bill;

  @override
  Widget build(BuildContext context) {
    final total = double.tryParse(bill.total.toString()) ?? 0;
    return InkWell(
      onTap: () => Get.toNamed(
        AppRoutes.PURCHASERETURNDETAILSSCREEN,
        arguments: bill,
      ),
      onLongPress: () => _showReturnActions(context, bill),
      child: Container(
        constraints: BoxConstraints(minHeight: 78.h),
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 19,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  child: Text(_statusLabel(bill.status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.sp)),
                ),
                SizedBox(height: 3.h),
                Text(bill.number,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        fontSize: 9.sp)),
              ]),
            ),
            Expanded(
              flex: 27,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${NumberFormat('#,##0.##').format(total)} ${bill.currency}',
                    style:
                        TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900),
                  ),
                ),
                if ((double.tryParse(bill.settledAmount) ?? 0) > 0)
                  Text('المسوّى: ${bill.settledAmount}',
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w800)),
              ]),
            ),
            Expanded(
              flex: 11,
              child: Text(
                '${bill.itemsCount > 0 ? bill.itemsCount : bill.items.length}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              flex: 31,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                    bill.seller.name.trim().isEmpty
                        ? 'غير محدد'
                        : bill.seller.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12.sp, fontWeight: FontWeight.w800)),
                SizedBox(height: 2.h),
                Text('فاتورة #${bill.billId}',
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 9.sp,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w800)),
              ]),
            ),
            Expanded(
              flex: 22,
              child: Text(_statusLabel(bill.status),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: _statusColor(bill.status))),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'مسودة';
      case 'confirmed':
      case 'pending':
        return 'قيد التسليم';
      case 'delivered':
        return 'قيد التسوية';
      case 'settled':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغى';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'settled':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      case 'confirmed':
      case 'pending':
        return Colors.orange.shade800;
      case 'delivered':
        return Colors.indigo;
      default:
        return AppColors.primaryColor;
    }
  }

  void _showReturnActions(BuildContext context, dynamic row) {
    final controller = Get.find<ReturnPurchasesController>();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.number,
                    style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 18.sp)),
                Text('${row.seller.name} • فاتورة #${row.billId}'),
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الإجمالي: ${row.total} ${row.currency}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text('المسوّى: ${row.settledAmount} ${row.currency}'),
                      if (row.items.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        ...row.items.map<Widget>((item) => Padding(
                              padding: EdgeInsets.only(bottom: 4.h),
                              child: Row(children: [
                                const Icon(Icons.inventory_2_outlined,
                                    size: 16),
                                SizedBox(width: 6.w),
                                Expanded(child: Text(item.displayName)),
                                Text('${item.quantity} × ${item.price}'),
                              ]),
                            )),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                if (row.status == 'draft')
                  ListTile(
                      leading: const Icon(Icons.verified_outlined,
                          color: Colors.green),
                      title: const Text('اعتماد وإخراج من المخزون'),
                      onTap: () {
                        Get.back();
                        controller.runAction(context, row, 'confirm');
                      }),
                if (row.status == 'confirmed' || row.status == 'pending')
                  ListTile(
                      leading: const Icon(Icons.local_shipping_outlined,
                          color: Colors.indigo),
                      title: const Text('تسجيل التسليم للمورد'),
                      onTap: () {
                        Get.back();
                        controller.runAction(context, row, 'deliver');
                      }),
                if (row.status == 'delivered')
                  ListTile(
                      leading: const Icon(Icons.account_balance_wallet_outlined,
                          color: Colors.orange),
                      title: const Text('تسوية المرتجع'),
                      onTap: () {
                        Get.back();
                        _showSettlementDialog(context, row, controller);
                      }),
                if (row.status == 'draft' || row.status == 'confirmed')
                  ListTile(
                      leading:
                          const Icon(Icons.cancel_outlined, color: Colors.red),
                      title: const Text('إلغاء المرتجع'),
                      onTap: () {
                        Get.back();
                        controller.runAction(context, row, 'cancel',
                            data: const {'reason': 'إلغاء من تطبيق الإدارة'});
                      }),
              ]),
        ),
      ),
    );
  }

  void _showSettlementDialog(BuildContext context, dynamic row,
      ReturnPurchasesController returnsController) {
    final billsController = Get.find<BillsController>();
    billsController.loadPurchaseBoxes();
    final amount = TextEditingController(
      text: ((double.tryParse(row.total) ?? 0) -
              (double.tryParse(row.settledAmount) ?? 0))
          .toStringAsFixed(2),
    );
    final billId = TextEditingController();
    var type = 'cash_refund';
    dynamic box;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: Text('تسوية ${row.number}'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(
                    labelText: 'طريقة التسوية', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                      value: 'cash_refund', child: Text('استرداد نقدي')),
                  DropdownMenuItem(
                      value: 'bill_allocation', child: Text('خصم من فاتورة')),
                ],
                onChanged: (value) => setState(() => type = value!),
              ),
              SizedBox(height: 10.h),
              TextField(
                  controller: amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: 'المبلغ (${row.currency})',
                      border: const OutlineInputBorder())),
              SizedBox(height: 10.h),
              if (type == 'cash_refund')
                Obx(() => DropdownButtonFormField<dynamic>(
                      initialValue: box,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'الصندوق', border: OutlineInputBorder()),
                      items: billsController.purchaseBoxes
                          .map((item) => DropdownMenuItem(
                              value: item,
                              child:
                                  Text('${item.boxName} (${item.currency})')))
                          .toList(),
                      onChanged: (value) => setState(() => box = value),
                    )),
              if (type == 'bill_allocation')
                TextField(
                    controller: billId,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'رقم فاتورة الشراء المفتوحة',
                        border: OutlineInputBorder())),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                final data = <String, dynamic>{
                  'type': type,
                  'amount': amount.text.trim()
                };
                if (type == 'cash_refund') data['box_id'] = box?.boxId;
                if (type == 'bill_allocation') {
                  data['bill_id'] = billId.text.trim();
                }
                Navigator.pop(dialogContext);
                returnsController.runAction(context, row, 'settle', data: data);
              },
              child: const Text('تسجيل التسوية'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      amount.dispose();
      billId.dispose();
    });
  }
}
