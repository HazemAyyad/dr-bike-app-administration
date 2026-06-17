import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../routes/app_routes.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../employee/my_orders/widgets/row_text.dart';
import '../../data/models/invoice_model.dart';
import '../controllers/sales_controller.dart';
import '../widgets/invoice_package_expandable_line.dart';
import '../widgets/proudact_details_widget.dart';

class BillDetailsScreen extends GetView<SalesController> {
  const BillDetailsScreen({Key? key}) : super(key: key);

  String _dash(String? v) => (v == null || v.trim().isEmpty) ? '-' : v.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'billDetails', action: false),
      body: GetBuilder<SalesController>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.invoiceModel == null) {
            return const Center(child: ShowNoData());
          }

          final invoice = controller.invoiceModel!;
          final fmt = NumberFormat('#,###.##');

          return CustomScrollView(
            slivers: [
              if (invoice.salesOrderId != null)
                SliverToBoxAdapter(
                  child: _SalesOrderLinkCard(
                    orderId: invoice.salesOrderId!,
                    serial: invoice.salesOrderSerial,
                  ),
                ),
              SliverToBoxAdapter(
                child: _InvoiceHeaderCard(
                  invoiceNumber: _dash(invoice.invoiceNumber),
                  invoiceDate: _dash(invoice.invoiceDate),
                  buyerTypeLabel: invoice.displayBuyerTypeLabel,
                  buyerName: _dash(invoice.buyerName),
                  phone: _dash(invoice.buyerPhone ?? invoice.phone),
                  address: _dash(invoice.buyerAddress ?? invoice.address),
                  paymentMethod: _dash(invoice.paymentMethod),
                  paymentBoxName: invoice.displayPaymentBox,
                  saleStatus: invoice.displaySaleStatus,
                  notes: _dash(invoice.notes),
                  additionalNotes: invoice.additionalNotes,
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 12.h)),
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  height: 32.h,
                  decoration: BoxDecoration(
                    color: ThemeService.isDark.value
                        ? AppColors.secondaryColor
                        : AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox.shrink(),
                      Flexible(child: RowText(title: 'productName')),
                      Flexible(child: RowText(title: 'quantity')),
                      Flexible(child: RowText(title: 'price')),
                      Flexible(child: RowText(title: 'total')),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 10.h)),
              if (invoice.isPackageSale &&
                  invoice.packageComponentLines.isNotEmpty)
                SliverToBoxAdapter(
                  child: InvoicePackageExpandableLine(invoice: invoice),
                )
              else if (invoice.isPackageSale)
                SliverToBoxAdapter(
                  child: ProudactDetailsWidget(
                    image: invoice.productImage,
                    cost: invoice.cost.toString(),
                    product: invoice.displayProductTitle,
                    quantity: invoice.quantity.toString(),
                    subtotal: invoice.subtotal,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        return ProudactDetailsWidget(
                          image: invoice.productImage,
                          cost: invoice.cost.toString(),
                          product: invoice.displayProductTitle,
                          quantity: invoice.quantity.toString(),
                          subtotal: invoice.subtotal,
                        );
                      }
                      final sub = invoice.subProducts[index - 1];
                      return ProudactDetailsWidget(
                        image: sub.productImage,
                        cost: sub.cost.toString(),
                        product: sub.displayProductName,
                        quantity: sub.quantity.toString(),
                        subtotal: sub.subtotal,
                      );
                    },
                    childCount: 1 + invoice.subProducts.length,
                  ),
                ),
              if (invoice.isPackageSale &&
                  invoice.additionalProductLines.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 6.h),
                    child: Text(
                      'instantSaleAdditionalProducts'.tr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                            fontSize: 14.sp,
                          ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sub = invoice.additionalProductLines[index];
                      return ProudactDetailsWidget(
                        image: sub.productImage,
                        cost: sub.cost,
                        product: sub.displayProductName,
                        quantity: sub.quantity,
                        subtotal: sub.subtotal,
                      );
                    },
                    childCount: invoice.additionalProductLines.length,
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: _InvoiceAdditionalNotesSection(
                  notes: invoice.additionalNotes,
                ),
              ),
              SliverToBoxAdapter(
                child: _InvoiceTotalsSection(
                  subtotal: fmt.format(double.tryParse(invoice.subtotal) ?? 0),
                  discount: fmt.format(double.tryParse(invoice.discount) ?? 0),
                  notesTotal: fmt.format(
                    double.tryParse(invoice.additionalNotesTotal) ?? 0,
                  ),
                  tax: fmt.format(double.tryParse(invoice.tax) ?? 0),
                  paid: fmt.format(double.tryParse(invoice.paidAmount) ?? 0),
                  remaining:
                      fmt.format(double.tryParse(invoice.remainingAmount) ?? 0),
                  total: fmt.format(double.tryParse(invoice.totalCost) ?? 0),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            ],
          );
        },
      ),
    );
  }
}

class _InvoiceHeaderCard extends StatelessWidget {
  const _InvoiceHeaderCard({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.buyerTypeLabel,
    required this.buyerName,
    required this.phone,
    required this.address,
    required this.paymentMethod,
    required this.paymentBoxName,
    required this.saleStatus,
    required this.notes,
    required this.additionalNotes,
  });

  final String invoiceNumber;
  final String invoiceDate;
  final String buyerTypeLabel;
  final String buyerName;
  final String phone;
  final String address;
  final String paymentMethod;
  final String paymentBoxName;
  final String saleStatus;
  final String notes;
  final List<InvoiceAdditionalNote> additionalNotes;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 0),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _metaRow(context, 'billNumber'.tr, invoiceNumber),
          _metaRow(context, 'date'.tr, invoiceDate),
          _metaRow(
            context,
            'buyerTypeSale'.tr,
            buyerTypeLabel,
            highlight: true,
          ),
          _metaRow(context, 'buyerName'.tr, buyerName),
          _metaRow(context, 'phoneNumberTitle'.tr, phone),
          _metaRow(context, 'address'.tr, address),
          Divider(height: 16.h),
          _metaRow(context, 'paymentMethod'.tr, paymentMethod),
          if (paymentBoxName != '-')
            _metaRow(context, 'boxName'.tr, paymentBoxName, highlight: true),
          _metaRow(context, 'status'.tr, saleStatus),
          if (notes != '-' && additionalNotes.isEmpty)
            _metaRow(context, 'notes'.tr, notes),
        ],
      ),
    );
  }

  Widget _metaRow(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.customGreyColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                    fontSize: highlight ? 13.sp : 12.sp,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceAdditionalNotesSection extends StatelessWidget {
  const _InvoiceAdditionalNotesSection({required this.notes});

  final List<InvoiceAdditionalNote> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'additionalNotes'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                  fontSize: 14.sp,
                ),
          ),
          SizedBox(height: 6.h),
          ...notes.map(
            (note) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      note.text.trim().isEmpty ? '-' : note.text,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    '${note.amount} ${'currency'.tr}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceTotalsSection extends StatelessWidget {
  const _InvoiceTotalsSection({
    required this.subtotal,
    required this.discount,
    required this.notesTotal,
    required this.tax,
    required this.paid,
    required this.remaining,
    required this.total,
  });

  final String subtotal;
  final String discount;
  final String notesTotal;
  final String tax;
  final String paid;
  final String remaining;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 1.h,
            width: double.infinity,
            color: AppColors.primaryColor,
          ),
          SizedBox(height: 10.h),
          _totalLine(context, 'subtotal'.tr, subtotal),
          _totalLine(context, 'discount'.tr, discount),
          if (notesTotal != '0')
            _totalLine(context, 'notesTotal'.tr, notesTotal),
          _totalLine(context, 'tax'.tr, tax),
          _totalLine(context, 'totalBill'.tr, total, bold: true),
          SizedBox(height: 4.h),
          _totalLine(context, 'paidAmount'.tr, paid),
          _totalLine(context, 'remainingAmount'.tr, remaining),
        ],
      ),
    );
  }

  Widget _totalLine(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  fontSize: bold ? 14.sp : 13.sp,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  fontSize: bold ? 14.sp : 13.sp,
                ),
          ),
        ],
      ),
    );
  }
}

class _SalesOrderLinkCard extends StatelessWidget {
  const _SalesOrderLinkCard({
    required this.orderId,
    this.serial,
  });

  final int orderId;
  final String? serial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 0),
      child: Material(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: () => Get.toNamed(
            AppRoutes.SALESORDERDETAILSCREEN,
            arguments: orderId,
          ),
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 20.sp, color: const Color(0xFF2563EB)),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'salesOrderLinkedInvoice'.tr,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                      Text(
                        serial ?? '#$orderId',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left,
                    color: const Color(0xFF2563EB), size: 22.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
