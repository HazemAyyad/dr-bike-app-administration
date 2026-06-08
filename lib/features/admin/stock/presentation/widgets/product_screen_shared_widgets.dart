import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/admin_ui_colors.dart';

/// Shared card shell used on product details and edit screens.
class ProductHeroCard extends StatelessWidget {
  const ProductHeroCard({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ProductMetaChip extends StatelessWidget {
  const ProductMetaChip({
    Key? key,
    required this.icon,
    required this.text,
  }) : super(key: key);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AdminUiColors.subtleOverlay(context),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15.sp,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              text.trim().isEmpty ? '—' : text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCollapsibleSection extends StatelessWidget {
  const ProductCollapsibleSection({
    Key? key,
    required this.icon,
    required this.title,
    required this.countText,
    required this.expanded,
    required this.child,
    this.onToggle,
    this.trailing,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String countText;
  final bool expanded;
  final Widget child;
  final VoidCallback? onToggle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AdminUiColors.subtleOverlay(context),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  countText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: 6.w),
                trailing!,
              ],
              if (onToggle != null) ...[
                SizedBox(width: 6.w),
                TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 19.sp,
                  ),
                  label: Text(expanded ? 'إخفاء' : 'عرض'),
                ),
              ],
            ],
          ),
          if (expanded || onToggle == null) ...[
            SizedBox(height: 10.h),
            child,
          ],
        ],
      ),
    );
  }
}

class ProductMetricData {
  const ProductMetricData(
    this.icon,
    this.label,
    this.value, {
    this.onTap,
    this.trailingIcon,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final IconData? trailingIcon;
}

class ProductMetricCard extends StatelessWidget {
  const ProductMetricCard({Key? key, required this.data}) : super(key: key);

  final ProductMetricData data;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 15.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: 7.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.58),
                      ),
                ),
                SizedBox(height: 3.h),
                Text(
                  data.value.trim().isEmpty ? '—' : data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.sp,
                      ),
                ),
              ],
            ),
          ),
          if (data.onTap != null)
            Icon(
              Icons.open_in_new,
              size: 13.sp,
              color: Theme.of(context).colorScheme.primary,
            )
          else if (data.trailingIcon != null)
            Icon(
              data.trailingIcon,
              size: 14.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );

    if (data.onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: data.onTap,
        child: child,
      ),
    );
  }
}

class ProductMiniStat extends StatelessWidget {
  const ProductMiniStat({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.58),
                ),
          ),
          SizedBox(height: 2.h),
          Text(
            value.trim().isEmpty ? '—' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

/// Expandable 2-column metric grid (details read-only view).
class ProductOverviewMetricGrid extends StatefulWidget {
  const ProductOverviewMetricGrid({
    Key? key,
    required this.items,
    this.initialVisibleCount = 4,
  }) : super(key: key);

  final List<ProductMetricData> items;
  final int initialVisibleCount;

  @override
  State<ProductOverviewMetricGrid> createState() =>
      _ProductOverviewMetricGridState();
}

class _ProductOverviewMetricGridState extends State<ProductOverviewMetricGrid> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final visibleItems =
        expanded ? items : items.take(widget.initialVisibleCount).toList();

    return Column(
      children: [
        GridView.builder(
          itemCount: visibleItems.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 8.h,
            childAspectRatio: 2.85,
          ),
          itemBuilder: (context, index) =>
              ProductMetricCard(data: visibleItems[index]),
        ),
        if (items.length > widget.initialVisibleCount)
          TextButton.icon(
            onPressed: () => setState(() => expanded = !expanded),
            icon: Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 19.sp,
            ),
            label: Text(expanded ? 'عرض أقل' : 'عرض المزيد'),
          ),
      ],
    );
  }
}
