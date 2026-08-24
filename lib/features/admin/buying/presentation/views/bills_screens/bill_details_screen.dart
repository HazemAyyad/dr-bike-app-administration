import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

import 'package:doctorbike/core/helpers/show_no_data.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/widgets/app_pull_to_refresh.dart';
import '../../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../../debts/presentation/binding/debts_binding.dart';
import '../../../../debts/presentation/controllers/debt_ledger_controller.dart';
import '../../../data/models/bills_models/bills_details_model.dart';
import '../../controllers/bills_controller.dart';
import '../../widgets/purchase_orders_widgets/cancel_bill.dart';

class BillDetailsScreen extends GetView<BillsController> {
  const BillDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String page = Get.arguments;
    return Scaffold(
      appBar: CustomAppBar(
        title: controller.billDetails == null
            ? 'تفاصيل فاتورة شراء'
            : 'فاتورة شراء #${controller.billDetails!.billId}',
        action: false,
      ),
      body: AppPullToRefresh(
        onRefresh: () async {
          final details = controller.billDetails;
          if (details == null) {
            return;
          }
          await controller.getBillDetails(
            context: context,
            billId: details.billId.toString(),
          );
        },
        child: CustomScrollView(
          physics: kRefreshableScrollPhysics,
          slivers: [
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
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 26.h),
                    child: Column(
                      children: [
                        const _PurchaseInvoicePrintActions(),
                        SizedBox(height: 10.h),
                        _PurchaseWorkflowPanel(page: page),
                        if (page == '3' || page == '4') ...[
                          SizedBox(height: 10.h),
                          CancelBill(billId: controller.billDetails!.billId),
                        ],
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

class _PurchaseInvoicePrintActions extends GetView<BillsController> {
  const _PurchaseInvoicePrintActions();

  @override
  Widget build(BuildContext context) {
    final details = controller.billDetails;
    if (details == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'فاتورة شراء #${details.billId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          IconButton(
            tooltip: 'حفظ PDF',
            onPressed: () => controller.getBillDetails(
              context: context,
              billId: details.billId.toString(),
              isDownload: true,
            ),
            icon: const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            tooltip: 'pdf'.tr,
            onPressed: controller.shareShownPurchaseBillPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: 'print'.tr,
            onPressed: controller.printShownPurchaseBillPdf,
            icon: const Icon(Icons.print_outlined),
          ),
        ],
      ),
    );
  }
}

class _PurchaseWorkflowPanel extends StatefulWidget {
  final String page;

  const _PurchaseWorkflowPanel({required this.page});

  @override
  State<_PurchaseWorkflowPanel> createState() => _PurchaseWorkflowPanelState();
}

class _PurchaseWorkflowPanelState extends State<_PurchaseWorkflowPanel> {
  BillsController get controller => Get.find<BillsController>();
  String get page => widget.page;
  int _selectedSection = 0;

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
        (double.tryParse(details.remainingAmount) ?? 0) > 0;
    final totalOrdered = details.products.fold<num>(
      0,
      (sum, p) => sum + p.orderedQuantity,
    );
    final totalReceived = details.products.fold<num>(
      0,
      (sum, p) => sum + p.receivedOwnedQuantity,
    );
    final totalRemaining = details.products.fold<num>(
      0,
      (sum, p) => sum + p.remainingQuantity,
    );
    final issueItems = _issueItems(details);
    final amanatItems = _activeAmanatItems(details);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PurchaseSummaryHeader(
          details: details,
          sourceType: _sourceTypeLabel(details),
          workflowLabel: _workflowLabel(details.workflowStatus),
          receivingLabel: _receivingLabel(details, totalRemaining),
          paymentLabel: _paymentLabel(details.paymentStatus),
          totalText: _money(details.finalTotal == '0'
              ? details.totalBill
              : details.finalTotal),
          paidText: _money(details.paidAmount),
          remainingText: _money(details.remainingAmount),
          onOpenLedger: () => _openSourceLedger(details),
        ),
        SizedBox(height: 10.h),
        _ContextualActionCards(
          remainingItems: details.products
              .where((item) => item.remainingQuantity > 0)
              .length,
          issueCount: issueItems.length,
          amanatCount: amanatItems.length,
          remainingAmount: details.remainingAmount,
          canReceive: canReceive,
          canPay: canPay,
          canFinalize: canFinalize,
          onReceive: () => _showReceivingSheet(context),
          onIssues: () => setState(() => _selectedSection = 2),
          onAmanat: () => setState(() => _selectedSection = 3),
          onPay: () => _showPurchasePaymentSheet(
            context,
            title: 'تسجيل دفعة مورد',
            primaryText: 'تسجيل الدفعة',
            initialAmount: details.remainingAmount,
            attachmentCategory: 'purchase_payment_evidence',
            attachableType: 'bill',
            attachableId: details.billId.toString(),
            onSubmit: () => controller.submitShownPurchasePayment(context),
          ),
          onFinalize: () => _showFinalizationSheet(context),
        ),
        if (details.workflowStatus != 'finalized' &&
            details.paymentStatus != 'paid') ...[
          SizedBox(height: 8.h),
          const _InlineNotice(
            icon: Icons.info_outline,
            title:
                'الدفع على الفاتورة يظهر بعد الاستلام والاعتماد. قبل الاعتماد استخدم دفعة على حساب المصدر إذا بدك تسجل مبلغ للمورد.',
          ),
        ],
        SizedBox(height: 10.h),
        _PurchaseDetailsSectionTabs(
          selected: _selectedSection,
          onChanged: (value) => setState(() => _selectedSection = value),
        ),
        SizedBox(height: 12.h),
        if (_selectedSection == 0)
          _SummaryTab(
            details: details,
            sourceType: _sourceTypeLabel(details),
            totalOrdered: totalOrdered,
            totalReceived: totalReceived,
            totalRemaining: totalRemaining,
            issueItems: issueItems,
            onIssuesTap: () => setState(() => _selectedSection = 2),
            onAccountPayment:
                (details.sellerId.isNotEmpty || details.customerId.isNotEmpty)
                    ? () => _showPurchasePaymentSheet(
                          context,
                          title: 'دفعة على حساب المصدر',
                          primaryText: 'تسجيل الدفعة',
                          initialAmount: details.remainingAmount == '0'
                              ? ''
                              : details.remainingAmount,
                          showAllocations: true,
                          attachmentCategory: 'account_payment_evidence',
                          attachableType: 'purchase_account_payment',
                          attachableId: details.sellerId.isNotEmpty
                              ? details.sellerId
                              : details.customerId,
                          onSubmit: () =>
                              controller.paySupplierAccountForShownSeller(
                            context,
                          ),
                        )
                    : null,
          ),
        if (_selectedSection == 1) ...[
          Row(
            children: [
              const Expanded(child: _SectionTitle(text: 'الأصناف والاستلام')),
              if (canReceive)
                TextButton.icon(
                  onPressed: () => _showReceivingSheet(context),
                  icon: Icon(Icons.fact_check_outlined, size: 16.sp),
                  label: const Text('استلام'),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          if (canReceive)
            _InlineNotice(
              icon: Icons.inventory_outlined,
              title:
                  'متبقي ${details.products.where((item) => item.remainingQuantity > 0).length} أصناف للاستلام',
              actionText: 'بدء مراجعة الاستلام',
              onPressed: () => _showReceivingSheet(context),
            ),
          if (canReceive) SizedBox(height: 8.h),
          ...details.products
              .map((item) => _PurchaseItemOverviewRow(item: item)),
        ],
        if (_selectedSection == 3 && amanatItems.isNotEmpty) ...[
          const _SectionTitle(text: 'الأمانات'),
          SizedBox(height: 8.h),
          ...amanatItems.map(
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
        if (_selectedSection == 2 && issueItems.isNotEmpty) ...[
          const _SectionTitle(text: 'الفروقات المفتوحة'),
          SizedBox(height: 8.h),
          ...issueItems.map(
            (item) => _IssueRow(
              product: item,
              onResolveMissing: (num.tryParse(item.missingAmount) ?? 0) > 0
                  ? () => _showIssueResolutionSheet(
                        context,
                        product: item,
                        issueType: 'missing',
                        quantity: num.tryParse(item.missingAmount) ?? 0,
                      )
                  : null,
              onResolveDamaged: item.damagedQuantity > 0
                  ? () => _showIssueResolutionSheet(
                        context,
                        product: item,
                        issueType: 'damaged',
                        quantity: item.damagedQuantity,
                      )
                  : null,
              onResolveMismatched: item.mismatchedQuantity > 0
                  ? () => _showIssueResolutionSheet(
                        context,
                        product: item,
                        issueType: 'mismatched',
                        quantity: item.mismatchedQuantity,
                      )
                  : null,
            ),
          ),
        ],
        if (_selectedSection == 2 && issueItems.isEmpty)
          const _EmptyTabState(text: 'لا توجد فروقات غير معالجة'),
        if (_selectedSection == 3 && amanatItems.isEmpty)
          const _EmptyTabState(text: 'لا توجد أمانات في هذه الفاتورة'),
        if (_selectedSection == 6) ...[
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
            const _EmptyTabState(text: 'لا توجد مرفقات')
          else
            ..._groupAttachments(details.attachments).entries.map(
                  (entry) => _AttachmentGroup(
                    title: entry.key,
                    attachments: entry.value,
                  ),
                ),
        ],
        if (_selectedSection == 4)
          _PaymentsTab(
            details: details,
            canPay: canPay,
            onPay: () => _showPurchasePaymentSheet(
              context,
              title: 'تسجيل دفعة مورد',
              primaryText: 'تسجيل الدفعة',
              initialAmount: details.remainingAmount,
              attachmentCategory: 'purchase_payment_evidence',
              attachableType: 'bill',
              attachableId: details.billId.toString(),
              onSubmit: () => controller.submitShownPurchasePayment(context),
            ),
          ),
        if (_selectedSection == 5 && details.returns.isNotEmpty) ...[
          const _SectionTitle(text: 'المرتجعات'),
          SizedBox(height: 8.h),
          ...details.returns.map((ret) => _ReturnCard(ret: ret)),
        ],
        if (_selectedSection == 5 && details.returns.isEmpty)
          const _EmptyTabState(text: 'لا توجد مرتجعات مرتبطة بهذه الفاتورة'),
        if (_selectedSection == 7 && controller.isTimelineLoading.value) ...[
          const Center(child: CircularProgressIndicator()),
        ] else if (_selectedSection == 7 &&
            controller.purchaseTimeline.isNotEmpty) ...[
          const _SectionTitle(text: 'الحركات'),
          SizedBox(height: 8.h),
          ...controller.purchaseTimeline.map(
            (event) => _TimelineCard(event: event),
          ),
        ],
        if (_selectedSection == 7 && controller.purchaseTimeline.isEmpty)
          const _EmptyTabState(text: 'لا توجد حركات ظاهرة بعد'),
      ],
    );
  }

  String _money(String value) {
    final amount = double.tryParse(value) ?? 0;
    return '${intl.NumberFormat('#,##0.00').format(amount)} ₪';
  }

  String _workflowLabel(String status) {
    switch (status) {
      case 'finalized':
        return 'مكتملة';
      case 'awaiting_finalization':
        return 'بانتظار الاعتماد';
      case 'partially_received':
        return 'مستلم جزئياً';
      default:
        return status.isEmpty ? 'بانتظار الاستلام' : status;
    }
  }

  String _receivingLabel(BillDetailsModel details, num totalRemaining) {
    if (totalRemaining <= 0) return 'مستلم بالكامل';
    final received = details.products.fold<num>(
      0,
      (sum, p) => sum + p.receivedOwnedQuantity,
    );
    return received > 0 ? 'مستلم جزئياً' : 'بانتظار الاستلام';
  }

  String _paymentLabel(String status) {
    switch (status) {
      case 'paid':
        return 'مدفوعة';
      case 'partially_paid':
      case 'partial':
        return 'مدفوعة جزئياً';
      case 'unpaid':
      case '':
        return 'غير مدفوعة';
      default:
        return status;
    }
  }

  String _sourceTypeLabel(BillDetailsModel details) {
    final hasSeller = details.sellerId.isNotEmpty;
    final hasCustomer = details.customerId.isNotEmpty;
    if (hasSeller && hasCustomer) return 'مورد + زبون';
    if (hasSeller) return 'مورد';
    if (hasCustomer) return 'زبون';
    return 'مصدر شراء';
  }

  Map<String, List<PurchaseAttachmentUiModel>> _groupAttachments(
    List<PurchaseAttachmentUiModel> attachments,
  ) {
    final groups = <String, List<PurchaseAttachmentUiModel>>{};
    for (final attachment in attachments) {
      final key = _attachmentContextLabel(attachment.category);
      groups.putIfAbsent(key, () => []).add(attachment);
    }
    return groups;
  }

  String _attachmentContextLabel(String category) {
    if (category.contains('payment')) return 'الدفعات';
    if (category.contains('damaged')) return 'التالف';
    if (category.contains('mismatch')) return 'غير المطابق';
    if (category.contains('amanat')) return 'الأمانات';
    if (category.contains('return')) return 'المرتجعات';
    if (category.contains('receiv')) return 'الاستلام';
    if (category.contains('settlement')) return 'التسويات';
    return 'فاتورة المورد';
  }

  Future<void> _showFinalizationSheet(BuildContext context) async {
    final details = controller.billDetails!;
    final openIssues = _issueItems(details).length;
    final remaining = details.products
        .where((item) => item.remainingQuantity > 0)
        .fold<num>(0, (sum, item) => sum + item.remainingQuantity);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 22.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اعتماد الفاتورة',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16.sp,
                    ),
              ),
              SizedBox(height: 12.h),
              _InfoLine(
                  title: 'الإجمالي النهائي',
                  subtitle: _money(details.finalTotal)),
              _InfoLine(
                  title: 'المتبقي للاستلام', subtitle: remaining.toString()),
              _InfoLine(
                  title: 'الفروقات المفتوحة', subtitle: openIssues.toString()),
              if (openIssues > 0) ...[
                SizedBox(height: 10.h),
                const _MutedText(
                  text: 'لا يمكن اعتماد الفاتورة قبل معالجة الفروقات التالية',
                ),
              ],
              SizedBox(height: 16.h),
              AppButton(
                isLoading: controller.isWorkflowLoading,
                text: 'اعتماد',
                onPressed: openIssues > 0
                    ? null
                    : () async {
                        final ok = await controller
                            .finalizeShownPurchaseWithInitialPayment(
                          sheetContext,
                        );
                        if (!sheetContext.mounted) return;
                        if (!ok) return;
                        Navigator.of(sheetContext).pop();
                        Get.snackbar(
                          'success'.tr,
                          'تم اعتماد الفاتورة بنجاح',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.green.withValues(alpha: 0.12),
                          colorText: Colors.green.shade900,
                          margin: EdgeInsets.all(12.w),
                          duration: const Duration(seconds: 2),
                        );
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  // Kept for older entry points that may still call the full timeline sheet.
  // ignore: unused_element
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
    required Future<dynamic> Function() onSubmit,
    bool showAllocations = false,
    String? attachmentCategory,
    String? attachableType,
    String? attachableId,
  }) async {
    await controller.loadPurchaseBoxes();
    controller.preparePaymentAmount(amount: initialAmount);
    if (showAllocations) {
      await controller.loadOpenPurchaseAccountBills();
    }
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
                  if (showAllocations) ...[
                    SizedBox(height: 14.h),
                    _ManualAllocationSection(controller: controller),
                  ],
                  if (attachmentCategory != null) ...[
                    SizedBox(height: 12.h),
                    OutlinedButton.icon(
                      onPressed: () =>
                          controller.pickPurchasePaymentEvidence(context),
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('إرفاق إثبات مع الدفعة'),
                    ),
                    if (controller.purchasePaymentEvidenceFiles.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Wrap(
                          spacing: 6.w,
                          runSpacing: 6.h,
                          children: controller.purchasePaymentEvidenceFiles
                              .map(
                                (file) => InputChip(
                                  label: Text(
                                    file.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onDeleted: () => controller
                                      .removePurchasePaymentEvidence(file),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                  SizedBox(height: 18.h),
                  AppButton(
                    isLoading: controller.isWorkflowLoading,
                    text: primaryText,
                    onPressed: () async {
                      final result = await onSubmit();
                      if (result != false && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                        Get.snackbar(
                          'تمت العملية',
                          'تم تسجيل الدفعة بنجاح',
                          snackPosition: SnackPosition.BOTTOM,
                        );
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

  Future<void> _openSourceLedger(BillDetailsModel details) async {
    final isCustomer = details.customerId.isNotEmpty;
    final rawId = isCustomer ? details.customerId : details.sellerId;
    final id = int.tryParse(rawId);
    if (id == null || id <= 0) return;
    if (!Get.isRegistered<DebtLedgerController>() &&
        !Get.isPrepared<DebtLedgerController>()) {
      DebtsBinding().dependencies();
    }
    await Get.find<DebtLedgerController>().openPersonAccount(
      id: id,
      name: details.sellerName.isEmpty ? 'مصدر غير معروف' : details.sellerName,
      personType: isCustomer ? 'customer' : 'seller',
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
                            final result = await controller
                                .submitReviewedReceiving(context);
                            if (result && sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                              Get.snackbar(
                                'success'.tr,
                                'تم تسجيل الاستلام بنجاح',
                                snackPosition: SnackPosition.TOP,
                                backgroundColor:
                                    Colors.green.withValues(alpha: 0.12),
                                colorText: Colors.green.shade900,
                                margin: EdgeInsets.all(12.w),
                                duration: const Duration(seconds: 2),
                              );
                            } else {
                              Get.snackbar(
                                'error'.tr,
                                'لم يتم تسجيل الاستلام، راجع الكميات أو رسالة الخطأ',
                                snackPosition: SnackPosition.TOP,
                                backgroundColor:
                                    Colors.red.withValues(alpha: 0.12),
                                colorText: Colors.red.shade900,
                                margin: EdgeInsets.all(12.w),
                                duration: const Duration(seconds: 3),
                              );
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

  List<BillProductModel> _issueItems(BillDetailsModel details) {
    return details.products.where((item) {
      final missing = num.tryParse(item.missingAmount) ?? 0;
      return missing > 0 ||
          item.damagedQuantity > 0 ||
          item.mismatchedQuantity > 0;
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
                  SizedBox(height: 12.h),
                  OutlinedButton.icon(
                    onPressed: () =>
                        controller.pickAndUploadPurchaseAttachments(
                      context,
                      category: isPurchase
                          ? 'amanat_purchase_evidence'
                          : 'amanat_return_evidence',
                      attachableType: 'purchase_amanat_stock',
                      attachableId: item.amanat.id.toString(),
                    ),
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('رفع مرفق'),
                  ),
                  SizedBox(height: 18.h),
                  AppButton(
                    isLoading: controller.isWorkflowLoading,
                    text: isPurchase ? 'شراء' : 'إرجاع',
                    onPressed: () async {
                      bool ok;
                      if (isPurchase) {
                        ok = await controller.purchaseShownAmanat(
                          sheetContext,
                          amanatId: item.amanat.id.toString(),
                        );
                      } else {
                        ok = await controller.returnShownAmanat(
                          sheetContext,
                          amanatId: item.amanat.id.toString(),
                        );
                      }
                      if (!sheetContext.mounted) return;
                      if (ok) {
                        Navigator.of(sheetContext).pop();
                        Get.snackbar(
                          'success'.tr,
                          isPurchase
                              ? 'تم شراء الأمانة بنجاح'
                              : 'تم إرجاع الأمانة بنجاح',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.green.withValues(alpha: 0.12),
                          colorText: Colors.green.shade900,
                          margin: EdgeInsets.all(12.w),
                          duration: const Duration(seconds: 2),
                        );
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

  Future<void> _showIssueResolutionSheet(
    BuildContext context, {
    required BillProductModel product,
    required String issueType,
    required num quantity,
  }) async {
    final options = {
      'return_to_supplier':
          issueType == 'missing' ? 'اعتماد النقص' : 'إرجاع للمورد',
      'replacement_expected': 'بانتظار بديل',
      if (issueType != 'missing') 'accept_negotiated_price': 'قبول بسعر متفاوض',
      if (issueType != 'missing') 'accept_with_discount': 'قبول مع خصم',
      'other_settlement': 'تسوية أخرى',
    };
    String selected = issueType == 'missing'
        ? 'return_to_supplier'
        : issueType == 'damaged'
            ? 'accept_with_discount'
            : 'accept_negotiated_price';
    controller.prepareIssueResolution(
      quantity: quantity.toString(),
      unitPrice: product.price,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 18.h,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18.h,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issueType == 'missing'
                          ? 'تسوية نقص'
                          : issueType == 'damaged'
                              ? 'تسوية تالف'
                              : 'تسوية غير مطابق',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16.sp,
                          ),
                    ),
                    SizedBox(height: 6.h),
                    _MutedText(text: product.productName),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: options.entries.map((entry) {
                        return ChoiceChip(
                          label: Text(entry.value),
                          selected: selected == entry.key,
                          onSelected: (_) {
                            setSheetState(() => selected = entry.key);
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 12.h),
                    CustomTextField(
                      label: 'quantity',
                      hintText: '0',
                      controller: controller.issueQuantityController,
                      keyboardType: TextInputType.number,
                      validator: (_) => null,
                    ),
                    if (selected == 'accept_with_discount' ||
                        selected == 'accept_negotiated_price') ...[
                      SizedBox(height: 10.h),
                      CustomTextField(
                        label: 'السعر المتفاوض',
                        hintText: '0',
                        controller: controller.issueUnitPriceController,
                        keyboardType: TextInputType.number,
                        validator: (_) => null,
                      ),
                    ],
                    SizedBox(height: 10.h),
                    CustomTextField(
                      label: 'الأثر المالي',
                      hintText: '0',
                      controller: controller.issueAdjustmentController,
                      keyboardType: TextInputType.number,
                      isRequired: false,
                      validator: (_) => null,
                    ),
                    SizedBox(height: 6.h),
                    const _MutedText(
                      text:
                          'الأثر المالي هو فرق يدوي للتوثيق أو الخصم المتفق عليه. سعر التفاوض هو الذي يدخل في تكلفة المخزون عند قبول الصنف.',
                    ),
                    SizedBox(height: 10.h),
                    CustomTextField(
                      label: 'سبب / وصف',
                      hintText: 'سبب / وصف',
                      controller: controller.issueReasonController,
                      isRequired: false,
                      validator: (_) => null,
                    ),
                    SizedBox(height: 10.h),
                    CustomTextField(
                      label: 'notes',
                      hintText: 'notes',
                      controller: controller.issueNotesController,
                      isRequired: false,
                      validator: (_) => null,
                    ),
                    SizedBox(height: 12.h),
                    OutlinedButton.icon(
                      onPressed: () =>
                          controller.pickAndUploadPurchaseAttachments(
                        context,
                        category: issueType == 'damaged'
                            ? 'damaged_evidence'
                            : issueType == 'missing'
                                ? 'missing_evidence'
                                : 'mismatch_evidence',
                        attachableType: 'bill_item',
                        attachableId: product.billItemId.toString(),
                      ),
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('رفع دليل'),
                    ),
                    SizedBox(height: 16.h),
                    AppButton(
                      isLoading: controller.isWorkflowLoading,
                      text: 'تسجيل التسوية',
                      onPressed: () async {
                        final ok = await controller.resolveShownIssue(
                          context,
                          product: product,
                          issueType: issueType,
                          resolution: selected,
                        );
                        if (ok && sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                          Get.snackbar(
                            'success'.tr,
                            'تم تسجيل التسوية بنجاح',
                            snackPosition: SnackPosition.TOP,
                            backgroundColor:
                                Colors.green.withValues(alpha: 0.12),
                            colorText: Colors.green.shade900,
                            margin: EdgeInsets.all(12.w),
                            duration: const Duration(seconds: 2),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ManualAllocationSection extends StatelessWidget {
  final BillsController controller;

  const _ManualAllocationSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.isOpenPurchaseBillsLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.openPurchaseBills.isEmpty) {
      return const _MutedText(text: 'لا توجد فواتير مفتوحة لهذا المصدر');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'توزيع يدوي على الفواتير',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 13.sp,
              ),
        ),
        SizedBox(height: 4.h),
        const _MutedText(text: 'اتركها فارغة ليتم التخصيص للأقدم تلقائياً'),
        SizedBox(height: 8.h),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 260.h),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: controller.openPurchaseBills.length,
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
            itemBuilder: (_, index) {
              final bill = controller.openPurchaseBills[index];
              return Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'فاتورة #${bill.billId}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: bill.fillRemaining,
                          child: const Text('كامل المتبقي'),
                        ),
                      ],
                    ),
                    _MutedText(
                      text:
                          'الإجمالي ${bill.finalTotal.toStringAsFixed(2)} | المدفوع ${bill.paidAmount.toStringAsFixed(2)} | المتبقي ${bill.remainingAmount.toStringAsFixed(2)} ${bill.currency}',
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: bill.amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'مبلغ التخصيص',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PurchaseMoney {
  static String format(String value) {
    final amount = double.tryParse(value) ?? 0;
    return '${intl.NumberFormat('#,##0.00').format(amount)} ₪';
  }
}

class _PurchaseSummaryHeader extends StatelessWidget {
  const _PurchaseSummaryHeader({
    required this.details,
    required this.sourceType,
    required this.workflowLabel,
    required this.receivingLabel,
    required this.paymentLabel,
    required this.totalText,
    required this.paidText,
    required this.remainingText,
    this.onOpenLedger,
  });

  final BillDetailsModel details;
  final String sourceType;
  final String workflowLabel;
  final String receivingLabel;
  final String paymentLabel;
  final String totalText;
  final String paidText;
  final String remainingText;
  final VoidCallback? onOpenLedger;

  @override
  Widget build(BuildContext context) {
    return _DetailsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primaryColor,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            details.sellerName.isEmpty
                                ? 'مصدر غير معروف'
                                : details.sellerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.sp,
                                ),
                          ),
                        ),
                        if (onOpenLedger != null)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            constraints: BoxConstraints(
                              minWidth: 32.w,
                              minHeight: 32.w,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: onOpenLedger,
                            icon: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: AppColors.primaryColor,
                              size: 19.sp,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    _MutedText(
                      text:
                          '$sourceType • فاتورة #${details.billId} • ${details.createdAt}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              _StatusChip(label: 'سير العمل', value: workflowLabel),
              _StatusChip(label: 'الاستلام', value: receivingLabel),
              _StatusChip(label: 'الدفع', value: paymentLabel),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _MoneyBlock(label: 'الإجمالي النهائي', value: totalText),
              ),
              SizedBox(width: 8.w),
              Expanded(child: _MoneyBlock(label: 'المدفوع', value: paidText)),
              SizedBox(width: 8.w),
              Expanded(
                child: _MoneyBlock(
                  label: 'المتبقي',
                  value: remainingText,
                  highlighted: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyBlock extends StatelessWidget {
  const _MoneyBlock({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primaryColor.withValues(alpha: 0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 10.sp),
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                color: highlighted ? AppColors.primaryColor : Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextualActionCards extends StatelessWidget {
  const _ContextualActionCards({
    required this.remainingItems,
    required this.issueCount,
    required this.amanatCount,
    required this.remainingAmount,
    required this.canReceive,
    required this.canPay,
    required this.canFinalize,
    required this.onReceive,
    required this.onIssues,
    required this.onAmanat,
    required this.onPay,
    required this.onFinalize,
  });

  final int remainingItems;
  final int issueCount;
  final int amanatCount;
  final String remainingAmount;
  final bool canReceive;
  final bool canPay;
  final bool canFinalize;
  final VoidCallback onReceive;
  final VoidCallback onIssues;
  final VoidCallback onAmanat;
  final VoidCallback onPay;
  final VoidCallback onFinalize;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      if (canReceive && remainingItems > 0)
        _ActionNoticeCard(
          icon: Icons.inventory_outlined,
          title: 'يوجد $remainingItems أصناف بانتظار الاستلام',
          buttonText: 'مراجعة الاستلام',
          onPressed: onReceive,
        ),
      if (issueCount > 0)
        _ActionNoticeCard(
          icon: Icons.report_problem_outlined,
          title: 'يوجد $issueCount فرق غير معالج',
          buttonText: 'معالجة الفروقات',
          onPressed: onIssues,
        ),
      if (canPay)
        _ActionNoticeCard(
          icon: Icons.payments_outlined,
          title: 'المتبقي للمورد: ${_PurchaseMoney.format(remainingAmount)}',
          buttonText: 'تسجيل دفعة',
          onPressed: onPay,
        ),
      if (amanatCount > 0)
        _ActionNoticeCard(
          icon: Icons.handshake_outlined,
          title: 'يوجد $amanatCount قطعة أمانة',
          buttonText: 'عرض الأمانات',
          onPressed: onAmanat,
        ),
      if (canFinalize)
        _ActionNoticeCard(
          icon: Icons.fact_check_outlined,
          title: 'الفاتورة جاهزة للمراجعة والاعتماد',
          buttonText: 'اعتماد الفاتورة',
          onPressed: onFinalize,
          primary: true,
        ),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(children: cards);
  }
}

class _ActionNoticeCard extends StatelessWidget {
  const _ActionNoticeCard({
    required this.icon,
    required this.title,
    this.buttonText,
    this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String? buttonText;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: primary
            ? AppColors.primaryColor.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.sp),
            ),
          ),
          if (buttonText != null && onPressed != null)
            TextButton(onPressed: onPressed, child: Text(buttonText!)),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.details,
    required this.sourceType,
    required this.totalOrdered,
    required this.totalReceived,
    required this.totalRemaining,
    required this.issueItems,
    required this.onIssuesTap,
    required this.onAccountPayment,
  });

  final BillDetailsModel details;
  final String sourceType;
  final num totalOrdered;
  final num totalReceived;
  final num totalRemaining;
  final List<BillProductModel> issueItems;
  final VoidCallback onIssuesTap;
  final VoidCallback? onAccountPayment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(text: 'معلومات الشراء'),
              SizedBox(height: 8.h),
              _InfoLine(title: 'المورد / الشخص', subtitle: details.sellerName),
              _InfoLine(title: 'نوع المصدر', subtitle: sourceType),
              _InfoLine(title: 'رقم الفاتورة', subtitle: '#${details.billId}'),
              _InfoLine(title: 'التاريخ', subtitle: details.createdAt),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        _DetailsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(text: 'الملخص المالي'),
              SizedBox(height: 8.h),
              _InfoLine(
                title: 'الإجمالي الأولي',
                subtitle: _PurchaseMoney.format(details.totalBill),
              ),
              _InfoLine(
                title: 'الإجمالي النهائي',
                subtitle: _PurchaseMoney.format(details.finalTotal),
              ),
              _InfoLine(
                title: 'المدفوع',
                subtitle: _PurchaseMoney.format(details.paidAmount),
              ),
              _InfoLine(
                title: 'المتبقي',
                subtitle: _PurchaseMoney.format(details.remainingAmount),
              ),
              if (onAccountPayment != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: onAccountPayment,
                    icon: Icon(Icons.account_balance_wallet_outlined,
                        size: 16.sp),
                    label: const Text('دفعة على حساب المصدر'),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        _DetailsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(text: 'ملخص الاستلام'),
              SizedBox(height: 8.h),
              _InfoLine(
                  title: 'عدد الأصناف', subtitle: '${details.products.length}'),
              _InfoLine(title: 'المطلوب', subtitle: totalOrdered.toString()),
              _InfoLine(title: 'مستلم', subtitle: totalReceived.toString()),
              _InfoLine(title: 'متبقي', subtitle: totalRemaining.toString()),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        if (issueItems.isEmpty)
          const _EmptyTabState(text: 'لا توجد فروقات غير معالجة')
        else
          _InlineNotice(
            icon: Icons.report_problem_outlined,
            title: 'يوجد ${issueItems.length} فروقات مفتوحة',
            actionText: 'عرض الفروقات',
            onPressed: onIssuesTap,
          ),
      ],
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab({
    required this.details,
    required this.canPay,
    required this.onPay,
  });

  final BillDetailsModel details;
  final bool canPay;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MoneyBlock(
                label: 'الإجمالي',
                value: _PurchaseMoney.format(details.finalTotal),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _MoneyBlock(
                label: 'المدفوع',
                value: _PurchaseMoney.format(details.paidAmount),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _MoneyBlock(
                label: 'المتبقي',
                value: _PurchaseMoney.format(details.remainingAmount),
                highlighted: true,
              ),
            ),
          ],
        ),
        if (canPay) ...[
          SizedBox(height: 8.h),
          AppButton(
            text: 'تسجيل دفعة',
            isSafeArea: false,
            onPressed: onPay,
          ),
        ] else if (details.workflowStatus != 'finalized' &&
            details.paymentStatus != 'paid') ...[
          SizedBox(height: 8.h),
          const _InlineNotice(
            icon: Icons.lock_clock_outlined,
            title:
                'دفعة الفاتورة تتاح بعد الاستلام والاعتماد. لتسجيل مبلغ قبل الاعتماد استخدم دفعة على حساب المصدر من تبويب الملخص.',
          ),
        ],
        SizedBox(height: 12.h),
        const _SectionTitle(text: 'سجل الدفعات'),
        SizedBox(height: 8.h),
        if (details.payments.isEmpty)
          const _EmptyTabState(text: 'لا توجد دفعات مسجلة بعد')
        else
          ...details.payments.map((payment) => _PaymentCard(payment: payment)),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final PurchasePaymentUiModel payment;

  @override
  Widget build(BuildContext context) {
    return _DetailsCard(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${payment.paidAt} — ${_PurchaseMoney.format(payment.amount)}',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.sp),
          ),
          SizedBox(height: 4.h),
          _MutedText(
            text: [
              if (payment.boxName.isNotEmpty) payment.boxName,
              if (payment.paymentType.isNotEmpty) payment.paymentType,
              if (payment.note.isNotEmpty) payment.note,
            ].join(' • '),
          ),
        ],
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  const _ReturnCard({required this.ret});

  final PurchaseReturnUiModel ret;

  @override
  Widget build(BuildContext context) {
    return _DetailsCard(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'مرتجع #${ret.id}',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 13.sp),
                ),
              ),
              _StatusChip(label: 'الحالة', value: ret.status),
            ],
          ),
          SizedBox(height: 6.h),
          _MutedText(
            text:
                '${ret.createdAt} • ${ret.items.length} أصناف • ${_PurchaseMoney.format(ret.totalValue)}',
          ),
          if (ret.items.isNotEmpty) ...[
            SizedBox(height: 6.h),
            _MutedText(
              text: ret.items
                  .map((item) => '${item.productName} × ${item.quantity}')
                  .join(' • '),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentGroup extends StatelessWidget {
  const _AttachmentGroup({
    required this.title,
    required this.attachments,
  });

  final String title;
  final List<PurchaseAttachmentUiModel> attachments;

  @override
  Widget build(BuildContext context) {
    return _DetailsCard(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(text: title),
          SizedBox(height: 6.h),
          ...attachments
              .map((attachment) => _AttachmentRow(attachment: attachment)),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final title = event['title']?.toString() ?? '';
    final description = event['description']?.toString() ?? '';
    final createdAt = event['created_at']?.toString() ?? '';
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.history, color: AppColors.primaryColor, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? description : title,
                  style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 12.sp),
                ),
                if (description.isNotEmpty && title.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  _MutedText(text: description),
                ],
                if (createdAt.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  _MutedText(text: createdAt),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.title,
    this.actionText,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String? actionText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _ActionNoticeCard(
      icon: icon,
      title: title,
      buttonText: actionText,
      onPressed: onPressed,
    );
  }
}

class _EmptyTabState extends StatelessWidget {
  const _EmptyTabState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade700, fontSize: 12.sp),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.child,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(24),
            blurRadius: 6.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
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
    final hasDelivered = row.hasDeliveredEntry;
    final accepted = row.autoAccepted;
    final missing = row.autoMissing;
    final extra = row.effectiveExtra;
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
                child: OutlinedButton.icon(
                  onPressed: () {
                    row.deliveredNowController.text =
                        product.remainingQuantity.toString();
                    controller.update();
                  },
                  icon: Icon(Icons.done_all_outlined, size: 16.sp),
                  label: const Text('استلام كامل'),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    row.deliveredNowController.text = '0';
                    controller.update();
                  },
                  icon: Icon(Icons.remove_done_outlined, size: 16.sp),
                  label: const Text('لم يصل شيء'),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          CustomTextField(
            label: 'وصل فعلياً',
            hintText: 'أدخل الكمية التي وصلت من المورد',
            controller: row.deliveredNowController,
            keyboardType: TextInputType.number,
            onChanged: (_) => controller.update(),
            validator: (_) => null,
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(9.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                _StatusChip(
                  label: 'سيُضاف للمخزون',
                  value: hasDelivered ? accepted.toString() : '0',
                ),
                _StatusChip(
                  label: 'ناقص تلقائي',
                  value: hasDelivered ? missing.toString() : '0',
                ),
                if (extra > 0)
                  _StatusChip(label: 'أمانة', value: extra.toString()),
                if (row.damaged > 0)
                  _StatusChip(label: 'تالف', value: row.damaged.toString()),
                if (row.mismatched > 0)
                  _StatusChip(
                    label: 'غير مطابق',
                    value: row.mismatched.toString(),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _ReceivingIssueToggle(
                label: 'زائد / أمانة',
                selected: row.hasExtra,
                onSelected: (value) {
                  row.setIssueEnabled('extra', value);
                  controller.update();
                },
              ),
              _ReceivingIssueToggle(
                label: 'تالف',
                selected: row.hasDamaged,
                onSelected: (value) {
                  row.setIssueEnabled('damaged', value);
                  controller.update();
                },
              ),
              _ReceivingIssueToggle(
                label: 'غير مطابق',
                selected: row.hasMismatched,
                onSelected: (value) {
                  row.setIssueEnabled('mismatched', value);
                  controller.update();
                },
              ),
              _ReceivingIssueToggle(
                label: 'تعديل السعر',
                selected: row.editUnitPrice,
                onSelected: (value) {
                  row.setIssueEnabled('price', value);
                  controller.update();
                },
              ),
            ],
          ),
          if (row.hasExtra) ...[
            SizedBox(height: 8.h),
            CustomTextField(
              label: 'كمية الزائد / الأمانة',
              hintText: '0',
              controller: row.extraController,
              keyboardType: TextInputType.number,
              onChanged: (_) => controller.update(),
              validator: (_) => null,
            ),
          ],
          if (row.hasDamaged) ...[
            SizedBox(height: 8.h),
            CustomTextField(
              label: 'كمية التالف',
              hintText: '0',
              controller: row.damagedController,
              keyboardType: TextInputType.number,
              onChanged: (_) => controller.update(),
              validator: (_) => null,
            ),
          ],
          if (row.hasMismatched) ...[
            SizedBox(height: 8.h),
            CustomTextField(
              label: 'كمية غير المطابق',
              hintText: '0',
              controller: row.mismatchedController,
              keyboardType: TextInputType.number,
              onChanged: (_) => controller.update(),
              validator: (_) => null,
            ),
          ],
          if (row.editUnitPrice) ...[
            SizedBox(height: 8.h),
            CustomTextField(
              label: 'price',
              hintText: 'price',
              controller: row.unitPriceController,
              keyboardType: TextInputType.number,
              onChanged: (_) => controller.update(),
              validator: (_) => null,
            ),
          ],
          if (missing > 0 ||
              row.hasExtra ||
              row.hasDamaged ||
              row.hasMismatched) ...[
            SizedBox(height: 8.h),
            CustomTextField(
              label: 'سبب / وصف',
              hintText: 'سبب الفرق إن وجد',
              controller: row.reasonController,
              isRequired: false,
              validator: (_) => null,
            ),
          ],
          SizedBox(height: 8.h),
          _ReceivingValidityHint(row: row),
        ],
      ),
    );
  }
}

class _ReceivingIssueToggle extends StatelessWidget {
  const _ReceivingIssueToggle({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      selectedColor: AppColors.primaryColor,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.primaryColor : Colors.grey.shade300,
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.grey.shade800,
        fontWeight: FontWeight.w700,
        fontSize: 11.sp,
      ),
      onSelected: onSelected,
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

class _PurchaseDetailsSectionTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _PurchaseDetailsSectionTabs({
    required this.selected,
    required this.onChanged,
  });

  static const _sections = [
    _PurchaseDetailsSection(Icons.dashboard_outlined, 'ملخص'),
    _PurchaseDetailsSection(Icons.inventory_2_outlined, 'استلام'),
    _PurchaseDetailsSection(Icons.report_problem_outlined, 'مشاكل'),
    _PurchaseDetailsSection(Icons.handshake_outlined, 'أمانات'),
    _PurchaseDetailsSection(Icons.payments_outlined, 'دفعات'),
    _PurchaseDetailsSection(Icons.assignment_return_outlined, 'مرتجعات'),
    _PurchaseDetailsSection(Icons.attach_file_outlined, 'مرفقات'),
    _PurchaseDetailsSection(Icons.history, 'حركة'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_sections.length, (index) {
          final section = _sections[index];
          final isSelected = selected == index;
          return Padding(
            padding: EdgeInsetsDirectional.only(end: 8.w),
            child: ChoiceChip(
              selected: isSelected,
              avatar: Icon(
                section.icon,
                size: 15.sp,
                color: isSelected ? Colors.white : AppColors.primaryColor,
              ),
              label: Text(section.label),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade800,
                fontWeight: FontWeight.w700,
                fontSize: 11.sp,
              ),
              selectedColor: AppColors.primaryColor,
              backgroundColor: Colors.grey.shade50,
              side: BorderSide(
                color:
                    isSelected ? AppColors.primaryColor : Colors.grey.shade200,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              onSelected: (_) => onChanged(index),
            ),
          );
        }),
      ),
    );
  }
}

class _PurchaseDetailsSection {
  final IconData icon;
  final String label;

  const _PurchaseDetailsSection(this.icon, this.label);
}

class _PurchaseItemOverviewRow extends StatelessWidget {
  final BillProductModel item;

  const _PurchaseItemOverviewRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final missingQuantity = num.tryParse(item.missingAmount) ?? 0;
    final hasIssue = missingQuantity > 0 ||
        item.damagedQuantity > 0 ||
        item.mismatchedQuantity > 0;
    final hasAmanat = item.amanatStocks.any((a) => a.remainingQuantity > 0);
    final extraQuantity = num.tryParse(item.extraAmount) ?? 0;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              Icon(
                item.remainingQuantity <= 0
                    ? Icons.check_circle_outline
                    : Icons.pending_actions_outlined,
                color: item.remainingQuantity <= 0
                    ? const Color(0xFF15803D)
                    : AppColors.primaryColor,
                size: 18.sp,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              _StatusChip(
                label: 'مطلوب',
                value: item.orderedQuantity.toString(),
              ),
              _StatusChip(
                label: 'مستلم',
                value: item.receivedOwnedQuantity.toString(),
              ),
              _StatusChip(
                label: 'متبقي',
                value: item.remainingQuantity.toString(),
              ),
              if (missingQuantity > 0)
                _StatusChip(
                  label: 'ناقص',
                  value: missingQuantity.toString(),
                ),
              if (extraQuantity > 0)
                _StatusChip(
                  label: 'زائد',
                  value: extraQuantity.toString(),
                ),
              if (item.damagedQuantity > 0)
                _StatusChip(
                  label: 'تالف',
                  value: item.damagedQuantity.toString(),
                ),
              if (item.mismatchedQuantity > 0)
                _StatusChip(
                  label: 'غير مطابق',
                  value: item.mismatchedQuantity.toString(),
                ),
            ],
          ),
          if (hasIssue || hasAmanat) ...[
            SizedBox(height: 8.h),
            _MutedText(
              text: [
                if (hasIssue) 'يحتاج مراجعة من تبويب المشاكل',
                if (hasAmanat) 'يوجد أمانة مفتوحة',
              ].join(' • '),
            ),
          ],
        ],
      ),
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

class _IssueRow extends StatelessWidget {
  final BillProductModel product;
  final VoidCallback? onResolveMissing;
  final VoidCallback? onResolveDamaged;
  final VoidCallback? onResolveMismatched;

  const _IssueRow({
    required this.product,
    required this.onResolveMissing,
    required this.onResolveDamaged,
    required this.onResolveMismatched,
  });

  @override
  Widget build(BuildContext context) {
    final missingQuantity = num.tryParse(product.missingAmount) ?? 0;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              if (missingQuantity > 0)
                _StatusChip(
                  label: 'ناقص',
                  value: missingQuantity.toString(),
                ),
              if (product.damagedQuantity > 0)
                _StatusChip(
                  label: 'تالف',
                  value: product.damagedQuantity.toString(),
                ),
              if (product.mismatchedQuantity > 0)
                _StatusChip(
                  label: 'غير مطابق',
                  value: product.mismatchedQuantity.toString(),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              if (onResolveMissing != null)
                OutlinedButton.icon(
                  onPressed: onResolveMissing,
                  icon: const Icon(Icons.assignment_return_outlined),
                  label: const Text('تسوية النقص'),
                ),
              if (onResolveDamaged != null)
                OutlinedButton.icon(
                  onPressed: onResolveDamaged,
                  icon: const Icon(Icons.healing_outlined),
                  label: const Text('تسوية التالف'),
                ),
              if (onResolveMismatched != null)
                OutlinedButton.icon(
                  onPressed: onResolveMismatched,
                  icon: const Icon(Icons.compare_arrows_outlined),
                  label: const Text('تسوية غير مطابق'),
                ),
            ],
          ),
        ],
      ),
    );
  }
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
