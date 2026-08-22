import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:doctorbike/core/helpers/show_no_data.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../data/models/bills_models/bills_details_model.dart';
import '../../controllers/bills_controller.dart';
import '../../widgets/bills_widgets/bill_details.dart';
import '../../widgets/bills_widgets/bill_seller_details.dart';
import '../../widgets/bills_widgets/bill_title.dart';
import '../../widgets/purchase_orders_widgets/cancel_bill.dart';

class BillDetailsScreen extends GetView<BillsController> {
  const BillDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String page = Get.arguments;
    return Scaffold(
      appBar: CustomAppBar(
        title: 'billDetails',
        action: false,
        actions: [
          IconButton(
            onPressed: () {
              controller.getBillDetails(
                context: context,
                billId: controller.billDetails!.billId.toString(),
                isDownload: true,
              );
            },
            icon: Icon(
              Icons.file_download_outlined,
              color: AppColors.primaryColor,
              size: 30.sp,
            ),
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          SliverToBoxAdapter(child: BillTitle(page: page)),
          SliverToBoxAdapter(child: SizedBox(height: 15.h)),
          GetBuilder<BillsController>(
            builder: (controller) {
              if (controller.isAddLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.billDetails == null) {
                return const SliverFillRemaining(
                  child: Center(child: ShowNoData()),
                );
              }
              return SliverToBoxAdapter(
                child: Column(
                  children: [
                    BillDetails(page: page),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.w),
                      child: _PurchaseWorkflowPanel(page: page),
                    ),
                    SizedBox(height: 10.h),
                    const BillSellerDetails(),
                    SizedBox(height: 10.h),
                    page == '3' || page == '4'
                        ? CancelBill(billId: controller.billDetails!.billId)
                        : const SizedBox.shrink(),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}

class _PurchaseWorkflowPanel extends GetView<BillsController> {
  final String page;

  const _PurchaseWorkflowPanel({required this.page});

  @override
  Widget build(BuildContext context) {
    final details = controller.billDetails!;
    final canReceive = page != '1' &&
        details.workflowStatus != 'finalized' &&
        details.products.any((item) => item.remainingQuantity > 0);
    final canFinalize = page != '1' &&
        details.workflowStatus != 'finalized' &&
        details.products.any((item) => item.receivedOwnedQuantity > 0);
    final canPay = details.workflowStatus == 'finalized' &&
        details.paymentStatus != 'paid' &&
        details.remainingAmount != '0';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _StatusChip(
                label: 'حالة الاستلام',
                value: details.workflowStatus.isEmpty
                    ? 'awaiting_receiving'
                    : details.workflowStatus,
              ),
              _StatusChip(
                label: 'حالة الدفع',
                value: details.paymentStatus.isEmpty
                    ? 'unpaid'
                    : details.paymentStatus,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'المستلم: ${details.products.fold<num>(0, (sum, p) => sum + p.receivedOwnedQuantity)} / المطلوب: ${details.products.fold<num>(0, (sum, p) => sum + p.orderedQuantity)}',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                ),
          ),
          if (details.finalTotal != '0' || details.paidAmount != '0') ...[
            SizedBox(height: 6.h),
            Text(
              'الإجمالي النهائي: ${details.finalTotal} | المدفوع: ${details.paidAmount} | المتبقي: ${details.remainingAmount}',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Colors.grey.shade700,
                    fontSize: 12.sp,
                  ),
            ),
          ],
          if (canReceive || canFinalize) SizedBox(height: 12.h),
          if (canReceive)
            AppButton(
              isLoading: controller.isWorkflowLoading,
              text: 'مراجعة واستلام الأصناف',
              onPressed: () => _showReceivingSheet(context),
            ),
          if (canReceive && canFinalize) SizedBox(height: 8.h),
          if (canFinalize)
            AppButton(
              isLoading: controller.isWorkflowLoading,
              text: 'اعتماد الفاتورة',
              onPressed: () => _showPurchasePaymentSheet(
                context,
                title: 'اعتماد الفاتورة',
                primaryText: 'اعتماد',
                initialAmount: '0',
                onSubmit: () =>
                    controller.finalizeShownPurchaseWithInitialPayment(context),
              ),
            ),
          if (canPay) ...[
            if (canReceive || canFinalize) SizedBox(height: 8.h),
            AppButton(
              isLoading: controller.isWorkflowLoading,
              text: 'تسجيل دفعة مورد',
              onPressed: () => _showPurchasePaymentSheet(
                context,
                title: 'تسجيل دفعة مورد',
                primaryText: 'تسجيل الدفعة',
                initialAmount: details.remainingAmount,
                onSubmit: () => controller.submitShownPurchasePayment(context),
              ),
            ),
          ],
          if (details.sellerId.isNotEmpty) ...[
            SizedBox(height: 8.h),
            AppButton(
              isLoading: controller.isWorkflowLoading,
              text: 'دفعة على حساب المورد',
              onPressed: () => _showPurchasePaymentSheet(
                context,
                title: 'دفعة على حساب المورد',
                primaryText: 'تسجيل وتخصيص للأقدم',
                initialAmount: details.remainingAmount == '0'
                    ? ''
                    : details.remainingAmount,
                onSubmit: () =>
                    controller.paySupplierAccountForShownSeller(context),
              ),
            ),
          ],
          if (_activeAmanatItems(details).isNotEmpty) ...[
            SizedBox(height: 14.h),
            const _SectionTitle(text: 'الأمانات'),
            SizedBox(height: 8.h),
            ..._activeAmanatItems(details).map(
              (item) => _AmanatRow(
                item: item,
                onPurchase: () => _showAmanatSheet(
                  context,
                  item: item,
                  isPurchase: true,
                ),
                onReturn: () => _showAmanatSheet(
                  context,
                  item: item,
                  isPurchase: false,
                ),
              ),
            ),
          ],
          if (details.attachments.isNotEmpty || page != '1') ...[
            SizedBox(height: 14.h),
            Row(
              children: [
                const Expanded(child: _SectionTitle(text: 'المرفقات')),
                IconButton(
                  tooltip: 'رفع مرفق',
                  onPressed: controller.isWorkflowLoading.value
                      ? null
                      : () =>
                          controller.pickAndUploadPurchaseAttachments(context),
                  icon: Icon(
                    Icons.upload_file_outlined,
                    color: AppColors.primaryColor,
                    size: 22.sp,
                  ),
                ),
              ],
            ),
            if (details.attachments.isEmpty)
              const _MutedText(text: 'لا توجد مرفقات بعد')
            else
              ...details.attachments.map(
                (attachment) => _AttachmentRow(attachment: attachment),
              ),
          ],
          if (details.payments.isNotEmpty) ...[
            SizedBox(height: 14.h),
            const _SectionTitle(text: 'الدفعات'),
            SizedBox(height: 8.h),
            ...details.payments.take(4).map(
                  (payment) => _InfoLine(
                    title: payment.amount,
                    subtitle: [
                      payment.paymentType,
                      payment.boxName,
                      payment.paidAt,
                    ].where((e) => e.isNotEmpty).join(' • '),
                  ),
                ),
          ],
          if (details.returns.isNotEmpty) ...[
            SizedBox(height: 14.h),
            const _SectionTitle(text: 'المرتجعات'),
            SizedBox(height: 8.h),
            ...details.returns.take(4).map(
                  (ret) => _InfoLine(
                    title: '${ret.totalValue} - ${ret.status}',
                    subtitle:
                        '${ret.createdAt}${ret.items.isEmpty ? '' : ' • ${ret.items.length} منتجات'}',
                  ),
                ),
          ],
          if (controller.isTimelineLoading.value) ...[
            SizedBox(height: 12.h),
            const Center(child: CircularProgressIndicator()),
          ] else if (controller.purchaseTimeline.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'سجل الحركة',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                  ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showFullTimelineSheet(context),
                icon: Icon(Icons.history, size: 16.sp),
                label: const Text('عرض كل الحركات'),
              ),
            ),
            SizedBox(height: 8.h),
            ...controller.purchaseTimeline.take(5).map((event) {
              final title = event['title']?.toString() ?? '';
              final description = event['description']?.toString() ?? '';
              final createdAt = event['created_at']?.toString() ?? '';
              return Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Text(
                  '$createdAt — ${title.isEmpty ? description : title}',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Colors.grey.shade700,
                        fontSize: 11.sp,
                      ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _showFullTimelineSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return ListView.separated(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 24.h),
              itemCount: controller.purchaseTimeline.length + 1,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (_, index) {
                if (index == 0) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          'كل حركات الفاتورة',
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16.sp,
                                  ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  );
                }
                final event = controller.purchaseTimeline[index - 1];
                final title = event['title']?.toString() ?? '';
                final description = event['description']?.toString() ?? '';
                final createdAt = event['created_at']?.toString() ?? '';
                final sourceType = event['source_type']?.toString() ?? '';
                return Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? description : title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                        ),
                      ),
                      if (description.isNotEmpty && title.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                      SizedBox(height: 6.h),
                      _MutedText(
                        text: [
                          if (createdAt.isNotEmpty) createdAt,
                          if (sourceType.isNotEmpty) sourceType,
                        ].join(' • '),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showPurchasePaymentSheet(
    BuildContext context, {
    required String title,
    required String primaryText,
    required String initialAmount,
    required Future<void> Function() onSubmit,
  }) async {
    await controller.loadPurchaseBoxes();
    controller.preparePaymentAmount(amount: initialAmount);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 18.h,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18.h,
          ),
          child: GetBuilder<BillsController>(
            builder: (controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16.sp,
                        ),
                  ),
                  SizedBox(height: 14.h),
                  CustomDropdownFieldWithSearch(
                    tital: 'boxName',
                    hint: 'boxNameExample',
                    items: controller.purchaseBoxes,
                    value: controller.selectedPurchaseBox.value,
                    onChanged: (value) {
                      controller.selectPurchaseBox(
                        value is ShownBoxesModel ? value : null,
                      );
                    },
                    itemAsString: (item) =>
                        '${item.boxName} (${item.currency})',
                    compareFn: (a, b) => a.boxId == b.boxId,
                  ),
                  SizedBox(height: 12.h),
                  CustomTextField(
                    label: 'cashValue',
                    hintText: 'totalExample',
                    controller: controller.purchasePaymentAmountController,
                    keyboardType: TextInputType.number,
                    validator: (value) => null,
                  ),
                  SizedBox(height: 12.h),
                  CustomTextField(
                    label: 'notes',
                    hintText: 'notes',
                    controller: controller.purchasePaymentNoteController,
                    isRequired: false,
                    validator: (value) => null,
                  ),
                  SizedBox(height: 18.h),
                  AppButton(
                    isLoading: controller.isWorkflowLoading,
                    text: primaryText,
                    onPressed: () async {
                      await onSubmit();
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showReceivingSheet(BuildContext context) async {
    controller.prepareReceivingRows();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.55,
          maxChildSize: 0.96,
          expand: false,
          builder: (_, scrollController) {
            return GetBuilder<BillsController>(
              builder: (controller) {
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 8.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'مراجعة الاستلام',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16.sp,
                                  ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 16.h),
                        itemCount: controller.receivingRows.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10.h),
                        itemBuilder: (_, index) {
                          return _ReceivingRowCard(
                            row: controller.receivingRows[index],
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 14.h),
                        child: AppButton(
                          isLoading: controller.isWorkflowLoading,
                          text: 'تسجيل الاستلام',
                          onPressed: () async {
                            await controller.submitReviewedReceiving(context);
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  List<_AmanatListItem> _activeAmanatItems(BillDetailsModel details) {
    return details.products.expand((product) {
      return product.amanatStocks
          .where((amanat) => amanat.remainingQuantity > 0)
          .map((amanat) => _AmanatListItem(product: product, amanat: amanat));
    }).toList();
  }

  Future<void> _showAmanatSheet(
    BuildContext context, {
    required _AmanatListItem item,
    required bool isPurchase,
  }) async {
    controller.prepareAmanatAction(
      quantity: item.amanat.remainingQuantity.toString(),
      unitPrice: item.amanat.negotiatedUnitPrice == '0'
          ? item.product.price
          : item.amanat.negotiatedUnitPrice,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 18.h,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18.h,
          ),
          child: GetBuilder<BillsController>(
            builder: (controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPurchase ? 'شراء الأمانة' : 'إرجاع الأمانة للمورد',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16.sp,
                        ),
                  ),
                  SizedBox(height: 6.h),
                  _MutedText(
                    text:
                        '${item.product.productName} • المتبقي ${item.amanat.remainingQuantity}',
                  ),
                  SizedBox(height: 14.h),
                  CustomTextField(
                    label: 'quantity',
                    hintText: 'quantity',
                    controller: controller.amanatQuantityController,
                    keyboardType: TextInputType.number,
                    validator: (value) => null,
                  ),
                  if (isPurchase) ...[
                    SizedBox(height: 12.h),
                    CustomTextField(
                      label: 'price',
                      hintText: 'price',
                      controller: controller.amanatUnitPriceController,
                      keyboardType: TextInputType.number,
                      validator: (value) => null,
                    ),
                  ] else ...[
                    SizedBox(height: 12.h),
                    CustomTextField(
                      label: 'notes',
                      hintText: 'notes',
                      controller: controller.amanatNoteController,
                      isRequired: false,
                      validator: (value) => null,
                    ),
                  ],
                  SizedBox(height: 18.h),
                  AppButton(
                    isLoading: controller.isWorkflowLoading,
                    text: isPurchase ? 'شراء' : 'إرجاع',
                    onPressed: () async {
                      if (isPurchase) {
                        await controller.purchaseShownAmanat(
                          context,
                          amanatId: item.amanat.id.toString(),
                        );
                      } else {
                        await controller.returnShownAmanat(
                          context,
                          amanatId: item.amanat.id.toString(),
                        );
                      }
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatusChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 11.sp,
            ),
      ),
    );
  }
}

class _ReceivingRowCard extends GetView<BillsController> {
  final PurchaseReceivingRowModel row;

  const _ReceivingRowCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final product = row.product;
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.productName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              _StatusChip(
                label: 'متبقي',
                value: product.remainingQuantity.toString(),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          _MutedText(
            text:
                'المطلوب ${product.orderedQuantity} • مستلم سابقاً ${product.receivedOwnedQuantity}',
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'وصل فعلياً',
                  hintText: '0',
                  controller: row.deliveredNowController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => controller.update(),
                  validator: (_) => null,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: CustomTextField(
                  label: 'مقبول',
                  hintText: '0',
                  controller: row.acceptedController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => controller.update(),
                  validator: (_) => null,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'ناقص',
                  hintText: '0',
                  controller: row.missingController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => controller.update(),
                  validator: (_) => null,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: CustomTextField(
                  label: 'زائد/أمانة',
                  hintText: '0',
                  controller: row.extraController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => controller.update(),
                  validator: (_) => null,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'تالف',
                  hintText: '0',
                  controller: row.damagedController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => controller.update(),
                  validator: (_) => null,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: CustomTextField(
                  label: 'غير مطابق',
                  hintText: '0',
                  controller: row.mismatchedController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => controller.update(),
                  validator: (_) => null,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          CustomTextField(
            label: 'price',
            hintText: 'price',
            controller: row.unitPriceController,
            keyboardType: TextInputType.number,
            onChanged: (_) => controller.update(),
            validator: (_) => null,
          ),
          SizedBox(height: 8.h),
          CustomTextField(
            label: 'سبب / وصف',
            hintText: 'سبب / وصف',
            controller: row.reasonController,
            isRequired: false,
            validator: (_) => null,
          ),
          SizedBox(height: 8.h),
          CustomTextField(
            label: 'notes',
            hintText: 'notes',
            controller: row.notesController,
            isRequired: false,
            validator: (_) => null,
          ),
          SizedBox(height: 8.h),
          _ReceivingValidityHint(row: row),
        ],
      ),
    );
  }
}

class _ReceivingValidityHint extends StatelessWidget {
  final PurchaseReceivingRowModel row;

  const _ReceivingValidityHint({required this.row});

  @override
  Widget build(BuildContext context) {
    final ok = row.isEmpty || row.isValid;
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_outline : Icons.error_outline,
          color: ok ? const Color(0xFF15803D) : Colors.red,
          size: 16.sp,
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            ok
                ? 'جاهز عند إدخال كميات'
                : 'الكميات غير متوازنة أو تتجاوز المتبقي',
            style: TextStyle(
              color: ok ? const Color(0xFF15803D) : Colors.red,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AmanatListItem {
  final BillProductModel product;
  final PurchaseAmanatUiModel amanat;

  const _AmanatListItem({
    required this.product,
    required this.amanat,
  });
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 13.sp,
          ),
    );
  }
}

class _MutedText extends StatelessWidget {
  final String text;

  const _MutedText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Colors.grey.shade700,
            fontSize: 11.sp,
          ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoLine({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6.sp, color: AppColors.primaryColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              subtitle.isEmpty ? title : '$title • $subtitle',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Colors.grey.shade700,
                    fontSize: 11.sp,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmanatRow extends StatelessWidget {
  final _AmanatListItem item;
  final VoidCallback onPurchase;
  final VoidCallback onReturn;

  const _AmanatRow({
    required this.item,
    required this.onPurchase,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.product.productName,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                ),
          ),
          SizedBox(height: 4.h),
          _MutedText(
            text:
                'المتبقي ${item.amanat.remainingQuantity} من ${item.amanat.quantity} • السعر ${item.amanat.negotiatedUnitPrice}',
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPurchase,
                  icon: Icon(Icons.shopping_cart_checkout, size: 16.sp),
                  label: const Text('شراء'),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReturn,
                  icon: Icon(Icons.assignment_return_outlined, size: 16.sp),
                  label: const Text('إرجاع'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  final PurchaseAttachmentUiModel attachment;

  const _AttachmentRow({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.attach_file,
        color: AppColors.primaryColor,
        size: 20.sp,
      ),
      title: Text(
        attachment.fileName.isEmpty ? 'مرفق' : attachment.fileName,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12.sp,
            ),
      ),
      subtitle: Text(
        [attachment.category, attachment.createdAt]
            .where((e) => e.isNotEmpty)
            .join(' • '),
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Colors.grey.shade700,
              fontSize: 11.sp,
            ),
      ),
      onTap: attachment.url.isEmpty
          ? null
          : () => launchUrl(
                Uri.parse(attachment.url),
                mode: LaunchMode.externalApplication,
              ),
    );
  }
}
