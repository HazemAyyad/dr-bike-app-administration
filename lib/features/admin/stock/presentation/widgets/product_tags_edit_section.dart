import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/outline_input_style.dart';
import '../controllers/stock_controller.dart';
import 'product_tag_chip.dart';

Future<void> showCreateProductTagDialog() async {
  final controller = Get.find<StockController>();
  final nameCtrl = TextEditingController();
  final colorCtrl = TextEditingController(text: '#128C7E');
  final ok = await Get.dialog<bool>(
    Builder(
      builder: (ctx) => AlertDialog(
        title: Text('newProductTag'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: OutlineInputStyle.merge(
                ctx,
                labelText: 'tagName'.tr,
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: colorCtrl,
              decoration: OutlineInputStyle.merge(
                ctx,
                labelText: 'tagColor'.tr,
                hintText: '#RRGGBB',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('save'.tr),
          ),
        ],
      ),
    ),
  );
  if (ok == true) {
    final name = nameCtrl.text.trim();
    var color = colorCtrl.text.trim();
    if (name.isEmpty) {
      Get.snackbar('error'.tr, 'tagName'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
      color = '#128C7E';
    }
    try {
      await controller.createCatalogTag(name: name, color: color);
      Get.snackbar('success'.tr, 'OK', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
}

class ProductTagsEditSection extends GetView<StockController> {
  const ProductTagsEditSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active =
          controller.catalogTags.where((t) => t.isActive).toList(growable: false);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'sectionProductTags'.tr,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          SizedBox(height: 10.h),
          if (active.isEmpty)
            Text(
              'noTagsYet'.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: active.map((t) {
                final sel = controller.selectedTagIds.contains(t.id);
                return FilterChip(
                  label: Text(t.name),
                  selected: sel,
                  showCheckmark: true,
                  avatar: CircleAvatar(
                    radius: 8,
                    backgroundColor: productTagBackgroundColor(t.color),
                  ),
                  onSelected: (_) => controller.toggleProductTagSelection(t.id),
                );
              }).toList(),
            ),
          SizedBox(height: 8.h),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => showCreateProductTagDialog(),
              icon: const Icon(Icons.label_outline),
              label: Text('newProductTag'.tr),
            ),
          ),
        ],
      );
    });
  }
}
