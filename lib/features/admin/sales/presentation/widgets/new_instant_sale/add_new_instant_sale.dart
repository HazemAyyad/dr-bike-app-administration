import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/sales_controller.dart';
import 'build_item.dart';

class AddNewInstantSale extends StatelessWidget {
  const AddNewInstantSale({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final SalesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AnimatedList(
        key: controller.listKey,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        initialItemCount: controller.items.length,
        itemBuilder: (context, index, animation) {
          final item = controller.items[index];
          return SizeTransition(
            sizeFactor: animation,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: CustomDropdownField(
                        isRequired: true,
                        items: controller.itemsName,
                        label: '${'item'.tr} ${index + 1} ',
                        hint: 'itemExample',
                        onChanged: (value) {
                          item.selectedItem.value = value!;
                        },
                      ),
                    ),
                    SizedBox(width: 10.w),
                    if (controller.items.length > 1 && index != 0)
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          final removedItem = controller.items[index];
                          controller.removeItem(index);
                          controller.listKey.currentState?.removeItem(
                            index,
                            (context, animation) => SizeTransition(
                              sizeFactor: animation,
                              child: Column(
                                children: [
                                  CustomDropdownField(
                                    isRequired: true,
                                    items: controller.itemsName,
                                    label: '${'item'.tr} ${index + 1} ',
                                    hint: 'itemExample',
                                    onChanged: (value) {
                                      removedItem.selectedItem.value = value!;
                                    },
                                  ),
                                  SizedBox(height: 20.h),
                                  buildItem(context, item, index, animation),
                                ],
                              ),
                            ),
                            duration: Duration(milliseconds: 300),
                          );
                        },
                      ),
                  ],
                ),
                SizedBox(height: 20.h),
                buildItem(context, item, index, animation),
                SizedBox(height: 15.h),
                if (index == controller.items.length - 1)
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          controller.addItem();
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_outlined,
                              color: ThemeService.isDark.value
                                  ? AppColors.primaryColor
                                  : AppColors.secondaryColor,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              'addNewItem'.tr,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: ThemeService.isDark.value
                                        ? AppColors.primaryColor
                                        : AppColors.secondaryColor,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
