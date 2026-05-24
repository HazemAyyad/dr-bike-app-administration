import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../controllers/debt_ledger_controller.dart';
import 'ledger_activity_section.dart';
import 'ledger_colors.dart';
import 'ledger_format.dart';

class TransactionDetailScreen extends GetView<DebtLedgerController> {
  const TransactionDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tx = controller.selectedTransaction.value;
      if (tx == null) {
        return Scaffold(
          appBar: AppBar(title: Text('ledgerTransactions'.tr)),
          body: Center(child: Text('ledgerNoTransactions'.tr)),
        );
      }

      final isTaken = tx.isTaken;
      final color = isTaken ? LedgerColors.takenGreen : LedgerColors.givenRed;
      final personName = controller.selectedPerson?.name ?? '';
      final balanceColor = controller.balanceColor(tx.balanceAfter);

      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              personName,
              style: TextStyle(
                color: LedgerColors.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 17.sp,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: LedgerColors.primaryBlue,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.formatTransactionTime(tx),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                tx.typeLabel,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                LedgerFormat.money(tx.amount, currency: tx.currency, fractionDigits: 1),
                                style: TextStyle(
                                  fontSize: 36.sp,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                  height: 1.05,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: balanceColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: balanceColor.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              LedgerFormat.labeled(
                                'ledgerBalance'.tr,
                                tx.balanceAfter,
                                currency: tx.currency,
                                fractionDigits: 1,
                              ),
                              style: TextStyle(
                                color: balanceColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          if (tx.displayDescription.isNotEmpty) ...[
                            SizedBox(height: 12.h),
                            Text(
                              tx.displayDescription,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey.shade800,
                                height: 1.35,
                              ),
                            ),
                          ],
                          if (tx.receiptImages.isNotEmpty) ...[
                            SizedBox(height: 16.h),
                            Text(
                              'ledgerReceiptImages'.tr,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _ReceiptImagesGallery(images: tx.receiptImages),
                          ],
                          SizedBox(height: 20.h),
                          Obx(
                            () => LedgerActivitySection(
                              entries: controller.transactionActivity,
                              loading: controller.transactionActivityLoading.value,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 28.w),
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: LedgerColors.cardBlue,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: () => controller.openEditTransaction(tx),
                              customBorder: const CircleBorder(),
                              child: SizedBox(
                                width: 48.w,
                                height: 48.w,
                                child: Icon(
                                  Icons.edit_outlined,
                                  color: LedgerColors.primaryBlue,
                                  size: 24.sp,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'edit'.tr,
                            style: TextStyle(
                              color: LedgerColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48.h,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: LedgerColors.givenRed,
                              side: BorderSide(color: LedgerColors.givenRed),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onPressed: () =>
                                controller.deleteTransaction(tx.id),
                            child: Text(
                              'delete'.tr,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: SizedBox(
                          height: 48.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LedgerColors.primaryBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onPressed: () =>
                                controller.archiveTransactionFromDetail(tx.id),
                            child: Text(
                              'ledgerArchive'.tr,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: double.infinity,
                    height: 46.h,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LedgerColors.primaryBlue,
                        side: BorderSide(
                          color: LedgerColors.primaryBlue.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () =>
                          controller.openTransactionShareSheet(tx),
                      icon: Icon(Icons.share_outlined, size: 20.sp),
                      label: Text(
                        'Share'.tr,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _ReceiptImagesGallery extends StatelessWidget {
  const _ReceiptImagesGallery({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: List.generate(images.length, (index) {
        final url = ShowNetImage.getPhoto(images[index]);
        return GestureDetector(
          onTap: () => FullScreenZoomImage.open(context, url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: url,
                  width: 108.w,
                  height: 108.w,
                  fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 108.w,
                height: 108.w,
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
                  errorWidget: (_, __, ___) => Container(
                    width: 108.w,
                    height: 108.w,
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey.shade500,
                      size: 32.sp,
                    ),
                  ),
                ),
                Icon(
                  Icons.zoom_in,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: 28.sp,
                  shadows: const [
                    Shadow(blurRadius: 8, color: Colors.black54),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
