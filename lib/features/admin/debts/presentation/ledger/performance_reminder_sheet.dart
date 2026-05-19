import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';
import 'ledger_performance_reminder_widget.dart';

class PerformanceReminderSheet extends StatefulWidget {
  const PerformanceReminderSheet({Key? key}) : super(key: key);

  @override
  State<PerformanceReminderSheet> createState() =>
      _PerformanceReminderSheetState();
}

class _PerformanceReminderSheetState extends State<PerformanceReminderSheet> {
  String _channel = 'whatsapp';
  bool _sending = false;
  String? _shareUrl;
  bool _loadingLink = true;

  @override
  void initState() {
    super.initState();
    _loadLink();
  }

  Future<void> _loadLink() async {
    final url = await Get.find<DebtLedgerController>().fetchPersonShareUrl();
    if (mounted) {
      setState(() {
        _shareUrl = url;
        _loadingLink = false;
      });
    }
  }

  Future<void> _send() async {
    if (_shareUrl == null || _shareUrl!.isEmpty) {
      Get.snackbar('error'.tr, 'ledgerShareLinkFailed'.tr);
      return;
    }
    setState(() => _sending = true);
    await Get.find<DebtLedgerController>().sendPerformanceReminder(
      channel: _channel,
      shareUrl: _shareUrl!,
    );
    if (mounted) {
      setState(() => _sending = false);
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DebtLedgerController>();
    final detail = controller.personDetail.value;
    final person = controller.selectedPerson;
    if (detail == null || person == null) {
      return const SizedBox.shrink();
    }

    final takenCount =
        detail.transactions.where((t) => t.isTaken).length;
    final givenCount =
        detail.transactions.where((t) => !t.isTaken).length;
    final timeLabel = controller.formatReminderTime();
    final smsMessage = controller.buildPerformanceReminderSmsMessage(
      _shareUrl ?? '',
    );
    final whatsappMessage = controller.buildPerformanceReminderWhatsappMessage(
      _shareUrl ?? '',
    );
    final messagePreview =
        _channel == 'sms' ? smsMessage : whatsappMessage;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.92.sh),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                    color: Colors.grey.shade700,
                  ),
                  Expanded(
                    child: Text(
                      'ledgerPerformanceReminder'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: LedgerColors.primaryBlue,
                      ),
                    ),
                  ),
                  SizedBox(width: 48.w),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                children: [
                  Expanded(
                    child: _ChannelChip(
                      label: 'WhatsApp',
                      selected: _channel == 'whatsapp',
                      selectedColor: LedgerColors.primaryBlue,
                      onTap: () => setState(() => _channel = 'whatsapp'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _ChannelChip(
                      label: 'SMS',
                      selected: _channel == 'sms',
                      selectedColor: LedgerColors.primaryBlue,
                      onTap: () => setState(() => _channel = 'sms'),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_channel == 'whatsapp') ...[
                      Center(
                        child: LedgerPerformanceReminderWidget(
                          personName: person.name,
                          timeLabel: timeLabel,
                          reminderTitle: 'ledgerPerformanceReminder'.tr,
                          balance: detail.balance,
                          totalTaken: detail.totalTaken,
                          totalGiven: detail.totalGiven,
                          takenCount: takenCount,
                          givenCount: givenCount,
                          takenLabel: 'took'.tr,
                          givenLabel: 'gave'.tr,
                          transactionsWord: 'ledgerTransactionsWord'.tr,
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'ledgerYourMessage'.tr,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: LedgerColors.primaryBlue,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (_loadingLink)
                      const Center(child: CircularProgressIndicator())
                    else
                      Text(
                        messagePreview,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade800,
                          height: 1.45,
                        ),
                      ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LedgerColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: _sending || _loadingLink ? null : _send,
                          child: _sending
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'ledgerSend'.tr,
                                  style: const TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: SizedBox(
                        height: 48.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LedgerColors.givenRed
                                .withValues(alpha: 0.85),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: _sending ? null : () => Get.back(),
                          child: Text(
                            'cancel'.tr,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _ChannelChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? selectedColor : selectedColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : selectedColor,
            ),
          ),
        ),
      ),
    );
  }
}
