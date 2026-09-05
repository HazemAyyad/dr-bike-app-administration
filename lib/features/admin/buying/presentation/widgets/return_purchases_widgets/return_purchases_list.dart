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
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: .18)),
          ),
          child: Row(children: [
            Icon(Icons.swipe_right_alt_rounded,
                color: AppColors.primaryColor, size: 23.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'اسحب بطاقة المرتجع من اليسار إلى اليمين لإظهار الخيارات',
                style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ),
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
    final itemsCount =
        bill.itemsCount > 0 ? bill.itemsCount : bill.items.length;
    final sourceLabel = bill.billId.toString().trim().isEmpty
        ? 'مرتجع مباشر'
        : 'من فاتورة شراء #${bill.billId}';
    final date = DateFormat('yyyy/MM/dd').format(bill.createdAt);
    return _SwipeReturnCard(
      onOptions: () => _showReturnActions(context, bill),
      child: Material(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor4
            : Colors.white,
        child: InkWell(
          onTap: () => Get.toNamed(
            AppRoutes.PURCHASERETURNDETAILSSCREEN,
            arguments: bill,
          ),
          child: Container(
            constraints: BoxConstraints(minHeight: 112.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.number,
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text('$date  •  $sourceLabel',
                          style: TextStyle(
                              fontSize: 10.5.sp, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: _statusColor(bill.status).withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(_statusLabel(bill.status),
                      style: TextStyle(
                          color: _statusColor(bill.status),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900)),
                ),
              ]),
              SizedBox(height: 10.h),
              Row(children: [
                CircleAvatar(
                  radius: 17.r,
                  backgroundColor:
                      AppColors.primaryColor.withValues(alpha: .08),
                  child: const Icon(Icons.storefront_outlined,
                      color: AppColors.primaryColor, size: 18),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.seller.name.trim().isEmpty
                            ? 'مورد غير محدد'
                            : bill.seller.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13.sp, fontWeight: FontWeight.w800),
                      ),
                      Text('$itemsCount أصناف',
                          style: TextStyle(
                              fontSize: 10.5.sp, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                      '${NumberFormat('#,##0.##').format(total)} ${bill.currency}',
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w900)),
                  if ((double.tryParse(bill.settledAmount) ?? 0) > 0)
                    Text('تمت تسوية ${bill.settledAmount} ${bill.currency}',
                        style: TextStyle(
                            fontSize: 9.5.sp,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w700)),
                ]),
              ]),
            ]),
          ),
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
                Text(row.billId.toString().trim().isEmpty
                    ? '${row.seller.name} • مرتجع مباشر'
                    : '${row.seller.name} • فاتورة #${row.billId}'),
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
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'طريقة التسوية', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                      value: 'cash_refund',
                      child: Text('استلمنا المبلغ نقدًا')),
                  DropdownMenuItem(
                      value: 'bill_allocation',
                      child: Text('خصم من فاتورة شراء مفتوحة')),
                  DropdownMenuItem(
                      value: 'debt_credit',
                      child: Text('إبقاؤه رصيدًا لنا على المورد')),
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
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Text(
                  type == 'cash_refund'
                      ? 'اختر الصندوق الذي دخل إليه المبلغ المسترد من المورد.'
                      : type == 'bill_allocation'
                          ? 'ستنخفض مديونية فاتورة شراء مفتوحة بنفس قيمة التسوية.'
                          : 'سيُغلق المرتجع وتبقى قيمته رصيدًا لنا على المورد في دفتر الديون، بدون حركة صندوق.',
                  style:
                      TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
                ),
              ),
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

class _SwipeReturnCard extends StatefulWidget {
  const _SwipeReturnCard({required this.child, required this.onOptions});

  final Widget child;
  final VoidCallback onOptions;

  @override
  State<_SwipeReturnCard> createState() => _SwipeReturnCardState();
}

class _SwipeReturnCardState extends State<_SwipeReturnCard> {
  double offset = 0;
  static const double revealWidth = 76;

  void _update(DragUpdateDetails details) {
    setState(() => offset = (offset + details.delta.dx).clamp(0, revealWidth));
  }

  void _finish(DragEndDetails details) {
    final shouldOpen =
        offset > revealWidth * .34 || (details.primaryVelocity ?? 0) > 350;
    setState(() => offset = shouldOpen ? revealWidth : 0);
  }

  @override
  Widget build(BuildContext context) => ClipRect(
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              left: 5.w,
              child: Material(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(11.r),
                child: InkWell(
                  onTap: () {
                    setState(() => offset = 0);
                    widget.onOptions();
                  },
                  borderRadius: BorderRadius.circular(11.r),
                  child: SizedBox(
                    width: 66.w,
                    height: 66.h,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.more_horiz_rounded,
                            color: Colors.white, size: 21.sp),
                        SizedBox(height: 3.h),
                        Text('الخيارات',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(offset, 0, 0),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: _update,
                onHorizontalDragEnd: _finish,
                child: widget.child,
              ),
            ),
          ],
        ),
      );
}
