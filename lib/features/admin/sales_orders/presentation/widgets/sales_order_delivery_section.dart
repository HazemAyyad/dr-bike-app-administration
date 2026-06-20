import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/sales_order_model.dart';
import '../controllers/sales_orders_controller.dart';
import 'sales_order_shiply_address_fields.dart';
import 'sales_order_shiply_sandbox_badge.dart';

/// Delivery company + address fields on checkout / edit.
class SalesOrderDeliverySection extends GetView<SalesOrdersController> {
  const SalesOrderDeliverySection({
    Key? key,
    this.parcelPriceForFee = 0,
  }) : super(key: key);

  final double parcelPriceForFee;

  InputDecoration _fieldDecoration(String hint, {bool floatingLabel = false}) {
    return InputDecoration(
      hintText: floatingLabel ? null : hint,
      labelText: floatingLabel ? hint : null,
      hintStyle: const TextStyle(color: SalesOrdersController.textSecondary),
      labelStyle: const TextStyle(color: SalesOrdersController.textSecondary),
      filled: true,
      fillColor: SalesOrdersController.cardGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: SalesOrdersController.borderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: SalesOrdersController.borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: SalesOrdersController.textPrimary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final companies = controller.deliveryCompanies;
      if (companies.isEmpty) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Text(
            'salesOrderDeliveryCompaniesEmpty'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              color: SalesOrdersController.textSecondary,
            ),
          ),
        );
      }

      final selectedId = controller.selectedDeliveryCompanyId.value;
      final isShiply = controller.isSelectedCompanyShiply;
      final isDoctorBike = controller.isSelectedCompanyDoctorBike;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'salesOrderDeliverySectionTitle'.tr,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: SalesOrdersController.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<int>(
            initialValue: companies.any((c) => c.id == selectedId) ? selectedId : null,
            dropdownColor: SalesOrdersController.cardGray,
            style: TextStyle(
              color: SalesOrdersController.textPrimary,
              fontSize: 14.sp,
            ),
            decoration: _fieldDecoration('salesOrderDeliveryCompany'.tr),
            items: companies
                .map(
                  (DeliveryCompanyModel c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(controller.deliveryCompanyLabel(c)),
                  ),
                )
                .toList(),
            onChanged: controller.onDeliveryCompanyChanged,
          ),
          SizedBox(height: 12.h),
          if (isShiply) ...[
            SalesOrderShiplySandboxBadge(controller: controller),
            SalesOrderShiplyAddressFields(
              controller: controller,
              parcelPriceForFee: parcelPriceForFee,
            ),
          ] else if (isDoctorBike) ...[
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                'salesOrderDoctorBikeDeliveryHint'.tr,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: SalesOrdersController.textSecondary,
                ),
              ),
            ),
          ] else ...[
            TextField(
              controller: controller.customerAddressController,
              maxLines: 2,
              style: TextStyle(
                color: SalesOrdersController.textPrimary,
                fontSize: 14.sp,
              ),
              decoration: _fieldDecoration(
                'salesOrderStreetAddress'.tr,
                floatingLabel: true,
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: controller.deliveryFeeController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: SalesOrdersController.textPrimary,
                fontSize: 14.sp,
              ),
              decoration: _fieldDecoration(
                'salesOrderDeliveryFeeInput'.tr,
                floatingLabel: true,
              ),
              onChanged: (_) => controller.onDeliveryFeeChanged(),
            ),
          ],
        ],
      );
    });
  }
}
