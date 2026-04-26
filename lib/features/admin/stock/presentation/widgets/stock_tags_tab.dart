import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/stock_controller.dart';
import 'product_card.dart';
import 'product_tag_chip.dart';
import 'product_tags_edit_section.dart';

class StockTagsTab extends GetView<StockController> {
  const StockTagsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tags = controller.catalogTags.toList(growable: false);
      final active = tags.where((t) => t.isActive).toList(growable: false);
      final selectedId = controller.selectedTagFilterId.value;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'manageProductTags'.tr,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            SizedBox(height: 8.h),
            OutlinedButton.icon(
              onPressed: () => _openManageSheet(context),
              icon: const Icon(Icons.tune),
              label: Text('manageProductTags'.tr),
            ),
            SizedBox(height: 16.h),
            Text(
              'filterByTag'.tr,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 8.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: ChoiceChip(
                      label: Text('all'.tr),
                      selected: selectedId == null || selectedId.isEmpty,
                      onSelected: (_) => controller.selectTagFilter(null),
                    ),
                  ),
                  ...active.map(
                    (t) => Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: ChoiceChip(
                        avatar: CircleAvatar(
                          radius: 6,
                          backgroundColor: productTagBackgroundColor(t.color),
                        ),
                        label: Text(t.name),
                        selected: selectedId == t.id,
                        onSelected: (_) {
                          if (selectedId == t.id) {
                            controller.selectTagFilter(null);
                          } else {
                            controller.selectTagFilter(t.id);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            if (selectedId == null || selectedId.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Text(
                  'selectTagToViewProducts'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              )
            else if (controller.isLoading.value && controller.tagFilterProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.tagFilterProducts.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Text(
                  'noData'.tr,
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                  childAspectRatio: 0.7,
                ),
                itemCount: controller.tagFilterProducts.length,
                itemBuilder: (context, index) {
                  final product = controller.tagFilterProducts[index];
                  return BuildProductCard(
                    product: product,
                    isCloseouts: false,
                  );
                },
              ),
              if (controller.tagProductsLoadingMore.value)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              SizedBox(height: 40.h),
            ],
          ],
        ),
      );
    });
  }

  Future<void> _openManageSheet(BuildContext context) async {
    await controller.refreshCatalogTags();
    if (!context.mounted) {
      return;
    }
    await Get.bottomSheet<void>(
      SafeArea(
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AdminUiColors.cardBackground(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          child: Obx(() {
            final list = controller.catalogTags.toList(growable: false);
            return ListView(
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'manageProductTags'.tr,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () async {
                    Get.back();
                    await showCreateProductTagDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: Text('newProductTag'.tr),
                ),
                SizedBox(height: 12.h),
                ...list.map((t) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: productTagBackgroundColor(t.color),
                    ),
                    title: Text(t.name),
                    subtitle: Text(
                      t.isActive ? 'active'.tr : 'inactive'.tr,
                      style: TextStyle(
                        color: t.isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                    trailing: t.isActive
                        ? TextButton(
                            onPressed: () async {
                              final ok = await Get.dialog<bool>(
                                AlertDialog(
                                  title: Text('deactivateTag'.tr),
                                  content: Text('deactivateTagConfirm'.tr),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(result: false),
                                      child: Text('cancel'.tr),
                                    ),
                                    FilledButton(
                                      onPressed: () => Get.back(result: true),
                                      child: Text('deactivateTag'.tr),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                try {
                                  await controller.deactivateCatalogTag(t.id);
                                  Get.snackbar(
                                    'success'.tr,
                                    'OK',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                } catch (e) {
                                  Get.snackbar(
                                    'error'.tr,
                                    e.toString(),
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              }
                            },
                            child: Text('deactivateTag'.tr),
                          )
                        : null,
                  );
                }),
              ],
            );
          }),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
    );
  }
}
