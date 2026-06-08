import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../data/models/all_stock_products_model.dart';
import '../../domain/product_location_utils.dart';
import 'product_location_badge.dart';
import 'product_location_modal_shell.dart';

String? _locationLabel(AllStockProductsModel product) {
  return ProductLocationLabel.withProductCode(
    sectionName: product.storeSectionName,
    shelfNumber: product.shelfNumber,
    productCode: product.productCode,
  );
}

String _locationOrUnset(String? label) =>
    (label?.trim().isNotEmpty == true) ? label!.trim() : 'noLocationAssigned'.tr;

Widget _compactLocationLine({
  required String from,
  required String to,
  Color? toColor,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          from,
          style: TextStyle(
            fontSize: 9.sp,
            color: AppColors.customGreyColor5,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Icon(
          Icons.arrow_forward,
          size: 12.sp,
          color: AppColors.customGreyColor5,
        ),
      ),
      Expanded(
        child: Text(
          to,
          style: TextStyle(
            fontSize: 9.sp,
            fontWeight: FontWeight.w700,
            color: toColor ?? AppColors.operationalNavy,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
        ),
      ),
    ],
  );
}

Future<bool> showProductLocationMoveConfirm(
  BuildContext context, {
  required List<AllStockProductsModel> products,
  required String targetSectionName,
  String? targetShelf,
}) async {
  final targetLabel = ProductLocationLabel.withProductCode(
    sectionName: targetSectionName,
    shelfNumber: targetShelf,
  );
  final targetText = _locationOrUnset(targetLabel);

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ProductLocationModalShell(
      title: 'locationMoveConfirmTitle'.tr,
      onCancel: () => Navigator.pop(ctx, false),
      onConfirm: () => Navigator.pop(ctx, true),
      body: ListView(
        padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 12.h),
        children: [
          ProductLocationNeutralCard(
            icon: Icons.drive_file_move_outline,
            title: 'targetLocation'.tr,
            subtitle: targetText,
          ),
          SizedBox(height: 6.h),
          Text(
            'locationMoveConfirmSubtitle'.trParams({
              'count': products.length.toString(),
            }),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.operationalNavy,
            ),
          ),
          SizedBox(height: 6.h),
          _CompactProductList(
            children: products
                .map(
                  (product) => _CompactProductRow(
                    name: product.name,
                    code: product.productCode,
                    from: _locationOrUnset(_locationLabel(product)),
                    to: targetText,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
  );

  return result == true;
}

Future<bool> showProductLocationSwapConfirm(
  BuildContext context, {
  required List<AllStockProductsModel> groupA,
  required List<AllStockProductsModel> groupB,
  SwapGroupTargets targets = const SwapGroupTargets(),
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ProductLocationModalShell(
      title: 'locationSwapConfirmTitle'.tr,
      onCancel: () => Navigator.pop(ctx, false),
      onConfirm: () => Navigator.pop(ctx, true),
      body: ListView(
        padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 12.h),
        children: [
          ProductLocationNeutralCard(
            icon: Icons.swap_horiz_rounded,
            title: 'swapGroupsSummary'.tr,
            subtitle: 'swapGroupsCount'.trParams({
              'countA': groupA.length.toString(),
              'countB': groupB.length.toString(),
            }),
            accentColor: AppColors.customOrange3,
          ),
          if (targets.groupA != null) ...[
            SizedBox(height: 6.h),
            ProductLocationNeutralCard(
              icon: Icons.place_outlined,
              title: 'swapGroupADestination'.tr,
              subtitle: targets.groupA!.displayLabel,
            ),
          ],
          if (targets.groupB != null) ...[
            SizedBox(height: 6.h),
            ProductLocationNeutralCard(
              icon: Icons.place_outlined,
              title: 'swapGroupBDestination'.tr,
              subtitle: targets.groupB!.displayLabel,
              accentColor: AppColors.customOrange3,
            ),
          ],
          SizedBox(height: 6.h),
          Text(
            'swapGroupsBulkHint'.tr,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.customGreyColor5,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          _CompactSwapGroupBlock(
            title: '${'swapGroupA'.tr} (${groupA.length})',
            products: groupA,
            groupTarget: targets.groupA,
          ),
          SizedBox(height: 6.h),
          _CompactSwapGroupBlock(
            title: '${'swapGroupB'.tr} (${groupB.length})',
            products: groupB,
            groupTarget: targets.groupB,
          ),
        ],
      ),
    ),
  );

  return result == true;
}

class _CompactProductList extends StatelessWidget {
  const _CompactProductList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.operationalCardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.operationalCardBorder),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _CompactProductRow extends StatelessWidget {
  const _CompactProductRow({
    required this.name,
    required this.code,
    required this.from,
    required this.to,
    this.toColor,
    this.badge,
  });

  final String name;
  final String code;
  final String from;
  final String to;
  final Color? toColor;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.operationalNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[
                SizedBox(width: 4.w),
                Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.customGreyColor5,
                  ),
                ),
              ],
              if (code.isNotEmpty) ...[
                SizedBox(width: 4.w),
                Text(
                  '#$code',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: AppColors.customGreyColor5,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 3.h),
          _compactLocationLine(from: from, to: to, toColor: toColor),
        ],
      ),
    );
  }
}

class _CompactSwapGroupBlock extends StatelessWidget {
  const _CompactSwapGroupBlock({
    required this.title,
    required this.products,
    required this.groupTarget,
  });

  final String title;
  final List<AllStockProductsModel> products;
  final SwapGroupLocationTarget? groupTarget;

  @override
  Widget build(BuildContext context) {
    final toLabel = groupTargetLabel(
      groupTarget,
      unsetLabel: 'noLocationAssigned'.tr,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 4.h, left: 2.w),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.operationalNavy,
            ),
          ),
        ),
        _CompactProductList(
          children: products.map((product) {
            return _CompactProductRow(
              name: product.name,
              code: product.productCode,
              from: _locationOrUnset(_locationLabel(product)),
              to: toLabel,
              badge: !productHasAssignedLocation(product)
                  ? 'productHasNoLocationBadge'.tr
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }
}
