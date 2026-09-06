import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:io';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/helpers/product_priority_image.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../checks/data/models/check_model.dart';
import '../../../../widgets/unified_partner_selector.dart';
import '../../controllers/return_purchases_controller.dart';
import '../../controllers/bills_controller.dart';
import 'purchase_return_product_picker_screen.dart';

class CreatePurchaseReturnScreen extends StatefulWidget {
  const CreatePurchaseReturnScreen({Key? key}) : super(key: key);

  @override
  State<CreatePurchaseReturnScreen> createState() =>
      _CreatePurchaseReturnScreenState();
}

class _CreatePurchaseReturnScreenState
    extends State<CreatePurchaseReturnScreen> {
  ReturnPurchasesController get controller =>
      Get.find<ReturnPurchasesController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadReturnableBills(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
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
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false,
                    icon: Icon(Icons.receipt_long),
                    label: Text('من فاتورة')),
                ButtonSegment(
                    value: true,
                    icon: Icon(Icons.add_box_outlined),
                    label: Text('مرتجع مباشر')),
              ],
              selected: {controller.isDirectReturn.value},
              onSelectionChanged: (value) =>
                  controller.setDirectMode(value.first),
            ),
            SizedBox(height: 10.h),
            _ReturnModeHint(isDirect: controller.isDirectReturn.value),
            SizedBox(height: 14.h),
            if (controller.isDirectReturn.value) ...[
              _DirectSourceCard(controller: controller),
              SizedBox(height: 12.h),
              _SectionCard(
                title: 'المنتجات المختارة',
                icon: Icons.inventory_2_outlined,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Get.to(
                              () => const PurchaseReturnProductPickerScreen());
                          controller.update();
                        },
                        icon: const Icon(Icons.grid_view_rounded),
                        label: Text(controller.selectedDirectItems.isEmpty
                            ? 'اختيار المنتجات'
                            : 'تعديل المنتجات المختارة (${controller.selectedDirectItems.length})'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.fromHeight(50.h),
                          foregroundColor: AppColors.primaryColor,
                          side: const BorderSide(color: AppColors.primaryColor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    if (controller.selectedDirectItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('لم يتم اختيار منتجات للراجع'),
                      )
                    else
                      _ReturnProductsCheckoutTable(
                        lines: controller.selectedDirectItems,
                        allowRemove: true,
                      ),
                  ],
                ),
              ),
            ] else ...[
              _SectionCard(
                title: 'فاتورة الشراء',
                icon: Icons.receipt_long_outlined,
                child: _SelectedInvoiceCard(
                  bill: controller.selectedBill.value,
                  enabled: !controller.returnableBillsLoading.value,
                  onTap: () => _showInvoicePicker(context),
                ),
              ),
              if (controller.returnableBillsLoading.value)
                Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: const LinearProgressIndicator(),
                ),
              if (controller.returnableBillsError.value.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'تعذر تحميل الفواتير القابلة للإرجاع',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            controller.loadReturnableBills(force: true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
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
                          child: Center(
                              child: Text('لا توجد كميات متاحة للإرجاع')),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              margin: EdgeInsets.only(bottom: 9.h),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor
                                    .withValues(alpha: .06),
                                borderRadius: BorderRadius.circular(9.r),
                              ),
                              child: Text(
                                'اكتب كمية الراجع أمام الأصناف المطلوبة فقط، واترك باقي الأصناف على صفر.',
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _ReturnProductsCheckoutTable(
                              lines: controller.availableItems,
                              allowRemove: false,
                            ),
                          ],
                        ),
                ),
            ],
          ],
        );
      }),
      bottomNavigationBar: GetBuilder<ReturnPurchasesController>(builder: (_) {
        final lines = controller.isDirectReturn.value
            ? controller.directItems
            : controller.availableItems;
        final total = lines.fold<double>(0, (sum, line) => sum + line.total);
        final currency = controller.isDirectReturn.value
            ? controller.directCurrency.value
            : asString(controller.selectedBill.value?['currency'], 'شيكل');
        final count = lines.where((line) => line.quantity > 0).length;
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
          final lines = controller.isDirectReturn.value
              ? controller.directItems
              : controller.availableItems;
          final total = lines.fold<double>(0, (sum, line) => sum + line.total);
          final currency = controller.isDirectReturn.value
              ? controller.directCurrency.value
              : asString(controller.selectedBill.value?['currency'], 'شيكل');
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
                title: 'إضافة صور أو فيديو للمرتجع',
                allowedType: MediaType.both,
                customCameraCapture: controller.captureReturnMedia,
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

  Future<void> _showInvoicePicker(BuildContext context) async {
    if (controller.returnableBills.isEmpty &&
        !controller.returnableBillsLoading.value) {
      await controller.loadReturnableBills(force: true);
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (sheetContext) => _PurchaseInvoicePickerSheet(
        bills: controller.returnableBills,
        selectedId: asString(controller.selectedBill.value?['id']),
        onSelected: (bill) async {
          Navigator.of(sheetContext).pop();
          await controller.selectBill(bill);
        },
      ),
    );
  }
}

class _ReturnModeHint extends StatelessWidget {
  const _ReturnModeHint({required this.isDirect});

  final bool isDirect;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(11.w),
        decoration: BoxDecoration(
          color: (isDirect ? Colors.orange : AppColors.primaryColor)
              .withValues(alpha: .07),
          borderRadius: BorderRadius.circular(11.r),
          border: Border.all(
            color: (isDirect ? Colors.orange : AppColors.primaryColor)
                .withValues(alpha: .22),
          ),
        ),
        child: Row(children: [
          Icon(
            isDirect ? Icons.info_outline_rounded : Icons.link_rounded,
            color: isDirect ? Colors.orange.shade800 : AppColors.primaryColor,
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              isDirect
                  ? 'استخدم المرتجع المباشر فقط عندما لا تكون فاتورة الشراء مسجلة في النظام.'
                  : 'اختر فاتورة الشراء أولاً، وسنعرض فقط الأصناف والكميات المتاحة للإرجاع منها.',
              style: TextStyle(fontSize: 12.sp, height: 1.45),
            ),
          ),
        ]),
      );
}

class _SelectedInvoiceCard extends StatelessWidget {
  const _SelectedInvoiceCard({
    required this.bill,
    required this.enabled,
    required this.onTap,
  });

  final Map<String, dynamic>? bill;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = bill != null;
    return Material(
      color: selected
          ? AppColors.primaryColor.withValues(alpha: .05)
          : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(13.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected
                  ? AppColors.primaryColor.withValues(alpha: .45)
                  : Colors.grey.shade300,
            ),
          ),
          child: selected
              ? _InvoiceIdentity(bill: bill!, showSelectionMark: true)
              : Row(children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: const Icon(Icons.receipt_long_outlined,
                        color: AppColors.primaryColor),
                  ),
                  SizedBox(width: 11.w),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('اختيار فاتورة الشراء',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        Text('ابحث بالرقم أو المورد ثم راجع تفاصيل الفاتورة'),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left_rounded),
                ]),
        ),
      ),
    );
  }
}

class _PurchaseInvoicePickerSheet extends StatefulWidget {
  const _PurchaseInvoicePickerSheet({
    required this.bills,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Map<String, dynamic>> bills;
  final String selectedId;
  final ValueChanged<Map<String, dynamic>> onSelected;

  @override
  State<_PurchaseInvoicePickerSheet> createState() =>
      _PurchaseInvoicePickerSheetState();
}

class _PurchaseInvoicePickerSheetState
    extends State<_PurchaseInvoicePickerSheet> {
  final searchController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final results = widget.bills.where((bill) {
      if (normalized.isEmpty) return true;
      return asString(bill['id']).toLowerCase().contains(normalized) ||
          asString(bill['party_name']).toLowerCase().contains(normalized) ||
          asString(bill['final_total']).toLowerCase().contains(normalized);
    }).toList(growable: false);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            child: Row(children: [
              Expanded(
                child: Text('اختر فاتورة الشراء',
                    style: TextStyle(
                        fontSize: 18.sp, fontWeight: FontWeight.w900)),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ]),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: SearchBar(
              controller: searchController,
              leading: const Icon(Icons.search_rounded),
              hintText: 'ابحث برقم الفاتورة أو اسم المورد أو المبلغ',
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Colors.grey.shade100),
              onChanged: (value) => setState(() => query = value),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('${results.length} فاتورة قابلة للإرجاع',
                  style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const Center(child: Text('لا توجد فواتير مطابقة'))
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 20.h),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final bill = results[index];
                      final selected =
                          asString(bill['id']) == widget.selectedId;
                      return Material(
                        color: selected
                            ? AppColors.primaryColor.withValues(alpha: .07)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        child: InkWell(
                          onTap: () => widget.onSelected(bill),
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.all(13.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primaryColor
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: _InvoiceIdentity(
                              bill: bill,
                              showSelectionMark: selected,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

class _InvoiceIdentity extends StatelessWidget {
  const _InvoiceIdentity({
    required this.bill,
    required this.showSelectionMark,
  });

  final Map<String, dynamic> bill;
  final bool showSelectionMark;

  @override
  Widget build(BuildContext context) {
    final rawDate = asString(bill['created_at']);
    final date = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
    final currency = asString(bill['currency'], 'شيكل');
    return Row(children: [
      Container(
        width: 45.w,
        height: 45.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text('#${asString(bill['id'])}',
            style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 11.sp,
                fontWeight: FontWeight.w900)),
      ),
      SizedBox(width: 11.w),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(asString(bill['party_name'], 'غير محدد'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 3.h),
          Text(
            '$date  •  ${asString(bill['final_total'], '0')} $currency',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
          ),
          Text(
            '${asString(bill['available_items_count'], '0')} أصناف متاحة للإرجاع',
            style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w700),
          ),
        ]),
      ),
      Icon(
        showSelectionMark
            ? Icons.check_circle_rounded
            : Icons.chevron_left_rounded,
        color: showSelectionMark ? Colors.green : Colors.grey.shade500,
      ),
    ]);
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

class _DirectSourceCard extends StatelessWidget {
  const _DirectSourceCard({required this.controller});
  final ReturnPurchasesController controller;

  @override
  Widget build(BuildContext context) {
    final bills = Get.find<BillsController>();
    return _SectionCard(
      title: 'الزبون أو المورد',
      icon: Icons.people_alt_outlined,
      child: Column(children: [
        UnifiedPartnerSelector<SellerModel>(
          customers: bills.allCustomersList,
          sellers: bills.allSellersList,
          selected: controller.selectedDirectPartner.value,
          selectedIsSeller: controller.directPartnerIsSeller.value,
          idOf: (item) => item.id,
          nameOf: (item) => item.name,
          phoneOf: (item) => item.phone,
          onSelected: (item, isSeller) =>
              controller.selectDirectPartner(item, isSeller: isSeller),
          onCleared: () => controller.selectDirectPartner(null),
          onAddRequested: (isSeller) async {
            final added = await bills.addPurchasePartner(isSeller);
            if (added != null) {
              controller.selectDirectPartner(added, isSeller: isSeller);
            }
          },
          showTitle: false,
          hintText: 'ابحث بالاسم أو رقم الهاتف',
        ),
        SizedBox(height: 6.h),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'يمكنك اختيار المنتجات أولاً، وحدد الجهة قبل حفظ المرتجع.',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
          ),
        ),
      ]),
    );
  }
}

class _ReturnProductsCheckoutTable extends StatelessWidget {
  const _ReturnProductsCheckoutTable({
    required this.lines,
    required this.allowRemove,
  });

  final List<PurchaseReturnDraftLine> lines;
  final bool allowRemove;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: (allowRemove ? 525 : 475).w,
            child: Column(children: [
              Container(
                color: AppColors.primaryColor.withValues(alpha: .08),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
                child: Row(children: [
                  _ReturnTableHeader('الصنف', width: 200.w),
                  _ReturnTableHeader('كمية الراجع', width: 88.w),
                  _ReturnTableHeader('السعر', width: 86.w),
                  _ReturnTableHeader('الإجمالي', width: 85.w),
                  if (allowRemove) SizedBox(width: 42.w),
                ]),
              ),
              ...lines.map(
                (line) => _ReturnCheckoutTableRow(
                  line: line,
                  allowRemove: allowRemove,
                ),
              ),
            ]),
          ),
        ),
      );
}

class _ReturnTableHeader extends StatelessWidget {
  const _ReturnTableHeader(this.label, {required this.width});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _ReturnCheckoutTableRow extends StatelessWidget {
  const _ReturnCheckoutTableRow({
    required this.line,
    required this.allowRemove,
  });

  final PurchaseReturnDraftLine line;
  final bool allowRemove;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReturnPurchasesController>();
    final imageUrls = line.allImageUrlsInPriority;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(children: [
        SizedBox(
          width: 200.w,
          child: Row(children: [
            InkWell(
              onTap: imageUrls.isEmpty
                  ? null
                  : () => FullScreenZoomImage.open(
                        context,
                        imageUrls.first,
                        title: line.productName,
                      ),
              borderRadius: BorderRadius.circular(8.r),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: SizedBox(
                  width: 42.w,
                  height: 42.w,
                  child: imageUrls.isEmpty
                      ? const _ReturnImagePlaceholder()
                      : ProductPriorityImage(
                          imageUrls: imageUrls,
                          fit: BoxFit.cover,
                          placeholder: const _ReturnImagePlaceholder(),
                          missingPlaceholder: const _ReturnImagePlaceholder(),
                        ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10.5.sp, fontWeight: FontWeight.w800),
                  ),
                  if (line.variant.isNotEmpty)
                    Text(
                      line.variant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 9.5.sp,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w700),
                    ),
                  Text(
                    'المتاح ${_returnQuantity(line.available)}',
                    style:
                        TextStyle(fontSize: 9.sp, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ]),
        ),
        _ReturnTableInput(
          width: 88.w,
          controller: line.quantityController,
          maxValue: line.available,
          onChanged: (_) => controller.update(),
        ),
        SizedBox(
          width: 86.w,
          child: line.isDirect
              ? _ReturnTableInput(
                  width: 78.w,
                  controller: line.priceController,
                  onChanged: (_) => controller.update(),
                )
              : Text(
                  line.unitPrice.toStringAsFixed(2),
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
                ),
        ),
        SizedBox(
          width: 85.w,
          child: AnimatedBuilder(
            animation: Listenable.merge(
                [line.quantityController, line.priceController]),
            builder: (_, __) => Text(
              line.total.toStringAsFixed(2),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        if (allowRemove)
          SizedBox(
            width: 42.w,
            child: IconButton(
              tooltip: 'إزالة من الراجع',
              onPressed: () {
                controller.changeDirectQuantity(line, 0);
                controller.update();
              },
              icon: Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 20.sp),
            ),
          ),
      ]),
    );
  }
}

class _ReturnTableInput extends StatelessWidget {
  const _ReturnTableInput({
    required this.width,
    required this.controller,
    required this.onChanged,
    this.maxValue,
  });

  final double width;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final double? maxValue;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 7.w, vertical: 9.h),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            onChanged: (value) {
              final parsed = double.tryParse(value);
              if (maxValue != null && parsed != null && parsed > maxValue!) {
                final clamped = _returnQuantity(maxValue!);
                controller.value = TextEditingValue(
                  text: clamped,
                  selection: TextSelection.collapsed(offset: clamped.length),
                );
                onChanged(clamped);
                return;
              }
              onChanged(value);
            },
          ),
        ),
      );
}

class _ReturnImagePlaceholder extends StatelessWidget {
  const _ReturnImagePlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.grey.shade100,
        child: Icon(Icons.inventory_2_outlined,
            color: Colors.grey.shade400, size: 20.sp),
      );
}

String _returnQuantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
