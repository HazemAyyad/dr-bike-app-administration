import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/widgets/skeleton_loading.dart';

/// Skeleton grid matching [InstantSaleProductPickerScreen] horizontal layout.
class InstantSaleProductPickerGridSkeleton extends StatelessWidget {
  const InstantSaleProductPickerGridSkeleton({
    Key? key,
    this.minRows = 2,
    this.maxRows = 4,
    this.visibleColumns = 4,
  }) : super(key: key);

  final int minRows;
  final int maxRows;
  final int visibleColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hGap = 6.w;
        final vGap = 6.h;
        final padH = 10.w;
        final gridW = constraints.maxWidth - padH * 2;
        final gridH = constraints.maxHeight;
        final minCellH = 82.h;
        final rows = ((gridH + vGap) / (minCellH + vGap))
            .floor()
            .clamp(minRows, maxRows);
        final cellW =
            (gridW - hGap * (visibleColumns - 1)) / visibleColumns;
        final cellH = (gridH - vGap * (rows - 1)) / rows;
        final aspectRatio = cellH / cellW;
        final itemCount = rows * visibleColumns;

        return GridView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: padH),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: rows,
            mainAxisSpacing: hGap,
            crossAxisSpacing: vGap,
            childAspectRatio: aspectRatio,
          ),
          itemCount: itemCount,
          itemBuilder: (_, __) => const _InstantSaleProductCardSkeleton(),
        );
      },
    );
  }
}

class _InstantSaleProductCardSkeleton extends StatelessWidget {
  const _InstantSaleProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: SkeletonBlock(
              width: double.infinity,
              height: double.infinity,
              radius: 0,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 4.h, 4.w, 2.h),
            child: SkeletonBlock(width: double.infinity, height: 8.h),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.h),
            child: Row(
              children: [
                Expanded(
                  child: SkeletonBlock(width: double.infinity, height: 7.h),
                ),
                SizedBox(width: 4.w),
                SkeletonBlock(width: 28.w, height: 14.h, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
