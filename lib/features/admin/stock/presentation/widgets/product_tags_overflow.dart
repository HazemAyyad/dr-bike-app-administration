import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/product_tag_model.dart';
import 'product_tag_chip.dart';

/// Shows first tag + optional +N chip; tap +N opens all tags.
class ProductTagsOverflow extends StatelessWidget {
  const ProductTagsOverflow({
    super.key,
    required this.tags,
    this.dense = true,
  });

  final List<ProductTagModel> tags;
  final bool dense;

  void _showAllTags(BuildContext context) {
    if (tags.length <= 1) return;
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'tags'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags
                    .map(
                      (t) => ProductTagChip(
                        name: t.name,
                        colorHex: t.color,
                        dense: dense,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final first = tags.first;
    final extra = tags.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ProductTagChip(
            name: first.name,
            colorHex: first.color,
            dense: dense,
          ),
        ),
        if (extra > 0) ...[
          SizedBox(width: 3.w),
          GestureDetector(
            onTap: () => _showAllTags(context),
            child: ProductTagChip(
              name: '+$extra',
              colorHex: '#9E9E9E',
              dense: dense,
            ),
          ),
        ],
      ],
    );
  }
}
