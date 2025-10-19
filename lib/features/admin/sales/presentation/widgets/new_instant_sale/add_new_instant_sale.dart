import 'package:doctorbike/core/helpers/custom_chechbox.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/product_model.dart';
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
                  children: [
                    Text(
                      'item'.tr,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor6
                                : AppColors.customGreyColor,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                    Text(
                      '*',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Colors.red,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    )
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor
                              : AppColors.whiteColor2,
                          border: Border.all(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(11.r),
                        ),
                        child: DropdownSearch<ProductModel>(
                          items: (filter, infiniteScrollProps) =>
                              controller.products,
                          itemAsString: (u) =>
                              "${u.nameAr} (${'stock'.tr}: ${u.stock})",
                          compareFn: (a, b) => a.id == b.id,
                          validator: (value) {
                            if (value == null) {
                              return 'item'.tr;
                            }
                            return null;
                          },
                          decoratorProps: DropDownDecoratorProps(
                            decoration: InputDecoration(
                              hoverColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 15.w),
                              labelText: 'itemExample'.tr,
                              labelStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: ThemeService.isDark.value
                                        ? AppColors.customGreyColor2
                                        : AppColors.customGreyColor6,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                          ),
                          popupProps:
                              const PopupProps.menu(showSearchBox: true),
                          onChanged: (value) {
                            if (value != null) {
                              item.selectedItem.value = value.id;
                            }
                          },
                        ),
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
                  () {
                    if (item.selectedCustomersSellers.value) {
                      final allProjectIds = controller.products
                          .where((p) => p.id == item.selectedItem.value)
                          .expand((p) => p.projects)
                          .map((id) => id.toString())
                          .toList();
                      return CustomDropdownField(
                        label: 'projectName'.tr,
                        hint: 'projectNameExample',
                        dropdownField: controller.ongoingProjects
                            .where((proj) =>
                                allProjectIds.contains(proj.id.toString()))
                            .map(
                              (proj) => DropdownMenuItem<String>(
                                value: proj.id.toString(),
                                child: Text(proj.name),
                              ),
                            )
                            .toList(),
                        value: item.selectedValue.value,
                        onChanged: (val) {
                          item.selectedValue.value = val!;
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                if (index == controller.items.length - 1)
                  Column(
                    children: [
                      SizedBox(height: 10.h),
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
