import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:io';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../../core/helpers/custom_upload_button.dart';
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
      appBar: AppBar(
        title: const Text('إنشاء مرتجع شراء'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.secondaryColor,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
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
          ],
        );
      }),
      bottomNavigationBar: GetBuilder<ReturnPurchasesController>(builder: (_) {
        final total = controller.availableItems
            .fold<double>(0, (sum, line) => sum + line.total);
        final currency =
            asString(controller.selectedBill.value?['currency'], 'شيكل');
        final count =
            controller.availableItems.where((line) => line.quantity > 0).length;
        return SafeArea(
          child: Container(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: .08),
                  blurRadius: 12,
                  offset: const Offset(0, -4)),
            ]),
            child: Row(children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12.r)),
                child: Icon(Icons.assignment_return_outlined,
                    color: AppColors.primaryColor, size: 28.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المرتجع ($count)',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13.sp)),
                      Text('${total.toStringAsFixed(2)} $currency',
                          style: TextStyle(
                              fontSize: 12.sp, color: Colors.grey.shade600)),
                    ]),
              ),
              SizedBox(width: 12.w),
              SizedBox(
                height: 46.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  onPressed: count == 0 || controller.isLoading.value
                      ? null
                      : () => _showCheckoutSheet(context),
                  child: Text('متابعة',
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        );
      }),
    );
  }

  Future<void> _showCheckoutSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (sheetContext) => GetBuilder<ReturnPurchasesController>(
        builder: (_) {
          final total = controller.availableItems
              .fold<double>(0, (sum, line) => sum + line.total);
          final currency =
              asString(controller.selectedBill.value?['currency'], 'شيكل');
          return ListView(
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w,
                MediaQuery.of(sheetContext).viewInsets.bottom + 18.h),
            children: [
              Row(children: [
                Expanded(
                    child: Text('اعتماد مرتجع الشراء',
                        style: TextStyle(
                            fontSize: 18.sp, fontWeight: FontWeight.w800))),
                IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded)),
              ]),
              SizedBox(height: 12.h),
              CustomTextField(
                label: 'سبب المرتجع',
                hintText: 'تالف، غير مطابق، مقاس خاطئ…',
                controller: controller.reasonController,
                isRequired: false,
                validator: (_) => null,
                minLines: 3,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
              SizedBox(height: 10.h),
              CustomTextField(
                label: 'notes',
                hintText: 'ملاحظات إضافية',
                controller: controller.notesController,
                isRequired: false,
                validator: (_) => null,
                minLines: 4,
                maxLines: 7,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
              SizedBox(height: 12.h),
              MediaUploadButton(
                title: 'إضافة صور المرتجع',
                allowedType: MediaType.image,
                isShowPreview: true,
                initialFiles: controller.pendingAttachments
                    .where((file) => file.path != null)
                    .map((file) => File(file.path!))
                    .toList(),
                onFilesChanged: controller.setPendingAttachmentFiles,
              ),
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(12.r)),
                child: Row(children: [
                  const Expanded(
                      child: Text('إجمالي المرتجع',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  Text('${total.toStringAsFixed(2)} $currency',
                      style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 17.sp)),
                ]),
              ),
              SizedBox(height: 14.h),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        minimumSize: Size.fromHeight(50.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r))),
                    onPressed: controller.isLoading.value
                        ? null
                        : () async => controller.saveDraft(sheetContext),
                    child: const Text('حفظ مسودة'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: AppButton(
                    isLoading: controller.isLoading,
                    isSafeArea: false,
                    height: 50.h,
                    text: 'اعتماد المرتجع',
                    onPressed: () async =>
                        controller.saveDraft(sheetContext, confirm: true),
                  ),
                ),
              ]),
            ],
          );
        },
      ),
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
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 4.h),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
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
              clipBehavior: Clip.antiAlias,
              child: line.productImage.trim().isEmpty
                  ? const Icon(Icons.inventory_2_outlined,
                      color: AppColors.primaryColor)
                  : Image.network(line.productImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primaryColor))),
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
