import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../data/models/debt_ledger_models.dart';
import '../controllers/debt_ledger_controller.dart';
import 'ledger_activity_section.dart';
import 'ledger_colors.dart';
import 'ledger_currency_tab_bar.dart';
import 'ledger_format.dart';
import 'period_filter_sheet.dart';
import 'person_report_screen.dart';
import 'share_sheet.dart';

class PersonDetailScreen extends StatefulWidget {
  const PersonDetailScreen({Key? key}) : super(key: key);

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  @override
  void initState() {
    super.initState();
    final c = Get.find<DebtLedgerController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => c.loadPersonDetail());
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DebtLedgerController>();
    final person = controller.selectedPerson;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                person?.name ?? '',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 2.h),
              GestureDetector(
                onTap: () => _showContactSheet(context, person),
                child: Text(
                  'ledgerTapContact'.tr,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.delete_outline, size: 24.sp),
              color: Colors.grey.shade700,
              tooltip: 'ledgerDeletedTitle'.tr,
              onPressed: () => controller.openPersonDeleted(),
            ),
            IconButton(
              icon: Icon(Icons.folder_outlined, size: 26.sp),
              color: LedgerColors.primaryBlue,
              tooltip: 'ledgerArchiveTitle'.tr,
              onPressed: () => controller.openPersonArchive(),
            ),
            IconButton(
              icon: Icon(Icons.filter_list, size: 24.sp),
              onPressed: () => Get.bottomSheet(
                const PeriodFilterSheet(),
                isScrollControlled: true,
              ),
            ),
          ],
        ),
        body: Obx(() {
          final c = controller;
          if (c.personLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final detail = c.personDetail.value;
          if (detail == null) {
            return Center(child: Text('ledgerNoTransactions'.tr));
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  children: [
                    Obx(
                      () => LedgerCurrencyTabBar(
                        selected: c.selectedCurrency.value,
                        onSelected: c.changeCurrency,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(() {
                      final cur = c.selectedCurrency.value;
                      final stats =
                          c.personCurrencyBalance ?? detail.balanceFor(cur);
                      return _BalanceCard(
                        currency: cur,
                        balance: stats.balance,
                        totalTaken: stats.totalTaken,
                        totalGiven: stats.totalGiven,
                        color: c.balanceColor(stats.balance),
                        collectionLine:
                            c.collectionReminderLabel(detail.person),
                      );
                    }),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _QuickAction(
                          icon: Icons.note_alt_outlined,
                          label: 'ledgerNote'.tr,
                          onTap: c.openPersonNoteSheet,
                        ),
                        _QuickAction(
                          icon: Icons.phone_outlined,
                          label: 'ledgerCall'.tr,
                          onTap: c.callPerson,
                        ),
                        _QuickAction(
                          icon: Icons.share_outlined,
                          label: 'ledgerShare'.tr,
                          onTap: () => Get.bottomSheet(
                            const ShareOptionsSheet(),
                            isScrollControlled: true,
                          ),
                        ),
                        _QuickAction(
                          icon: Icons.notifications_active_outlined,
                          label: 'ledgerDebtCollection'.tr,
                          onTap: c.openCollectionReminderSheet,
                        ),
                        _QuickAction(
                          icon: Icons.picture_as_pdf_outlined,
                          label: 'ledgerReport'.tr,
                          onTap: () => Get.to(() => const PersonReportScreen()),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Obx(
                      () {
                        final cur = c.selectedCurrency.value;
                        final count =
                            c.personDetail.value?.transactions.length ?? 0;
                        return Row(
                          children: [
                            Text(
                              '${'ledgerTransactions'.tr} ($count) — $cur',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: LedgerColors.primaryBlue,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: c.openArchiveSheet,
                              borderRadius: BorderRadius.circular(8.r),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 4.h,
                                ),
                                child: Text(
                                  'ledgerArchive'.tr,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: LedgerColors.givenRed,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 10.h),
                    Obx(() {
                      final txs =
                          c.personDetail.value?.transactions ?? const [];
                      if (txs.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.h),
                          child: Center(
                            child: Text(
                              'ledgerNoTransactions'.tr,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: txs
                            .map(
                              (tx) => _TransactionCard(
                                transaction: tx,
                                onTap: () => c.openTransactionDetail(tx),
                              ),
                            )
                            .toList(),
                      );
                    }),
                    SizedBox(height: 16.h),
                    Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'ledgerActivityLogCurrency'.trParams({
                              'currency': c.selectedCurrency.value,
                            }),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          LedgerActivitySection(
                            entries: c.personActivity,
                            loading: c.personActivityLoading.value,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _BottomActions(controller: c),
            ],
          );
        }),
      ),
    );
  }

  void _showContactSheet(BuildContext context, LedgerPersonInfo? person) {
    if (person == null) return;
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              person.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            if (person.phone != null && person.phone!.isNotEmpty)
              ListTile(
                leading:
                    const Icon(Icons.phone, color: LedgerColors.primaryBlue),
                title: Text(person.phone!),
                onTap: () {
                  Get.back();
                  launchUrl(Uri.parse('tel:${person.phone}'));
                },
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text(
                  'ledgerNoPhone'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String currency;
  final double balance;
  final double totalTaken;
  final double totalGiven;
  final Color color;
  final String? collectionLine;

  const _BalanceCard({
    required this.currency,
    required this.balance,
    required this.totalTaken,
    required this.totalGiven,
    required this.color,
    this.collectionLine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'took'.tr,
                  amount: totalTaken,
                  currency: currency,
                  color: LedgerColors.takenGreen,
                ),
              ),
              Container(
                width: 1,
                height: 44.h,
                color: Colors.grey.shade200,
              ),
              Expanded(
                child: _StatColumn(
                  label: 'gave'.tr,
                  amount: totalGiven,
                  currency: currency,
                  color: LedgerColors.givenRed,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'ledgerBalance'.tr,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            LedgerFormat.money(balance, currency: currency, fractionDigits: 1),
            style: TextStyle(
              fontSize: 34.sp,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.1,
            ),
          ),
          if (collectionLine != null && collectionLine!.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              collectionLine!,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
        ),
        SizedBox(height: 4.h),
        Text(
          LedgerFormat.money(amount, currency: currency, fractionDigits: 1),
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: LedgerColors.primaryBlue,
              size: 22.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final LedgerTransaction transaction;
  final VoidCallback onTap;

  const _TransactionCard({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ledger = Get.find<DebtLedgerController>();
    final isTaken = transaction.isTaken;
    final color = isTaken ? LedgerColors.takenGreen : LedgerColors.givenRed;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(14),
                  bottom: transaction.receiptImages.isEmpty
                      ? const Radius.circular(14)
                      : Radius.zero,
                ),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        transaction.typeLabel,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      LedgerFormat.money(
                                        transaction.amount,
                                        currency: transaction.currency,
                                      ),
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Icon(
                                      isTaken
                                          ? Icons.south_east
                                          : Icons.north_east,
                                      size: 15.sp,
                                      color: color,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  LedgerFormat.labeled(
                                    'ledgerBalanceBefore'.tr,
                                    transaction.balanceBefore,
                                    currency: transaction.currency,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  ledger.formatTransactionTime(transaction),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Text(
                            LedgerFormat.money(
                              transaction.balanceAfter,
                              currency: transaction.currency,
                              fractionDigits: 1,
                            ),
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      if (transaction.displayDescription.isNotEmpty) ...[
                        SizedBox(height: 10.h),
                        Text(
                          transaction.displayDescription,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey.shade800,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (transaction.receiptImages.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
                  child: _ReceiptThumbnails(
                    images: transaction.receiptImages,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptThumbnails extends StatelessWidget {
  const _ReceiptThumbnails({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, index) {
          final url = ShowNetImage.getPhoto(images[index]);
          return GestureDetector(
            onTap: () => FullScreenZoomImage.open(context, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: url,
                    width: 72.w,
                    height: 72.h,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 72.w,
                      height: 72.h,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 72.w,
                      height: 72.h,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.zoom_in,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 22.sp,
                    shadows: const [
                      Shadow(
                        blurRadius: 6,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final DebtLedgerController controller;

  const _BottomActions({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _LedgerActionButton(
                label: 'gave'.tr,
                color: LedgerColors.givenRed,
                onPressed: () => controller.openTransactionEntry(type: 'given'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _LedgerActionButton(
                label: 'took'.tr,
                color: LedgerColors.takenGreen,
                onPressed: () => controller.openTransactionEntry(type: 'taken'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _LedgerActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
