import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/debt_ledger_models.dart';
import 'ledger_colors.dart';

class LedgerActivitySection extends StatelessWidget {
  const LedgerActivitySection({
    Key? key,
    required this.entries,
    this.loading = false,
    this.showTitle = true,
  }) : super(key: key);

  final List<LedgerActivityEntry> entries;
  final bool loading;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text(
            'ledgerActivityLog'.tr,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: LedgerColors.primaryBlue,
            ),
          ),
          SizedBox(height: 8.h),
        ],
        if (loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (entries.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              'ledgerNoActivity'.tr,
              style: TextStyle(fontSize: 13.sp, color: Colors.grey),
            ),
          )
        else
          ...entries.map((e) => _ActivityTile(entry: e)),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.entry});

  final LedgerActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
              color: LedgerColors.primaryBlue,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            entry.description,
            style: TextStyle(fontSize: 12.sp, color: Colors.black87),
          ),
          if (entry.createdAt != null && entry.createdAt!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              entry.createdAt!,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}
