import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../data/models/suspended_instant_sale_model.dart';

/// Dialogs for suspended invoices.
class SuspendedInvoiceDialog {
  static const Color _headerGray = Color(0xFF6B7280);
  static const Color _bodyGray = Color(0xFFF5F6F8);
  static const Color _bodyText = Color(0xFF374151);
  static const Color _noteHeader = Color(0xFFE5E7EB);
  static const Color _noteBody = Colors.white;

  static Future<bool?> showConfirm({
    required BuildContext context,
    required String titleKey,
    required String messageKey,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFFD9D9D9).withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                color: _headerGray,
                child: Text(
                  titleKey.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: ThemeService.isDark.value
                    ? const Color(0xFF1F1F23)
                    : _bodyGray,
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      messageKey.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.45,
                        color: ThemeService.isDark.value
                            ? Colors.white70
                            : _bodyText,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text('cancel'.tr),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text('confirm'.tr),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<String?> showNotes({
    required BuildContext context,
    required SuspendedInstantSaleModel item,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (ctx) => _SuspendedInvoiceNotesDialog(item: item),
    );
  }

  /// Confirm dialogs only — gray header, white title (matches suspended-invoice UX).
}

class _SuspendedInvoiceNotesDialog extends StatefulWidget {
  const _SuspendedInvoiceNotesDialog({required this.item});

  final SuspendedInstantSaleModel item;

  @override
  State<_SuspendedInvoiceNotesDialog> createState() =>
      _SuspendedInvoiceNotesDialogState();
}

class _SuspendedInvoiceNotesDialogState
    extends State<_SuspendedInvoiceNotesDialog> {
  final TextEditingController noteCtrl = TextEditingController();

  static const Color _noteHeader = SuspendedInvoiceDialog._noteHeader;
  static const Color _noteBody = SuspendedInvoiceDialog._noteBody;
  static const Color _bodyText = SuspendedInvoiceDialog._bodyText;

  @override
  void dispose() {
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Dialog(
      backgroundColor: _noteBody,
      insetPadding: EdgeInsets.symmetric(horizontal: 18.w),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 0.82.sh),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                color: _noteHeader,
                child: Text(
                  'suspendedInvoiceNotes'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _bodyText,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: _noteBody,
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
                  child: Column(
                    children: [
                      Expanded(
                        child: item.noteLog.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 18.h),
                                  child: Text(
                                    'suspendedInvoiceNotesEmpty'.tr,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: _bodyText,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: item.noteLog.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 8.h),
                                itemBuilder: (_, index) {
                                  final note = item.noteLog[index];
                                  return Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(10.w),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          note.userName,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w700,
                                            color: _bodyText,
                                          ),
                                        ),
                                        if (note.createdAt.isNotEmpty)
                                          Text(
                                            note.createdAt,
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              color: const Color(0xFF6B7280),
                                            ),
                                          ),
                                        SizedBox(height: 5.h),
                                        Text(
                                          note.note,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            height: 1.35,
                                            color: _bodyText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      SizedBox(height: 12.h),
                      TextField(
                        controller: noteCtrl,
                        minLines: 2,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'suspendedInvoiceNoteHint'.tr,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                        ),
                        style: const TextStyle(color: _bodyText),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'cancel'.tr,
                                style: const TextStyle(color: _bodyText),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _noteHeader,
                                foregroundColor: _bodyText,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                              onPressed: () {
                                final value = noteCtrl.text.trim();
                                if (value.isEmpty) return;
                                Navigator.of(context).pop(value);
                              },
                              child: Text('save'.tr),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
