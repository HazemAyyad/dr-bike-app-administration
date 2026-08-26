import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/return_purchases_controller.dart';

class CreatePurchaseReturnScreen extends GetView<ReturnPurchasesController> {
  const CreatePurchaseReturnScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.returnableBills.isEmpty) controller.loadReturnableBills();
    });
    return Scaffold(
      appBar: const CustomAppBar(title: 'إنشاء مرتجع شراء', action: false),
      backgroundColor: Colors.grey.shade50,
      body: GetBuilder<ReturnPurchasesController>(builder: (_) {
        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 110.h),
          children: [
            _SectionCard(
              title: 'فاتورة الشراء',
              icon: Icons.receipt_long_outlined,
              child: DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: controller.selectedBill.value,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'اختر الفاتورة القابلة للإرجاع',
                  border: OutlineInputBorder(),
                ),
                items: controller.returnableBills.map((bill) {
                  return DropdownMenuItem(
                    value: bill,
                    child: Text(
                      '#${asString(bill['id'])} — ${asString(bill['party_name'])} — ${asString(bill['currency'])}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: controller.selectBill,
              ),
            ),
            SizedBox(height: 12.h),
            if (controller.selectedBill.value != null)
              _SectionCard(
                title: 'أصناف الفاتورة',
                icon: Icons.inventory_2_outlined,
                child: controller.availableItems.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child:
                            Center(child: Text('لا توجد كميات متاحة للإرجاع')),
                      )
                    : Column(
                        children: controller.availableItems
                            .map((line) => _ReturnLineTile(line: line))
                            .toList(),
                      ),
              ),
            SizedBox(height: 12.h),
            _SectionCard(
              title: 'سبب المرتجع والملاحظات',
              icon: Icons.notes_outlined,
              child: Column(
                children: [
                  CustomTextField(
                    label: 'سبب المرتجع',
                    hintText: 'تالف، غير مطابق، مقاس خاطئ…',
                    controller: controller.reasonController,
                    isRequired: false,
                    validator: (_) => null,
                  ),
                  SizedBox(height: 10.h),
                  CustomTextField(
                    label: 'notes',
                    hintText: 'ملاحظات إضافية',
                    controller: controller.notesController,
                    isRequired: false,
                    validator: (_) => null,
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: GetBuilder<ReturnPurchasesController>(builder: (_) {
        final total = controller.availableItems
            .fold<double>(0, (sum, line) => sum + line.total);
        final currency =
            asString(controller.selectedBill.value?['currency'], 'شيكل');
        return SafeArea(
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إجمالي المرتجع'),
                    Text('${total.toStringAsFixed(2)} $currency',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17.sp,
                            color: AppColors.primaryColor)),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        if (await controller.saveDraft(context)) {
                          Get.back();
                        }
                      },
                child: const Text('حفظ مسودة'),
              ),
              SizedBox(width: 8.w),
              SizedBox(
                width: 145.w,
                child: AppButton(
                  isLoading: controller.isLoading,
                  isSafeArea: false,
                  height: 44.h,
                  text: 'اعتماد المرتجع',
                  onPressed: () async {
                    if (await controller.saveDraft(context, confirm: true)) {
                      Get.back();
                    }
                  },
                ),
              ),
            ]),
          ),
        );
      }),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: AppColors.primaryColor),
            SizedBox(width: 8.w),
            Text(title,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.sp))
          ]),
          SizedBox(height: 12.h),
          child,
        ]),
      );
}

class _ReturnLineTile extends StatelessWidget {
  const _ReturnLineTile({required this.line});
  final PurchaseReturnDraftLine line;
  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(8.r)),
              child: const Icon(Icons.inventory_2_outlined,
                  color: AppColors.primaryColor)),
          SizedBox(width: 10.w),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(line.productName,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                if (line.variant.isNotEmpty) Text(line.variant),
                Text('المتاح: ${line.available} • السعر: ${line.unitPrice}',
                    style: TextStyle(
                        fontSize: 11.sp, color: Colors.grey.shade700)),
              ])),
          SizedBox(
              width: 70.w,
              child: TextField(
                controller: line.quantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'الكمية', isDense: true),
                onChanged: (_) =>
                    Get.find<ReturnPurchasesController>().update(),
              )),
        ]),
      );
}
