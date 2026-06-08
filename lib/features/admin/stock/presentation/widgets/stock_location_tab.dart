import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/stock_controller.dart';
import 'product_card.dart';
import '../../../../../routes/app_routes.dart';
import 'stock_product_grid_layout.dart';

class StockLocationTab extends GetView<StockController> {
  const StockLocationTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sections = controller.storeSections
          .where((s) => s.isActive)
          .toList(growable: false);
      final selectedSectionId = controller.selectedLocationSectionId.value;
      final selectedShelf = controller.selectedLocationShelf.value;
      final shelves = controller.sectionShelves.toList(growable: false);

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'manageStoreSections'.tr,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            SizedBox(height: 8.h),
            OutlinedButton.icon(
              onPressed: () async {
                await Get.toNamed(AppRoutes.STORESECTIONSSETTINGSSCREEN);
                await controller.refreshAfterStoreSectionsChanged();
              },
              icon: const Icon(Icons.settings_outlined),
              label: Text('manageStoreSections'.tr),
            ),
            SizedBox(height: 16.h),
            Text(
              'filterByStoreLocation'.tr,
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
                      selected:
                          selectedSectionId == null || selectedSectionId.isEmpty,
                      onSelected: (_) => controller.selectLocationFilter(null),
                    ),
                  ),
                  ...sections.map(
                    (s) => Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: ChoiceChip(
                        avatar: const Icon(Icons.place_outlined, size: 16),
                        label: Text(s.name),
                        selected: selectedSectionId == s.id,
                        onSelected: (_) {
                          if (selectedSectionId == s.id) {
                            controller.selectLocationFilter(null);
                          } else {
                            controller.selectLocationFilter(s.id);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (selectedSectionId != null && selectedSectionId.isNotEmpty) ...[
              SizedBox(height: 12.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: FilterChip(
                        label: Text('allShelves'.tr),
                        selected: selectedShelf == null || selectedShelf.isEmpty,
                        onSelected: (_) => controller.selectLocationShelf(null),
                      ),
                    ),
                    ...shelves.map(
                      (shelf) => Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: FilterChip(
                          label: Text('${'shelfNumber'.tr} $shelf'),
                          selected: selectedShelf == shelf,
                          onSelected: (_) {
                            if (selectedShelf == shelf) {
                              controller.selectLocationShelf(null);
                            } else {
                              controller.selectLocationShelf(shelf);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 16.h),
            if (selectedSectionId == null || selectedSectionId.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Text(
                  'selectSectionToViewProducts'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              )
            else if (controller.isLoading.value &&
                controller.locationFilterProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.locationFilterProducts.isEmpty)
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
                gridDelegate: StockProductGridLayout.delegate(
                  aspectRatio: StockProductGridLayout.aspectRatioForTab(0),
                ),
                itemCount: controller.locationFilterProducts.length,
                itemBuilder: (context, index) {
                  final product = controller.locationFilterProducts[index];
                  return Align(
                    alignment: Alignment.topCenter,
                    child: BuildProductCard(
                      product: product,
                      isCloseouts: false,
                    ),
                  );
                },
              ),
              if (controller.locationProductsLoadingMore.value)
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
}
