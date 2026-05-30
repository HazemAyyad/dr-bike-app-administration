import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/helpers/auth_logo.dart';
import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';
import 'ledger_format.dart';

class LedgerTransactionSuccessScreen extends StatefulWidget {
  final String personName;
  final String type;
  final String typeLabel;
  final double amount;
  final String currency;
  final double balanceAfter;
  final String timeLabel;

  const LedgerTransactionSuccessScreen({
    Key? key,
    required this.personName,
    required this.type,
    required this.typeLabel,
    required this.amount,
    required this.currency,
    required this.balanceAfter,
    required this.timeLabel,
  }) : super(key: key);

  @override
  State<LedgerTransactionSuccessScreen> createState() =>
      _LedgerTransactionSuccessScreenState();
}

class _LedgerTransactionSuccessScreenState
    extends State<LedgerTransactionSuccessScreen> {
  Timer? _autoCloseTimer;
  bool _userInteracted = false;

  bool get _isTaken => widget.type == 'taken';

  Color get _amountColor =>
      _isTaken ? LedgerColors.takenGreen : LedgerColors.givenRed;

  @override
  void initState() {
    super.initState();
    _autoCloseTimer = Timer(const Duration(seconds: 1), _finish);
  }

  void _cancelAutoClose() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = null;
  }

  void _finish() {
    if (!mounted) return;
    final ledger = Get.find<DebtLedgerController>();
    ledger.loadPersonDetail();
    ledger.fetchSummary();
    Get.back(result: true);
  }

  void _onUserTap(VoidCallback action) {
    if (_userInteracted) {
      action();
      return;
    }
    _userInteracted = true;
    _cancelAutoClose();
    action();
  }

  void _share() {
    final text = '${widget.personName}\n'
        '${widget.typeLabel}: ${LedgerFormat.money(widget.amount, currency: widget.currency)}\n'
        '${LedgerFormat.labeled('ledgerBalance'.tr, widget.balanceAfter, currency: widget.currency)}\n'
        '${widget.timeLabel}';

    SharePlus.instance.share(ShareParams(text: text));
    _finish();
  }

  @override
  void dispose() {
    _cancelAutoClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balanceColor =
        Get.find<DebtLedgerController>().balanceColor(widget.balanceAfter);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                SizedBox(height: 28.h),
                Text(
                  'ledgerTransactionSuccessTitle'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: LedgerColors.primaryBlue,
                  ),
                ),
                SizedBox(height: 24.h),
                Expanded(
                  child: Center(
                    child: _SuccessCard(
                      personName: widget.personName,
                      timeLabel: widget.timeLabel,
                      typeLabel: widget.typeLabel,
                      amount: widget.amount,
                      currency: widget.currency,
                      amountColor: _amountColor,
                      balanceAfter: widget.balanceAfter,
                      balanceColor: balanceColor,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Share'.tr,
                        filled: true,
                        onPressed: () => _onUserTap(_share),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _ActionButton(
                        label: 'ledgerFinish'.tr,
                        filled: false,
                        onPressed: () => _onUserTap(_finish),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  final String personName;
  final String timeLabel;
  final String typeLabel;
  final double amount;
  final String currency;
  final Color amountColor;
  final double balanceAfter;
  final Color balanceColor;

  const _SuccessCard({
    required this.personName,
    required this.timeLabel,
    required this.typeLabel,
    required this.amount,
    required this.currency,
    required this.amountColor,
    required this.balanceAfter,
    required this.balanceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 320.w),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            personName,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: LedgerColors.primaryBlue,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            timeLabel,
            style: TextStyle(
              fontSize: 13.sp,
              color: LedgerColors.primaryBlue.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'ledgerNewTransaction'.tr,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A3A6B),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            LedgerFormat.money(amount, currency: currency),
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.bold,
              color: amountColor,
              height: 1.1,
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: balanceColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: balanceColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              LedgerFormat.labeled(
                'ledgerBalance'.tr,
                balanceAfter,
                currency: currency,
              ),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: balanceColor,
              ),
            ),
          ),
          SizedBox(height: 28.h),
          SizedBox(
            height: 48.h,
            child: const AppLogo(),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50.h,
      child: filled
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LedgerColors.primaryBlue,
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
                  color: Colors.white,
                ),
              ),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: LedgerColors.cardBlue,
                side: BorderSide.none,
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
                  color: LedgerColors.primaryBlue,
                ),
              ),
            ),
    );
  }
}
