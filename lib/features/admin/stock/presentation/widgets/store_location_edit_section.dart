import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/outline_input_style.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/stock_controller.dart';
import '../../data/models/store_section_model.dart';
import 'product_location_badge.dart';
import '../../../../../core/helpers/app_success_notice.dart';

import '../../../../../core/helpers/app_failure_notice.dart';

Future<void> showCreateStoreSectionDialog() async {
  final controller = Get.find<StockController>();
  final nameCtrl = TextEditingController();
  final ok = await Get.dialog<bool>(
    Builder(
      builder: (ctx) {
        final onSurface = Theme.of(ctx).colorScheme.onSurface;
        final dialogBg = Theme.of(ctx).brightness == Brightness.dark
            ? AdminUiColors.cardBackground(ctx)
            : Colors.grey.shade100;
        final actionBg = Theme.of(ctx).brightness == Brightness.dark
            ? Colors.grey.shade700
            : Colors.grey.shade300;

        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(
            'newStoreSection'.tr,
            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
          ),
          content: TextField(
            controller: nameCtrl,
            style: TextStyle(color: onSurface),
            decoration: OutlineInputStyle.merge(
              ctx,
              labelText: 'storeSectionName'.tr,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              style: TextButton.styleFrom(foregroundColor: onSurface),
              child: Text('cancel'.tr),
            ),
            FilledButton(
              onPressed: () => Get.back(result: true),
              style: FilledButton.styleFrom(
                backgroundColor: actionBg,
                foregroundColor: onSurface,
              ),
              child: Text('save'.tr),
            ),
          ],
        );
      },
    ),
  );
  if (ok == true) {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      AppFailureNotice.show(
        title: 'error'.tr,
        message: 'storeSectionName'.tr,
      );
      return;
    }
    try {
      await controller.createStoreSection(name: name);
      AppSuccessNotice.show(
        title: 'success'.tr,
        message: 'OK',
      );
    } catch (e) {
      AppFailureNotice.show(
        title: 'error'.tr,
        message: e.toString(),
      );
    }
  }
}

class StoreLocationPickerTile extends GetView<StockController> {
  const StoreLocationPickerTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      if (controller.purchaseProductCreationMode.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StoreLocationDropdown(
              sections: controller.storeSections.toList(),
              selectedId: controller.selectedProductStoreSectionId.value,
              onChanged: controller.setProductStoreSection,
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: showCreateStoreSectionDialog,
                icon: const Icon(Icons.add),
                label: Text('newStoreSection'.tr),
              ),
            ),
          ],
        );
      }
      final sectionName = controller.selectedProductSectionName;
      final productCode = controller.editingProductId.value != null
          ? controller.productDetails.value?.productCode
          : null;
      final subtitle = ProductLocationLabel.withProductCode(
            sectionName: sectionName,
            productCode: productCode,
          ) ??
          'selectStoreLocationHint'.tr;

      return Material(
        color: AdminUiColors.subtleOverlay(context),
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () => showStoreLocationPickerSheet(context),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Row(
              children: [
                Icon(Icons.place_outlined, size: 20.sp, color: cs.primary),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'sectionStoreLocation'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.sp,
                            ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55),
                              fontSize: 11.sp,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left, size: 22.sp, color: cs.primary),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class StoreLocationDropdown extends StatelessWidget {
  const StoreLocationDropdown({
    Key? key,
    required this.sections,
    required this.selectedId,
    required this.onChanged,
  }) : super(key: key);

  final List<StoreSectionModel> sections;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      StoreSectionModel(id: '', name: 'بدون موقع'),
      ...sections.where((section) => section.isActive),
    ];
    final selected = options.firstWhere(
      (section) => section.id == selectedId,
      orElse: () => options.first,
    );
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DropdownSearch<StoreSectionModel>(
      selectedItem: selected,
      items: (filter, _) => options,
      itemAsString: (section) => section.name,
      compareFn: (a, b) => a.id == b.id,
      popupProps: PopupProps.menu(
        showSearchBox: true,
        showSelectedItems: true,
        searchDelay: Duration.zero,
        constraints: const BoxConstraints(maxHeight: 320),
        menuProps: MenuProps(
          backgroundColor: dark ? Colors.grey.shade900 : Colors.grey.shade100,
        ),
        searchFieldProps: TextFieldProps(
          decoration: OutlineInputStyle.merge(
            context,
            hintText: 'ابحث عن الموقع في المحل',
            base: const InputDecoration(prefixIcon: Icon(Icons.search)),
          ),
        ),
        emptyBuilder: (_, __) =>
            const Center(child: Text('لا توجد مواقع مطابقة')),
      ),
      decoratorProps: DropDownDecoratorProps(
        decoration: OutlineInputStyle.merge(
          context,
          labelText: 'storeSection'.tr,
        ),
      ),
      onChanged: (section) =>
          onChanged(section == null || section.id.isEmpty ? null : section.id),
    );
  }
}

Future<void> showStoreLocationPickerSheet(BuildContext context) async {
  final controller = Get.find<StockController>();
  await controller.ensureStoreSectionsLoaded();
  if (!context.mounted) return;

  await Get.bottomSheet<void>(
    SafeArea(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AdminUiColors.cardBackground(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: Obx(() {
          final sections = controller.storeSections
              .where((s) => s.isActive)
              .toList(growable: false);
          return ListView(
            shrinkWrap: true,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'sectionStoreLocation'.tr,
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
              StoreLocationDropdown(
                sections: sections,
                selectedId: controller.selectedProductStoreSectionId.value,
                onChanged: controller.setProductStoreSection,
              ),
              SizedBox(height: 12.h),
              FilledButton.icon(
                onPressed: () async {
                  Get.back();
                  await showCreateStoreSectionDialog();
                },
                icon: const Icon(Icons.add),
                label: Text('newStoreSection'.tr),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: Get.back,
                  child: Text('done'.tr),
                ),
              ),
            ],
          );
        }),
      ),
    ),
    isScrollControlled: true,
    backgroundColor:
        ThemeService.isDark.value ? AppColors.darkColor : AppColors.whiteColor,
  );
}
