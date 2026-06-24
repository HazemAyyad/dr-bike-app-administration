import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../domain/product_location_utils.dart';
import '../controllers/stock_controller.dart';
import 'product_card.dart';
import '../../../../../routes/app_routes.dart';
import 'stock_product_grid_layout.dart';
import 'stock_results_count_banner.dart';

class StockLocationTab extends GetView<StockController> {
  const StockLocationTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sections = controller.storeSections
          .where((s) => s.isActive)
          .toList(growable: false);
      final selectedSectionId = controller.selectedLocationSectionId.value;
      final hasLocationFilter = selectedSectionId != null &&
          selectedSectionId.isNotEmpty;

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
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: ChoiceChip(
                      avatar: const Icon(Icons.location_off_outlined, size: 16),
                      label: Text('noLocationAssigned'.tr),
                      selected: selectedSectionId ==
                          kUnassignedStoreSectionFilterId,
                      onSelected: (_) {
                        if (selectedSectionId ==
                            kUnassignedStoreSectionFilterId) {
                          controller.selectLocationFilter(null);
                        } else {
                          controller.selectLocationFilter(
                            kUnassignedStoreSectionFilterId,
                          );
                        }
                      },
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
            SizedBox(height: 16.h),
            if (!hasLocationFilter)
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
            else ...[
              StockResultsCountBanner(
                count: controller.locationFilterTotalCount.value,
              ),
              if (controller.locationFilterProducts.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Text(
                    'noData'.tr,
                    textAlign: TextAlign.center,
                  ),
                )
              else
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
              if (controller.locationFilterProducts.isNotEmpty &&
                  controller.locationProductsLoadingMore.value)
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
