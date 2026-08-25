import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/product_image_utils.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../sales/presentation/utils/product_image_viewer.dart';
import '../../../sales/presentation/utils/sales_amount_format.dart';
import '../controllers/maintenance_controller.dart';
import 'maintenance_service_media.dart';

class MaintenanceProductsSection extends StatelessWidget {
  const MaintenanceProductsSection({Key? key, required this.controller})
      : super(key: key);

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final isLocked =
            controller.selectedStep.value >= 4 || controller.isDelivered.value;

        return Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'maintenanceParts'.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  if (!isLocked)
                    TextButton.icon(
                      onPressed: () => _showServicesPicker(context),
                      icon:
                          Icon(Icons.home_repair_service_outlined, size: 18.sp),
                      label: Text('خدمات', style: TextStyle(fontSize: 12.sp)),
                    ),
                  if (!isLocked)
                    TextButton.icon(
                      onPressed: () => controller.openProductPicker(context),
                      icon: Icon(Icons.add, size: 18.sp),
                      label: Text('add'.tr, style: TextStyle(fontSize: 12.sp)),
                    ),
                ],
              ),
              if (controller.maintenanceProducts.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  child: Text(
                    'maintenanceNoPartsYet'.tr,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                )
              else
                _ProductsTable(controller: controller),
              if (controller.selectedMaintenanceServices.isNotEmpty) ...[
                SizedBox(height: 8.h),
                _ServicesTable(controller: controller),
              ],
              SizedBox(height: 8.h),
              _amountField(
                label: 'maintenanceLaborCost'.tr,
                controller: controller.laborCostController,
                enabled: !isLocked,
                onChanged: () {
                  controller.recalculateTotals();
                  controller.scheduleAutoSave();
                },
              ),
              SizedBox(height: 6.h),
              _amountField(
                label: 'discount'.tr,
                controller: controller.discountController,
                enabled: !isLocked,
                onChanged: () {
                  controller.recalculateTotals();
                  controller.scheduleAutoSave();
                },
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'total'.tr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    SalesAmountFormat.display(controller.invoiceTotal),
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showServicesPicker(BuildContext context) async {
    await controller.loadMaintenanceServices();
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => _MaintenanceServicesPicker(controller: controller),
    );
  }

  Widget _amountField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required VoidCallback onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: TextStyle(fontSize: 12.sp)),
        ),
        Expanded(
          flex: 3,
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 13.sp),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6.r)),
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
      ],
    );
  }
}

class _MaintenanceServicesPicker extends StatefulWidget {
  const _MaintenanceServicesPicker({required this.controller});

  final MaintenanceController controller;

  @override
  State<_MaintenanceServicesPicker> createState() =>
      _MaintenanceServicesPickerState();
}

class _MaintenanceServicesPickerState
    extends State<_MaintenanceServicesPicker> {
  final TextEditingController _searchController = TextEditingController();

  MaintenanceController get controller => widget.controller;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'خدمات الصيانة',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'بحث عن خدمة',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                onChanged: (value) =>
                    controller.loadMaintenanceServices(search: value),
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: GetBuilder<MaintenanceController>(
                  builder: (_) {
                    if (controller.isServicesLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.maintenanceServices.isEmpty) {
                      return Center(child: Text('noData'.tr));
                    }
                    return ListView.separated(
                      itemCount: controller.maintenanceServices.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (_, index) {
                        final service = controller.maintenanceServices[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.home_repair_service_outlined,
                            color: AppColors.primaryColor,
                          ),
                          title: Text(
                            service.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                '${service.price.toStringAsFixed(2)} شيكل',
                              ),
                              if (service.description.trim().isNotEmpty ||
                                  service.media.isNotEmpty) ...[
                                SizedBox(width: 6.w),
                                Icon(
                                  service.media.any((item) => item.isVideo)
                                      ? Icons.play_circle_outline
                                      : Icons.info_outline,
                                  size: 15.sp,
                                  color: AppColors.primaryColor,
                                ),
                                SizedBox(width: 2.w),
                                Flexible(
                                  child: Text(
                                    'اضغط لعرض الشرح والوسائط',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: IconButton(
                            tooltip: 'إضافة الخدمة',
                            onPressed: () {
                              controller
                                  .addMaintenanceServiceToDetails(service);
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                          onTap: () => showMaintenanceServiceDetails(
                            context,
                            service,
                            onAdd: () => controller
                                .addMaintenanceServiceToDetails(service),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductsTable extends StatelessWidget {
  const _ProductsTable({required this.controller});

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    final isLocked =
        controller.selectedStep.value >= 4 || controller.isDelivered.value;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7.r)),
            ),
            child: Row(
              children: [
                Expanded(child: _headerText('productName'.tr)),
                _headerCell('quantity'.tr, 34),
                _headerCell('price'.tr, 58),
                _headerCell('total'.tr, 62),
                if (!isLocked) SizedBox(width: 26.w),
              ],
            ),
          ),
          ...List.generate(controller.maintenanceProducts.length, (index) {
            final item = controller.maintenanceProducts[index];
            final isLast = index == controller.maintenanceProducts.length - 1;
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _ProductThumb(imageUrl: item.imageUrl),
                        SizedBox(width: 5.w),
                        Expanded(
                          child: Text(
                            item.productName.isEmpty ? '-' : item.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _dataCell('${item.quantity}', 34, center: true),
                  _dataCell(
                    SalesAmountFormat.display(item.unitPrice),
                    58,
                    center: true,
                  ),
                  _dataCell(
                    SalesAmountFormat.display(item.lineTotal),
                    62,
                    center: true,
                    bold: true,
                  ),
                  if (!isLocked)
                    SizedBox(
                      width: 26.w,
                      child: IconButton(
                        tooltip: 'delete'.tr,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints.tight(
                          Size(24.w, 24.w),
                        ),
                        icon: Icon(
                          Icons.close,
                          size: 16.sp,
                          color: Colors.red.shade500,
                        ),
                        onPressed: () => controller.removeProduct(index),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _headerText(String value) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _headerCell(String value, double width) {
    return SizedBox(
      width: width.w,
      child: Text(
        value,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _dataCell(
    String value,
    double width, {
    bool center = false,
    bool bold = false,
  }) {
    return SizedBox(
      width: width.w,
      child: Text(
        value,
        textAlign: center ? TextAlign.center : TextAlign.start,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: bold ? AppColors.primaryColor : Colors.grey.shade800,
        ),
      ),
    );
  }
}

class _ServicesTable extends StatelessWidget {
  const _ServicesTable({required this.controller});

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    final isLocked =
        controller.selectedStep.value >= 4 || controller.isDelivered.value;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFDF5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7.r)),
            ),
            child: Row(
              children: [
                Expanded(child: _headerText('الخدمة')),
                _headerCell('السعر', 72),
                if (!isLocked) SizedBox(width: 26.w),
              ],
            ),
          ),
          ...List.generate(controller.selectedMaintenanceServices.length,
              (index) {
            final item = controller.selectedMaintenanceServices[index];
            final isLast =
                index == controller.selectedMaintenanceServices.length - 1;
            return InkWell(
              onTap: () => showMaintenanceServiceDetails(context, item),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.home_repair_service_outlined,
                            size: 18.sp,
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (item.description.trim().isNotEmpty ||
                              item.media.isNotEmpty) ...[
                            SizedBox(width: 4.w),
                            Icon(
                              item.media.any((media) => media.isVideo)
                                  ? Icons.play_circle_outline
                                  : Icons.info_outline,
                              size: 17.sp,
                              color: AppColors.primaryColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                    _dataCell(
                      SalesAmountFormat.display(item.price),
                      72,
                      center: true,
                      bold: true,
                    ),
                    if (!isLocked)
                      SizedBox(
                        width: 26.w,
                        child: IconButton(
                          tooltip: 'delete'.tr,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints.tight(
                            Size(24.w, 24.w),
                          ),
                          icon: Icon(
                            Icons.close,
                            size: 16.sp,
                            color: Colors.red.shade500,
                          ),
                          onPressed: () =>
                              controller.removeMaintenanceService(index),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _headerText(String value) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _headerCell(String value, double width) {
    return SizedBox(
      width: width.w,
      child: Text(
        value,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _dataCell(
    String value,
    double width, {
    bool center = false,
    bool bold = false,
  }) {
    return SizedBox(
      width: width.w,
      child: Text(
        value,
        textAlign: center ? TextAlign.center : TextAlign.start,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: bold ? AppColors.primaryColor : Colors.grey.shade800,
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final thumbnail = ShowNetImage.getThumbnailPhoto(imageUrl);
    final hasImage = ProductImageUtils.isValidUrl(imageUrl);

    return GestureDetector(
      onTap: hasImage ? () => openProductImageViewer(context, imageUrl) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.r),
        child: SizedBox(
          width: 30.w,
          height: 30.w,
          child: hasImage
              ? CachedNetworkImage(imageUrl: thumbnail, fit: BoxFit.cover)
              : ColoredBox(
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 15.sp,
                    color: Colors.grey,
                  ),
                ),
        ),
      ),
    );
  }
}
