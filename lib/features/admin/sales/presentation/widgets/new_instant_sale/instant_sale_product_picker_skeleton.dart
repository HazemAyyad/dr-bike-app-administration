import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/utils/desktop_layout.dart';
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
        final desktop = DesktopLayout.isDesktop(context);
        final columns = DesktopLayout.gridColumnsForWidth(
          constraints.maxWidth - padH * 2,
          minTileWidth: desktop ? 190 : 152.w,
          min: desktop ? 4 : minRows,
          max: desktop ? 8 : 10,
          gap: hGap,
        );
        final itemCount = columns * (desktop ? 4 : visibleColumns);

        return GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: padH),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: hGap,
            crossAxisSpacing: vGap,
            childAspectRatio: desktop ? 0.76 : 0.72,
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
          const Expanded(
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
