import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => Divider(height: 1.h),
                      itemBuilder: (context, index) {
                        final ProductModel product = products[index];
                        final isSelected = selected.containsKey(product.id);
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selected.remove(product.id);
                              } else {
                                selected[product.id] = ProjectProductModel(
                                  productId: product.id,
                                  productName: product.nameAr,
                                );
                              }
                            });
                          },
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (_) {
                              setState(() {
                                if (isSelected) {
                                  selected.remove(product.id);
                                } else {
                                  selected[product.id] = ProjectProductModel(
                                    productId: product.id,
                                    productName: product.nameAr,
                                  );
                                }
                              });
                            },
                          ),
                          title: Text(
                            product.nameAr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [
                              product.displayProductCode,
                              if ((product.storeSectionName ?? '').isNotEmpty)
                                product.storeSectionName!,
                            ].join(' - '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
