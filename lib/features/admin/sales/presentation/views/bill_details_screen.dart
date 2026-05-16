import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../employee/my_orders/widgets/row_text.dart';
import '../controllers/sales_controller.dart';
import '../widgets/proudact_details_widget.dart';

class BillDetailsScreen extends GetView<SalesController> {
  const BillDetailsScreen({Key? key}) : super(key: key);

  String _dash(String? v) =>
      (v == null || v.trim().isEmpty) ? '-' : v.trim();

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
              SliverToBoxAdapter(
                child: _InvoiceHeaderCard(
                  traderName: invoice.displayTraderName,
                  phone: _dash(invoice.phone),
                  address: _dash(invoice.address),
                  invoiceNumber: _dash(invoice.invoiceNumber),
                  invoiceDate: _dash(invoice.invoiceDate),
                  paymentMethod: _dash(invoice.paymentMethod),
                  saleStatus: _dash(invoice.saleStatus),
                  notes: _dash(invoice.notes),
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
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return ProudactDetailsWidget(
                        image: invoice.productImage,
                        cost: invoice.cost.toString(),
                        product: invoice.product.toString(),
                        quantity: invoice.quantity.toString(),
                        subtotal: invoice.subtotal,
                      );
                    }
                    final sub = invoice.subProducts[index - 1];
                    return ProudactDetailsWidget(
                      image: sub.productImage,
                      cost: sub.cost.toString(),
                      product: sub.productName.toString(),
                      quantity: sub.quantity.toString(),
                      subtotal: sub.subtotal,
                    );
                  },
                  childCount: 1 + invoice.subProducts.length,
                ),
              ),
              SliverToBoxAdapter(
                child: _InvoiceTotalsSection(
                  subtotal: fmt.format(double.tryParse(invoice.subtotal) ?? 0),
                  discount: fmt.format(double.tryParse(invoice.discount) ?? 0),
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
    required this.traderName,
    required this.phone,
    required this.address,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.paymentMethod,
    required this.saleStatus,
    required this.notes,
  });

  final String traderName;
  final String phone;
  final String address;
  final String invoiceNumber;
  final String invoiceDate;
  final String paymentMethod;
  final String saleStatus;
  final String notes;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            traderName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 6.h),
          _metaRow(context, 'phoneNumberTitle'.tr, phone),
          _metaRow(context, 'address'.tr, address),
          Divider(height: 16.h),
          _metaRow(context, 'billNumber'.tr, invoiceNumber),
          _metaRow(context, 'date'.tr, invoiceDate),
          _metaRow(context, 'paymentMethod'.tr, paymentMethod),
          _metaRow(context, 'status'.tr, saleStatus),
          if (notes != '-') _metaRow(context, 'notes'.tr, notes),
        ],
      ),
    );
  }

  Widget _metaRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.customGreyColor,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
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
    required this.tax,
    required this.paid,
    required this.remaining,
    required this.total,
  });

  final String subtotal;
  final String discount;
  final String tax;
  final String paid;
  final String remaining;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            height: 1.h,
            width: double.infinity,
            color: AppColors.primaryColor,
          ),
          SizedBox(height: 10.h),
          _totalLine(context, 'subtotal'.tr, subtotal),
          _totalLine(context, 'discount'.tr, discount),
          _totalLine(context, 'tax'.tr, tax),
          _totalLine(context, 'paidAmount'.tr, paid),
          _totalLine(context, 'remainingAmount'.tr, remaining),
          SizedBox(height: 6.h),
          _totalLine(
            context,
            'totalBill'.tr,
            total,
            bold: true,
          ),
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
      child: Text(
        '$label : $value',
        textAlign: TextAlign.end,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              fontSize: bold ? 14.sp : 13.sp,
            ),
      ),
    );
  }
}
