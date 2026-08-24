import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/product_priority_image.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../projects/data/models/project_details_model.dart';
import '../../../sales/data/models/product_model.dart';
import '../controllers/target_section_controller.dart';

Future<void> showGoalProductsPickerSheet(BuildContext context) async {
  final controller = Get.find<TargetSectionController>();
  if (controller.products.isEmpty) {
    controller.getAllProducts();
  }

  final selected = <String, ProjectProductModel>{
    for (final item in controller.productsIds) item.productId: item,
  };
  String query = '';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final products = controller.products.where((product) {
            final search = query.trim().toLowerCase();
            if (search.isEmpty) return true;
            return product.nameAr.toLowerCase().contains(search) ||
                product.displayProductCode.toLowerCase().contains(search) ||
                (product.storeSectionName ?? '').toLowerCase().contains(search);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'chooseProducts'.tr,
                            style:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.operationalNavy,
                                    ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'search'.tr,
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) => setState(() => query = value),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  if (selected.isNotEmpty)
                    SizedBox(
                      height: 38.h,
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        scrollDirection: Axis.horizontal,
                        itemCount: selected.length,
                        separatorBuilder: (_, __) => SizedBox(width: 6.w),
                        itemBuilder: (_, index) {
                          final item = selected.values.elementAt(index);
                          return Chip(
                            label: Text(
                              item.productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => setState(
                              () => selected.remove(item.productId),
                            ),
                          );
                        },
                      ),
                    ),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 700 ? 4 : 2,
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 8.h,
                        mainAxisExtent: 176.h,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final ProductModel product = products[index];
                        final isSelected = selected.containsKey(product.id);
                        return _GoalProductPickerCard(
                          product: product,
                          isSelected: isSelected,
                          onTap: () => setState(() {
                            if (isSelected) {
                              selected.remove(product.id);
                            } else {
                              selected[product.id] = ProjectProductModel(
                                productId: product.id,
                                productName: product.nameAr,
                              );
                            }
                          }),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.operationalPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        onPressed: () {
                          controller.productsIds
                            ..clear()
                            ..addAll(selected.values);
                          controller.update();
                          Navigator.pop(context);
                        },
                        child: Text(
                          '${'done'.tr} (${selected.length})',
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _GoalProductPickerCard extends StatelessWidget {
  const _GoalProductPickerCard({
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  final ProductModel product;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = product.allImageUrlsInPriority.isNotEmpty &&
        product.imageUrl != 'no image';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? AppColors.operationalPurple
                  : Colors.grey.shade300,
              width: isSelected ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImage
                        ? ProductPriorityImage(
                            imageUrls: product.allImageUrlsInPriority,
                            fit: BoxFit.cover,
                            placeholder: const _ProductPlaceholder(),
                            missingPlaceholder: const _ProductPlaceholder(),
                          )
                        : const _ProductPlaceholder(),
                    Positioned(
                      top: 6.h,
                      right: 6.w,
                      child: Container(
                        height: 24.w,
                        width: 24.w,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.operationalPurple
                              : Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected ? Icons.check : Icons.add,
                          color: isSelected
                              ? Colors.white
                              : AppColors.operationalPurple,
                          size: 16.sp,
                        ),
                      ),
                    ),
                    if ((product.storeSectionName ?? '').isNotEmpty)
                      Positioned(
                        left: 6.w,
                        right: 6.w,
                        bottom: 6.h,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.58),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            product.storeSectionName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(7.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nameAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      product.displayProductCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppColors.customGreyColor5,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
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
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.operationalSurface,
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.customGreyColor5,
        size: 28.sp,
      ),
    );
  }
}
