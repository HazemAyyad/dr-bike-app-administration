import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../data/models/instant_sales_model.dart';
import '../utils/instant_sale_display.dart';

/// Who created / last edited an instant sale invoice.
class InstantSaleAuditInfo extends StatelessWidget {
  final InstantSalesModel sale;
  final bool compact;

  const InstantSaleAuditInfo({
    Key? key,
    required this.sale,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _compactLine(Icons.person_add_alt_1_outlined, sale.addedByDisplay),
          if (sale.hasEditor)
            _compactLine(Icons.edit_outlined, sale.editedByDisplay),
        ],
      );
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailLine(
            icon: Icons.person_add_alt_1_outlined,
            label: 'instantSaleAddedBy'.tr,
            value: sale.addedByDisplay,
          ),
          SizedBox(height: 8.h),
          _detailLine(
            icon: Icons.edit_outlined,
            label: 'instantSaleEditedBy'.tr,
            value: sale.editedByDisplay,
            muted: !sale.hasEditor,
          ),
        ],
      ),
    );
  }

  Widget _compactLine(IconData icon, String value) {
    return Padding(
      padding: EdgeInsets.only(top: 2.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: Colors.grey.shade600),
          SizedBox(width: 3.w),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailLine({
    required IconData icon,
    required String label,
    required String value,
    bool muted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.sp, color: AppColors.secondaryColor),
        SizedBox(width: 8.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade800,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: muted ? Colors.grey.shade600 : AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
