import 'package:doctorbike/core/helpers/custom_chechbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/sales_controller.dart';
import 'build_item.dart';

class AddNewInstantSaleWidget extends GetView<SalesController> {
  const AddNewInstantSaleWidget({Key? key}) : super(key: key);

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
                        label: 'item',
                        hint: 'itemExample',
                        dropdownField: controller.products.map((e) {
                          return DropdownMenuItem<String>(
                            value: e.id.toString(),
                            child: Text(e.nameAr),
                          );
                        }).toList(),
                        value: controller.products.any((e) =>
                                e.id.toString() == item.selectedItem.value)
                            ? item.selectedItem.value
                            : null,
                        onChanged: (value) {
                          item.selectedItem.value = value!;
                        },
                      ),
                    ),
                    SizedBox(width: 10.w),
                    if (controller.items.length > 1 && index != 0)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
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
                                    items: controller.products
                                        .map((a) => a.nameAr)
                                        .toList(),
                                    label: '${'item'.tr} ${index + 1} ',
                                    hint: 'itemExample',
                                    onChanged: (value) {
                                      removedItem.selectedItem.value = value!;
                                    },
                                  ),
                                  SizedBox(height: 10.h),
                                  BuildItem(
                                    item: removedItem,
                                    index: index,
                                    animation: animation,
                                  ),
                                ],
                              ),
                            ),
                            duration: const Duration(milliseconds: 300),
                          );
                        },
                      ),
                  ],
                ),
                SizedBox(height: 10.h),
                BuildItem(item: item, index: index, animation: animation),
                SizedBox(height: 10.h),
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: CustomCheckBox(
                          title: 'instantSale'.tr,
                          value: RxBool(
                              !item.selectedCustomersSellers.value == true),
                          onChanged: (val) {
                            item.selectedValue.value = null;
                            item.selectedCustomersSellers.value = false;
                          },
                        ),
                      ),
                      Flexible(
                        child: CustomCheckBox(
                          title: 'saleForProject'.tr,
                          value: RxBool(
                              !item.selectedCustomersSellers.value == false),
                          onChanged: (val) {
                            item.selectedValue.value = null;
                            item.selectedCustomersSellers.value = true;
                          },
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                Obx(
                  () => item.selectedCustomersSellers.value
                      ? CustomDropdownField(
                          label: 'projectName'.tr,
                          hint: 'projectNameExample',
                          dropdownField: controller.ongoingProjects
                              .map(
                                (e) => DropdownMenuItem<String>(
                                  value: e.id.toString(),
                                  child: Text(e.name),
                                ),
                              )
                              .toList(),
                          value: item.selectedValue.value,
                          onChanged: (val) {
                            item.selectedValue.value = val!;
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                // SizedBox(height: 10.h),
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
