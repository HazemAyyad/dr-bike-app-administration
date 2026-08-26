import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/return_purchases_controller.dart';
import '../../controllers/bills_controller.dart';

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
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10.h),
          Text(
            month,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                ),
          ),
          SizedBox(height: 8.h),
          ...bills.map((bill) => _ReturnPurchaseCard(bill: bill)),
        ],
      ),
    );
  }
}

class _ReturnPurchaseCard extends StatelessWidget {
  const _ReturnPurchaseCard({required this.bill});

  final dynamic bill;

  @override
  Widget build(BuildContext context) {
    final firstItem = bill.items.isEmpty ? null : bill.items.first;
    final total = double.tryParse(bill.total.toString()) ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: () {
        _showReturnActions(context, bill);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : AppColors.whiteColor2,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(32),
              blurRadius: 5.r,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
                child: Row(
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Icon(
                        Icons.assignment_return_outlined,
                        color: AppColors.primaryColor,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            label: bill.number,
                            value: bill.createdAt?.toString() ?? '',
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${'sellerName1'.tr}: ${bill.seller.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall!.copyWith(
                                      fontSize: 11.sp,
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          Text('فاتورة الشراء #${bill.billId}',
                              style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey.shade700)),
                          SizedBox(height: 5.h),
                          Wrap(
                            spacing: 5.w,
                            runSpacing: 5.h,
                            children: [
                              if (firstItem != null)
                                _MiniChip(
                                  icon: Icons.inventory_2_outlined,
                                  text: firstItem.displayName,
                                ),
                              if (firstItem != null)
                                _MiniChip(
                                  icon: Icons.numbers_outlined,
                                  text:
                                      '${'quantity'.tr}: ${firstItem.quantity}',
                                ),
                              _MiniChip(
                                icon: Icons.list_alt_outlined,
                                text:
                                    '${bill.itemsCount > 0 ? bill.itemsCount : bill.items.length} أصناف',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(minWidth: 72.w, maxWidth: 110.w),
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.customGreen1,
                borderRadius: Get.locale!.languageCode == 'en'
                    ? const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'total'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                  ),
                  SizedBox(height: 4.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${NumberFormat('#,##0.00').format(total)} ${bill.currency}',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor5,
                ),
          ),
        ),
        if (value.isNotEmpty) ...[
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.customGreyColor5,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: AppColors.primaryColor),
          SizedBox(width: 4.w),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.sp,
                ),
          ),
        ],
      ),
    );
  }
}
